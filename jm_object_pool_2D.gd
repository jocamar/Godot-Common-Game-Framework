extends Node2D

var objects : Array = [];

export (int) var pool_size = 100;
export (bool) var update_every_frame = true;

# Initializes the pool, instancing all the object prototypes.
# Must be called before you can use the pool.
func initialize_pool(pool_object : GDScriptNativeClass):
	var test_object = pool_object.new();
	assert(test_object is PooledObject2D);
	test_object.free();
	test_object = null;
	
	objects.clear();
	for i in range(pool_size):
		var new_obj = pool_object.new();
		new_obj._pool = self;
		objects.append(new_obj);

# Gets a new object from the pool from the list of sleeping objects. The object's _on_awake
# method is called. The returned object can them be initialized by the user (e.g. by giving
# it a position somewhere in the scene).
func awake_object() -> PooledObject2D:
	if objects.empty():
		return null;
	
	var new_obj : PooledObject2D = null;
	for obj in objects:
		if !obj.alive:
			new_obj = obj;
			break;
	
	if !new_obj:
		return null;
		
	new_obj.alive = true;
	new_obj._on_awake();
	
	return new_obj;

# Puts all objects in the pool to sleep.
func sleep_all():
	for obj in objects:
		obj.alive = false;

func _ready():
	pass # Replace with function body.

func _draw():
	for obj in objects:
		if obj.alive:
			obj._draw(self);


func _process(delta):
	for obj in objects:
		if obj.alive:
			obj._update(delta);
		
	if update_every_frame:
		update();
