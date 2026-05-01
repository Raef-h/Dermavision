"""
convert_and_test.py
====================
1. Loads the best available Keras model (fl_iid_model.keras preferred)
2. Converts it to TFLite WITHOUT quantization — pure float32
   (tf.lite.Optimize.DEFAULT was removed because it triggers FULLY_CONNECTED v12
    which is only supported by TFLite runtime >= 2.17)
3. Saves it to assets/model/dermavision_optimized.tflite  (replaces old one)
4. Runs inference with:
   a) A dummy random-noise image
   b) A synthetic skin-tone image
   c) A real image if you pass one as a CLI argument:
         python convert_and_test.py path/to/skin_image.jpg
"""

import sys, os, json, shutil
import numpy as np

BASE   = os.path.dirname(os.path.abspath(__file__))
OUT    = os.path.join(BASE, "assets", "model", "dermavision_optimized.tflite")
LABELS = os.path.join(BASE, "assets", "labels.json")

SEP = "=" * 60

# ── Import TF ────────────────────────────────────────────────────────────────
print(SEP)
print("  Step 1 · Importing TensorFlow")
print(SEP)
try:
    import tensorflow as tf
    print(f"  [OK] TensorFlow {tf.__version__}")
except ImportError:
    print("  [ERROR] TensorFlow not found in this Python environment.")
    print("  Activate the tf-env and re-run:  .\\tf-env\\Scripts\\python.exe convert_and_test.py")
    sys.exit(1)

# ── Pick Keras model ─────────────────────────────────────────────────────────
print(f"\n{SEP}")
print("  Step 2 · Loading Keras model")
print(SEP)

CANDIDATES = [
    os.path.join(BASE, "fl_iid_model.keras"),
    os.path.join(BASE, "fl_noniid_model.keras"),
    os.path.join(BASE, "baseline_model.keras"),
]

model = None
chosen = None
for path in CANDIDATES:
    if os.path.exists(path):
        print(f"  Trying: {os.path.basename(path)} …")
        try:
            model = tf.keras.models.load_model(path)
            chosen = path
            print(f"  [OK] Loaded: {os.path.basename(path)}")
            break
        except Exception as e:
            print(f"  [SKIP] {e}")

if model is None:
    print("  [ERROR] No suitable Keras model found in project root.")
    sys.exit(1)

model.summary(print_fn=lambda x: print("  " + x))

# ── Convert to TFLite ────────────────────────────────────────────────────────
print(f"\n{SEP}")
print("  Step 3 · Converting to TFLite")
print(SEP)

converter = tf.lite.TFLiteConverter.from_keras_model(model)
# NOTE: Do NOT use tf.lite.Optimize.DEFAULT here!
# DEFAULT triggers dynamic-range quantization, which causes FULLY_CONNECTED
# to output op version 12 — only supported by TFLite runtime >= 2.17.
# tflite_flutter 0.10.x and 0.11.x bundle TFLite < 2.17, so they crash.
# Plain float32 conversion produces FULLY_CONNECTED v4 (compatible everywhere).
tflite_bytes = converter.convert()

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "wb") as f:
    f.write(tflite_bytes)

size_kb = len(tflite_bytes) / 1024
print(f"  [OK] TFLite model saved → {OUT}")
print(f"       Size: {size_kb:.1f} KB")

# ── Reload & inspect ─────────────────────────────────────────────────────────
print(f"\n{SEP}")
print("  Step 4 · Reloading model + inspecting tensors")
print(SEP)

interp = tf.lite.Interpreter(model_content=tflite_bytes)
interp.allocate_tensors()
inp_d = interp.get_input_details()[0]
out_d = interp.get_output_details()[0]
print(f"  Input  shape  : {inp_d['shape']}   dtype={inp_d['dtype'].__name__}")
print(f"  Output shape  : {out_d['shape']}   dtype={out_d['dtype'].__name__}")

num_classes = int(out_d['shape'][-1])

# ── Load labels ──────────────────────────────────────────────────────────────
labels   = json.load(open(LABELS))
lbl_keys = list(labels.keys())
print(f"  Labels ({len(lbl_keys)}): {lbl_keys}")
if num_classes != len(lbl_keys):
    print(f"  [WARN] Model outputs {num_classes} classes but labels.json has {len(lbl_keys)}")

def run_and_print(tag, image_array):
    """Run inference and pretty-print results."""
    interp.set_tensor(inp_d['index'], image_array.astype(np.float32))
    interp.invoke()
    scores = interp.get_tensor(out_d['index'])[0]
    prob_sum = float(np.sum(scores))
    top_i = int(np.argmax(scores))
    top_k = lbl_keys[top_i] if top_i < len(lbl_keys) else f"class_{top_i}"
    print(f"\n  [{tag}]")
    print(f"  Probability sum : {prob_sum:.4f}  {'(softmax ✓)' if 0.97 < prob_sum < 1.03 else '(not softmax!)'}")
    print(f"  Top prediction  : {labels.get(top_k, top_k)} ({top_k})  —  {scores[top_i]*100:.2f}%")
    print("  All classes:")
    for k, s in sorted(zip(lbl_keys, scores), key=lambda x: -x[1]):
        bar = "#" * int(s * 30)
        print(f"    {labels.get(k, k):<28} {s*100:5.1f}%  {bar}")
    return scores

# ── Test A: random noise ──────────────────────────────────────────────────────
print(f"\n{SEP}")
print("  Step 5a · Dummy (random noise) inference")
print(SEP)
inp_h = int(inp_d['shape'][1])
inp_w = int(inp_d['shape'][2])
dummy = np.random.rand(1, inp_h, inp_w, 3)
run_and_print("DUMMY", dummy)

# ── Test B: synthetic skin tone ───────────────────────────────────────────────
print(f"\n{SEP}")
print("  Step 5b · Synthetic skin-tone inference")
print(SEP)
skin = np.tile(np.array([0.85, 0.65, 0.55], dtype=np.float32), (1, inp_h, inp_w, 1))
run_and_print("SKIN", skin)

# ── Test C: real image (optional) ─────────────────────────────────────────────
if len(sys.argv) > 1:
    img_path = sys.argv[1]
    print(f"\n{SEP}")
    print(f"  Step 5c · Real image inference: {img_path}")
    print(SEP)
    try:
        from PIL import Image
        pil = Image.open(img_path).convert("RGB").resize((inp_w, inp_h))
        np_img = np.expand_dims(np.array(pil, dtype=np.float32) / 255.0, 0)
        run_and_print("REAL IMAGE", np_img)
    except ImportError:
        print("  [WARN] Pillow not installed. Install with: pip install Pillow")
    except Exception as e:
        print(f"  [ERROR] {e}")
else:
    print(f"\n  TIP: Pass a real image to test it:")
    print(f"         .\\tf-env\\Scripts\\python.exe convert_and_test.py path\\to\\image.jpg")

print(f"\n{SEP}")
print("  ✓  Conversion + tests complete!")
print(f"  Model ready at: assets/model/dermavision_optimized.tflite")
print(SEP)
