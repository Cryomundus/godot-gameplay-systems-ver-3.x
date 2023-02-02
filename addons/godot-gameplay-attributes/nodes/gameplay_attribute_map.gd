@icon("res://addons/godot-gameplay-attributes/assets/attribute_map_icon.png")
@tool
class_name GameplayAttributeMap extends Node

## A GameplayAttributeMap is the core node which makes the magic for you.[br]
##
## A GameplayAttributeMap stores and handles a set of attributes and effects for your gameplay mechanics.


## Emitted when an attribute changes.
signal attribute_changed(attribute: AttributeSpec)
## Emitted each time an effect is applied to a specific AttributeSpec.
signal attribute_effect_applied(attribute_effect: AttributeEffect, attribute: AttributeSpec)
## Emitted after an effect is has been applied for the last time to a specific AttributeSpec.
signal attribute_effect_removed(attribute_effect: AttributeEffect, attribute: AttributeSpec)
## Emitted once a GameplayEffect has been applied.
## [br]
## The signal is called once, even if a time-based AttributeEffect is still going on.
signal effect_applied(effect: GameplayEffect)


@export_category("Owner")
## Is the path to the owning character
@export_node_path var owning_character := NodePath()


@export_category("Attributes")
## Is the array of Attribute resources generated by the inspector plugin.
@export var attributes: Array[AttributeResource] = []
## Is the AttributeTable selected resource.
@export var table: AttributeTable = null


var _attributes_dict: Dictionary = {}
## Is the list of child GameplayEffect nodes
var effects: Array[GameplayEffect] = []:
	get:
		var _effects: Array[GameplayEffect] = []
		
		for child in get_children():
			if child is GameplayEffect:
				_effects.append(child)
		
		return _effects


func _add_attribute_spec(spec: AttributeResource) -> void:
	if Engine.is_editor_hint():
		attributes.append(spec)


func _apply_initial_effects() -> void:
	for effect in effects:
		apply_effect(effect)
	

func _handle_character_child_entered_tree(node: Node) -> void:
	if node is GameplayEffect:
		add_child(node)


func _get_attribute_at(index: int) -> AttributeResource:
	if Engine.is_editor_hint():
		if attributes.size() > index:
			return attributes[index]

		attributes.append(AttributeResource.new())
		return attributes[index]
	else:
		return null


func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_attributes()
		
		if owning_character != null and not owning_character.is_empty():
			var character = get_node(owning_character)

			if character:
				character.child_entered_tree.connect(func (child):
					if child is GameplayEffect:
						apply_effect(child)	
				)

		_apply_initial_effects()


func _setup_attributes() -> void:
	_attributes_dict = {}

	for attribute in attributes:
		var previous = get_attribute_by_name(attribute.attribute_name)
		
		if previous:
			previous.free()
		
		var spec = AttributeSpec.from_attribute(attribute)
		
		spec.changed.connect(func (attribute): 
			attribute_changed.emit(attribute)	
		)
		
		_attributes_dict[spec.attribute_name] = spec


func _setup_owning_character() -> void:
	if owning_character == null or owning_character.is_empty():
		return
	
	var owning_character = get_node(owning_character)

	if owning_character:
		owning_character.child_entered_tree.connect(func (child):
			if child is GameplayEffect:
				apply_effect(child)	
		)
		

func _update_attribute(index: int, key: String, value: float) -> void:
	if Engine.is_editor_hint():
		if attributes.size() >= index:
			if key in attributes[index]:
				attributes[index][key] = value


## Applies an effect on current GameplayAttributeMap
func apply_effect(effect: GameplayEffect) -> void:
	if effect == null:
		return

	for attribute_affected in effect.attributes_affected:
		if not attribute_affected.attribute_name in _attributes_dict:
			return
		
		if attribute_affected.life_time == AttributeEffect.LIFETIME_ONE_SHOT:
			var spec = _attributes_dict[attribute_affected.attribute_name]
			
			if not attribute_affected.should_apply(effect, self):
				continue
			
			_attributes_dict[attribute_affected.attribute_name].current_value += attribute_affected.get_current_value()
			attribute_effect_applied.emit(attribute_affected, spec)
			attribute_effect_removed.emit(attribute_affected, spec)
		elif attribute_affected.life_time == AttributeEffect.LIFETIME_TIME_BASED:
			var counts = 0
			var timer = Timer.new()
			
			add_child(timer)
			
			timer.wait_time = attribute_affected.apply_every_second
			timer.timeout.connect(func ():
				var spec = _attributes_dict[attribute_affected.attribute_name]
				
				if not attribute_affected.should_apply(effect, self):
					counts += 1
					return
				
				if attribute_affected.max_applications != 0 and attribute_affected.max_applications == counts:
					attribute_effect_removed.emit(attribute_affected, spec)
					timer.stop()
					remove_child(timer)
				else:
					spec.current_value += attribute_affected.get_current_value()
					attribute_effect_applied.emit(attribute_affected, spec)

					if attribute_affected.max_applications != 0:
						counts += 1
			)
			
			timer.start()

	effect_applied.emit(effect)


## Gets an instance of AttributeSpec by it's attribute_name
func get_attribute_by_name(attribute_name: String) -> AttributeSpec:
	if _attributes_dict.has(attribute_name):
		return _attributes_dict.get(attribute_name)
	
	return null


## Represents an attribute as a class
class AttributeSpec extends Object:
	## Emitted when the instance has changed one of it's values
	signal changed(spec: AttributeSpec)
	## Emitted when the instance has changed it's minimum value
	signal minimum_value_changed(from: float, to: float)
	## Emitted when the instance has changed it's maximum value
	signal maximum_value_changed(from: float, to: float)
	
	## used internally to avoid the initial signals propagation 
	var __setup := false
	## It's the attribute name
	var attribute_name := ""
	## It's the current attribute's value
	var current_value := 0.0:
		get:
			return current_value
		set(value):
			var previous_value = current_value
			
			if previous_value == value:
				return
			
			if maximum_value > minimum_value:
				current_value = clampf(value, minimum_value, maximum_value)
			elif maximum_value == minimum_value and maximum_value == 0.0:
				current_value = value
			else:
				if maximum_value == 0.0 and minimum_value > 0.0:
					current_value = clampf(value, value + 1, minimum_value)
				else:
					current_value = clampf(value, maximum_value, minimum_value)
			if not __setup:
				changed.emit(self)
	## It's the maximum attribute's value. Keep 0 to mark it as infinite
	var maximum_value := 0.0:
		get:
			return maximum_value
		set(value):
			var previous_value = maximum_value
			maximum_value = value
			
			if not __setup:
				maximum_value_changed.emit(previous_value, value)
	## It's the maximum attribute's value. 
	var minimum_value := 0.0:
		get: 
			return minimum_value
		set(value):
			var previous_value = minimum_value
			minimum_value = value
			
			if not __setup:
				minimum_value_changed.emit(previous_value, value)


	## Creates an instance of [AttributeSpec] starting from an [AttributeResource]
	static func from_attribute(attribute: AttributeResource) -> AttributeSpec:
		var instance = AttributeSpec.new()
		instance.__setup = true
		instance.attribute_name = attribute.attribute_name
		instance.maximum_value = attribute.maximum_value
		instance.minimum_value = attribute.minimum_value
		instance.current_value = attribute.current_value
		instance.__setup = false
		return instance
