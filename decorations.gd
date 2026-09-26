extends Node

signal decoration_clicked(decoration)
signal decoration_removed(decoration)

var items = []


func _ready():
	for saved in Settings.decorations:
		spawn(saved["type"], saved["position"])
	Settings.changed.connect(on_setting_changed)


func add_next_to(type, anchor):
	var region_size = Vector2i(Decoration.CATALOG[type]["region"].size) * Settings.size
	var decoration = spawn(type, Vector2i(anchor.end.x, anchor.end.y - region_size.y))
	save()
	return decoration


func spawn(type, spot):
	var decoration = Decoration.new()
	decoration.type = type
	decoration.position = spot
	decoration.moved.connect(save)
	decoration.clicked.connect(func(): decoration_clicked.emit(decoration))
	decoration.remove_requested.connect(func(): remove(decoration))
	add_child(decoration)
	items.append(decoration)
	return decoration


func remove(decoration):
	items.erase(decoration)
	decoration_removed.emit(decoration)
	decoration.queue_free()
	save()


func clear():
	for decoration in items.duplicate():
		remove(decoration)


func random_of_kind(kind):
	var matching = items.filter(func(decoration): return decoration.kind() == kind)
	return null if matching.is_empty() else matching.pick_random()


func set_all_visible(value):
	for decoration in items:
		decoration.visible = value


func save():
	Settings.update("decorations", items.map(func(decoration): return {"type": decoration.type, "position": decoration.position}))


func on_setting_changed(key):
	if key == "size":
		for decoration in items:
			decoration.apply_size()
