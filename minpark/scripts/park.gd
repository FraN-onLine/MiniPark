extends Node2D

@onready var add_new_button: Button = $CanvasLayer/AddNewButton
@onready var inhabitants_label: Label = $CanvasLayer/InhabitantsLabel
@onready var avatars_list: Label = $CanvasLayer/AvatarsList

func _ready() -> void:
	randomize()
	queue_redraw()
	add_new_button.pressed.connect(_on_add_new_pressed)
	var spawner := preload("res://scripts/park_characters.gd").new()
	spawner.name = "ParkCharacters"
	add_child(spawner)
	_update_inhabitant_count()
	_update_avatar_list()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color(0.16, 0.52, 0.2))
	for i in range(22):
		var x: float = randf_range(40, 1110)
		var y: float = randf_range(40, 608)
		draw_circle(Vector2(x, y), randf_range(2, 6), Color(0.28, 0.68, 0.24))
	for i in range(4):
		var x: float = randf_range(100, 1050)
		var y: float = randf_range(90, 560)
		draw_circle(Vector2(x, y), 8, Color(0.90, 0.84, 0.22))

func _update_inhabitant_count() -> void:
	var count := 0
	var spawner := get_node_or_null("ParkCharacters")
	if spawner != null:
		count = spawner.get_child_count()
	else:
		var dir := DirAccess.open("res://data/avatars")
		if dir != null:
			for file_name in dir.get_files():
				if file_name.ends_with(".png"):
					count += 1
	inhabitants_label.text = "Inhabitants: %d" % count

func _update_avatar_list() -> void:
	var lines: PackedStringArray = []
	var dir := DirAccess.open("res://data/avatars")
	if dir != null:
		var files := dir.get_files()
		files.sort()
		for file_name in files:
			if not file_name.ends_with(".png"):
				continue
			var meta_path := "res://data/avatars/%s.txt" % file_name.get_basename()
			var display_name := file_name.get_basename()
			if FileAccess.file_exists(meta_path):
				var meta_file := FileAccess.open(meta_path, FileAccess.READ)
				if meta_file != null:
					var data := meta_file.get_as_text().split("\n", false)
					if data.size() > 0 and data[0].strip_edges().length() > 0:
						display_name = data[0].strip_edges()
			lines.append("• %s" % display_name)
	avatars_list.text = "Created avatars:\n" + "\n".join(lines) if lines.size() > 0 else "Created avatars:\n• None yet"

func _on_add_new_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")
