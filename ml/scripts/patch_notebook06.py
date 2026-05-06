import os

NOTEBOOK_PATH = "06_EdgeDeployment.ipynb"

def patch_notebook():
    print("Checking notebook 06...")
    if not os.path.exists(NOTEBOOK_PATH):
        print(f"Error: {NOTEBOOK_PATH} not found.")
        return

    # Notebook 6 is entirely dynamic and loads the label_classes.npy
    # and dermavision_optimized.tflite model directly.
    # It automatically adapts to 4 classes since it uses np.argmax on the output.
    # No code changes are required!
    print("Notebook 6 does not require any code modifications.")
    print("It dynamically reads the 4 classes from label_classes.npy and tests the model.")
    print("You can run 06_EdgeDeployment.ipynb as is!")

if __name__ == "__main__":
    patch_notebook()
