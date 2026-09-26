extends AnimatedSprite2D

const FRAME_SIZE = 32
const FRAMES_PER_SECOND = 8 # TODO: confirm animation speed
const SPRITES = "res://assets/catpack/Sprites/"
const ANIMATIONS = {
	"idle": {"sheet": SPRITES + "Classical/Individual/Idle.png"},
	"box": {"sheet": SPRITES + "Classical/Individual/Box3.png"},
	"dracula": {"sheet": SPRITES + "Halloween/draculacats.png", "row": 10, "frames": 6},
}

var dragging = false
var drag_offset = Vector2i.ZERO


func _ready():
	sprite_frames = build_sprite_frames()
	sit_on_taskbar()
	pick_next_animation()


func _process(_delta):
	if dragging:
		get_window().position = DisplayServer.mouse_get_position() - drag_offset


func _input(event):
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_offset = DisplayServer.mouse_get_position() - get_window().position
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_tree().quit()


func build_sprite_frames():
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in ANIMATIONS:
		var settings = ANIMATIONS[animation_name]
		var sheet = load(settings["sheet"])
		var y = settings.get("row", 0) * FRAME_SIZE
		var width = settings.get("frames", 0) * FRAME_SIZE
		if width == 0:
			width = sheet.get_width()
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, FRAMES_PER_SECOND)
		for x in range(0, width, FRAME_SIZE):
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(x, y, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation_name, frame)
	return frames


func sit_on_taskbar():
	var work_area = DisplayServer.screen_get_usable_rect()
	var window = get_window()
	var margin_from_right = 200 # TODO: confirm starting spot
	window.position = Vector2i(
		work_area.end.x - window.size.x - margin_from_right,
		work_area.end.y - window.size.y
	)


func pick_next_animation():
	var roll = randf()
	if roll < 0.7:
		play("idle")
	elif roll < 0.85:
		play("box")
	else:
		play("dracula")
	get_tree().create_timer(randf_range(4.0, 10.0)).timeout.connect(pick_next_animation)
