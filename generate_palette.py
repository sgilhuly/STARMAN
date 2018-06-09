from PIL import Image
palette = Image.open('palette.png')

# Assumes a 16x1 image
for i in range(16):
	rgb = [int(n/4) for n in palette.getpixel((i, 0))]
	# PALETTE 15, 65536 * Blue + 256 * Green + Red
	print('PALETTE %d, %d' % (i, rgb[0] + rgb[1] * 256 + rgb[2] * 65536))
