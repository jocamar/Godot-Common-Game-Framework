extends Node

class_name FsmState

var state_machine : Node = null;
var active = false;

func set_state_machine(sm : Node):
	state_machine = sm;

func _on_enter(msg : Dictionary = {}):
	pass;
	
func _on_exit():
	pass;

# Same as calling transition_to on the StateMachine
func transition_to(target_state : String, msg : Dictionary = {}) -> bool:
	if !active || !state_machine:
		return false;
	
	return state_machine.transition_to(target_state, msg);
	
# Same as calling transition_to_previous on the StateMachine
func transition_to_previous(msg : Dictionary = {}) -> bool:
	if !active || !state_machine:
		return false;
	
	return state_machine.transition_to_previous(msg);
