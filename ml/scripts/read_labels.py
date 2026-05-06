import numpy as np
import os
classes = np.load(os.path.join(os.path.dirname(__file__), '..', 'data', 'label_classes.npy'), allow_pickle=True)
print("Classes:", list(classes))
print("Count:", len(classes))

