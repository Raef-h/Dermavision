import numpy as np
classes = np.load('label_classes.npy', allow_pickle=True)
print("Classes:", list(classes))
print("Count:", len(classes))
