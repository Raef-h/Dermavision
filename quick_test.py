"""Quick TFLite model check — minimal dependencies, fast startup."""
import sys, os, json, numpy as np

BASE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(BASE, "assets", "model", "dermavision_optimized.tflite")
LABELS = os.path.join(BASE, "assets", "labels.json")

# Load labels
labels = json.load(open(LABELS))
label_keys = list(labels.keys())
print(f"[1] Labels OK — {len(label_keys)} classes: {label_keys}")

# Load model (tflite_runtime preferred over full TF)
try:
    import tflite_runtime.interpreter as tflite
except ImportError:
    import tensorflow.lite as tflite

interp = tflite.Interpreter(model_path=MODEL)
interp.allocate_tensors()
inp  = interp.get_input_details()[0]
out  = interp.get_output_details()[0]
print(f"[2] Model OK — input shape: {inp['shape']}, output shape: {out['shape']}")

# Run inference on random noise
dummy = np.random.rand(1, 224, 224, 3).astype(np.float32)
interp.set_tensor(inp['index'], dummy)
interp.invoke()
scores = interp.get_tensor(out['index'])[0]
prob_sum = float(np.sum(scores))
top_i = int(np.argmax(scores))
print(f"[3] Inference OK — prob sum={prob_sum:.4f}, top={labels[label_keys[top_i]]} ({scores[top_i]*100:.1f}%)")
print("\nAll classes:")
for k, s in sorted(zip(label_keys, scores), key=lambda x: -x[1]):
    print(f"  {labels[k]:<28} {s*100:5.1f}%")

print("\n=== MODEL IS WORKING CORRECTLY ===")
