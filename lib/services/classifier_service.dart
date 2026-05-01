import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/classification_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Message passed into the isolate
// ─────────────────────────────────────────────────────────────────────────────
class _InferenceRequest {
  final SendPort replyPort;
  final String imagePath;
  final Uint8List modelBytes;
  final Map<String, String> labelMap;

  const _InferenceRequest({
    required this.replyPort,
    required this.imagePath,
    required this.modelBytes,
    required this.labelMap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate entry point — runs entirely off the main thread
// ─────────────────────────────────────────────────────────────────────────────
void _inferenceEntry(_InferenceRequest req) {
  final stopwatch = Stopwatch()..start();

  try {
    // 1. Create interpreter first to read actual input shape from model
    final interpreter = Interpreter.fromBuffer(req.modelBytes);
    final inputShape =
        interpreter.getInputTensor(0).shape; // e.g. [1, 128, 128, 3]
    final imgH = inputShape[1];
    final imgW = inputShape[2];

    // 2. Decode + resize image to model's expected size
    final rawBytes = File(req.imagePath).readAsBytesSync();
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      interpreter.close();
      req.replyPort.send({'error': 'Failed to decode image'});
      return;
    }
    final resized = img.copyResize(decoded, width: imgW, height: imgH);
    decoded = null; // free original immediately

    // 3. Normalize pixels → float32 [0, 1] in shape [1, imgH, imgW, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        imgH,
        (y) => List.generate(imgW, (x) {
          final pixel = resized.getPixel(x, y);
          // Model has a built-in Rescaling(scale=2.0, offset=-1.0) layer
          // that maps [0,1] → [-1,1] internally, so we provide [0,1] floats.
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    // 4. Read output shape, run & immediately close
    final outputShape = interpreter.getOutputTensor(0).shape; // e.g. [1, 3]
    final numClasses = outputShape.length > 1 ? outputShape[1] : outputShape[0];
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    interpreter.run(input, output);
    interpreter.close(); // ← key: close immediately to free RAM

    stopwatch.stop();

    final scores = output[0];
    final labelKeys = req.labelMap.keys.toList();

    // 5. Build sorted results
    final indexed = List.generate(
      scores.length,
      (i) =>
          MapEntry(i < labelKeys.length ? labelKeys[i] : 'class_$i', scores[i]),
    )..sort((a, b) => b.value.compareTo(a.value));

    final topClasses = indexed
        .take(3)
        .map(
          (e) => {
            'label': e.key,
            'displayName': req.labelMap[e.key] ?? e.key,
            'confidence': e.value,
          },
        )
        .toList();

    req.replyPort.send({
      'label': indexed[0].key,
      'displayName': req.labelMap[indexed[0].key] ?? indexed[0].key,
      'confidence': indexed[0].value,
      'topClasses': topClasses,
      'inferenceTimeMs': stopwatch.elapsedMilliseconds,
    });
  } catch (e) {
    req.replyPort.send({'error': e.toString()});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public service — called from the UI layer
// ─────────────────────────────────────────────────────────────────────────────
class ClassifierService {
  // Singleton label map – loaded once, lightweight (< 1 KB)
  static Map<String, String>? _labelMap;

  static Future<Map<String, String>> _loadLabelMap() async {
    if (_labelMap != null) return _labelMap!;
    final raw = await rootBundle.loadString('assets/labels.json');
    _labelMap = Map<String, String>.from(jsonDecode(raw) as Map);
    return _labelMap!;
  }

  /// Runs classification entirely inside a fresh [Isolate].
  /// The TFLite interpreter is created AND closed within the isolate,
  /// so peak RAM is bounded to a single inference window.
  static Future<ClassificationResult> classify(String imagePath) async {
    // Load assets on main thread (they must be accessed via rootBundle)
    final modelBytes = await rootBundle.load(
      'assets/model/dermavision_optimized.tflite',
    );
    final modelUint8 = modelBytes.buffer.asUint8List();
    final labelMap = await _loadLabelMap();

    // Spawn isolate
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _inferenceEntry,
      _InferenceRequest(
        replyPort: receivePort.sendPort,
        imagePath: imagePath,
        modelBytes: modelUint8,
        labelMap: labelMap,
      ),
      debugName: 'DivisionInference',
    );

    final raw = await receivePort.first as Map;
    receivePort.close();

    if (raw.containsKey('error')) {
      throw Exception(raw['error']);
    }

    final topRaw = raw['topClasses'] as List;
    return ClassificationResult(
      label: raw['label'] as String,
      displayName: raw['displayName'] as String,
      confidence: (raw['confidence'] as num).toDouble(),
      inferenceTimeMs: raw['inferenceTimeMs'] as int,
      topClasses: topRaw
          .map(
            (e) => ClassScore(
              label: e['label'] as String,
              displayName: e['displayName'] as String,
              confidence: (e['confidence'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
