extends Node

const EventManager = preload("jm_event_manager.gd");
const ViewportsManager = preload("jm_viewports.gd");

var ViewportsScene = preload("res://addons/jm_game_template/scenes/viewports.tscn");

export (PackedScene) var initial_scene;
export (String) var initial_scene_id;
export (int, 1, 4) var num_split_screen_viewports = 1;

var scenes_holder : Node;
var event_manager : EventManager;
var viewports : Control;

var loaded_scenes_map = {}
var loaded_scenes_list : Array = []

var cameras = {}

var loader = null;
var _is_loading_scene = false;
var _is_loading_additive = false;
var _loading_scene_id = "";
var _scene_load_progress = 0;
var _scene_failed_to_load = false;

var time_max = 100 # msec

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("jm_global_game_manager");
	
	event_manager = EventManager.new();
	add_child(event_manager, true);
	
	viewports = ViewportsScene.instance();
	add_child(viewports, true);
	viewports.set_num_split_screen_viewports(num_split_screen_viewports);
	
	scenes_holder = Node.new();
	viewports.set_scenes_holder(scenes_holder);
	
	var new_scene = initial_scene.instance();
	loaded_scenes_map[initial_scene_id] = new_scene;
	loaded_scenes_list.append(new_scene);
	
	scenes_holder.add_child(new_scene, true);
	
	pause_mode = Node.PAUSE_MODE_PROCESS;
	scenes_holder.pause_mode = Node.PAUSE_MODE_STOP;
	
	set_process(false)

# Returns the viewport with the given idx
func get_viewport_by_idx(viewport_idx : int) -> Viewport:
	return viewports.get_viewport_by_idx(viewport_idx);

# Returns the offset position of the viewport origin point in the screen ([0, 0] means top right, [0.5, 0] is top center, etc)
func get_viewport_normalized_offset(viewport_idx : int) -> Vector2:
	return viewports.get_viewport_normalized_offset(viewport_idx);

# Returns the screen share of the given viewport ([1,1] means whole screen, [0.5, 1] means half horizontal and full vertical, etc)
func get_viewport_relative_screen_share(viewport_idx : int) -> Vector2:
	return viewports.get_viewport_relative_screen_share(viewport_idx);


# Returns the current resolution scale for all viewports.
func get_viewport_resolution_scale() -> float:
	return viewports.viewport_resolution_scale;

# Sets the viewport resolution scale for each split-screen viewport.
# Setting a scale of 0.5 will make all viewports render at half the base
# resolution. This is useful in order to increase performance when you
# add multiple players.
func set_viewport_resolution_scale(resolution : float):
	viewports.set_viewport_resolution_scale(resolution);

# Sets the number of split-screen viewports for local multiplayer. This
# number must be between 1 and 4.
func set_num_split_screen_viewports(value : int):
	assert(value <= 4 && value >= 1)
	viewports.set_num_split_screen_viewports(value);
	num_split_screen_viewports = value;

# Returns the current number of split-screen viewports
func get_num_split_screen_viewports():
	return num_split_screen_viewports;
	
# Sets a camera as the given camera for a viewport. The camera must not be in any scene
# and will be deleted when the scene with the given scene_id is unloaded or a new camera
# replaces it.
func set_player_camera(camera : Node, viewport_idx : int, scene_id : String):
	assert(viewport_idx >= 0 && viewport_idx < 4)
	assert(camera && !camera.is_inside_tree());
	viewports.set_player_camera(camera, viewport_idx);
	
	if !cameras.has(scene_id):
		cameras[scene_id] = [];
	
	cameras[scene_id].append(camera);

# Sets the post-process material for the given viewport idx. This allows you
# to easily add post-processing effects to the game on indivitual split-screen
# viewports.
func set_postprocess_material(ppmaterial, viewport_idx : int):
	viewports.set_postprocess_material(ppmaterial, viewport_idx);

# Adds a scene to the tree via load_scene and unloads all other scenes
func change_scene(scene, unique_id: String) -> bool:
	return load_scene(scene, unique_id);

# Adds a scene to the tree via load_scene without unloading any other scenes
func add_scene(scene, unique_id: String) -> bool:
	return load_scene(scene, unique_id, true);
	
# Loads a scene to the manager with the specified unique_id. If additive is
# true then the scene will be loaded parallel to other scenes, otherwise all other
# scenes will be unloaded before this one is loaded. The scene can either be a path
# to the resource or a PackedScene. Returns true on success, false otherwise.
func load_scene(scene, unique_id: String, additive = false) -> bool:
	var to_load : PackedScene;
	
	if scene is String:
		to_load = load(scene);
	elif scene is PackedScene:
		to_load = scene;
	else:
		return false;
		
	if not additive:
		for loaded_scene in loaded_scenes_list:
			loaded_scene.queue_free();
		loaded_scenes_list.clear();
		loaded_scenes_map = {};
		
		var cams_arrays = cameras.values();
		for cam_array in cams_arrays:
			for cam in cam_array:
				cam.queue_free();
		cameras = {};
	
	if loaded_scenes_map.has(unique_id):
		return false;
		
	var new_scene = to_load.instance();
	loaded_scenes_map[unique_id] = new_scene;
	loaded_scenes_list.append(new_scene);
	
	scenes_holder.add_child(new_scene, true);
	print("Memory: " + str(OS.get_static_memory_peak_usage()));
	return true;

# Loads a scene asynchronously. Works the same as load_scene but the scene will
# be loaded over several frames. This can be used to make animated loading stuff
# like loading animations and loading bars. Use get_load_scene_progress to
# obtain the load progress of the scene and is_loading_scene/failed_loading_scene
# to check on the state of the loading.
func load_scene_async(scene : String, unique_id: String, additive = false) -> bool:
	if loaded_scenes_map.has(unique_id) && additive:
		return false;
	
	loader = ResourceLoader.load_interactive(scene)
	if loader == null: # check for errors
		return false;
	
	set_process(true)
	_is_loading_additive = additive;
	_is_loading_scene = true;
	_loading_scene_id = unique_id;
	return true;

# Getter to obtain the current progress of an async scene being loaded
func get_load_scene_progress() -> float:
	return _scene_load_progress;

# Getter to check if an async scene is currently being loaded
func is_loading_scene() -> bool:
	return _is_loading_scene;

# Getter to check if an async scene has failed to load.
func failed_loading_scene() -> bool:
	return _scene_failed_to_load;

# Unloads the scene with the specified unique_id. If a camera has been registered
# to that scene that camera is deleted too.
func unload_scene(unique_id : String):
	if loaded_scenes_map.has(unique_id):
		loaded_scenes_list.erase(loaded_scenes_map[unique_id]);
		loaded_scenes_map[unique_id].queue_free();
		loaded_scenes_map.erase(unique_id);
		
		if cameras.has(unique_id):
			var cam_list = cameras[unique_id];
			for cam in cam_list:
				cam.queue_free();
			cameras[unique_id].clear();
			
func _process(time):
	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + time_max:
		# Poll your loader.
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			loader = null
			load_scene(resource,_loading_scene_id,_is_loading_additive)
			_is_loading_scene = false;
			break
		elif err == OK:
			_scene_load_progress = float(loader.get_stage()) / loader.get_stage_count()
		else: # Error during loading.
			loader = null
			_scene_failed_to_load = true;
			break

