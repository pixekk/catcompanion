extends AnimatedSprite2D

enum State { SIT, BUSY, DRAG, HIDDEN }

const ROAM_ZONE_HEIGHT_RATIO = 0.25
const SIT_TIME_MIN = 20.0
const SIT_TIME_MAX = 60.0
const FADE_SECONDS = 0.6
const DRAG_THRESHOLD = 4
const ANNOYED_PETS = 4
const ANNOYED_WINDOW_SECONDS = 3.0
const AWAY_SECONDS = 300
const OFFSCREEN = Vector2i(-100000, -100000)
const SIT_ANIMATIONS = ["idle", "idle2", "wait"]
const MUSIC_APPS = ["spotify", "applemusic", "itunes", "tidal", "deezer", "foobar2000", "aimp", "musicbee", "vlc"]
const BOWL_OFFSET = Vector2i(-2, -16)
const STROKE_DISTANCE = 600.0
const STROKE_WINDOW_SECONDS = 1.5

@onready var menu: CatMenu = $Menu
@onready var tray: StatusIndicator = $Tray
@onready var decorations = $Decorations
@onready var windows_helper = $WindowsHelper

var state = State.SIT
var sit_time_left = 0.0
var activity = 0
var away_nap_activity = -1
var fade_tween: Tween
var used_decoration = null
var mouse_down = false
var press_mouse_position = Vector2i.ZERO
var drag_offset = Vector2i.ZERO
var recent_pets = []
var user_away = false
var fullscreen_app = false
var hidden_by_user = false
var music_focused = false
var shown_position = Vector2i.ZERO
var offscreen = false
var stroke_distance = 0.0
var stroke_started = 0.0


func _ready():
	apply_skin()
	apply_size()
	move_to_random_spot()
	Settings.changed.connect(on_setting_changed)
	menu.hide_toggled.connect(toggle_hidden)
	menu.decoration_added.connect(func(type): decorations.add_next_to(type, cat_rect()))
	menu.decorations_cleared.connect(decorations.clear)
	decorations.decoration_clicked.connect(on_decoration_clicked)
	decorations.decoration_removed.connect(on_decoration_removed)
	tray.pressed.connect(func(_button, mouse_position): menu.open_beside(Rect2i(mouse_position, Vector2i.ZERO)))
	windows_helper.status_changed.connect(on_windows_status)
	windows_helper.start()
	sit()


func _process(delta):
	match state:
		State.SIT:
			sit_time_left -= delta
			if sit_time_left <= 0:
				choose_activity()
		State.DRAG:
			get_window().position = DisplayServer.mouse_get_position() - drag_offset


func _input(event):
	if state == State.HIDDEN:
		return
	if event is InputEventMouseMotion and mouse_down and state != State.DRAG:
		var moved = DisplayServer.mouse_get_position() - press_mouse_position
		if moved.length() > DRAG_THRESHOLD:
			start_drag()
	elif event is InputEventMouseMotion and not mouse_down:
		track_stroke(event.screen_relative.length())
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		menu.open_beside(cat_rect())
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_down = true
			press_mouse_position = DisplayServer.mouse_get_position()
		else:
			mouse_down = false
			if state == State.DRAG:
				sit()
			else:
				pet()


func begin_activity(new_state):
	activity += 1
	state = new_state
	if fade_tween:
		fade_tween.kill()
	modulate.a = 1.0
	if used_decoration:
		var decoration = used_decoration
		used_decoration = null
		decoration.set_occupant(null)
		decoration.set_playing(false)
		decoration.visible = true
		if offscreen:
			place_beside(decoration.rect())
	return activity


func is_current(activity_id):
	return activity_id == activity


func sit():
	begin_activity(State.SIT)
	sit_time_left = randf_range(SIT_TIME_MIN, SIT_TIME_MAX)
	if music_focused and randf() < 0.5:
		play("dance")
	else:
		play(SIT_ANIMATIONS.pick_random())


func choose_activity():
	var options = [[teleport, 4], [loaf, 2], [nap, 2 if is_night() else 1]]
	var bed = decorations.random_of_kind("bed")
	if bed:
		options.append([rest_on.bind(bed, randf_range(60.0, 180.0)), 3 if is_night() else 2])
	var perch = decorations.random_of_kind("perch")
	if perch:
		options.append([rest_on.bind(perch, randf_range(30.0, 90.0)), 2])
	var bowl = decorations.random_of_kind("bowl")
	if bowl:
		options.append([eat_at_bowl.bind(bowl), 2])
	var toy = decorations.random_of_kind("toy")
	if toy:
		options.append([play_with.bind(toy), 2])
	var total = 0
	for option in options:
		total += option[1]
	var roll = randf() * total
	for option in options:
		roll -= option[1]
		if roll <= 0:
			option[0].call()
			return


func teleport():
	var activity_id = begin_activity(State.BUSY)
	await play_once("box_rise", true)
	if not is_current(activity_id):
		return
	await fade_to(0.0)
	if not is_current(activity_id):
		return
	move_to_random_spot()
	flip_h = randf() < 0.5
	await fade_to(1.0)
	if not is_current(activity_id):
		return
	await play_once("box_rise")
	if is_current(activity_id):
		sit()


func loaf():
	var activity_id = begin_activity(State.BUSY)
	play("loaf")
	await wait(randf_range(20.0, 45.0))
	if is_current(activity_id):
		sit()


func nap():
	var activity_id = begin_activity(State.BUSY)
	await play_once("yawn")
	if not is_current(activity_id):
		return
	play("sleep")
	await wait(randf_range(30.0, 90.0))
	if is_current(activity_id):
		sit()


func nap_while_away():
	var activity_id = begin_activity(State.BUSY)
	away_nap_activity = activity_id
	await play_once("yawn")
	if is_current(activity_id):
		play("sleep")


func wake_up():
	var activity_id = begin_activity(State.BUSY)
	await play_once("yawn")
	if is_current(activity_id):
		sit()


func rest_on(decoration, seconds):
	var activity_id = begin_activity(State.BUSY)
	if decoration.kind() == "bed":
		await play_once("yawn")
		if not is_current(activity_id):
			return
	await fade_to(0.0)
	if not is_current(activity_id):
		return
	move_offscreen()
	modulate.a = 1.0
	used_decoration = decoration
	decoration.set_occupant(sprite_frames)
	await wait(seconds)
	if is_current(activity_id):
		sit()


func play_with(toy):
	var activity_id = begin_activity(State.BUSY)
	await fade_to(0.0)
	if not is_current(activity_id):
		return
	place_beside(toy.rect())
	flip_h = true
	await fade_to(1.0)
	if not is_current(activity_id):
		return
	used_decoration = toy
	toy.set_playing(true)
	await play_once("excited")
	if not is_current(activity_id):
		return
	play("dance")
	await wait(randf_range(3.0, 6.0))
	if is_current(activity_id):
		sit()


func track_stroke(distance):
	if state != State.SIT:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now - stroke_started > STROKE_WINDOW_SECONDS:
		stroke_started = now
		stroke_distance = 0.0
	stroke_distance += distance
	if stroke_distance >= STROKE_DISTANCE:
		stroke_distance = 0.0
		enjoy_stroke()


func enjoy_stroke():
	var activity_id = begin_activity(State.BUSY)
	await play_once(Skins.stroke_reaction(Settings.skin))
	if is_current(activity_id):
		sit()


func eat_at_bowl(bowl):
	var activity_id = begin_activity(State.BUSY)
	await fade_to(0.0)
	if not is_current(activity_id):
		return
	used_decoration = bowl
	bowl.visible = false
	move_to(bowl.position + BOWL_OFFSET * Settings.size)
	flip_h = false
	await fade_to(1.0)
	for bite in 2:
		if not is_current(activity_id):
			return
		await play_once("eat")
	if not is_current(activity_id):
		return
	await fade_to(0.0)
	if not is_current(activity_id):
		return
	used_decoration = null
	bowl.visible = true
	place_beside(bowl.rect())
	await fade_to(1.0)
	if is_current(activity_id):
		sit()


func pet():
	var now = Time.get_ticks_msec() / 1000.0
	recent_pets.append(now)
	recent_pets = recent_pets.filter(func(time): return now - time < ANNOYED_WINDOW_SECONDS)
	var activity_id = begin_activity(State.BUSY)
	if recent_pets.size() >= ANNOYED_PETS:
		recent_pets.clear()
		await play_once("annoyed")
	else:
		await play_once(Skins.pet_reactions(Settings.skin).pick_random())
	if is_current(activity_id):
		sit()


func start_drag():
	begin_activity(State.DRAG)
	drag_offset = press_mouse_position - get_window().position
	play("idle")


func play_once(animation_name, backwards = false):
	if backwards:
		play_backwards(animation_name)
	else:
		play(animation_name)
	await animation_finished


func fade_to(alpha):
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", alpha, FADE_SECONDS)
	await fade_tween.finished


func wait(seconds):
	await get_tree().create_timer(seconds).timeout


func is_night():
	var hour = Time.get_datetime_dict_from_system()["hour"]
	return hour >= 22 or hour < 7


func toggle_hidden():
	hidden_by_user = not hidden_by_user
	update_hidden()


func update_hidden():
	var should_hide = hidden_by_user or fullscreen_app
	menu.cat_hidden = should_hide
	if should_hide and state != State.HIDDEN:
		begin_activity(State.HIDDEN)
		shown_position = get_window().position
		move_offscreen()
		decorations.set_all_visible(false)
	elif not should_hide and state == State.HIDDEN:
		move_to(shown_position)
		decorations.set_all_visible(true)
		sit()


func on_windows_status(idle_seconds, fullscreen, foreground_app):
	var app = foreground_app.to_lower()
	music_focused = MUSIC_APPS.any(func(music_app): return app.contains(music_app))
	if fullscreen != fullscreen_app:
		fullscreen_app = fullscreen
		update_hidden()
	var away = idle_seconds >= AWAY_SECONDS
	if away and not user_away:
		user_away = true
		if state == State.SIT:
			nap_while_away()
	elif not away and user_away:
		user_away = false
		if is_current(away_nap_activity):
			wake_up()


func on_decoration_clicked(decoration):
	if decoration == used_decoration:
		pet()


func on_decoration_removed(decoration):
	if decoration == used_decoration:
		used_decoration = null
		if offscreen:
			move_to_random_spot()
		sit()


func on_setting_changed(key):
	match key:
		"size":
			apply_size()
			move_to(Vector2i(clamp_to_roam_zone(Vector2(get_window().position))))
			sit()
		"monitor":
			move_to_random_spot()
			sit()
		"skin":
			apply_skin()
			sit()


func apply_skin():
	sprite_frames = Skins.build_frames(Settings.skin)
	tray.icon = ImageTexture.create_from_image(sprite_frames.get_frame_texture("idle", 0).get_image())


func apply_size():
	get_window().min_size = Vector2i.ONE
	get_window().size = Vector2i(Skins.FRAME_SIZE, Skins.FRAME_SIZE) * Settings.size


func cat_rect():
	return Rect2i(get_window().position, get_window().size)


func place_beside(anchor):
	var screen_area = DisplayServer.screen_get_usable_rect(Settings.monitor)
	var window_size = get_window().size
	var x = anchor.end.x
	if x + window_size.x > screen_area.end.x:
		x = anchor.position.x - window_size.x
	move_to(Vector2i(x, anchor.end.y - window_size.y))


func roam_zone():
	var area = Rect2(DisplayServer.screen_get_usable_rect(Settings.monitor))
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
	move_to(Vector2i(spot))


func move_to(spot):
	offscreen = false
	get_window().position = spot


func move_offscreen():
	offscreen = true
	get_window().position = OFFSCREEN
