extends SceneTree

func _init() -> void:
	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame
		
	var level = current_scene
	var wanderer = level.get_node("Wanderer")
	var objects = level.get_node("Objects")
	var statue_a = objects.get_node("WatcherStatueA")
	
	statue_a.position = Vector2(80, 72)
	statue_a.facing_direction = Vector2.DOWN
	
	wanderer.global_position = Vector2(80, 150)
	await physics_frame
	await physics_frame
	
	statue_a.rotation = 0.0
	await physics_frame
	print("Watcher A (rotation = 0 deg, facing DOWN): sees Wanderer at (80, 150): ", statue_a.can_see_wanderer())
	
	statue_a.rotation = deg_to_rad(90.0)
	await physics_frame
	print("Watcher A (rotation = 90 deg, facing LEFT): sees Wanderer at (80, 150): ", statue_a.can_see_wanderer())
	
	statue_a.rotation = deg_to_rad(-90.0)
	await physics_frame
	print("Watcher A (rotation = -90 deg, facing RIGHT): sees Wanderer at (80, 150): ", statue_a.can_see_wanderer())
	
	statue_a.rotation = deg_to_rad(180.0)
	await physics_frame
	print("Watcher A (rotation = 180 deg, facing UP): sees Wanderer at (80, 150): ", statue_a.can_see_wanderer())

	quit(0)
