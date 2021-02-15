extends Node2D

export (Array, String) var material_folders = [];
export (bool) var is_recursive = false; 
export (float) var time_before_hding = 0.5;

var showed = false;
var time_accumulated = 0;

func read_folder(path : String):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true,true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				read_folder(path + "/" + file_name);
			else:
				var resource = load(path + "/" + file_name);
				if resource is CanvasItemMaterial || resource is ShaderMaterial:
					var new_sprite = Sprite.new();
					new_sprite.material = resource;
					new_sprite.visible = false;
					add_child(new_sprite);
				elif resource is ParticlesMaterial:
					var new_particles = Particles2D.new();
					new_particles.process_material = resource;
					new_particles.emitting = false;
					new_particles.visible = false;
					add_child(new_particles);
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path: " + path);

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false);
	for folder in material_folders:
		read_folder(folder);
		
func show_cache():
	var children = get_children();
	for child in children:
		child.visible = true;
		if child is Particles2D:
			child.emitting = true;
			
	set_process(true);
			
func _process(delta):
	if !showed:
		return;
		
	if time_accumulated >= time_before_hding:
		var children = get_children();
		for child in children:
			child.visible = false;
			child.set_process(false);
			child.set_physics_process(false);
		visible = false;
		set_process(false);
		set_physics_process(false)
		time_accumulated = 0;
		showed = false;
	else:
		time_accumulated += delta;
