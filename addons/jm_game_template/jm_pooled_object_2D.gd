extends Reference

class_name PooledObject2D

var alive : bool = false;
var _pool : Node2D = null;

# Called every frame if the object is alive. Use this to submit draw commands to draw
# this object in the pool (e.g using methods like pool.draw_texture(texture,Vector2()))
func _draw(pool : Node2D):
	pass;
	
# Causes the object to go to sleep and its _update method will no longer be called
func sleep():
	_on_sleep();
	alive = false;

# Called when the object is awoken by the pool, reset the object and run any code
# that must run before the object begins updating.
func _on_awake():
	pass;

# Called when the object is put to sleep. Reset the object here and run any cleanup
# code necessary.
func _on_sleep():
	pass;

# Called every frame if the object is alive.
func _update(delta):
	pass;
