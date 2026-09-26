class_name Skins

const FRAME_SIZE = 32
const FRAMES_PER_SECOND = 8
const FOLDER = "res://assets/catpack/"
const PLAIN = {
	"Cream": "Sprites/3Aug2025Update.png",
	"Orange": "CatPackDifferentSkins/OrangeCat.png",
	"White": "CatPackDifferentSkins/WhiteCat.png",
	"Grey": "CatPackDifferentSkins/Grey.png",
}
const RIBBON_COLORS = ["Red", "Pink", "Purple", "Blue", "Green", "Yellow", "Brown", "White"]
const DEFAULT = "Cream"

const SHARED_ANIMATIONS = {
	"idle": [0, 10],
	"idle2": [1, 10],
	"sleep": [2, 4],
	"dance": [3, 4],
	"yawn": [4, 8],
	"loaf": [6, 12],
	"box_rise": [9, 12],
	"eat": [13, 15],
	"wait": [14, 6],
}
const PLAIN_REACTIONS = {"content": [15, 13], "blush": [17, 12], "annoyed": [16, 9]}
const RIBBON_REACTIONS = {"shy": [5, 12], "excited": [12, 12], "annoyed": [7, 9]}
const LOOPING = ["idle", "idle2", "sleep", "dance", "loaf", "wait"]
const SPEEDS = {"sleep": 3, "loaf": 5}


static func names():
	var result = PLAIN.keys()
	for color in RIBBON_COLORS:
		result.append("Ribbon " + color)
	return result


static func is_ribbon(skin):
	return skin.begins_with("Ribbon ")


static func reactions(skin):
	return RIBBON_REACTIONS if is_ribbon(skin) else PLAIN_REACTIONS


static func pet_reactions(skin):
	return reactions(skin).keys().filter(func(animation_name): return animation_name != "annoyed")


static func sheet_path(skin):
	if is_ribbon(skin):
		return FOLDER + "Sprites/CatwithRibbon/CatPackRibbon%s.png" % skin.trim_prefix("Ribbon ")
	return FOLDER + PLAIN[skin]


static func build_frames(skin):
	var sheet = load(sheet_path(skin))
	var layout = SHARED_ANIMATIONS.merged(reactions(skin))
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in layout:
		var row = layout[animation_name][0]
		var frame_count = layout[animation_name][1]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, SPEEDS.get(animation_name, FRAMES_PER_SECOND))
		frames.set_animation_loop(animation_name, animation_name in LOOPING)
		for column in frame_count:
			var frame_texture = AtlasTexture.new()
			frame_texture.atlas = sheet
			frame_texture.region = Rect2(column * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation_name, frame_texture)
	return frames
