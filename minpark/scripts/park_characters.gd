extends Node2D

const AVATAR_FOLDER := "res://data/avatars/"
const CURRENT_FILE := "res://data/current_avatar.txt"

var spawned := false

func _ready() -> void:
	spawn_saved_characters()

func spawn_saved_characters() -> void:
	if spawned:
		return
	var dir := DirAccess.open("res://data/avatars")
	if dir == null:
		return
	var files := dir.get_files()
	files.sort()
	var spawn_positions := [Vector2(220, 180), Vector2(330, 420), Vector2(780, 210), Vector2(900, 460)]
	var spawned_count := 0
	var index := 0
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		var avatar_path := AVATAR_FOLDER + file_name
		var meta_path := AVATAR_FOLDER + file_name.get_basename() + ".txt"
		var character_scene := preload("res://scenes/avatar_instance.tscn")
		var character: Node2D = character_scene.instantiate()
		character.position = spawn_positions[index % spawn_positions.size()]
		character.set_meta("avatar_path", avatar_path)
		character.set_meta("meta_path", meta_path)
		add_child(character)
		spawned_count += 1
		index += 1
	spawned = true
	if get_parent() != null and get_parent().has_method("_update_inhabitant_count"):
		get_parent()._update_inhabitant_count()
	if get_parent() != null and get_parent().has_method("_update_avatar_list"):
		get_parent()._update_avatar_list()
