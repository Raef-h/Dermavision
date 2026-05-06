import os

NOTEBOOK_PATH = "02_BaselineCNN_MobileNet.ipynb"

def patch_notebook():
    if not os.path.exists(NOTEBOOK_PATH):
        print(f"Error: {NOTEBOOK_PATH} not found.")
        return

    with open(NOTEBOOK_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    target_str = "\"    outputs = Dense(3, activation='softmax')(x)\\n\","
    replacement_str = "\"    outputs = Dense(4, activation='softmax')(x)\\n\","

    new_content = content.replace(target_str, replacement_str)

    if new_content != content:
        with open(NOTEBOOK_PATH, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Successfully updated {NOTEBOOK_PATH} to 4 classes.")
    else:
        print(f"No changes were needed or target string was not found in {NOTEBOOK_PATH}.")

if __name__ == "__main__":
    patch_notebook()
