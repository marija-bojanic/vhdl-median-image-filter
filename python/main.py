import scipy.signal as signal
import matplotlib.pyplot as plt

IMAGE_SIZE = 256

swImage = plt.imread('lenaCorrupted.bmp')

plt.imshow(swImage, cmap='gray', vmin=0, vmax=255)
plt.show()

swImageDenoised = signal.medfilt2d(swImage, 3)

plt.imshow(swImageDenoised, cmap='gray', vmin=0, vmax=255)
plt.show()