import glob, re
from xml.etree import ElementTree

# *.MAP format:
# map width (should be <= 128) (2B)
# map height (should be <= 128) (2B)
# for each tile:
#   background (0-255) (2B)
#   solid (0-3) (2B) (0x1 is human passable, 0x2 is boat passable)

# Default is 2 bytes, size of BASIC integer
def byts(number, nbytes=2):
	return (number).to_bytes(nbytes, byteorder='little')

# Find each tmx file, and export to the appropriately named MAP file
for map_file in glob.glob('assets/*.tmx'):
	export_file_name = re.sub('^assets/', 'STARMAN/',
		re.sub('.tmx$', '.MAP', map_file)).upper()
	export_file = open(export_file_name, 'wb')

	# Assume that the xml is well formed 
	root = ElementTree.parse(map_file).getroot()
	export_file.write(byts(int(root.attrib['width'])))
	export_file.write(byts(int(root.attrib['height'])))

	# Find tiles and solid offsets, and the layers solid, messages, background
	tile_tileset = root.find('tileset[@source="tiles.tsx"]')
	tile_offset = int(tile_tileset.attrib['firstgid'])
	solid_tileset = root.find('tileset[@source="solid.tsx"]')
	solid_offset = int(solid_tileset.attrib['firstgid'])

	tile_layer = root.find('layer[@name="background"]')
	solid_layer = root.find('layer[@name="solid"]')
	object_layer = root.find('objectgroup[@name="objects"]')
	trigger_layer = root.find('objectgroup[@name="triggers"]')

	# Write the tile data and the solid data
	tile_data = tile_layer.find('data').text.replace('\n', '').split(',')
	solid_data = solid_layer.find('data').text.replace('\n', '').split(',')
	for i in range(len(tile_data)):
		# Discard flips and rotates for now
		export_file.write(byts((int(tile_data[i]) - tile_offset) & 0xff))
		export_file.write(byts(int(solid_data[i]) - solid_offset))

	# Ignore the objects and triggers for now
	export_file.close()
	print(map_file, 'written to', export_file_name)
