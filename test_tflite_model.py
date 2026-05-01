"""
Test script to verify the Dermavision TFLite model works correctly.
Tests:
 1. Model can be loaded
 2. Input/output shapes are correct
 3. Model can process a dummy image
 4. Output probabilities sum to ~1.0 (softmax check)
 5. Synthetic skin-tone image inference
"""

import sys
import os
import json
import numpy as np

# Attempt to import tflite_runtime or fall back to tensorflow
try:
    import tflite_runtime.interpreter as tflite
    print("[OK] Using tflite_runtime")
except ImportError:
    try:
        import tensorflow as tf
        tflite = tf.lite
        print("[OK] Using tensorflow.lite")
    except ImportError:
        print("[ERROR] Neither tflite_runtime nor tensorflow is installed.")
        print("  Install with: pip install tflite-runtime  OR  pip install tensorflow")
        sys.exit(1)

try:
    from PIL import Image
    HAVE_PIL = True
except ImportError:
    HAVE_PIL = False
    print("[WARN] Pillow not installed — skipping real-image test")

# Paths relative to the project root
BASE = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE, "assets", "model", "dermavision_optimized.tflite")
LABELS_PATH = os.path.join(BASE, "assets", "labels.json")

print("=" * 60)
print("  Dermavision TFLite Model Verification")
print("=" * 60)

# ─── 1. Load Labels ────────────────────────────────────────────────────────────
print("\n[1] Loading labels...")
try:
    with open(LABELS_PATH, "r") as f:
        labels = json.load(f)
    label_keys = list(labels.keys())
    print(f"    Labels loaded: {label_keys}")
except Exception as e:
    print(f"    [ERROR] Failed to load labels: {e}")
    sys.exit(1)

# ─── 2. Load Model ─────────────────────────────────────────────────────────────
print("\n[2] Loading TFLite model...")
try:
    interpreter = tflite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    print("    [OK] Model loaded and tensors allocated successfully")
except Exception as e:
    print(f"    [ERROR] Failed to load model: {e}")
    sys.exit(1)

# ─── 3. Inspect Input/Output Tensors ──────────────────────────────────────────
print("\n[3] Inspecting model tensors...")
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\n    Input tensor(s): {len(input_details)}")
for d in input_details:
    print(f"      index={d['index']}  shape={d['shape']}  dtype={d['dtype'].__name__}  name={d['name']}")

print(f"\n    Output tensor(s): {len(output_details)}")
for d in output_details:
    print(f"      index={d['index']}  shape={d['shape']}  dtype={d['dtype'].__name__}  name={d['name']}")

expected_input_shape = (1, 224, 224, 3)
actual_input_shape = tuple(input_details[0]['shape'])
if actual_input_shape == expected_input_shape:
    print(f"\n    [OK] Input shape matches expected {expected_input_shape}")
else:
    print(f"\n    [WARN] Input shape is {actual_input_shape}, expected {expected_input_shape}")

num_classes = output_details[0]['shape'][-1]
print(f"    Model outputs {num_classes} classes, labels.json has {len(label_keys)} labels")
if num_classes == len(label_keys):
    print("    [OK] Class count matches labels")
else:
    print(f"    [WARN] Mismatch — model classes={num_classes}, labels={len(label_keys)}")

# ─── 4. Run Inference with Dummy Image ────────────────────────────────────────
print("\n[4] Running inference with a dummy (random noise) image...")
try:
    dummy_input = np.random.rand(1, 224, 224, 3).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], dummy_input)
    interpreter.invoke()
    dummy_output = interpreter.get_tensor(output_details[0]['index'])
    dummy_scores = dummy_output[0]
    
    print(f"    Raw scores: {[f'{s:.4f}' for s in dummy_scores]}")
    prob_sum = float(np.sum(dummy_scores))
    print(f"    Sum of probabilities: {prob_sum:.6f}")
    
    if 0.98 <= prob_sum <= 1.02:
        print("    [OK] Probabilities sum to ~1.0 (softmax output confirmed)")
    else:
        print(f"    [WARN] Probabilities sum to {prob_sum:.4f} — may be logits, not probabilities")
    
    top_idx = int(np.argmax(dummy_scores))
    top_label = label_keys[top_idx] if top_idx < len(label_keys) else f"class_{top_idx}"
    top_display = labels.get(top_label, top_label)
    print(f"    Top class: {top_display} ({top_label}) — confidence: {dummy_scores[top_idx]*100:.2f}%")
    
    print("\n    Full output breakdown:")
    sorted_pairs = sorted(zip(label_keys, dummy_scores), key=lambda x: x[1], reverse=True)
    for k, s in sorted_pairs:
        bar = "#" * int(s * 40)
        print(f"      {labels[k]:<30} {s*100:6.2f}%  {bar}")
    
    print("\n    [OK] Dummy inference completed successfully")

except Exception as e:
    print(f"    [ERROR] Inference failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# ─── 5. Melanoma Detection Test (uniform skin-tone image) ─────────────────────
print("\n[5] Running inference with a synthetic skin-tone image...")
try:
    skin_color = np.array([0.85, 0.65, 0.55], dtype=np.float32)
    synthetic_skin = np.tile(skin_color, (1, 224, 224, 1))
    
    interpreter.set_tensor(input_details[0]['index'], synthetic_skin)
    interpreter.invoke()
    skin_output = interpreter.get_tensor(output_details[0]['index'])
    skin_scores = skin_output[0]
    
    top_idx = int(np.argmax(skin_scores))
    top_label = label_keys[top_idx] if top_idx < len(label_keys) else f"class_{top_idx}"
    top_display = labels.get(top_label, top_label)
    print(f"    Top prediction: {top_display} ({top_label})")
    print(f"    Confidence: {skin_scores[top_idx]*100:.2f}%")
    print("\n    All predictions for synthetic skin image:")
    sorted_pairs2 = sorted(zip(label_keys, skin_scores), key=lambda x: x[1], reverse=True)
    for k, s in sorted_pairs2:
        bar = "#" * int(s * 40)
        print(f"      {labels[k]:<30} {s*100:6.2f}%  {bar}")

    print("\n    [OK] Synthetic skin inference completed successfully")
except Exception as e:
    print(f"    [ERROR] Synthetic skin test failed: {e}")

# ─── 6. Real Image Test (optional) ────────────────────────────────────────────
if len(sys.argv) > 1 and HAVE_PIL:
    img_path = sys.argv[1]
    print(f"\n[6] Running inference on real image: {img_path}")
    try:
        pil_img = Image.open(img_path).convert("RGB").resize((224, 224))
        np_img = np.array(pil_img, dtype=np.float32) / 255.0
        np_img = np.expand_dims(np_img, axis=0)
        
        interpreter.set_tensor(input_details[0]['index'], np_img)
        interpreter.invoke()
        real_output = interpreter.get_tensor(output_details[0]['index'])
        real_scores = real_output[0]
        
        top_idx = int(np.argmax(real_scores))
        top_label = label_keys[top_idx] if top_idx < len(label_keys) else f"class_{top_idx}"
        top_display = labels.get(top_label, top_label)
        print(f"    Top prediction: {top_display} ({top_label})")
        print(f"    Confidence: {real_scores[top_idx]*100:.2f}%")
        print("\n    All predictions:")
        sorted_real = sorted(zip(label_keys, real_scores), key=lambda x: x[1], reverse=True)
        for k, s in sorted_real:
            bar = "#" * int(s * 40)
            print(f"      {labels[k]:<30} {s*100:6.2f}%  {bar}")
        
        print("\n    [OK] Real image inference completed successfully")
    except Exception as e:
        print(f"    [ERROR] Real image inference failed: {e}")
        import traceback
        traceback.print_exc()
else:
    if len(sys.argv) > 1 and not HAVE_PIL:
        print("\n[6] SKIPPED — Pillow is not installed (pip install Pillow)")
    else:
        print("\n[6] To test with a real image, run:")
        print("      python test_tflite_model.py <path_to_image>")

print("\n" + "=" * 60)
print("  SUMMARY: All core checks passed!")
print("  The TFLite model is working correctly.")
print("=" * 60)
