# Godot Common Game Framework

![Header image](https://github.com/jocamar/Godot-Common-Game-Framework/blob/main/graphics/framework.png?raw=true)

This is a collection of simple nodes and objects I've used over the past months of using Godot to help in a variety of ways. I figure this might be useful for some other people, especially in gamejam contexts to quickly get access to some common features like split-screen, a global event bus or async scene loading.

## Installation

To install this addon simply clone this **into a folder named `jm_game_template` inside your project's addons folder**, enable the plugin in your project settings and optionally add the `jm_globals.gd` script as one of your autoload singletons for easier access to the `GameManager`.

## Features

Below is the list of nodes included in the addon.

### GameManager

This is a singleton node that should be in the root of your project and helps with implementing split-screen, per screen post-processing and async scene loading. In order to use it create a simple empty scene and add a `GameManager` node to it, then make this scene your project's startup scene in the project settings. In the `GameManager` node configure your initial scene its `Initial Scene` property in the inspector. This will be the first scene the `GameManager` will load much as if you were configuring it in your project's settings.

Afterwards you can call the `GameManager`'s methods (easier if you have included `jm_globals.gd` in your autoloaded singletons by typing `<singleton-name>.manager()`) like `set_num_split_screen_viewports` and `set_player_camera` to easily setup split-screen. You can also use the `set_postprocess_material` to add post processing by giving it a material. When using this node do not use Godot's built-in node tree `change_scene` methods, as this will unload the `GameManager`. Instead the `GameManager` provides a set of methods to load scenes like `change_scene`, `load_scene`, `unload_scene`, `add_scene` as well as `load_scene_async`.

![GameManager Example](https://github.com/jocamar/Godot-Common-Game-Framework/blob/main/graphics/gamemanagerexample.png?raw=true)

### EventManager

The event manager provides a simple way to implement the observer pattern besides Godot's built-in signals. Godot's signals are great and the best approach in most cases, but when you want to listen to events from multiple nodes and don't care who the emissor is or when two nodes are far apart in the scene tree, they might not be the best approach. Having a global event bus that any node can submit events to, and register listeners in, is useful in these cases.

You can add `EventManager`'s to your scenes at will but if you added a `GameManager` it already provides you with a global `EventManager`. If you added the `jm_globals.gd` script to your autoloads you can access it by calling `<singleton-name>.events()`. Adding listeners is simple and works much the same as connecting signals. In the case of a node registering a listener: `<singleton-name>.events().listen("my_event", "my_callback", self)`. When calling the manager's `listen` method directly, care must be taken to call its `ignore` method to unregister the listener when the node is deleted, so as to avoid dangling listeners. To help with this there is the `SubscriptionList` class, which can handle this for you. To use it simply declare it as a variable in your node's script (`var events : SubscriptionList`), initialize it with the node reference and the event manager to which it will bind (`events = SubscriptionList.new(<singleton-name>.events(), self)` and then use its `listen` method to register callbacks. When the object goes out of scope (in this case when the node it belongs to is deleted) it will automatically unregister all listeners.

To submit events the `EventManager` provides a `raise_event` method where you can specify an event as well as submit parameters to go along with it. When an event is raised all listeners registered to it from any node in the tree will be called, whithout the nodes needing to know who raised the event.

![EventManager Example](https://github.com/jocamar/Godot-Common-Game-Framework/blob/main/graphics/eventmanagerexample.png?raw=true)

### StateMachine

This provides a simple state machine implementation you can use in games. This is useful for characters that have different behaviors depending on which state they're in (e.g. running, jumping, stunned, attacking, etc). Usage is simple, add a `StateMachine` node wherever you need it and then add each state as its direct child. States must inherint the `FsmState` node type and can then override its `_process`, `_physics_process` and other methods to provide unique behavior for each state. Only the current active state in the `StateMachine` will be processed.

If no initial state is configured the first child of the `StateMachine` will be the initial state. A state can transition to another by calling its `transition_to` method with the name of the state to transition to. There is also a `transition_to_previous` method which will move the state machine back one state. However the state machine only keeps record of the last state it was in, so calling this multiple times will just alternate between two states.

![StateMachine Example](https://github.com/jocamar/Godot-Common-Game-Framework/blob/main/graphics/statemachineexample1.png?raw=true)

![StateMachine Example](https://github.com/jocamar/Godot-Common-Game-Framework/blob/main/graphics/statemachineexample2.png?raw=true)

### NodePool

While pooling objects in Godot is not as necessary as in Unity, it can still be useful at times. The `NodePool` provides a simple way to do this. To use it add a `NodePool` node somewhere in your scene and configure its `Pool Size` to the max number of nodes in the pool and its `Object Prototype` with the scenes to instance.

When starting your game or loading your scene call the pool's `initialize_pool` method to create all instances of the prototype and then these will be available inside the pool (but they will not be in the scene tree until awoken). Calling the pool's `awake_node` method will provide you with an instance of an available node in the pool which you can then initialize (e.g. giving it a new position somewhere). When you're done with a pooled node simply set its `alive` variable to false (if the node does not have an `alive` variable declared you won't be able to sleep it, it'll just remain running forever). As the pool does not know how to reset the node's state you should do so either in the `_on_sleep` or `_on_awake` methods in your node (declare them if you need to) so that it is set to a "clean" state.

### ObjectPool2D

Works much the same way as the `NodePool` except this one can be used with `Reference` instead of nodes and uses the `Node2D` drawing functions to be able to draw lots of 2D objects (like bullets in a bullet hell game for example). You can see Godot's custom drawing tutorial for some more info on this technique: https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html

The main difference to `NodePool` is that you must provide it with the object class of the objects in the pool in its `initialize_pool` method (these must inherit `PooledObject2D`). In your object class you should override the `_update` and `_draw` methods. The `_draw` method receives the object's pool as a parameter and you should use this to submit the draw commands for the object (e.g. using `draw_texture`). To sleep an object you can call its `sleep` method.



### MaterialCache and MaterialCache2D

These two nodes help deal with a common Godot issue of shaders being lazily compiled when they're first used, which can lead to hiccups in your game the first time a certain object is drawn or a shader needed. In order to fix this you can add a `MaterialCache` node (typically as a child of your camera so it's always visible) and provide it with a folder where you have saved your materials. The node will then instance either a `MeshInstance`, a particle system or a `Sprite` depending on each material and assign the material to it. This will force the compilation of the shaders if the cache is visible.

This is typically done at the startup of the game to move what would be several small hiccups into a larger break during the loading phase. You can control when this is done by calling the `show_cache` method. When this method is called (typically during loading or just at the start of your game) all the materials will be drawn and shown (make sure to set the `MaterialCache`'s scale to something small so it isn't noticeable, or hide it behind the loading screen).
