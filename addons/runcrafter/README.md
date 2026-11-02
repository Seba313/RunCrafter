# RunCrafter – visual state machines for Godot 4 (PlayMaker-style)

RunCrafter is a Godot 4.5+ counterpart of Unity's **PlayMaker** plugin (tested on 4.7).
You build game logic from **finite state machines (FSMs)** – states, events, transitions and ready-made **actions** –
in a graph editor, without writing code.

| PlayMaker (Unity)           | RunCrafter (Godot)                                          |
|-----------------------------|-------------------------------------------------------------|
| PlayMakerFSM (component)    | `RCFsmComponent` node                                       |
| FSM / FSM Template          | `RCFsm` resource (embedded in the scene or a `.tres` file)  |
| State                       | `RCState`                                                   |
| Event / Transition          | events (String) / `RCTransition`                            |
| Global Transition           | global transitions (from any state)                         |
| FsmStateAction              | `RCAction` (+ about 210 ready-made actions)                 |
| FSM Variables               | FSM variables (`RCVariable`)                                |
| Globals                     | global variables and events (`runcrafter_globals.tres`)     |
| "Show in Inspector"         | variable with the **Inspector** option (per-instance override) |
| Action Sequence             | the state's **Sequence** option                             |
| FINISHED                    | `FINISHED`, sent when all actions have finished             |
| Debug (state highlighting)  | live highlighting of the active state + the **Log** tab     |
| Action Browser              | **Add Action…** window with search and categories           |

## Installation

Requires **Godot 4.5 or newer** (tested on 4.7).

1. Copy `addons/runcrafter` into your project.
2. Enable the plugin in *Project → Project Settings → Plugins → RunCrafter*.
3. A **RunCrafter** tab appears next to the 2D / 3D / Script editors.

## Quick start

1. Select the node that should get a state machine and click **Add FSM** in the RunCrafter tab. This adds an **RCFsmComponent** child named `FSM` (its parent is the FSM's "owner", see `owner_path`). You can also add an `RCFsmComponent` by hand and click **Create FSM**.
2. The new FSM opens with one state, `State 1`.
3. **Right-click the graph** to add a state (*Add State*). **Right-click a state** to add a transition, set the start state, copy, duplicate or delete it.
4. **Connecting (like PlayMaker):** grab an event row of a state (e.g. `FINISHED`) and drag it onto any part of another state. The state under the cursor is highlighted. Dropping on its own state creates a self transition; empty space or `Esc` cancels. Dragging an already connected transition re-targets it. The whole area below the title bar picks the nearest event row, so you never move a state by accident; move states by their title bar (hover a state to see its action count). Right-click an event row for a menu: change event, Disconnect, Move Up/Down, Delete.
5. In the **State** tab click **Add Action…**. Actions run from top to bottom. Click an action's title to fold it (folded actions show a one-line summary of their parameters); *Collapse All / Expand All* fold the whole list.
6. Run the game: the active state glows orange and transitions are listed in the **Log** tab.

Opening the editor:
* selecting an `RCFsmComponent` node opens it in the RunCrafter tab,
* selecting a node that **owns** an FSM (its parent) loads that FSM into RunCrafter without leaving the 2D/3D view,
* selecting a node without an FSM shows an empty RunCrafter tab with an **Add FSM** button,
* the **Edit FSM '…' in RunCrafter** button at the top of the Inspector always opens it (also from the Script editor); a node with several FSMs gets one button per FSM and a picker in the RunCrafter toolbar.

Graph shortcuts: `Delete` deletes, `Ctrl+C` / `Ctrl+V` copy and paste, `Ctrl+D` duplicates. All changes support Undo/Redo.

## Groups, comments and problem checks

* **Groups** – select states, right-click a state (or the empty graph) and choose *Group Selected States*. The titled frame moves its states together; drop more states onto it to add them, or right-click a state > *Remove from Group*. Double-click the frame (or right-click > *Edit Group…*) to change the title, notes and color.
* **Comments** – right-click the empty graph > *Add Comment* places a resizable note. Double-click it to edit the text.
* Groups and comments only help you organize the graph; they do nothing while the game runs.
* **Problems** – RunCrafter checks the FSM while you edit it: missing target nodes, variables or states, syntax errors in expressions, unconnected events and states that nothing leads to. States with problems get a red (error) or yellow (warning) outline and a ⚠ in the title, the list is shown at the top of the **State** tab, and the toolbar shows a counter (click it to jump to the next state with a problem).
* **Live values** – while the game runs, the **Variables** and **Globals** tabs show the current value of every variable in orange (▶ value) for the FSM being edited.

## Variables and binding

* The **Variables** tab holds the FSM's local variables. Types: float, int, bool, String, Vector2, Vector3, Color, Object, Array, Dictionary.
* The **≡** button next to an action parameter binds it to a variable. The value is then read from the variable when the state is entered and every frame.
* `store_*` and `variable` fields pick the variable the action writes its result to.
* Both the **≡** menu and the variable drop-down (▾) have **New Variable…**, which creates a variable on the spot (name and type are suggested from the field, optionally global).
* A `NodePath` parameter can be bound to an Object variable (e.g. a node found with *Find Node*).
* The **Globals** tab holds variables and events shared by all FSMs. In actions they use the `g:` prefix; in expressions they are available by their plain name.
* Variables with **Inspector** checked appear in the Inspector of the `RCFsmComponent` (*Variables* group), so every instance can have its own value.
* Expressions (`Expression Test`, `Set Variable (Expression)`, `Set Property`, `Tween Property`…) are Godot [Expressions](https://docs.godotengine.org/en/stable/classes/class_expression.html). They see all variables, and `self` is the owner node. Note: `Expression` does not support constants such as `Vector2.ZERO` – write `Vector2(0, 0)`.
* Texts (`Log`, `Set Text`, `Build String`) replace `{variable_name}` with the variable's value.
* **Signal Name** fields have a drop-down with the signals of the action's target node (its script signals first, then built-in ones, with argument types). Connect / Disconnect Signal uses the **Source** node.

## Templates (FSM Templates)

The **Template** menu:
* **Save Copy as Template…** saves a copy of the FSM to a `.tres` file.
* **Use Template…** links a `.tres` file to the node. The same file can be shared by many nodes; editing it changes every instance (*Save Template* button or Ctrl+S).
* **Make Unique** embeds an independent copy in the scene.

## Scripting API

```gdscript
@onready var fsm: RCFsmComponent = $RCFsmComponent

fsm.send_event("HIT")                        # send an event
fsm.send_event("HIT", {"damage": 10}, self)  # ...with data and a sender (Get Event Info action)
fsm.send_event_delayed("RESPAWN", 2.0)
fsm.set_var("health", 50)                    # variables
var hp = fsm.get_var("health")
fsm.goto_state("Dead")                       # force a state
fsm.get_active_state_name()
fsm.state_changed.connect(func(from, to, ev): print(from, " -> ", to))
RCFsmComponent.broadcast(get_tree(), "GAME_OVER")   # to every FSM
fsm.custom_signal.connect(func(name, args): print(name, args))  # Emit FSM Signal action
fsm.state_event_data                         # data of the event that entered the current state
```

## Sub-FSMs (Run FSM) and event data

* **Run FSM** runs an FSM template as a sub-state machine on the same owner and waits until it executes the **Finish FSM** action. *Input / Output Variables* copy variables into the sub-FSM and back. Leaving the state stops the sub-FSM.
* **Send Event** and **Send Event To Group** have a *Data Expression* field. The receiver reads the data, the event name and the sender with **Get Event Info** (including a single Dictionary field).

## Custom actions

Create a script with a `class_name` that extends `RCAction`. It appears in the action browser automatically.

```gdscript
@tool
class_name RCHeal
extends RCAction

const CATEGORY := "My Game"
const DESCRIPTION := "Heals the owner."

@export var amount: int = 10
@export var done_event: String = ""     # *_event  -> event picker
@export var store_new_hp: String = ""   # store_*  -> variable picker
@export var every_frame: bool = false

func _on_enter() -> void:
	get_owner_node().heal(amount)
	store(store_new_hp, get_owner_node().hp)
	finish()                 # the action is done
	send_event(done_event)

# Also available: _on_update(delta), _on_physics_update(delta), _on_exit(), _on_input(event),
# get_target("target"), get_var(), set_var(), eval(expr), format_text(), connect_signal(),
# connect_signal_any(obj, "signal") + _on_signal_args(args) - a signal with any number of arguments
```

Property naming conventions (used by the editor):
* `store_*`, `variable`, `*_variable` – variable picker,
* `event`, `*_event` – event picker (new events are added automatically),
* `*input_action` – Input Map action picker,
* `signal_name` – signal picker for the target node,
* `NodePath` – relative to the FSM owner (empty = the owner itself); the ⊙ button picks a node from the scene.

`connect_signal()` disconnects signals automatically when the state exits.

## Action library (categories)

**State Machine**: Send Event (self / other FSM / broadcast, with delay and data), Send Event To Group, Send Event By Name, Next Frame Event, Random Event, Repeat Event, Array For Each, Run FSM, Finish FSM, FSM Control, Get/Set FSM Variable, Get State Info, Get Event Info.
**Time**: Wait, Random Wait, Get Time.
**Logic**: Bool Test, Bool Changed, Int/Float/String Compare, Expression Test, Int Switch, Node Is Valid, Run Expression.
**Variables**: Set Float/Int/Bool/String/Vector2/Vector3/Color, Set Variable (Expression), Bool Flip, Build String, Convert To String.
**Math**: Float/Int Operator, Float/Int Add, Float/Int Clamp, Float Move Toward, Float Remap, Float Snap, Random Float/Int/Bool, Random Vector, Float Interpolate, Vector2/3 Operator, Angle Between, Get/Set Vector XY(Z), Sample Curve, Sample Noise.
**Array**: Add, Get, Count, Clear, Contains, Remove.
**Dictionary**: Get, Set, Has, Erase, Keys / Values.
**String**: Split, Replace, Contains / Starts / Ends With, Length, Substring, Case / Trim, String To Number, Format Number.
**Node**: Set/Get Property, Call Method, Call Group, Instantiate, Destroy Node, Reparent Node, Set Visible, Set Process Mode, Find Node, Add To Group, Is In Group, Get/Set Meta, Get Distance, Get Child Count.
**Transform 2D / 3D**: Set/Get Position, Translate, Rotate, Set Rotation, Set Scale, Look At, Move Towards.
**Physics**: Set/Get Velocity 2D/3D, Move And Slide, Character Jump, Apply Impulse/Force 2D/3D, Is On Floor, Is On Wall / Ceiling, Get Slide Collision, Raycast 2D/3D, Shape Cast, Trigger/Contact Event, Get Overlapping Bodies / Areas, Set Collision Layer / Mask, Set Gravity Scale, Freeze Body.
**Navigation**: Navigate To, Set Navigation Target, Is Navigation Finished, Get Navigation Info, Patrol.
**Camera**: Make Camera Current, Camera Zoom, Camera Follow, Screen To World.
**Input**: Input Action Event, Get Input Axis, Get Input Vector, Get Action Strength, Get Joy Axis, Joypad Vibration, Simulate Action, Key Event, Mouse Button Event, Any Key Event, Touch Event, Get Mouse Position, Warp Mouse.
**Animation**: Play Animation (AnimationPlayer / AnimatedSprite), Stop Animation, AnimationPlayer Control, Get Animation Info, Tween Property, Tween Sequence, Typewriter Text, Shake, AnimationTree Travel / Condition, Set AnimationTree Parameter.
**Rendering**: Set Shader Parameter, Set Shader Global, Particles Control, Set Sprite, Fade CanvasItem, Set Light, Set Environment Property.
**Audio**: Play Sound, Play One Shot, Stop Sound, Fade Volume, Music Crossfade, Set Pitch, Set Bus Volume, Toggle Bus Effect.
**Scene**: Change Scene, Load Scene Async, Reload Scene, Quit Game, Set Time Scale, Pause Game, Set Mouse Mode, Save / Load Variables (save games in `user://`), Window Control.
**UI**: Set Text, Button Event, Control Value Event, Get Control Value, Grab Focus, Set Modulate, Set Range Value, Set Theme Override.
**Signals**: Signal Event, Signal Event If, Wait For Signal, Signal Counter, Emit Signal, Emit FSM Signal, Connect / Disconnect Signal.
**Network**: HTTP Request, Call RPC, Is Multiplayer Authority.
**Localization**: Translate, Set Locale.
**Debug**: Log, Comment, Debug Draw, Assert.

## Demo

`addons/runcrafter/examples/demo_2d.tscn` contains:
* a player (Idle / Move / Hurt / Check HP / Dead, a global `HIT` transition, variables exposed in the Inspector),
* coins sharing the `coin_fsm.tres` template (Trigger Event, sending an event to another FSM, tween, destroy),
* a traffic light (Wait / Random Wait),
* a HUD (Set Text with `{variables}`, Input Action Event, Get FSM Variable).

Controls: arrow keys move, Space or Enter deals damage.

## Execution semantics

* Entering a state calls `_on_enter()` of every enabled action in order. If one of them sends an event that causes a transition, the remaining actions are not started (as in PlayMaker).
* Every frame `_on_update()` and `_on_physics_update()` are called for actions that have not finished.
* When all actions have called `finish()`, the state sends `FINISHED`. A state without actions sends it immediately. `FINISHED` is not sent when an action has already requested a transition, and it never "leaks" into the next state.
* On exit `_on_exit()` is called and signals connected with `connect_signal()` are disconnected.
* Infinite-loop protection: at most `max_transitions_per_frame` transitions per frame.
* Every instance runs its own copy of the FSM, so a shared template is never modified while the game runs.

## License

MIT © Seba313 – see `LICENSE`. Inspired by PlayMaker for Unity (not affiliated with Hutong Games). Developed with the help of Claude (Anthropic).
