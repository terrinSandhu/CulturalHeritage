import spectral  # Import Spectral Python for handling hyperspectral data
import numpy as np
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt

# Step 1: Load hyperspectral data (ENVI format)
data = spectral.open_image('C:/Users/tssan/Desktop/MSE215/11-10/hyper/462/capture/462.hdr').load()

# Step 2: Preprocess data (e.g., normalization)
data = data / np.max(data)  # Normalize the data

# Step 3: Dimensionality Reduction (e.g., PCA to reduce spectral bands)
pca = PCA(n_components=3)  # Reduce to 3 components for visualization
data_reshaped = data.reshape(-1, data.shape[2])  # Flatten spatial dimensions
data_reduced = pca.fit_transform(data_reshaped)
data_pca = data_reduced.reshape(data.shape[0], data.shape[1], 3)  # Reshape back

# Step 4: Visualization (using the first 3 principal components as RGB)
plt.imshow((data_pca - data_pca.min()) / (data_pca.max() - data_pca.min()))  # Normalize for display
plt.title("PCA Visualization of Hyperspectral Data")
plt.show()


