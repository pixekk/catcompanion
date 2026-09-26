class_name Decoration
extends Window

signal moved
signal clicked
signal remove_requested

const BEDS = "res://assets/catpack/CatItems/Beds/"
const BOWLS = "res://assets/catpack/CatItems/CatToys/CatBowls.png"
const CATALOG = {
	"bed_red": {"label": "Red bed", "kind": "bed", "texture": BEDS + "CatBedRed.png", "region": Rect2(0, 0, 64, 64)},
	"bed_pink": {"label": "Pink bed", "kind": "bed", "texture": BEDS + "CatBedPink.png", "region": Rect2(0, 0, 64, 64)},
	"bed_purple": {"label": "Purple bed", "kind": "bed", "texture": BEDS + "CatBedPurple.png", "region": Rect2(0, 0, 64, 64)},
	"bed_blue": {"label": "Blue bed", "kind": "bed", "texture": BEDS + "CatBedBlue.png", "region": Rect2(0, 0, 64, 64)},
	"bed_green": {"label": "Green bed", "kind": "bed", "texture": BEDS + "CatBedGreen.png", "region": Rect2(0, 0, 64, 64)},
	"bed_brown": {"label": "Brown bed", "kind": "bed", "texture": BEDS + "CatBedBrown.png", "region": Rect2(0, 0, 64, 64)},
	"bowl_green": {"label": "Green food bowl", "kind": "bowl", "texture": BOWLS, "region": Rect2(0, 0, 16, 16)},
	"bowl_blue": {"label": "Blue food bowl", "kind": "bowl", "texture": BOWLS, "region": Rect2(16, 0, 16, 16)},
	"bowl_purple": {"label": "Purple food bowl", "kind": "bowl", "texture": BOWLS, "region": Rect2(0, 16, 16, 16)},
	"bowl_red": {"label": "Red food bowl", "kind": "bowl", "texture": BOWLS, "region": Rect2(16, 16, 16, 16)},
}
const SLEEPER_OFFSET = Vector2(16, 7)
const DRAG_THRESHOLD = 4

var type = ""
var sleeper = AnimatedSprite2D.new()
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
	var sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = AtlasTexture.new()
	sprite.texture.atlas = load(CATALOG[type]["texture"])
	sprite.texture.region = CATALOG[type]["region"]
	add_child(sprite)

	sleeper.centered = false
	sleeper.position = SLEEPER_OFFSET
	sleeper.visible = false
	add_child(sleeper)

	menu.add_item("Remove")
	menu.id_pressed.connect(func(_id): remove_requested.emit())
	add_child(menu)

	window_input.connect(on_window_input)
	apply_size()


func kind():
	return CATALOG[type]["kind"]


func apply_size():
	content_scale_factor = Settings.size
	size = Vector2i(CATALOG[type]["region"].size) * Settings.size


func rect():
	return Rect2i(position, size)


func set_sleeper(frames):
	sleeper.visible = frames != null
	if frames:
		sleeper.sprite_frames = frames
		sleeper.play("sleep")


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
