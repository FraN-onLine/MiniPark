extends Control

@onready var preview: TextureRect = $VBoxContainer/AvatarPreview
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var clear_button: Button = $VBoxContainer/HBoxContainer/ClearButton
@onready var save_button: Button = $VBoxContainer/HBoxContainer/SaveButton

const IMAGE_SIZE := 16
const SAVE_FOLDER := "res://data/avatars/"
const MANIFEST_PATH := "res://data/avatars/manifest.txt"

var image: Image
var base_image: Image
var texture: ImageTexture

var drawing := false
var brush_color := Color.BLACK
var name_color := Color.WHITE
var name_edit: LineEdit
var name_color_picker: ColorPickerButton
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

	_build_editor_ui()
	clear_button.pressed.connect(_on_clear_pressed)
	save_button.pressed.connect(_on_save_pressed)

	load_base_image()

	preview.mouse_filter = Control.MOUSE_FILTER_STOP
	preview.gui_input.connect(_on_preview_input)

	status_label.text = "Draw your little buddy!"

func _build_editor_ui():
	var container: VBoxContainer = $VBoxContainer
	container.remove_child(preview)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.custom_minimum_size = Vector2(70, 0)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Buddy"
	name_edit.text = "Buddy"
	name_edit.max_length = 18
	name_edit.custom_minimum_size = Vector2(220, 0)
	name_row.add_child(name_label)
	name_row.add_child(name_edit)
	container.add_child(name_row)
	container.move_child(name_row, 1)

	var color_row := HBoxContainer.new()
	color_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var color_label := Label.new()
	color_label.text = "Name color"
	color_label.custom_minimum_size = Vector2(90, 0)
	name_color_picker = ColorPickerButton.new()
	name_color_picker.color = name_color
	name_color_picker.color_changed.connect(_on_name_color_changed)
	color_row.add_child(color_label)
	color_row.add_child(name_color_picker)
	container.add_child(color_row)
	container.move_child(color_row, 2)

	var palette_row := HBoxContainer.new()
	palette_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var palette_label := Label.new()
	palette_label.text = "Palette"
	palette_label.custom_minimum_size = Vector2(70, 0)
	palette_row.add_child(palette_label)
	for color in palette_colors:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.modulate = color
		swatch.text = " "
		swatch.pressed.connect(_on_palette_button_pressed.bind(color))
		palette_row.add_child(swatch)
	var custom_picker := ColorPickerButton.new()
	custom_picker.custom_minimum_size = Vector2(44, 32)
	custom_picker.color = brush_color
	custom_picker.color_changed.connect(_on_custom_color_changed)
	palette_row.add_child(custom_picker)
	container.add_child(palette_row)
	container.move_child(palette_row, 3)

	container.add_child(preview)
	container.move_child(preview, 4)

func load_base_image():

	var loaded_image = Image.load_from_file("res://Lil Guys/lil guy base.png")

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

	texture = ImageTexture.create_from_image(image)

	preview.texture = texture

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

	texture.update(image)

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

	texture.update(image)

func mouse_to_pixel(mouse:Vector2)->Vector2i:

	var size = preview.size

	if mouse.x < 0:
		return Vector2i(-1,-1)

	if mouse.y < 0:
		return Vector2i(-1,-1)

	if mouse.x >= size.x:
		return Vector2i(-1,-1)

	if mouse.y >= size.y:
		return Vector2i(-1,-1)

	var px = floor(mouse.x / size.x * IMAGE_SIZE)
	var py = floor(mouse.y / size.y * IMAGE_SIZE)

	return Vector2i(px,py)

############################################################
# SAVE / CLEAR
############################################################

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

	var dir := DirAccess.open("res://")

	if dir == null:
		status_label.text = "Couldn't access project folder."
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
	meta.store_string(avatar_name + "\n" + str(name_color) + "\n" + image_path)
	meta.close()

	var current := FileAccess.open("res://data/current_avatar.txt", FileAccess.WRITE)
	if current != null:
		current.store_string(image_path + "\n" + avatar_name + "\n" + str(name_color))
		current.close()

	_write_avatar_manifest()

	status_label.text = "Buddy released!"

	await get_tree().create_timer(0.8).timeout

	get_tree().change_scene_to_file("res://scenes/park.tscn")

func _write_avatar_manifest() -> void:
	var manifest := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if manifest == null:
		return
	var dir := DirAccess.open("res://data/avatars")
	if dir == null:
		manifest.close()
		return
	var files := dir.get_files()
	files.sort()
	var lines: PackedStringArray = ["avatar_manifest"]
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		var meta_path := "res://data/avatars/%s.txt" % file_name.get_basename()
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