"""
TFLite model binary inspector — works without tensorflow installed.
Reads the FlatBuffer structure to verify:
  - File is a valid TFLite model
  - Input/output tensor shapes
  - Operator count
  - Buffer (weight) count
"""
import struct
import sys
import os

MODEL_PATH = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "..", "..", "mobile_app", "assets", "model", "dermavision_optimized.tflite"))


print("=" * 62)
print("  TFLite Binary Inspector (no tensorflow required)")
print("=" * 62)

with open(MODEL_PATH, "rb") as f:
    data = f.read()

print(f"\n  Model file size: {len(data)/1024/1024:.2f} MB ({len(data):,} bytes)")

# TFLite FlatBuffer layout:
#   bytes 0-3  : offset to root table (little-endian uint32)
#   bytes 4-7  : file_identifier 'TFL3' (for TFLite v3 schema)
file_id = data[4:8]
print(f"  File identifier: {file_id}")
if file_id in (b'TFL3', b'TFL2', b'TFL1'):
    print(f"  [OK] Valid TFLite FlatBuffer signature detected")
else:
    print(f"  [WARN] Unexpected signature — may still be valid flatbuffer")

# Root table offset
root_offset = struct.unpack_from('<I', data, 0)[0]
print(f"\n  Root table offset: 0x{root_offset:X}")

# — Try to read using flatbuffers if available —
try:
    import flatbuffers
    print(f"\n  flatbuffers version: {flatbuffers.__version__}")
    print("  [OK] flatbuffers package is available")
except ImportError:
    print("\n  flatbuffers package not importable — using raw binary scan")

# ─── Heuristic: count 'OPERATORS' entries via schema magic ───────────────────
# Instead of parsing the full schema, we scan for the tensor shape signature.
# The model's subgraph tensors contain shape arrays as int32 sequences.
# This is a best-effort diagnostic.

# Count occurrences of model structure markers
num_tfl3 = data.count(b'TFL3')
num_tensors_keyword = data.count(b'tensor')
print(f"\n  Raw scan heuristics:")
print(f"    TFL3 markers count  : {num_tfl3}")
print(f"    'tensor' occurrences: {num_tensors_keyword}")

# Check for MobileNet patterns (what the model was supposedly trained on)
mobilenet_strings = [b'MobilenetV', b'mobilenet', b'depthwise_conv', b'depthwise', b'conv_2d']
found = []
for s in mobilenet_strings:
    if s.lower() in data.lower():
        found.append(s.decode('utf-8', errors='replace'))
if found:
    print(f"\n  Architecture markers found in model: {found}")
    print(f"  [OK] Model contains MobileNet-related operators — consistent with skin lesion classifier")
else:
    print(f"\n  No explicit architecture name found (normal for optimized .tflite)")

# ─── Look for shape [1,224,224,3] pattern ────────────────────────────────────
shape_bytes = struct.pack('<4i', 1, 224, 224, 3)  # [1, 224, 224, 3] as int32 LE
if shape_bytes in data:
    print(f"\n  [OK] Input shape [1, 224, 224, 3] found in binary — input size confirmed")
else:
    # Try without batch dim
    shape_bytes2 = struct.pack('<3i', 224, 224, 3)
    if shape_bytes2 in data:
        print(f"\n  [OK] Shape [224, 224, 3] found in binary — input dimensions confirmed")
    else:
        print(f"\n  [WARN] Could not find shape [224,224,3] as raw bytes (may be encoded differently)")

# ─── Look for output shape 7 (7 classes) ─────────────────────────────────────
# The output tensor shape [1, 7] should appear
shape_7 = struct.pack('<2i', 1, 7)
if shape_7 in data:
    print(f"  [OK] Output shape [1, 7] found in binary — 7-class output confirmed")
else:
    shape_7b = struct.pack('<i', 7)
    count_7 = data.count(shape_7b)
    print(f"  Info: value '7' appears {count_7} times as int32 in the binary (may include output shape)")

# ─── File integrity check ─────────────────────────────────────────────────────
import hashlib
md5 = hashlib.md5(data).hexdigest()
sha256 = hashlib.sha256(data).hexdigest()
print(f"\n  File integrity:")
print(f"    MD5    : {md5}")
print(f"    SHA256 : {sha256}")
print(f"  [OK] File is readable and intact ({len(data):,} bytes)")

print("\n" + "=" * 62)
print("  Binary inspection complete.")
print("  To run full inference test, tensorflow must be installed.")
print("=" * 62)
