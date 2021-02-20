extends Reference

# Helper object to handle unregistering all listeners associated with an object.
# Instance a SubscriptionList as one of the variables in your script and use its
# methods to register listeners and when the node is destroyed (causing the 
# SubscriptionList to go out of scope) any listeners registered will be automatically
# unregistered.
class_name SubscriptionList

class EventListener:
	var event: String
	var callback_func: String
	
var subscriptions : Array = []
var event_manager;
var listener_obj_id: int
var listener_obj : Node;

func _init(manager: Node, listener: Object):
	event_manager = manager;
	listener_obj_id = listener.get_instance_id();
	listener_obj = instance_from_id(listener_obj_id);

func _notification(what):
	if (what == NOTIFICATION_PREDELETE && is_instance_valid(event_manager)):
		for entry in subscriptions:
			event_manager.ignore(entry.event, entry.callback_func, listener_obj_id)
		subscriptions.clear();

# Same as calling the listen method on the EventManager but this will make sure
# that the listener will be ignored as soon as this SubscriptionList goes out of
# scope.
func listen(event: String, callback_func: String):
	if event_manager && listener_obj && is_instance_valid(event_manager) && is_instance_valid(listener_obj):
		var has_entry = false;
		for entry in subscriptions:
			if entry.event == event && entry.callback_func == callback_func:
				has_entry = true;
				break;
		
		if !has_entry:
			event_manager.listen(event, callback_func, listener_obj);
			var new_entry = EventListener.new();
			new_entry.event = event;
			new_entry.callback_func = callback_func;
			subscriptions.append(new_entry);

# Same as calling the ignore method on the EventManager
func ignore(event: String, callback_func: String):
	if event_manager && listener_obj && is_instance_valid(event_manager):
		event_manager.ignore(event, callback_func, listener_obj)
		for i in range(subscriptions.size()):
			var entry = subscriptions[i];
			if entry.event == event && entry.callback_func == callback_func:
				subscriptions.remove(i);
				break;
		
