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
	var spawned_count := 0
	var index := 0
	var existing_positions: Array = []
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		var avatar_path := AVATAR_FOLDER + file_name
		var meta_path := AVATAR_FOLDER + file_name.get_basename() + ".txt"
		var character_scene := preload("res://scenes/avatar_instance.tscn")
		var character: Node2D = character_scene.instantiate()
		# find a spawn position that is at least min_sep away from existing ones
		var pos := _find_spawn_position(existing_positions, 120)
		character.position = pos
		existing_positions.append(pos)
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

func _find_spawn_position(existing: Array, min_sep: int) -> Vector2:
	var attempts := 0
	while attempts < 200:
		attempts += 1
		var x = randf_range(60, 1090)
		var y = randf_range(60, 588)
		var p = Vector2(x, y)
		var ok := true
		for e in existing:
			if p.distance_to(e) < min_sep:
				ok = false
				break
		if ok:
			return p
	# fallback: spread in a grid if random failed
	var count = existing.size()
	var cols = max(1, int(sqrt(count + 1)))
	var row = int(count / cols)
	var col = count % cols
	var gx = lerp(100, 1000, float(col) / max(1, cols - 1))
	var gy = lerp(100, 500, float(row) / max(1, row + 1))
	return Vector2(gx, gy)
