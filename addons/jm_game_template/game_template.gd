tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("GameManager", "Node", preload("jm_game_manager.gd"), preload("graphics/game_manager_icon.png"))
	add_custom_type("EventManager", "Node", preload("jm_event_manager.gd"), preload("graphics/event_manager_icon.png"))
	add_custom_type("NodePool", "Spatial", preload("jm_node_pool.gd"), preload("graphics/node_pool.png"))
	add_custom_type("ObjectPool2D", "Node2D", preload("jm_object_pool_2D.gd"), preload("graphics/object_pool_2d_icon.png"))
	add_custom_type("MaterialCache", "Spatial", preload("jm_material_cache_3D.gd"), preload("graphics/material_cache_3d_icon.png"))
	add_custom_type("MaterialCache2D", "Node2D", preload("jm_material_cache_2D.gd"), preload("graphics/material_cache_2d_icon.png"))
	add_custom_type("StateMachine", "Node", preload("jm_state_machine.gd"), preload("graphics/state_machine_icon.png"))
	pass


func _exit_tree():
	pass
