extends Node

signal changed(key)

const PATH = "user://settings.cfg"
const SIZES = {1: "A Fine Boi", 2: "He Chonk", 3: "Hefty Chonk", 4: "OH LAWD, HE COMIN"}
const DEFAULT_SIZE = 2

var size = DEFAULT_SIZE
var monitor = 0
var skin = Skins.DEFAULT
var decorations = []


func _ready():
	var config = ConfigFile.new()
	config.load(PATH)
	size = config.get_value("cat", "size", DEFAULT_SIZE)
	if not SIZES.has(size):
		size = DEFAULT_SIZE
	monitor = config.get_value("cat", "monitor", DisplayServer.get_primary_screen())
	if monitor < 0 or monitor >= DisplayServer.get_screen_count():
		monitor = DisplayServer.get_primary_screen()
	skin = config.get_value("cat", "skin", Skins.DEFAULT)
	if skin not in Skins.names():
		skin = Skins.DEFAULT
	var saved_decorations = config.get_value("room", "decorations", [])
	if saved_decorations is Array:
		decorations = saved_decorations.filter(is_valid_decoration)


func update(key, value):
	set(key, value)
	var config = ConfigFile.new()
	config.set_value("cat", "size", size)
	config.set_value("cat", "monitor", monitor)
	config.set_value("cat", "skin", skin)
	config.set_value("room", "decorations", decorations)
	config.save(PATH)
	changed.emit(key)


func is_valid_decoration(saved):
	return saved is Dictionary and Decoration.CATALOG.has(saved.get("type")) and saved.get("position") is Vector2i
