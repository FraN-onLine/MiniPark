extends Control

@onready var preview: TextureRect = $VBoxContainer/AvatarPreview
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var clear_button: Button = $VBoxContainer/HBoxContainer/ClearButton
@onready var save_button: Button = $VBoxContainer/HBoxContainer/SaveButton
@onready var skip_button: Button = $VBoxContainer/HBoxContainer/SkipButton
@onready var name_edit: LineEdit = $VBoxContainer/NameRow/NameEdit
@onready var name_color_picker: ColorPickerButton = $VBoxContainer/ColorRow/NameColorPicker
@onready var custom_color_picker: ColorPickerButton = $VBoxContainer/PaletteRow/CustomColorPicker
@onready var base_button_1: TextureButton = $VBoxContainer/BaseButtons/BaseButton1
@onready var base_button_2: TextureButton = $VBoxContainer/BaseButtons/BaseButton2
@onready var swatch_buttons: Array[Button] = [
	$VBoxContainer/PaletteRow/Swatch1,
	$VBoxContainer/PaletteRow/Swatch2,
	$VBoxContainer/PaletteRow/Swatch3,
	$VBoxContainer/PaletteRow/Swatch4,
	$VBoxContainer/PaletteRow/Swatch5,
	$VBoxContainer/PaletteRow/Swatch6,
	$VBoxContainer/PaletteRow/Swatch7,
	$VBoxContainer/PaletteRow/Swatch8,
	$VBoxContainer/PaletteRow/Swatch9,
	$VBoxContainer/PaletteRow/Swatch10,
	$VBoxContainer/PaletteRow/Swatch11,
	$VBoxContainer/PaletteRow/Swatch12,
]

const IMAGE_SIZE := 16

# NOTE: res:// is read-only in exported builds!
# For saving avatars we must use user:// (writable in exports).
# For loading base images we use load() + get_image() (works in exports).
const SAVE_FOLDER := "user://data/avatars/"
const MANIFEST_PATH := "user://data/avatars/manifest.txt"
const CURRENT_AVATAR_PATH := "user://data/current_avatar.txt"
const BASE_1_PATH := "res://Lil Guys/lil guy base.png"
const BASE_2_PATH := "res://Lil Guys/lil guy base 2.png"

var image: Image
var base_image: Image
var image_texture: ImageTexture

var drawing := false
var brush_color := Color.BLACK
var name_color := Color.WHITE
var selected_base_path: String = BASE_1_PATH
var palette_colors: Array[Color] = [
	Color(0.12, 0.12, 0.12),
	Color(1.0, 0.25, 0.25),
	Color(1.0, 0.55, 0.15),
	Color(1.0, 0.85, 0.20),
	Color(0.35, 0.90, 0.25),
	Color(0.15, 0.80, 0.35),
	Color(0.15, 0.75, 0.85),
	Color(0.20, 0.45, 0.95),
	Color(0.55, 0.25, 0.95),
	Color(1.0, 0.35, 0.70),
	Color(1.0, 0.90, 0.95),
	Color(0.70, 0.80, 0.90)
]

func _ready():

	randomize()

	_setup_scene_ui()
	clear_button.pressed.connect(_on_clear_pressed)
	save_button.pressed.connect(_on_save_pressed)
	if skip_button != null:
		skip_button.pressed.connect(_on_skip_pressed)

	load_base_image()

	preview.mouse_filter = Control.MOUSE_FILTER_STOP
	preview.gui_input.connect(_on_preview_input)

	status_label.text = "Draw your little buddy!"

func _setup_scene_ui():
	_apply_font_to_controls(self)
	name_edit.placeholder_text = "Buddy"
	name_edit.text = "Buddy"
	name_edit.max_length = 18
	name_color_picker.color = name_color
	name_color_picker.color_changed.connect(_on_name_color_changed)
	custom_color_picker.color = brush_color
	custom_color_picker.color_changed.connect(_on_custom_color_changed)
	_setup_base_buttons()

	for index in range(min(swatch_buttons.size(), palette_colors.size())):
		var color: Color = palette_colors[index]
		var swatch: Button = swatch_buttons[index]
		swatch.text = ""
		swatch.flat = false
		swatch.custom_minimum_size = Vector2(30, 30)
		swatch.pressed.connect(_on_palette_button_pressed.bind(color))

		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		style.border_color = Color(1.0, 1.0, 1.0, 0.45)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		swatch.add_theme_stylebox_override("normal", style)
		swatch.add_theme_stylebox_override("hover", style)
		swatch.add_theme_stylebox_override("pressed", style)
		swatch.add_theme_stylebox_override("focus", style)

func _setup_base_buttons() -> void:
	base_button_1.pressed.connect(_on_base_button_pressed.bind(BASE_1_PATH))
	base_button_2.pressed.connect(_on_base_button_pressed.bind(BASE_2_PATH))
	base_button_1.texture_normal = _make_button_texture(BASE_1_PATH, Color.WHITE)
	base_button_2.texture_normal = _make_button_texture(BASE_2_PATH, Color(0.95, 0.95, 1.0))
	base_button_1.texture_pressed = base_button_1.texture_normal
	base_button_2.texture_pressed = base_button_2.texture_normal
	base_button_1.texture_hover = base_button_1.texture_normal
	base_button_2.texture_hover = base_button_2.texture_normal
	base_button_1.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	base_button_2.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	base_button_1.custom_minimum_size = Vector2(96, 96)
	base_button_2.custom_minimum_size = Vector2(96, 96)
	_update_base_button_state()

func _on_base_button_pressed(path: String) -> void:
	selected_base_path = path
	load_base_image()
	_update_base_button_state()
	status_label.text = "Base changed."

func _update_base_button_state() -> void:
	var selected := selected_base_path == BASE_1_PATH
	base_button_1.modulate = Color.WHITE if selected else Color(0.72, 0.72, 0.72, 1.0)
	base_button_2.modulate = Color.WHITE if not selected else Color(0.72, 0.72, 0.72, 1.0)

func _make_button_texture(path: String, tint: Color) -> Texture2D:
	var resource = load(path)
	if resource is Texture2D:
		var tex2d: Texture2D = resource as Texture2D
		var img := tex2d.get_image().duplicate()
		img.convert(Image.FORMAT_RGBA8)
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c = img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
		return ImageTexture.create_from_image(img)
	# fallback: try loading image file directly
	var img2 := Image.load_from_file(path)
	if img2 != null and not img2.is_empty():
		img2.convert(Image.FORMAT_RGBA8)
		return ImageTexture.create_from_image(img2)
	# final fallback: tiny blank texture
	var blank := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	blank.fill(Color(1,1,1,1))
	return ImageTexture.create_from_image(blank)

func load_base_image():

	# Use load() + get_image() instead of Image.load_from_file().
	# In exported builds, PNGs are converted to GPU texture formats inside the PCK,
	# so Image.load_from_file() fails. load() works because it uses Godot's resource system.
	var base_texture: Texture2D = load(selected_base_path)
	var loaded_image: Image = null

	if base_texture != null:
		loaded_image = base_texture.get_image()
		if loaded_image != null:
			loaded_image = loaded_image.duplicate()

	# Fallback: try loading as raw file (works in editor, may fail in exports)
	if loaded_image == null or loaded_image.is_empty():
		loaded_image = Image.load_from_file(selected_base_path)

	# Second fallback: try base 1 as a resource
	if loaded_image == null or loaded_image.is_empty():
		base_texture = load(BASE_1_PATH)
		if base_texture != null:
			loaded_image = base_texture.get_image()
			if loaded_image != null:
				loaded_image = loaded_image.duplicate()

	# Third fallback: try loading base 1 as raw file
	if loaded_image == null or loaded_image.is_empty():
		loaded_image = Image.load_from_file(BASE_1_PATH)

	# Final fallback: create a blank white image
	if loaded_image == null or loaded_image.is_empty():
		loaded_image = Image.create(
			IMAGE_SIZE,
			IMAGE_SIZE,
			false,
			Image.FORMAT_RGBA8
		)
		loaded_image.fill(Color.WHITE)

	if loaded_image.get_width() != IMAGE_SIZE:
		loaded_image.resize(
			IMAGE_SIZE,
			IMAGE_SIZE,
			Image.INTERPOLATE_NEAREST
		)

	loaded_image.convert(Image.FORMAT_RGBA8)
	base_image = loaded_image.duplicate()
	image = loaded_image.duplicate()

	image_texture = ImageTexture.create_from_image(image)

	preview.texture = image_texture

	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	preview.stretch_mode = TextureRect.STRETCH_SCALE

func _on_preview_input(event):

	if event is InputEventMouseButton:

		match event.button_index:

			MOUSE_BUTTON_LEFT:

				drawing = event.pressed

				if drawing:

					paint(event.position)

			MOUSE_BUTTON_RIGHT:

				if event.pressed:

					erase(event.position)

	elif event is InputEventMouseMotion:

		if drawing:

			paint(event.position)

func paint(mouse_position:Vector2):

	var pixel = mouse_to_pixel(mouse_position)

	if pixel.x < 0:
		return

	if not _can_paint_pixel(pixel):
		return

	image.set_pixel(
		pixel.x,
		pixel.y,
		brush_color
	)

	image_texture.update(image)

func _can_paint_pixel(pixel: Vector2i) -> bool:
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= IMAGE_SIZE or pixel.y >= IMAGE_SIZE:
		return false
	if base_image == null:
		return false
	var source_color: Color = base_image.get_pixel(pixel.x, pixel.y)
	return source_color.a > 0.0 and _is_white_like(source_color)

func _is_white_like(color: Color) -> bool:
	return color.r > 0.95 and color.g > 0.95 and color.b > 0.95

func erase(mouse_position:Vector2):

	var pixel = mouse_to_pixel(mouse_position)

	if pixel.x < 0:
		return

	image.set_pixel(
		pixel.x,
		pixel.y,
		Color.WHITE
	)

	image_texture.update(image)

func mouse_to_pixel(mouse:Vector2)->Vector2i:

	var rect_size = preview.size

	if mouse.x < 0:
		return Vector2i(-1,-1)

	if mouse.y < 0:
		return Vector2i(-1,-1)

	if mouse.x >= rect_size.x:
		return Vector2i(-1,-1)

	if mouse.y >= rect_size.y:
		return Vector2i(-1,-1)

	var px = floor(mouse.x / rect_size.x * IMAGE_SIZE)
	var py = floor(mouse.y / rect_size.y * IMAGE_SIZE)

	return Vector2i(px,py)

############################################################
# SAVE / CLEAR
############################################################

func _apply_font_to_controls(node: Node) -> void:
	var font := load("res://Fonts/fusion-pixel-12px-monospaced-kr-latin-400-normal.ttf")
	if node is Label:
		(node as Label).add_theme_font_override("font", font)
	elif node is LineEdit:
		(node as LineEdit).add_theme_font_override("font", font)
	elif node is Button:
		(node as Button).add_theme_font_override("font", font)
	elif node is ColorPickerButton:
		(node as ColorPickerButton).add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font_to_controls(child)

func _on_palette_button_pressed(color: Color):
	brush_color = color
	status_label.text = "Brush colour set."

func _on_custom_color_changed(color: Color):
	brush_color = color
	status_label.text = "Custom colour ready."

func _on_name_color_changed(color: Color):
	name_color = color
	status_label.text = "Name colour updated."

func _on_clear_pressed():

	load_base_image()

	status_label.text = "Canvas cleared."

func _on_save_pressed():

	# user:// is the only writable location in exported builds
	var dir := DirAccess.open("user://")

	if dir == null:
		status_label.text = "Couldn't access user folder."
		return

	dir.make_dir_recursive("data/avatars")

	var avatar_name := name_edit.text.strip_edges()
	if avatar_name.is_empty():
		avatar_name = "buddy"
	var safe_name := avatar_name.to_snake_case()
	var unique_suffix := str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var unique_name := safe_name + "_" + unique_suffix
	var image_path := SAVE_FOLDER + unique_name + ".png"
	var meta_path := SAVE_FOLDER + unique_name + ".txt"

	var err := image.save_png(image_path)

	if err != OK:
		status_label.text = "Couldn't save image."
		return

	var meta := FileAccess.open(meta_path, FileAccess.WRITE)
	if meta == null:
		status_label.text = "Couldn't save character data."
		return
	meta.store_string(avatar_name + "\n" + str(name_color) + "\n" + image_path + "\n" + selected_base_path)
	meta.close()

	var current := FileAccess.open(CURRENT_AVATAR_PATH, FileAccess.WRITE)
	if current != null:
		current.store_string(image_path + "\n" + avatar_name + "\n" + str(name_color) + "\n" + selected_base_path)
		current.close()

	_write_avatar_manifest()

	status_label.text = "Buddy released!"

	await get_tree().create_timer(0.8).timeout

	get_tree().change_scene_to_file("res://scenes/park.tscn")

func _write_avatar_manifest() -> void:
	var manifest := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if manifest == null:
		return
	var dir := DirAccess.open("user://data/avatars")
	if dir == null:
		manifest.close()
		return
	var files := dir.get_files()
	files.sort()
	var lines: PackedStringArray = ["avatar_manifest"]
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		var meta_path := "user://data/avatars/%s.txt" % file_name.get_basename()
		var display_name := file_name.get_basename()
		var color_value := ""
		if FileAccess.file_exists(meta_path):
			var meta_file := FileAccess.open(meta_path, FileAccess.READ)
			if meta_file != null:
				var data := meta_file.get_as_text().split("\n", false)
				if data.size() > 0 and data[0].strip_edges().length() > 0:
					display_name = data[0].strip_edges()
				if data.size() > 1 and data[1].strip_edges().length() > 0:
					color_value = data[1].strip_edges()
		lines.append("%s|%s|%s" % [file_name, display_name, color_value])
	manifest.store_string("\n".join(lines))
	manifest.close()

func _on_skip_pressed() -> void:
	# Immediately enter the park without saving
	status_label.text = "Skipping creation. Entering park..."
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/park.tscn")
