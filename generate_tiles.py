from PIL import Image

SIZE = 16

# tiles.png should be a grid of 16x16 images, in indexed mode
tiles = Image.open('tiles.png')
count_x = int(tiles.width / SIZE)
count_y = int(tiles.height / SIZE)

# First write number of tiles
tiles_out = open('STARMAN/TILES.DAT', 'wb')
tiles_out.write((count_x * count_y).to_bytes(2, byteorder='little'))
for grid_y in range(count_y):
	for grid_x in range(count_x):
		# Each image is 128 (2B), 16 (2B), then pixel data (256 x 1B)
		tiles_out.write((int(SIZE * SIZE / 2)).to_bytes(2, byteorder='little'))
		tiles_out.write((SIZE).to_bytes(2, byteorder='little'))
		for y in range(SIZE):
			for x in range(SIZE):
				i = tiles.getpixel((grid_x * SIZE + x, grid_y * SIZE + y))
				tiles_out.write((i).to_bytes(1, byteorder='little'))
tiles_out.close()
