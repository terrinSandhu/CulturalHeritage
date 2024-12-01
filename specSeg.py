import spectral
import matplotlib.pyplot as plt

# Load your hyperspectral data
data = spectral.open_image('C:/Users/tssan/Desktop/MSE215/11-10/hyper/459/capture/459.hdr').load()

# Define indices for each region (these need adjustment based on your dataset)
uv_band_index = 0  # Assuming the first band is UV
ir_band_index = -1  # Assuming the last band is IR
vis_red_index = 29  # Example red band index in visible range
vis_green_index = 19  # Example green band index in visible range
vis_blue_index = 9  # Example blue band index in visible range

# Extract bands
uv_image = data[:, :, uv_band_index]
ir_image = data[:, :, ir_band_index]
vis_image = data[:, :, [vis_red_index, vis_green_index, vis_blue_index]]

# Normalize the images for display
uv_image_norm = (uv_image - uv_image.min()) / (uv_image.max() - uv_image.min())
ir_image_norm = (ir_image - ir_image.min()) / (ir_image.max() - ir_image.min())
vis_image_norm = (vis_image - vis_image.min()) / (vis_image.max() - vis_image.min())

# Plot the images
plt.figure(figsize=(12, 4))

# Plot the UV image in grayscale
plt.subplot(1, 3, 1)
plt.imshow(uv_image_norm, cmap="gray")
plt.title("UV Band (Grayscale)")
plt.axis("off")

# Plot the visible image in RGB
plt.subplot(1, 3, 2)
plt.imshow(vis_image_norm)
plt.title("Visible Bands (RGB)")
plt.axis("off")

# Plot the IR image in grayscale
plt.subplot(1, 3, 3)
plt.imshow(ir_image_norm, cmap="gray")
plt.title("IR Band (Grayscale)")
plt.axis("off")

plt.tight_layout()
plt.show()
