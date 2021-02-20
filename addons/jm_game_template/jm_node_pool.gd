extends Spatial

var alive_nodes : Array = [];
var asleep_nodes : Array = [];

export (int) var pool_size = 100;
export (PackedScene) var object_prototype;
export (bool) var use_global_coords = false;

var node_holder : Node = self;

# Initializes the pool, instancing all the object prototypes.
# Must be called before you can use the pool.
func initialize_pool():
	if !object_prototype:
		return false;
	
	alive_nodes.clear();
	asleep_nodes.clear();
	
	if use_global_coords:
		node_holder = Node.new();
		add_child(node_holder);
	
	for i in range(pool_size):
		var new_node = object_prototype.instance();
		asleep_nodes.append(new_node);

# Sets a node in the pool to sleep. This will remove the node from the scene tree
# and call its _on_sleep method. After this the node is available to be spun up again
# in the future. Note: the _on_sleep method on the node should reset that node to a
# "clean" state, otherwise the node will retain state when it awakens again.
func sleep_node(node : Node):
	if !alive_nodes.find(node):
		return;
		
	if "alive" in node:
			node.alive = false;
	
	if node.has_method("_on_sleep"):
		node._on_sleep();
	
	alive_nodes.erase(node);
	asleep_nodes.append(node);
	node_holder.remove_child(node);

# Gets a new node from the pool from the list of sleeping nodes. The node's _on_awake
# method is called. The returned node can them be initialized by the user (e.g. by giving
# it a position somewhere in the scene)
func awake_node() -> Node:
	if asleep_nodes.empty():
		return null;
	
	var new_node : Node = asleep_nodes.pop_back();
	
	alive_nodes.append(new_node);
	node_holder.add_child(new_node);
	
	if "alive" in new_node:
		new_node.alive = true;
	
	if new_node.has_method("_on_awake"):
		new_node._on_awake();
	
	return new_node;

# Puts all nodes in the pool to sleep.
func sleep_all():
	asleep_nodes += alive_nodes;
	
	for node in alive_nodes:
		if "alive" in node:
			node.alive = false;
		
		if node.has_method("_on_sleep"):
			node._on_sleep();
		node_holder.remove_child(node);
		
	alive_nodes.clear();
	
func _process(delta):
	for i in range(alive_nodes.size(), 0, -1):
		var node : Node = alive_nodes[i-1];
		if "alive" in node && !node.alive:
			if node.has_method("_on_sleep"):
				node._on_sleep();
				
			alive_nodes.remove(i-1);
			node_holder.remove_child(node);
			asleep_nodes.append(node);
		
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for node in asleep_nodes:
			node.queue_free();
		asleep_nodes.clear();
