extends Node

var listeners = {};

class ListenerInfo:
	var callback;
	var obj : Node;
	var func_name : String;
	var obj_id : int;

# Registers a callback to listen to the specified event. If this method was
# called directly from user code (instead of using the provided SubscriptionList
# class) then the ignore method should be called whenever listener_obj is deleted
# to avoid dangling listeners.
func listen(event: String, callback_func: String, listener_obj: Node):
	assert(listener_obj && is_instance_valid(listener_obj) && listener_obj.has_method(callback_func));
	
	if not listeners.has(event):
		listeners[event] = []
		
	var new_info = ListenerInfo.new();
	new_info.callback = funcref(listener_obj, callback_func);
	new_info.obj = listener_obj;
	new_info.func_name = callback_func;
	new_info.obj_id = listener_obj.get_instance_id()
	
	listeners[event].append(new_info)

# Opposite of listen, unregisters a callback to a given event.
func ignore(event: String, callback_func: String, listener_obj):
	var listener_id : int;
	if listener_obj is int:
		listener_id = listener_obj;
	else:
		if !listener_obj || !is_instance_valid(listener_obj) || !(listener_obj is Node):
			return;
		listener_id = listener_obj.get_instance_id();
	
	if listeners.has(event):
		var listener_list : Array = listeners[event];
		for i in range(listener_list.size()):
			if listener_list[i].obj_id == listener_id && listener_list[i].func_name == callback_func:
				listener_list.remove(i);
				break;

# Raises an event with the event manager, calling all listener callbacks registered
# for that event synchronously.
func raise_event(event: String, args = {}):
	if listeners.has(event):
		for info in listeners[event]:
			var listener_info : ListenerInfo = info;
			if listener_info.obj.is_inside_tree():
				if args is Dictionary && args.empty():
					listener_info.callback.call_func()
				else:
					listener_info.callback.call_func(args)
