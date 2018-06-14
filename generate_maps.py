import glob, re
from xml.etree import ElementTree

# *.MAP format:
# map width (should be <= 128)
# map height (should be <= 128)
# for each tile:
#   background (0-255)
#   solid (0-3) (0x1 is human passable, 0x2 is boat passable)
# number of triggers
# for each trigger:
#   x1, y1, x2, y2
#   text length

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

	# Write the trigger count, then the number of triggers
	all_triggers = trigger_layer.findall('object')
	export_file.write(byts(len(all_triggers)))
	for trigger in all_triggers:
		x1 = int(int(trigger.attrib['x']) / 16)
		y1 = int(int(trigger.attrib['y']) / 16)
		x2 = x1 - 1 + int(int(trigger.attrib['width']) / 16)
		y2 = y1 - 1 + int(int(trigger.attrib['height']) / 16)
		export_file.write(byts(x1))
		export_file.write(byts(y1))
		export_file.write(byts(x2))
		export_file.write(byts(y2))
		trigger_script = trigger.find('properties/property[@name="script"]')
		if 'value' in trigger_script.attrib:
			trigger_bytes = trigger_script.attrib['value'].encode()
		else:
			trigger_bytes = trigger_script.text.encode()
		export_file.write(byts(len(trigger_bytes)))
		export_file.write(trigger_bytes)

	# Ignore the objects for now
	export_file.close()
	print(map_file, 'written to', export_file_name)
