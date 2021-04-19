extends Control

enum VIEWPORT_GROW_SETTING {
	HORIZONTAL_FIRST,
	VERTICAL_FIRST
}

export (int, 1, 4) var num_split_screen_viewports setget set_num_split_screen_viewports , get_num_split_screen_viewports;
export (VIEWPORT_GROW_SETTING) var grow_setting = VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST;
export (float) var viewport_resolution_scale = 1;

var HViewports = preload("scenes/viewports_h.tscn");
var PViewport = preload("scenes/player_viewport.tscn");

var viewports_h_bottom : HBoxContainer = null;
var viewports_h_top : HBoxContainer = null;

var main_viewport_container : Control;
var main_viewport : Viewport;

var player_viewports : Array = [];
var player_viewport_containers : Array = [];
var player_cameras : Array = [null, null, null, null];

var main_viewport_scenes : Node = null;

# Called when the node enters the scene tree for the first time.
func _ready():
	viewports_h_top = $ViewportsV/ViewportsH;
	setup_viewports();

func get_viewport_by_idx(viewport_idx : int) -> Viewport:
	if viewport_idx < num_split_screen_viewports:
		return player_viewports[viewport_idx];
	
	return null;
	
func get_viewport_normalized_offset(viewport_idx : int) -> Vector2:
	if viewport_idx == 0:
		return Vector2.ZERO;
	elif viewport_idx == 1:
		if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
			return Vector2(0.5,0);
		else:
			return Vector2(0, 0.5);
	elif viewport_idx == 2:
		if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
			return Vector2(0,0.5);
		else:
			return Vector2(0.5, 0.0);
	elif viewport_idx == 3:
		return Vector2(0.5,0.5);
	
	return Vector2.ZERO;

func get_viewport_relative_screen_share(viewport_idx : int) -> Vector2:
	if num_split_screen_viewports == 1:
		if viewport_idx == 0:
			return Vector2.ONE;
		else:
			return Vector2.ZERO;
	elif num_split_screen_viewports == 2:
		if viewport_idx <= 1:
			if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
				return Vector2(0.5,1.0);
			else:
				return Vector2(1.0,0.5);
		else:
			return Vector2.ZERO;
	elif num_split_screen_viewports == 3:
		if viewport_idx == 0:
			return Vector2(0.5,0.5);
		elif viewport_idx == 1:
			if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
				return Vector2(0.5,0.5);
			else:
				return Vector2(1.0,0.5);
		elif viewport_idx == 3:
			if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
				return Vector2(1.0,0.5);
			else:
				return Vector2(0.5,0.5);
		else:
			return Vector2.ZERO;
	else:
		return Vector2(0.5,0.5);
	
func set_scenes_holder(holder : Node):
	if main_viewport_scenes:
		return;
		
	assert(!holder.is_inside_tree());
		
	main_viewport_scenes = holder;
	if main_viewport:
		main_viewport.add_child(main_viewport_scenes);
		
func set_player_camera(camera : Node, viewport_idx : int):
	assert(viewport_idx >= 0 && viewport_idx < 4);
	assert(camera && !camera.is_inside_tree());
	
	if player_cameras[viewport_idx]:
		var cam_to_remove = player_cameras[viewport_idx];
		
		if cam_to_remove == camera:
			return;
		elif is_instance_valid(cam_to_remove):
			cam_to_remove.get_parent().remove_child(cam_to_remove);
			cam_to_remove.queue_free();
		
	player_cameras[viewport_idx] = camera;
	if player_viewports.size() > viewport_idx:
		player_viewports[viewport_idx].add_child(player_cameras[viewport_idx]);


func set_postprocess_material(postProcessMaterial, viewport_idx : int):
	if player_viewports.size() > viewport_idx:
		var viewportContainer : ViewportContainer = player_viewport_containers[viewport_idx];
		viewportContainer.material = postProcessMaterial;
	
	
func set_num_split_screen_viewports(value):
	num_split_screen_viewports = value;
	setup_viewports();
	
func get_num_split_screen_viewports():
	return num_split_screen_viewports;
	
func set_viewport_resolution_scale(value : float):
	viewport_resolution_scale = value;
	for viewport in player_viewport_containers:
		viewport.stretch_shrink = 1 / value;
		
func set_grow_setting(value):
	grow_setting = value;
	while player_viewports.size() > 0:
		remove_viewport();
	setup_viewports();
	
func setup_viewports():
	if player_viewports.size() == num_split_screen_viewports:
		return;
	
	if player_viewports.size() > num_split_screen_viewports:
		while player_viewports.size() > num_split_screen_viewports:
			remove_viewport();
	else:
		while player_viewports.size() < num_split_screen_viewports:
			add_viewport();
			
func add_horizontal_viewport_container():
	if viewports_h_bottom:
		return;
		
	var viewports_h = HViewports.instance();
	viewports_h_bottom = viewports_h;
	$ViewportsV.add_child(viewports_h);
	
func remove_horizontal_viewport_container():
	if !viewports_h_bottom:
		return;
		
	viewports_h_bottom.queue_free();
	viewports_h_bottom = null;

func remove_viewport():
	if player_viewports.size() == 0:
		return;
		
	var viewport_to_remove : ViewportContainer = player_viewport_containers.pop_back();
	player_viewports.pop_back();
	
	var cam_to_remove_idx = player_viewports.size();
	if player_cameras[cam_to_remove_idx]:
		var cam_to_remove : Node = player_cameras[cam_to_remove_idx];
		if is_instance_valid(cam_to_remove):
			cam_to_remove.get_parent().remove_child(cam_to_remove);
		else:
			player_cameras[cam_to_remove_idx] = null;
	
	if main_viewport_container == viewport_to_remove:
		main_viewport.remove_child(main_viewport_scenes);
		main_viewport = null;
		main_viewport_container = null;
	
	viewport_to_remove.get_parent().remove_child(viewport_to_remove);
	viewport_to_remove.queue_free();
	
	if viewports_h_bottom && viewports_h_bottom.get_child_count() <= 0:
		remove_horizontal_viewport_container();
	
func add_viewport():
	var player_viewport = PViewport.instance();
	player_viewport.stretch_shrink = 1 / viewport_resolution_scale;
	
	if player_viewports.size() == 0:
		viewports_h_top.add_child(player_viewport);
		main_viewport_container = player_viewport;
		main_viewport = player_viewport.get_child(0);
		
		if main_viewport_scenes:
			main_viewport.add_child(main_viewport_scenes);
		
		if player_cameras[0]:
			main_viewport.add_child(player_cameras[0]);
		
		player_viewports.push_back(main_viewport);
		player_viewport_containers.push_back(player_viewport);
	elif player_viewports.size() == 1:
		var container_to_add_viewport_to = viewports_h_top;
		if grow_setting == VIEWPORT_GROW_SETTING.VERTICAL_FIRST:
			add_horizontal_viewport_container();
			container_to_add_viewport_to = viewports_h_bottom;
		
		container_to_add_viewport_to.add_child(player_viewport);
		var viewport : Viewport = player_viewport.get_child(0);
		viewport.world = main_viewport.world;
		viewport.world_2d = main_viewport.world_2d;
		if player_cameras[1]:
			viewport.add_child(player_cameras[1]);
			
		player_viewports.push_back(viewport);
		player_viewport_containers.push_back(player_viewport);
	elif player_viewports.size() == 2:
		if grow_setting == VIEWPORT_GROW_SETTING.HORIZONTAL_FIRST:
			add_horizontal_viewport_container();
		var container_to_add_viewport_to = viewports_h_bottom;
		if grow_setting == VIEWPORT_GROW_SETTING.VERTICAL_FIRST:
			container_to_add_viewport_to = viewports_h_top;
			
		container_to_add_viewport_to.add_child(player_viewport);
		var viewport : Viewport = player_viewport.get_child(0);
		viewport.world = main_viewport.world;
		viewport.world_2d = main_viewport.world_2d;
		if player_cameras[2]:
			viewport.add_child(player_cameras[2]);
			
		player_viewports.push_back(viewport);
		player_viewport_containers.push_back(player_viewport);
	elif player_viewports.size() == 3:
		var container_to_add_viewport_to = viewports_h_bottom;
			
		container_to_add_viewport_to.add_child(player_viewport);
		var viewport : Viewport = player_viewport.get_child(0);
		viewport.world = main_viewport.world;
		viewport.world_2d = main_viewport.world_2d;
		if player_cameras[3]:
			viewport.add_child(player_cameras[3]);
			
		player_viewports.push_back(viewport);
		player_viewport_containers.push_back(player_viewport);
		
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if main_viewport_scenes:
			main_viewport_scenes.queue_free();
		
		for cam in player_cameras:
			if cam && is_instance_valid(cam):
				cam.queue_free();
