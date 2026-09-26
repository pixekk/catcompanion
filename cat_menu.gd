class_name CatMenu
extends PopupMenu

signal hide_toggled
signal decoration_added(type)
signal decorations_cleared

enum Item { HIDE = 100, QUIT, CLEAR_DECORATIONS }

var cat_hidden = false
var size_menu = PopupMenu.new()
var monitor_menu = PopupMenu.new()
var skin_menu = PopupMenu.new()
var decoration_menu = PopupMenu.new()


func _ready():
	for size_option in Settings.SIZES:
		size_menu.add_radio_check_item(Settings.SIZES[size_option], size_option)
	size_menu.id_pressed.connect(func(size_option): Settings.update("size", size_option))

	monitor_menu.id_pressed.connect(func(screen_index): Settings.update("monitor", screen_index))

	skin_menu.add_separator("Skin")
	for skin_name in Skins.names():
		if skin_name == "Ribbon " + Skins.RIBBON_COLORS[0]:
			skin_menu.add_separator("Ribbon")
		skin_menu.add_radio_check_item(skin_name)
	skin_menu.index_pressed.connect(func(index): Settings.update("skin", skin_menu.get_item_text(index)))

	decoration_menu.add_separator("Add")
	for type in Decoration.CATALOG:
		decoration_menu.add_item(Decoration.CATALOG[type]["label"])
		decoration_menu.set_item_metadata(decoration_menu.item_count - 1, type)
	decoration_menu.add_separator()
	decoration_menu.add_item("Remove all", Item.CLEAR_DECORATIONS)
	decoration_menu.index_pressed.connect(on_decoration_index_pressed)

	add_submenu_node_item("Size", size_menu)
	add_submenu_node_item("Monitor", monitor_menu)
	add_submenu_node_item("Customize", skin_menu)
	add_submenu_node_item("Decorations", decoration_menu)
	add_separator()
	add_item("Hide cat", Item.HIDE)
	add_item("Quit", Item.QUIT)
	id_pressed.connect(on_id_pressed)


func open_beside(anchor):
	refresh()
	CatMenu.popup_beside(self, anchor)


func refresh():
	for index in size_menu.item_count:
		size_menu.set_item_checked(index, size_menu.get_item_id(index) == Settings.size)
	monitor_menu.clear()
	for screen_index in DisplayServer.get_screen_count():
		monitor_menu.add_radio_check_item("Monitor %d" % (screen_index + 1), screen_index)
		monitor_menu.set_item_checked(screen_index, screen_index == Settings.monitor)
	for index in skin_menu.item_count:
		skin_menu.set_item_checked(index, skin_menu.get_item_text(index) == Settings.skin)
	set_item_text(get_item_index(Item.HIDE), "Show cat" if cat_hidden else "Hide cat")


func on_id_pressed(id):
	match id:
		Item.HIDE:
			hide_toggled.emit()
		Item.QUIT:
			get_tree().quit()


func on_decoration_index_pressed(index):
	var type = decoration_menu.get_item_metadata(index)
	if type:
		decoration_added.emit(type)
	elif decoration_menu.get_item_id(index) == Item.CLEAR_DECORATIONS:
		decorations_cleared.emit()


static func popup_beside(menu, anchor):
	menu.popup(Rect2i(anchor.position, Vector2i.ZERO))
	menu.content_scale_factor = 1.0
	menu.min_size = Vector2i(menu.get_contents_minimum_size())
	menu.size = menu.min_size
	var screen_area = DisplayServer.screen_get_usable_rect(DisplayServer.get_screen_from_rect(Rect2(anchor)))
	var x = anchor.end.x
	if x + menu.size.x > screen_area.end.x:
		x = anchor.position.x - menu.size.x
	var y = clamp(anchor.end.y - menu.size.y, screen_area.position.y, screen_area.end.y - menu.size.y)
	menu.position = Vector2i(x, y)
