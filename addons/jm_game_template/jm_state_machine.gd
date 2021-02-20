extends Node

signal transitioned_to(state)

export var initial_state := NodePath()

var current_state : FsmState = null;
var prev_state : FsmState = null;
var states = {};

func _ready():
	var num_states = 0;
	var _initial_state : FsmState = null;
	for child in get_children():
		if child is FsmState:
			add_state(child);
			if !_initial_state:
				_initial_state = child;
			
	if !initial_state.is_empty() && has_node(initial_state):
		var _state = get_node(initial_state)
		if _state is FsmState:
			_initial_state = _state;
	
	assert(_initial_state); #must have an initial state by this point
	_enter_state(_initial_state);
	
func _exit_state():
	current_state._on_exit();
	current_state.set_process(false);
	current_state.set_physics_process(false);
	current_state.set_process_input(false);
	current_state.set_process_unhandled_input(false);
	current_state.set_process_unhandled_key_input(false);
	current_state.active = false;
	prev_state = current_state;
	current_state = null;
	
func _enter_state(state : FsmState, msg : Dictionary = {}):
	current_state = state;
	current_state.active = true;
	current_state.set_process(true);
	current_state.set_physics_process(true);
	current_state.set_process_input(true);
	current_state.set_process_unhandled_input(true);
	current_state.set_process_unhandled_key_input(true);
	current_state._on_enter(msg);

# Adds a new state to the state machine. The recommended way to setup the states
# is by adding them in the inspector, but in case states need to be added during
# runtime this method can be used.
func add_state(new_state : FsmState):
	new_state.set_state_machine(self);
	states[new_state.name] = new_state;
	new_state.set_process(false);
	new_state.set_physics_process(false);
	new_state.set_process_input(false);
	new_state.set_process_unhandled_input(false);
	new_state.set_process_unhandled_key_input(false);
	new_state.active = false;

# Removes a state from the state machine. If that state if the current_state
# the FSM will attempt to return to the previous state.
func remove_state(state : FsmState):
	if state && states.has(state.name):
		if current_state == state:
			transition_to_previous();
		
		state.set_state_machine(null);
		states.erase(state.name);

# Transitions to the target_state. Optionally sends a msg to the new state
# so it can initialize itself on its _on_enter method. Returns true if successful
# and false otherwise.
func transition_to(target_state : String, msg : Dictionary = {}) -> bool:
	if !states.has(target_state):
		return false;
		
	var _state : FsmState = states[target_state];
	
	if !_state || _state.is_queued_for_deletion():
		return false;
		
	_exit_state();
	_enter_state(_state, msg);
	emit_signal("transitioned_to", target_state);
	return true;

# Same as transition_to, except this will transition to the previous stored state
# in the state machine.
func transition_to_previous(msg : Dictionary = {}) -> bool:
	if !prev_state || prev_state.is_queued_for_deletion():
		return false;
	
	var _state = prev_state;
	_exit_state();
	_enter_state(_state, msg)
	emit_signal("transitioned_to", _state.name);
	return true;
