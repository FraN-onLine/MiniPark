extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var wander_timer: Timer = $WanderTimer

var move_speed: float = 96.0
var direction: Vector2 = Vector2.ZERO
var wobble_time: float = 0.0
var name_label: Label
var name_color: Color = Color.WHITE

func _ready() -> void:
	randomize()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -4)
	sprite.scale = Vector2(4, 4)
	load_avatar_texture()
	create_name_label()
	load_avatar_name()
	wander_timer.timeout.connect(_on_wander_timeout)
	wander_timer.wait_time = randf_range(0.8, 1.6)
	wander_timer.start()
	_pick_new_direction()

func _physics_process(delta: float) -> void:
	wobble_time += delta
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		sprite.position = Vector2(0, -2 + sin(wobble_time * 8.0) * 1.0)
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, 0.0, 0.2)
	else:
		velocity = direction * move_speed
		move_and_slide()
		var bob: float = sin(wobble_time * 12.0) * 2.0
		sprite.position = Vector2(0, -4 + bob)
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, direction.x * 4.0, 0.2)
	_update_sprite_direction()
	if global_position.x < 40 or global_position.x > 1110 or global_position.y < 40 or global_position.y > 608:
		global_position.x = clamp(global_position.x, 40, 1110)
		global_position.y = clamp(global_position.y, 40, 608)
		_pick_new_direction()

func _on_wander_timeout() -> void:
	_pick_new_direction()
	wander_timer.wait_time = randf_range(0.8, 1.6)

func _pick_new_direction() -> void:
	var angle: float = randf_range(0.0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	if randf() < 0.2:
		direction = Vector2.ZERO
	if randf() < 0.25:
		var wobble: Vector2 = Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35))
		direction += wobble
	if direction.length() > 0.0:
		direction = direction.normalized()
	else:
		direction = Vector2.LEFT

func _update_sprite_direction() -> void:
	if direction.x < 0.0:
		sprite.scale.x = abs(sprite.scale.x)
	elif direction.x > 0.0:
		sprite.scale.x = -abs(sprite.scale.x)

func create_name_label() -> void:
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-90, -52)
	name_label.custom_minimum_size = Vector2(180, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", load("res://Fonts/fusion-pixel-12px-monospaced-kr-latin-400-normal.ttf"))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))
	name_label.add_theme_constant_override("outline_size", 2)
	add_child(name_label)

func _parse_color(value: String) -> Color:
	var trimmed := value.strip_edges()
	if trimmed.is_empty():
		return Color.WHITE
	if trimmed.begins_with("(") and trimmed.ends_with(")"):
		var inner := trimmed.substr(1, trimmed.length() - 2)
		var parts := inner.split(",", false)
		if parts.size() >= 3:
			var r := float(parts[0].strip_edges())
			var g := float(parts[1].strip_edges())
			var b := float(parts[2].strip_edges())
			var a := 1.0
			if parts.size() >= 4:
				a = float(parts[3].strip_edges())
			return Color(r, g, b, a)
	return Color(trimmed)

func load_avatar_name() -> void:
	var metadata_path: String = "res://data/current_avatar.txt"
	if has_meta("meta_path"):
		metadata_path = get_meta("meta_path")
	var display_name: String = "Buddy"
	var display_color: Color = Color(1.0, 0.95, 0.7, 1.0)
	if FileAccess.file_exists(metadata_path):
		var file: FileAccess = FileAccess.open(metadata_path, FileAccess.ModeFlags.READ)
		if file != null:
			var data: PackedStringArray = file.get_as_text().split("\n", false)
			if data.size() > 0 and data[0].strip_edges().length() > 0 and not data[0].strip_edges().begins_with("user://") and not data[0].strip_edges().begins_with("res://"):
				display_name = data[0].strip_edges()
				if data.size() > 1 and data[1].strip_edges().length() > 0:
					display_color = _parse_color(data[1].strip_edges())
			else:
				if data.size() > 1 and data[1].strip_edges().length() > 0:
					display_name = data[1].strip_edges()
				if data.size() > 2 and data[2].strip_edges().length() > 0:
					display_color = _parse_color(data[2].strip_edges())
	name_label.text = display_name
	name_color = display_color
	name_label.modulate = Color.WHITE
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.set("theme_override_colors/font_color", Color.WHITE)
	name_label.modulate = name_color

func load_avatar_texture() -> void:
	var image_path: String = "res://data/avatar.png"
	var metadata_path: String = "res://data/current_avatar.txt"
	if has_meta("meta_path"):
		metadata_path = get_meta("meta_path")
	if FileAccess.file_exists(metadata_path):
		var file: FileAccess = FileAccess.open(metadata_path, FileAccess.ModeFlags.READ)
		if file != null:
			var data: PackedStringArray = file.get_as_text().split("\n", false)
			if data.size() > 0 and data[0].strip_edges().length() > 0:
				if data[0].strip_edges().begins_with("user://") or data[0].strip_edges().begins_with("res://"):
					image_path = data[0].strip_edges()
				elif data.size() > 2 and data[2].strip_edges().length() > 0:
					image_path = data[2].strip_edges()
	var image: Image
	if FileAccess.file_exists(image_path):
		image = Image.load_from_file(image_path)
	else:
		image = Image.load_from_file("res://Lil Guys/lil guy base.png")
	if image.is_empty():
		image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
	if image.get_width() != 16 or image.get_height() != 16:
		image.resize(16, 16)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	sprite.texture = texture
