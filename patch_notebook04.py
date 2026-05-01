import os

NOTEBOOK_PATH = "04_FL_NonIID_MobileNet.ipynb"

def patch_notebook():
    if not os.path.exists(NOTEBOOK_PATH):
        print(f"Error: {NOTEBOOK_PATH} not found.")
        return

    with open(NOTEBOOK_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update Dense layer
    target_str1 = "\"    outputs = Dense(3, activation='softmax')(x)\\n\","
    replacement_str1 = "\"    outputs = Dense(4, activation='softmax')(x)\\n\","
    content = content.replace(target_str1, replacement_str1)

    # 2. Update split_data_noniid range(3) -> range(4)
    target_str2 = "\"    for class_idx in range(3):\\n\","
    replacement_str2 = "\"    for class_idx in range(4):\\n\","
    content = content.replace(target_str2, replacement_str2)

    target_str3 = "\"        for other_class in range(3):\\n\","
    replacement_str3 = "\"        for other_class in range(4):\\n\","
    content = content.replace(target_str3, replacement_str3)

    # 3. Update primary_class = client_id % 3
    target_str4 = "\"        primary_class = client_id % 3\\n\","
    replacement_str4 = "\"        primary_class = client_id % 4\\n\","
    content = content.replace(target_str4, replacement_str4)

    # 4. Update confusion matrix labels
    target_str5 = "xticklabels=['melanoma', 'nevus', 'other'], yticklabels=['melanoma', 'nevus', 'other']"
    replacement_str5 = "xticklabels=['invalid', 'melanoma', 'nevus', 'other'], yticklabels=['invalid', 'melanoma', 'nevus', 'other']"
    content = content.replace(target_str5, replacement_str5)

    # 5. Update classification report labels
    target_str6 = "target_names=['melanoma', 'nevus', 'other']"
    replacement_str6 = "target_names=['invalid', 'melanoma', 'nevus', 'other']"
    content = content.replace(target_str6, replacement_str6)

    with open(NOTEBOOK_PATH, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Successfully updated {NOTEBOOK_PATH} to 4 classes.")

if __name__ == "__main__":
    patch_notebook()
