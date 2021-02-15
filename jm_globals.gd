extends Node

# Add this script to your autoload scripts to get global access to the game's
# GameManager and EventManager singletons.

const EventManager = preload("jm_event_manager.gd");
const GameManager = preload("jm_game_manager.gd");

var _game_manager : GameManager = null;
var _event_manager : EventManager = null;

func manager() -> GameManager:
	if !_game_manager:
		var managers = get_tree().get_nodes_in_group("jm_global_game_manager");
		if managers.size() > 0:
			_game_manager = managers[0];
	
	return _game_manager;
	
func events() -> EventManager:
	if !_event_manager:
		_event_manager = manager().event_manager;
		
	return _event_manager;
	
