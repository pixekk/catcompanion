extends AnimatedSprite2D

enum State { SIT, REACT, DRAG, TELEPORT }

const FRAME_SIZE = 32
const FRAMES_PER_SECOND = 8
const LAYOUTS = {
	"modern": {
		"idle": [0, 10],
		"idle2": [1, 10],
		"box_rise": [9, 12],
		"content": [15, 13],
		"blush": [17, 12],
		"annoyed": [16, 9],
	},
	"classic": {
		"idle": [0, 10],
		"idle2": [1, 10],
		"box_rise": [9, 12],
		"shy": [5, 12],
		"excited": [12, 12],
		"dance": [3, 4],
		"annoyed": [4, 8],
	},
}
const SIT_ANIMATIONS = ["idle", "idle2"]
const ANNOYED_ANIMATION = "annoyed"
const BOX_ANIMATION = "box_rise"

const SKIN_FOLDER = "res://assets/catpack/"
const PLAIN_SKINS = {
	"Cream": "Sprites/3Aug2025Update.png",
	"Orange": "CatPackDifferentSkins/OrangeCat.png",
	"White": "CatPackDifferentSkins/WhiteCat.png",
	"Grey": "CatPackDifferentSkins/Grey.png",
}
const RIBBON_COLORS = ["Red", "Pink", "Purple", "Blue", "Green", "Yellow", "Brown", "White"]
const DEFAULT_SKIN = "Cream"

const SIZES = {2: "Small", 3: "Medium", 4: "Large", 5: "Huge"}
const DEFAULT_SIZE = 4
const QUIT_ID = 100
const SETTINGS_PATH = "user://settings.cfg"

const ROAM_ZONE_HEIGHT_RATIO = 0.25
const SIT_TIME_MIN = 30.0
const SIT_TIME_MAX = 90.0
const FADE_SECONDS = 0.6
const DRAG_THRESHOLD = 4
const ANNOYED_PETS = 4
const ANNOYED_WINDOW_SECONDS = 3.0

var state = State.SIT
var sit_time_left = 0.0
var teleport_tween: Tween
var pixel_scale = DEFAULT_SIZE
var screen = 0
var skin = DEFAULT_SKIN
var pet_reactions = []
var mouse_down = false
var press_mouse_position = Vector2i.ZERO
var drag_offset = Vector2i.ZERO
var recent_pets = []
var menu: PopupMenu
var size_menu: PopupMenu
var monitor_menu: PopupMenu
var customize_menu: PopupMenu


func _ready():
	load_settings()
	apply_skin()
	animation_finished.connect(on_animation_finished)
	build_menu()
	apply_size()
	move_to_random_spot()
	sit()


func _process(delta):
	match state:
		State.SIT:
			sit_time_left -= delta
			if sit_time_left <= 0:
				teleport()
		State.DRAG:
			get_window().position = DisplayServer.mouse_get_position() - drag_offset


func _input(event):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion and mouse_down and state != State.DRAG:
		var moved = DisplayServer.mouse_get_position() - press_mouse_position
		if moved.length() > DRAG_THRESHOLD:
			start_drag()


func handle_mouse_button(event):
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		open_menu()
	elif event.button_index == MOUSE_BUTTON_LEFT and state != State.TELEPORT:
		if event.pressed:
			mouse_down = true
			press_mouse_position = DisplayServer.mouse_get_position()
		else:
			mouse_down = false
			if state == State.DRAG:
				sit()
			else:
				pet()


func sit():
	state = State.SIT
	if teleport_tween:
		teleport_tween.kill()
	modulate.a = 1.0
	sit_time_left = randf_range(SIT_TIME_MIN, SIT_TIME_MAX)
	play(SIT_ANIMATIONS.pick_random())


func pet():
	var now = Time.get_ticks_msec() / 1000.0
	recent_pets.append(now)
	recent_pets = recent_pets.filter(func(time): return now - time < ANNOYED_WINDOW_SECONDS)
	state = State.REACT
	if recent_pets.size() >= ANNOYED_PETS:
		recent_pets.clear()
		play(ANNOYED_ANIMATION)
	else:
		play(pet_reactions.pick_random())


func on_animation_finished():
	if state == State.REACT:
		sit()


func start_drag():
	state = State.DRAG
	drag_offset = press_mouse_position - get_window().position
	play("idle")


func teleport():
	state = State.TELEPORT
	play_backwards(BOX_ANIMATION)
	await animation_finished
	if state != State.TELEPORT:
		return
	teleport_tween = create_tween()
	teleport_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	teleport_tween.tween_callback(move_to_random_spot)
	teleport_tween.tween_callback(func(): flip_h = randf() < 0.5)
	teleport_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	await teleport_tween.finished
	if state != State.TELEPORT:
		return
	play(BOX_ANIMATION)
	await animation_finished
	if state == State.TELEPORT:
		sit()


func roam_zone():
	var area = Rect2(DisplayServer.screen_get_usable_rect(screen))
	var window_size = Vector2(get_window().size)
	var zone_height = area.size.y * ROAM_ZONE_HEIGHT_RATIO
	var top_left = Vector2(area.position.x, area.end.y - zone_height)
	return Rect2(top_left, Vector2(area.size.x, zone_height) - window_size)


func clamp_to_roam_zone(point):
	var zone = roam_zone()
	return point.clamp(zone.position, zone.end)


func move_to_random_spot():
	var zone = roam_zone()
	var spot = zone.position + Vector2(randf() * zone.size.x, randf() * zone.size.y)
	get_window().position = Vector2i(spot)


func skin_names():
	var names = PLAIN_SKINS.keys()
	for color in RIBBON_COLORS:
		names.append("Ribbon " + color)
	return names


func apply_skin():
	var sheet_path
	var layout
	if PLAIN_SKINS.has(skin):
		sheet_path = SKIN_FOLDER + PLAIN_SKINS[skin]
		layout = LAYOUTS["modern"]
	else:
		sheet_path = SKIN_FOLDER + "Sprites/CatwithRibbon/CatPackRibbon%s.png" % skin.trim_prefix("Ribbon ")
		layout = LAYOUTS["classic"]
	sprite_frames = build_sprite_frames(load(sheet_path), layout)
	pet_reactions = layout.keys().filter(
		func(animation_name): return animation_name not in SIT_ANIMATIONS and animation_name not in [ANNOYED_ANIMATION, BOX_ANIMATION]
	)


func build_sprite_frames(sheet, layout):
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in layout:
		var row = layout[animation_name][0]
		var frame_count = layout[animation_name][1]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, FRAMES_PER_SECOND)
		frames.set_animation_loop(animation_name, animation_name in SIT_ANIMATIONS)
		for column in frame_count:
			var frame_texture = AtlasTexture.new()
			frame_texture.atlas = sheet
			frame_texture.region = Rect2(column * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation_name, frame_texture)
	return frames


func build_menu():
	size_menu = PopupMenu.new()
	for size_option in SIZES:
		size_menu.add_radio_check_item(SIZES[size_option], size_option)
	size_menu.id_pressed.connect(on_size_chosen)

	monitor_menu = PopupMenu.new()
	monitor_menu.id_pressed.connect(on_monitor_chosen)

	customize_menu = PopupMenu.new()
	customize_menu.add_separator("Skin")
	for skin_name in skin_names():
		if skin_name == "Ribbon " + RIBBON_COLORS[0]:
			customize_menu.add_separator("Ribbon")
		customize_menu.add_radio_check_item(skin_name)
	customize_menu.index_pressed.connect(on_customize_chosen)

	menu = PopupMenu.new()
	menu.add_submenu_node_item("Size", size_menu)
	menu.add_submenu_node_item("Monitor", monitor_menu)
	menu.add_submenu_node_item("Customize", customize_menu)
	menu.add_separator()
	menu.add_item("Quit", QUIT_ID)
	menu.id_pressed.connect(on_menu_chosen)
	add_child(menu)


func open_menu():
	for index in size_menu.item_count:
		size_menu.set_item_checked(index, size_menu.get_item_id(index) == pixel_scale)
	monitor_menu.clear()
	for screen_index in DisplayServer.get_screen_count():
		monitor_menu.add_radio_check_item("Monitor %d" % (screen_index + 1), screen_index)
		monitor_menu.set_item_checked(screen_index, screen_index == screen)
	for index in customize_menu.item_count:
		customize_menu.set_item_checked(index, customize_menu.get_item_text(index) == skin)
	menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func on_size_chosen(size_option):
	pixel_scale = size_option
	apply_size()
	save_settings()
	get_window().position = Vector2i(clamp_to_roam_zone(Vector2(get_window().position)))
	sit()


func on_monitor_chosen(screen_index):
	screen = screen_index
	save_settings()
	move_to_random_spot()
	sit()


func on_customize_chosen(index):
	skin = customize_menu.get_item_text(index)
	save_settings()
	apply_skin()
	sit()


func on_menu_chosen(id):
	if id == QUIT_ID:
		get_tree().quit()


func apply_size():
	get_window().size = Vector2i(FRAME_SIZE, FRAME_SIZE) * pixel_scale


func load_settings():
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	pixel_scale = config.get_value("cat", "size", DEFAULT_SIZE)
	if not SIZES.has(pixel_scale):
		pixel_scale = DEFAULT_SIZE
	screen = config.get_value("cat", "monitor", DisplayServer.get_primary_screen())
	if screen < 0 or screen >= DisplayServer.get_screen_count():
		screen = DisplayServer.get_primary_screen()
	skin = config.get_value("cat", "skin", DEFAULT_SKIN)
	if skin not in skin_names():
		skin = DEFAULT_SKIN


func save_settings():
	var config = ConfigFile.new()
	config.set_value("cat", "size", pixel_scale)
	config.set_value("cat", "monitor", screen)
	config.set_value("cat", "skin", skin)
	config.save(SETTINGS_PATH)
