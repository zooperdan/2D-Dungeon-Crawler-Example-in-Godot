#
# Simple implementation of a 2D dungeon crawler render.
# This loads atlases generated using the AtlasMaker (https://github.com/zooperdan/AtlasMaker-for-2D-Dungeon-Crawlers)
#
# Written by zooperdan
#

extends Node2D

var screen = {width = 320, height = 256}
var atlasData
var atlasTexture

var party = {
	direction = 2,
	x = 1,
	y = 1
}

var map = {
	width = 8,
	height = 8,
	squares = [
		[1,1,1,1,1,1,1,1],
		[1,0,0,0,1,0,0,1],
		[1,0,1,0,1,1,0,1],
		[1,0,0,1,0,0,0,1],
		[1,1,0,1,1,0,1,1],
		[1,0,0,0,0,0,1,1],
		[1,0,1,0,1,0,0,1],
		[1,1,1,1,1,1,1,1]
	],
	objects = [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,1,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,1,0,0,0,0],
		[0,0,0,0,0,0,0,0]
	],
	doors = [
		[0,0,0,0,0,0,1,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,1],
		[0,0,0,1,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[1,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,1,0,0,0,1,0,0]
	]	
}

func _ready():
	loadJSON()
	RenderingServer.set_default_clear_color(Color(0.0,0.0,0.0,1.0))
	atlasTexture = preload("res://Atlases/atlas.png")
	
func get_cropped_texture(texture: Texture2D, region: Rect2) -> Texture2D:
	var result := AtlasTexture.new()
	result.set_atlas(texture)
	result.set_region(region)
	return result
	
func loadJSON():

	

	var json = FileAccess.get_file_as_string("res://Atlases/atlas.json")

	var data = JSON.parse_string(json)

	atlasData = {
		version = data.version,
		generated = data.generated,
		resolution = data.resolution,
		depth = data.depth,
		width = data.width,
		layers = {}
	}
	
	for i in range(0, data.layers.size()):
		atlasData.layers[data.layers[i].name] = data.layers[i]
	
	

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("forward"):
			moveForward()
		if event.is_action_pressed("backward"):
			moveBackward()
		if event.is_action_pressed("strafe_left"):
			strafeLeft()
		if event.is_action_pressed("strafe_right"):
			strafeRight()
		if event.is_action_pressed("turn_left"):
			turnLeft()
		if event.is_action_pressed("turn_right"):
			turnRight()

func _draw():
	renderDungeon()
		
func _process(delta):
	queue_redraw()	
	
func canMove(pos: Vector2):
	
	# can't move through walls
	if map.squares[pos.y][pos.x] == 1:
		return false

	# can't step over chests
	if map.objects[pos.y][pos.x] == 1:
		return false
	
	return true

func invertDirection(direction:int):
	if direction == 0: return 2
	if direction == 1: return 3
	if direction == 2: return 0
	if direction == 3: return 1

func getDestPos(direction:int):
	
	var vec = Vector2(
		sin(deg_to_rad(direction*90)),
		-cos(deg_to_rad(direction*90))
	)

	vec.x = vec.x + party.x
	vec.y = vec.y + party.y
	
	return vec
				
func moveForward():

	var destPos = getDestPos(party.direction)

	if canMove(destPos):
		party.x = destPos.x
		party.y = destPos.y
	
func moveBackward():

	var destPos = getDestPos(invertDirection(party.direction))

	if canMove(destPos):
		party.x = destPos.x
		party.y = destPos.y
		
func strafeLeft():

	var direction = party.direction - 1
	if direction < 0: direction = 3
	
	var destPos = getDestPos(direction)

	if canMove(destPos):
		party.x = destPos.x
		party.y = destPos.y		
	
func strafeRight():

	var direction = party.direction + 1
	if direction > 3: direction = 0
	
	var destPos = getDestPos(direction)

	if canMove(destPos):
		party.x = destPos.x
		party.y = destPos.y		
			
func turnLeft():
	party.direction = party.direction - 1
	if party.direction < 0:
		party.direction = 3
		
func turnRight():
	party.direction = party.direction + 1
	if party.direction > 3:
		party.direction = 0
			
func getPlayerDirectionVectorOffsets(x, z):

	if party.direction == 0:
		return { x = party.x + x, y = party.y + z }
	elif party.direction == 1:
		return { x = party.x - z, y = party.y + x }
	elif party.direction == 2:
		return { x = party.x - x, y = party.y - z }
	elif party.direction == 3:
		return { x = party.x + z, y = party.y - x }

func getTileFromAtlas(layerId, tileType, x, z):

	if not atlasData.layers.has(layerId): return null

	var layer = atlasData.layers[layerId]
	
	
	
	for i in range(0, layer.tiles.size()):
		var tile = layer.tiles[i]
		if tile.type == tileType and tile.tile.x == x and tile.tile.y == z:
			return tile

	return null

func drawFrontWalls(layerId, x, z):
	
	var bothsides = atlasData.layers[layerId] and atlasData.layers[layerId].mode == 2
	
	var xx = x - (x * 2) if bothsides else 0
	var tile = getTileFromAtlas(layerId, "front", xx, z);

	if tile:
		var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
		var tx = tile.screen.x + (x * tile.coords.w)
		draw_set_transform(Vector2(tx, tile.screen.y), 0, Vector2(1,1))
		draw_texture(txt, Vector2(0,0))
		
func drawSideWalls(layerId, x, z):

	if x <= 0:
		var tile = getTileFromAtlas(layerId, "side", x - (x * 2), z);
		if tile:
			var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
			draw_set_transform(Vector2(tile.screen.x, tile.screen.y), 0, Vector2(1,1))
			draw_texture(txt, Vector2(0,0))

	if x >= 0:
		var tile = getTileFromAtlas(layerId, "side", x, z);
		if tile:
			var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
			var tx = screen.width - tile.screen.x
			draw_set_transform(Vector2(tx, tile.screen.y), 0, Vector2(-1,1))
			draw_texture(txt, Vector2(0,0))
	
func drawObject(layerId, x, z):

	var bothsides = atlasData.layers[layerId] and atlasData.layers[layerId].mode == 2
	
	var xx = x - (x * 2) if bothsides else 0
	var tile = getTileFromAtlas(layerId, "object", xx, z);

	if tile:
		var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
		draw_set_transform(Vector2(tile.screen.x, tile.screen.y), 0, Vector2(1,1))
		draw_texture(txt, Vector2(0,0))

func drawFrontDoors(layerId, x, z):
	
	var xx = x - (x * 2)
	var tile = getTileFromAtlas(layerId, "front", xx , z);

	if tile:
		var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
		var tx = tile.screen.x + (x * tile.coords.w)
		draw_set_transform(Vector2(tx, tile.screen.y), 0, Vector2(1,1))
		draw_texture(txt, Vector2(0,0))
			
func drawSideDoors(layerId, x, z):

	if x <= 0:
		var tile = getTileFromAtlas(layerId, "side", x - (x * 2), z);
		if tile:
			var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
			draw_set_transform(Vector2(tile.screen.x, tile.screen.y), 0, Vector2(1,1))
			draw_texture(txt, Vector2(0,0))

	if x >= 0:
		var tile = getTileFromAtlas(layerId, "side", x, z);
		if tile:
			var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
			var tx = screen.width - tile.screen.x
			draw_set_transform(Vector2(tx, tile.screen.y), 0, Vector2(-1,1))
			draw_texture(txt, Vector2(0,0))
						
func drawMapCell(x, z):

	var p = getPlayerDirectionVectorOffsets(x, z);

	if p.x >= 0 and p.y >= 0 and p.x < map.width and p.y < map.height:
		if map.squares[p.y][p.x] == 1:
			drawSideWalls("wall", x, z)
			drawFrontWalls("wall", x, z)
		if map.doors[p.y][p.x] != 0:
			drawFrontDoors("door", x, z)
			drawSideDoors("door", x, z)
		if map.objects[p.y][p.x] != 0:
			drawObject("object", x, z)

func drawBackground(layerId):
	
	var bothsides = atlasData.layers[layerId] and atlasData.layers[layerId].mode == 2

	for z in range(-atlasData.depth, 1):

		for x in range(-atlasData.width, atlasData.width):

			var xx = x - (x * 2) if bothsides else 0
			var tile = getTileFromAtlas(layerId, layerId, xx, z);
			
			if tile:
				var txt = get_cropped_texture(atlasTexture, Rect2(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h))
				draw_set_transform(Vector2(tile.screen.x, tile.screen.y), 0, Vector2(1,1))
				draw_texture(txt, Vector2(0,0))
					

func renderDungeon():
	
	drawBackground("ground")
	drawBackground("ceiling")
		
	for z in range(-atlasData.depth, 1):
		for x in range(-atlasData.width, 0):
			drawMapCell(x, z)
		for x in range(atlasData.width, 0, -1):
			drawMapCell(x, z)
		drawMapCell(0, z)

