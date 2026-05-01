"""
patch_notebook01.py
====================
Programmatically edits 01_DataSetup.ipynb to support the 4th "invalid" class.

Changes made
------------
1. Section-5 heading: "3 Classes" → "4 Classes" (+ adds invalid description)
2. simplify_class() comment: "Map to 3 classes" → "Map skin lesion classes …"
3. print inside mapping cell: updated message
4. Section-6 heading: "(3000 images)" → "(4000 images)" + extra note
5. Balanced-subset cell: add glob import + invalid_paths loading
6. Image-loading cell: add loop that loads invalid images
7. Label-encoding cell: num_classes=3 → num_classes=4  (+ comment for ordering)

Run:
    python patch_notebook01.py
"""

import json
import copy

NOTEBOOK = "01_DataSetup.ipynb"


def src(cell):
    """Return the source of a cell as a single string."""
    lines = cell.get("source", [])
    return "".join(lines)


def set_src(cell, text):
    """Set the source of a cell from a multiline string."""
    # ipynb stores source as list-of-strings (each ending with \n except last)
    lines = text.splitlines(keepends=True)
    cell["source"] = lines


def patch(nb):
    cells = nb["cells"]

    for i, cell in enumerate(cells):
        s = src(cell)

        # ── 1. Section-5 markdown heading ─────────────────────────────────
        if "## 5. Simplify to 3 Classes" in s:
            set_src(cell, (
                "## 5. Simplify to 4 Classes\n"
                "\n"
                "For this project, we use 4 classes:\n"
                "- **melanoma** (mel) - Malignant skin cancer\n"
                "- **nevus** (nv) - Benign mole (most common)\n"
                "- **other** - Combined remaining skin classes\n"
                "- **invalid** - Non-skin images (from CIFAR-10)"
            ))
            print("  ✓ Section-5 heading updated")

        # ── 2 & 3. simplify_class() code cell ────────────────────────────
        elif "# Map to 3 classes" in s and "def simplify_class" in s:
            set_src(cell, (
                "# Map skin lesion classes to 3 labels (invalid loaded separately)\n"
                "def simplify_class(dx):\n"
                "    if dx == 'mel':\n"
                "        return 'melanoma'\n"
                "    elif dx == 'nv':\n"
                "        return 'nevus'\n"
                "    else:\n"
                "        return 'other'\n"
                "\n"
                "if 'metadata' in locals():\n"
                "    metadata['class'] = metadata['dx'].apply(simplify_class)\n"
                "    print(\"Simplified class distribution (skin lesions only):\")\n"
                "    print(metadata['class'].value_counts())"
            ))
            print("  ✓ simplify_class() cell updated")

        # ── 4. Section-6 markdown heading ─────────────────────────────────
        elif "## 6. Create Balanced Subset (3000 images)" in s:
            set_src(cell, (
                "## 6. Create Balanced Subset (4000 images)\n"
                "\n"
                "We take 1000 images per class for faster training.\n"
                "The 4th class (invalid) is loaded separately from ham10000_data/invalid/."
            ))
            print("  ✓ Section-6 heading updated")

        # ── 5. Balanced-subset code cell ──────────────────────────────────
        elif "# Create balanced subset" in s and "for class_name in ['melanoma', 'nevus', 'other']:" in s:
            set_src(cell, (
                "# Create balanced subset for skin lesion classes\n"
                "import glob\n"
                "SAMPLES_PER_CLASS = 1000\n"
                "INVALID_DIR = 'ham10000_data/invalid'\n"
                "\n"
                "if 'metadata' in locals():\n"
                "    subset_dfs = []\n"
                "    for class_name in ['melanoma', 'nevus', 'other']:\n"
                "        class_df = metadata[metadata['class'] == class_name]\n"
                "        # Sample with replacement if class is smaller than needed\n"
                "        if len(class_df) >= SAMPLES_PER_CLASS:\n"
                "            sampled = class_df.sample(n=SAMPLES_PER_CLASS, random_state=42)\n"
                "        else:\n"
                "            sampled = class_df.sample(n=SAMPLES_PER_CLASS, replace=True, random_state=42)\n"
                "        subset_dfs.append(sampled)\n"
                "\n"
                "    subset = pd.concat(subset_dfs, ignore_index=True)\n"
                "    subset = subset.sample(frac=1, random_state=42).reset_index(drop=True)  # Shuffle\n"
                "\n"
                "    # Load invalid image paths\n"
                "    invalid_paths = glob.glob(f'{INVALID_DIR}/*.jpg')\n"
                "    invalid_paths = invalid_paths[:SAMPLES_PER_CLASS]\n"
                "    print(f\"Found {len(invalid_paths)} invalid images in {INVALID_DIR}\")\n"
                "\n"
                "    print(f\"Skin lesion subset size: {len(subset)}\")\n"
                "    print(f\"Total images (skin + invalid): {len(subset) + len(invalid_paths)}\")\n"
                "    print(f\"\\nSkin lesion class distribution:\")\n"
                "    print(subset['class'].value_counts())"
            ))
            print("  ✓ Balanced-subset cell updated")

        # ── 6. Image-loading code cell ────────────────────────────────────
        elif "# Load all images" in s and "loading and preprocessing images" in s.lower():
            set_src(cell, (
                "from tensorflow.keras.preprocessing.image import load_img, img_to_array\n"
                "from tqdm import tqdm\n"
                "\n"
                "IMG_SIZE = 128\n"
                "\n"
                "def find_image_path(image_id):\n"
                "    \"\"\"Find image in either part1 or part2 folder.\"\"\"\n"
                "    for folder in ['HAM10000_images_part_1', 'HAM10000_images_part_2']:\n"
                "        path = f'ham10000_data/{folder}/{image_id}.jpg'\n"
                "        if os.path.exists(path):\n"
                "            return path\n"
                "    return None\n"
                "\n"
                "def load_and_preprocess(image_id):\n"
                "    \"\"\"Load and preprocess a single image.\"\"\"\n"
                "    path = find_image_path(image_id)\n"
                "    if path is None:\n"
                "        return None\n"
                "    img = load_img(path, target_size=(IMG_SIZE, IMG_SIZE))\n"
                "    img_array = img_to_array(img) / 255.0  # Normalize to [0, 1]\n"
                "    return img_array\n"
                "\n"
                "# ── Load skin lesion images ──────────────────────────────────────────\n"
                "if 'subset' in locals():\n"
                "    print(\"Loading and preprocessing skin lesion images...\")\n"
                "    images = []\n"
                "    labels = []\n"
                "    valid_indices = []\n"
                "\n"
                "    for idx, row in tqdm(subset.iterrows(), total=len(subset)):\n"
                "        img = load_and_preprocess(row['image_id'])\n"
                "        if img is not None:\n"
                "            images.append(img)\n"
                "            labels.append(row['class'])\n"
                "            valid_indices.append(idx)\n"
                "\n"
                "    # ── Load invalid images ──────────────────────────────────────────\n"
                "    print(f\"\\nLoading {len(invalid_paths)} invalid images...\")\n"
                "    for path in tqdm(invalid_paths):\n"
                "        try:\n"
                "            img = load_img(path, target_size=(IMG_SIZE, IMG_SIZE))\n"
                "            img_array = img_to_array(img) / 255.0\n"
                "            images.append(img_array)\n"
                "            labels.append('invalid')\n"
                "        except Exception as e:\n"
                "            print(f\"Skipping {path}: {e}\")\n"
                "\n"
                "    X = np.array(images)\n"
                "    print(f\"\\nDone: Loaded {len(X)} images total (skin + invalid)\")\n"
                "    print(f\"Shape: {X.shape}\")"
            ))
            print("  ✓ Image-loading cell updated")

        # ── 7. Label-encoding cell ────────────────────────────────────────
        elif "num_classes=3" in s and "LabelEncoder" in s:
            set_src(cell, (
                "# Convert labels to numbers\n"
                "# NOTE: LabelEncoder sorts alphabetically:\n"
                "#   0=invalid, 1=melanoma, 2=nevus, 3=other\n"
                "from sklearn.preprocessing import LabelEncoder\n"
                "from tensorflow.keras.utils import to_categorical\n"
                "\n"
                "if 'labels' in locals():\n"
                "    label_encoder = LabelEncoder()\n"
                "    y_encoded = label_encoder.fit_transform(labels)\n"
                "    y = to_categorical(y_encoded, num_classes=4)\n"
                "\n"
                "    print(f\"Label classes: {label_encoder.classes_}\")\n"
                "    print(f\"y shape: {y.shape}\")"
            ))
            print("  ✓ Label-encoding cell updated (num_classes=4)")


def main():
    print(f"Reading {NOTEBOOK} ...")
    with open(NOTEBOOK, "r", encoding="utf-8") as f:
        nb = json.load(f)

    nb_patched = copy.deepcopy(nb)
    patch(nb_patched)

    with open(NOTEBOOK, "w", encoding="utf-8") as f:
        json.dump(nb_patched, f, indent=1, ensure_ascii=False)

    print(f"\nDone — {NOTEBOOK} saved.")


if __name__ == "__main__":
    main()
