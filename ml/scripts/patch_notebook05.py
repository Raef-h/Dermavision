import os

NOTEBOOK_PATH = "05_TFLiteOptimization.ipynb"

def patch_notebook():
    if not os.path.exists(NOTEBOOK_PATH):
        print(f"Error: {NOTEBOOK_PATH} not found.")
        return

    with open(NOTEBOOK_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update to prioritize fl_noniid_model.keras
    target_str1 = """# Load best model (IID usually better)
if os.path.exists('fl_iid_model.keras'):
    model = tf.keras.models.load_model('fl_iid_model.keras')
    model_name = 'FL IID'"""
    
    replacement_str1 = """# Load best model
if os.path.exists('fl_noniid_model.keras'):
    model = tf.keras.models.load_model('fl_noniid_model.keras')
    model_name = 'FL Non-IID'
elif os.path.exists('fl_iid_model.keras'):
    model = tf.keras.models.load_model('fl_iid_model.keras')
    model_name = 'FL IID'"""

    # In JSON, it's represented differently with \n and \", so let's do a more robust replace.
    # We will search and replace the specific lines in the json cell source array.
    
    target_line1 = "\"if os.path.exists('fl_iid_model.keras'):\\n\","
    replacement_line1 = "\"if os.path.exists('fl_noniid_model.keras'):\\n\",\n        \"    model = tf.keras.models.load_model('fl_noniid_model.keras')\\n\",\n        \"    model_name = 'FL Non-IID'\\n\",\n        \"elif os.path.exists('fl_iid_model.keras'):\\n\","

    content = content.replace(target_line1, replacement_line1)
    
    target_line2 = "\"    for model_file in ['fl_iid_model.keras', 'baseline_model.keras']:\\n\","
    replacement_line2 = "\"    for model_file in ['fl_noniid_model.keras', 'fl_iid_model.keras', 'baseline_model.keras']:\\n\","
    
    content = content.replace(target_line2, replacement_line2)

    with open(NOTEBOOK_PATH, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Successfully updated {NOTEBOOK_PATH} to use the fl_noniid_model.keras model.")

if __name__ == "__main__":
    patch_notebook()
