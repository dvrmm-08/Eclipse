extends SceneTree

func _init() -> void:
	change_scene_to_file("res://scenes/level_2.tscn")
	for i in range(5):
		await process_frame
		await physics_frame
		
	var level = current_scene
	var wanderer = level.get_node("Wanderer")
	var objects = level.get_node("Objects")
	
	print("Level 2 loaded. Wanderer at: ", wanderer.global_position)
	
	for child in objects.get_children():
		if child.has_method("can_see_wanderer"):
			print("Statue: ", child.name, " at: ", child.global_position, " rot: ", child.rotation, " (", rad_to_deg(child.rotation), " deg)")
			print("  Facing dir: ", child.get_current_facing_direction())
			print("  Can see wanderer at ", wanderer.global_position, "? ", child.can_see_wanderer())
			
			# Test placing wanderer directly 50px in front of statue along its facing direction
			var front_pos = child.global_position + child.get_current_facing_direction() * 50.0
			wanderer.global_position = front_pos
			await physics_frame
			await physics_frame
			print("  Moving wanderer to front: ", front_pos)
			print("  Can see wanderer at front? ", child.can_see_wanderer())
			
	quit(0)
