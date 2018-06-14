from PIL import Image

SIZE = 16

# TILES.DAT format:
# number of images
# for each image:
#   128
#   16
#   256 x pixel (1B each)

# tiles.png should be a grid of 16x16 images, in indexed mode
tiles = Image.open('assets/tiles.png')
count_x = int(tiles.width / SIZE)
count_y = int(tiles.height / SIZE)
print(count_x, '*', count_y, 'tiles')

# Default is 2 bytes, size of BASIC integer
def byts(number, nbytes=2):
	return (number).to_bytes(nbytes, byteorder='little')

# First write number of tiles
tiles_out = open('STARMAN/TILES.DAT', 'wb')
tiles_out.write(byts(count_x * count_y))
for grid_y in range(count_y):
	for grid_x in range(count_x):
		# Each image is 128 (2B), 16 (2B), then pixel data (256 x 1B)
		tiles_out.write(byts(int(SIZE * SIZE / 2)))
		tiles_out.write(byts(SIZE))
		for y in range(SIZE):
			for x in range(SIZE):
				i = tiles.getpixel((grid_x * SIZE + x, grid_y * SIZE + y))
				tiles_out.write(byts(i, nbytes=1))
tiles_out.close()
