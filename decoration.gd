class_name Decoration
extends Window

signal moved
signal clicked
signal remove_requested

const BEDS = "res://assets/catpack/CatItems/Beds/"
const TOYS = "res://assets/catpack/CatItems/CatToys/"
const ROOM = "res://assets/catpack/CatItems/Decorations/CatRoomDecorations.png"
const BED_SPOT = Vector2(16, 7)
const CATALOG = {
	"bed_red": {"group": "Beds", "label": "Red bed", "kind": "bed", "texture": BEDS + "CatBedRed.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"bed_pink": {"group": "Beds", "label": "Pink bed", "kind": "bed", "texture": BEDS + "CatBedPink.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"bed_purple": {"group": "Beds", "label": "Purple bed", "kind": "bed", "texture": BEDS + "CatBedPurple.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"bed_blue": {"group": "Beds", "label": "Blue bed", "kind": "bed", "texture": BEDS + "CatBedBlue.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"bed_green": {"group": "Beds", "label": "Green bed", "kind": "bed", "texture": BEDS + "CatBedGreen.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"bed_brown": {"group": "Beds", "label": "Brown bed", "kind": "bed", "texture": BEDS + "CatBedBrown.png", "region": Rect2(0, 0, 64, 64), "spot": BED_SPOT},
	"cushion_blue": {"group": "Beds", "label": "Big blue cushion", "kind": "bed", "texture": ROOM, "region": Rect2(202, 138, 110, 82), "spot": Vector2(39, 26)},
	"bowl_green": {"group": "Food", "label": "Green food bowl", "kind": "bowl", "texture": TOYS + "CatBowls.png", "region": Rect2(0, 0, 16, 16)},
	"bowl_blue": {"group": "Food", "label": "Blue food bowl", "kind": "bowl", "texture": TOYS + "CatBowls.png", "region": Rect2(16, 0, 16, 16)},
	"bowl_purple": {"group": "Food", "label": "Purple food bowl", "kind": "bowl", "texture": TOYS + "CatBowls.png", "region": Rect2(0, 16, 16, 16)},
	"bowl_red": {"group": "Food", "label": "Red food bowl", "kind": "bowl", "texture": TOYS + "CatBowls.png", "region": Rect2(16, 16, 16, 16)},
	"ball_blue": {"group": "Toys", "label": "Blue ball", "kind": "toy", "texture": TOYS + "BlueBall-Sheet.png", "region": Rect2(0, 0, 24, 16), "frames": 5},
	"ball_orange": {"group": "Toys", "label": "Orange ball", "kind": "toy", "texture": TOYS + "OrangeBall-Sheet.png", "region": Rect2(0, 0, 24, 16), "frames": 5},
	"ball_pink": {"group": "Toys", "label": "Pink ball", "kind": "toy", "texture": TOYS + "PinkBall-Sheet.png", "region": Rect2(0, 0, 24, 16), "frames": 5},
	"toy_mouse": {"group": "Toys", "label": "Toy mouse", "kind": "toy", "texture": TOYS + "Mouse-Sheet.png", "region": Rect2(0, 0, 32, 32), "frames": 4, "stride": 42},
	"feather_wand": {"group": "Toys", "label": "Feather wand", "kind": "toy", "texture": TOYS + "CatToy.png", "region": Rect2(0, 0, 32, 32), "frames": 6},
	"scratching_post": {"group": "Toys", "label": "Scratching post", "kind": "toy", "texture": TOYS + "toyss.png", "region": Rect2(0, 0, 64, 64)},
	"cat_tower": {"group": "Furniture", "label": "Cat tower", "kind": "perch", "texture": ROOM, "region": Rect2(582, 16, 85, 175), "headroom": 12, "spot": Vector2(26, 2)},
	"plant_big": {"group": "Furniture", "label": "Big plant", "kind": "plant", "texture": ROOM, "region": Rect2(140, 299, 45, 108)},
	"plant_big_dark": {"group": "Furniture", "label": "Big plant (dark pot)", "kind": "plant", "texture": ROOM, "region": Rect2(138, 552, 45, 108)},
	"plant_small": {"group": "Furniture", "label": "Small plant", "kind": "plant", "texture": ROOM, "region": Rect2(132, 193, 23, 29)},
	"plant_small_blue": {"group": "Furniture", "label": "Small plant (blue pot)", "kind": "plant", "texture": ROOM, "region": Rect2(164, 226, 23, 29)},
}
const OCCUPANT_ANIMATIONS = {"bed": "sleep", "perch": "loaf"}
const DRAG_THRESHOLD = 4

var type = ""
var sprite = AnimatedSprite2D.new()
var occupant = AnimatedSprite2D.new()
var menu = PopupMenu.new()
var mouse_down = false
var dragging = false
var press_mouse_position = Vector2i.ZERO
var drag_offset = Vector2i.ZERO


func _init():
	borderless = true
	transparent = true
	transparent_bg = true
	unresizable = true
	always_on_top = true


func _ready():
	sprite.centered = false
	sprite.position.y = info().get("headroom", 0)
	sprite.sprite_frames = build_frames()
	add_child(sprite)

	occupant.centered = false
	occupant.position = info().get("spot", Vector2.ZERO)
	occupant.visible = false
	add_child(occupant)

	menu.add_item("Remove")
	menu.id_pressed.connect(func(_id): remove_requested.emit())
	add_child(menu)

	window_input.connect(on_window_input)
	apply_size()


func info():
	return CATALOG[type]


func kind():
	return info()["kind"]


func build_frames():
	var region = info()["region"]
	var stride = info().get("stride", region.size.x)
	var frames = SpriteFrames.new()
	var texture = load(info()["texture"])
	for index in info().get("frames", 1):
		var frame_texture = AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(region.position + Vector2(index * stride, 0), region.size)
		frames.add_frame("default", frame_texture)
	return frames


func apply_size():
	var region_size = Vector2i(info()["region"].size) + Vector2i(0, info().get("headroom", 0))
	content_scale_factor = Settings.size
	size = region_size * Settings.size


func rect():
	return Rect2i(position, size)


func set_occupant(frames):
	occupant.visible = frames != null
	if frames:
		occupant.sprite_frames = frames
		occupant.play(OCCUPANT_ANIMATIONS[kind()])


func set_playing(playing):
	if playing:
		sprite.play()
	else:
		sprite.stop()
		sprite.frame = 0


func _process(_delta):
	if dragging:
		position = DisplayServer.mouse_get_position() - drag_offset


func on_window_input(event):
	if event is InputEventMouseMotion and mouse_down and not dragging:
		var moved_distance = DisplayServer.mouse_get_position() - press_mouse_position
		if moved_distance.length() > DRAG_THRESHOLD:
			dragging = true
			drag_offset = press_mouse_position - position
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		CatMenu.popup_beside(menu, rect())
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_down = true
			press_mouse_position = DisplayServer.mouse_get_position()
		else:
			mouse_down = false
			if dragging:
				dragging = false
				moved.emit()
			else:
				clicked.emit()
