import tkinter as tk
from tkinter import Canvas
import numpy as np
import spectral
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib.pyplot as plt

# Load your hyperspectral data
data = spectral.open_image('C:/Users/tssan/Desktop/MSE215/11-10/hyper/462/capture/462.hdr').load()
data_rgb = data[:, :, :3]  # Use the first three bands as an RGB image for visualization

# Initialize the main GUI window
root = tk.Tk()
root.title("Hyperspectral Data Viewer")

# Function to plot the spectral data of a clicked pixel
def plot_spectra(x, y):
    spectra = data[y, x, :]  # Get the spectral profile for the selected pixel

    # Clear the existing plot
    fig.clear()
    ax = fig.add_subplot(111)
    ax.plot(spectra)
    ax.set_title(f"Spectral Profile at ({x}, {y})")
    ax.set_xlabel("Wavelength Index")
    ax.set_ylabel("Reflectance")
    
    # Update the canvas
    canvas.draw()

# Function to handle mouse click events
def on_click(event):
    x, y = int(event.x), int(event.y)
    plot_spectra(x, y)

# Convert the RGB image to a format compatible with tkinter
rgb_image = (data_rgb - data_rgb.min()) / (data_rgb.max() - data_rgb.min()) * 255
rgb_image = rgb_image.astype(np.uint8)

# Create a tkinter canvas to display the image
canvas = Canvas(root, width=rgb_image.shape[1], height=rgb_image.shape[0])
canvas.pack(side=tk.RIGHT)

# Create a matplotlib figure for the spectral plot
fig, ax = plt.subplots(figsize=(4, 4))
ax.plot([])  # Initialize with an empty plot
ax.set_title("Spectral Profile")
ax.set_xlabel("Wavelength Index")
ax.set_ylabel("Reflectance")

# Embed the matplotlib figure into tkinter
canvas_plot = FigureCanvasTkAgg(fig, master=root)
canvas_plot.get_tk_widget().pack(side=tk.LEFT)

# Load the image onto the canvas
img = tk.PhotoImage(width=rgb_image.shape[1], height=rgb_image.shape[0])
canvas.create_image((0, 0), image=img, anchor="nw")

# Bind the mouse click event to the canvas
canvas.bind("<Button-1>", on_click)

root.mainloop()
