Gameplay Attributes
===================

Gameplay attributes are a set of nodes used to describe some
characters attributes for both 2D and 3D games made with Godot.

# Install

Clone this repo inside your `addons` directory.

Enable this plugin by going to `project settings/plugins`.

Enjoy!

# How it works

There are three main **nodes** types:

- `GameplayAttributesMap`: it is the wrapper around a set of attributes
- `GameplayAttribute`: describes an attribute (current value, max value)
- `GameplayEffect`: is where the magic happens, it describes how attributes work
together and how to change them.

A character should have one `GameplayAttributesMap`. 

A `GameplayAttributesMap` can have many `GameplayAttribute` (like health, mana, shield, movement speed, strength etc).

A character could be affected by many `GameplayEffect`s (like direct damage, attributes regen over time, attributes consumption over time etc)

## Example: creating your first Attributes map

The first thing I'd suggest, is to create a new `scene`, save it and name **CharacterAttributes** which inherits directly from `GameplayAttributesMap`.

Add some `GameplayAttribute` to your new scene and rename them to `Health` and `Mana`.

Set Health params to `50`/`50` (**Current value**/**Maximum Value**)
Set Mana params to `5`/`50` (**Current value**/**Maximum Value**)

Now add an `AttributeRegenGameplayEffect` node to your scene, and set the **Attribute Name** to `Mana`. Change the **Increment Per Second** to 1

Add your new created `scene` **CharacterAttributes** to your character.

Connect `CharacterAttributes`'s signal `attribute_changed` to a function

```gdscript
func _on_attribute_changed(attribute) -> void:
  print(attribute.name + ":" + str(attribute.current_value))
```

Start your game and watch your mana regen!

## Creating your own effects

`GameplayEffects` (or effects from now) are the primary way to modify attributes.

An effect is simply a node which can be activated (and deactivated) under some
circumstances:

- Immediate activation (`EffectActivationEvent.ImmediateActivation`)
- Attribute changed activation (`EffectActivationEvent.AttributeChanged`)

There are two main effect categories: instants and timed-based.

An instant effect could be a jump, a damage, a permanent boost etc.

A timed effect could be a stamina regen, mana regen, stamina leech, bleeding etc.

There are three functions to take care in an effect:

- `apply_effect` is called when the effect is ready to be applied
- `should_activate` is called when an effect could be applied
- `should_deactivate` is called when an effect could be stopped and removed from it's parent

`apply_effect() -> void` takes no argument and must return nothing. Inside this function you can apply your damage, boost, you can move your character and so on

`should_activate(event_id: int) -> bool` takes an `int` argument (which is the `EffectActivationEvent` enum) to determine when the effect has tried to activate itself.

`should_deactivate` will remove the effect from it's parent if it returns `true`

At this point, I'd suggest you to create your own effects inheriting the existing ones:

- `AttributeConsumeGameplayEffect` applies a timed attribute consumption
- `AttributeRegenGameplayEffect` applies a timed attribute regeneration
- `DamageGameplayEffect` calculates the instant damage with min/max parameters

You can of course create you own starting from the base class `GameplayEffect` or `TimedGameplayEffect`

# Contribution

Every contribution is really welcome, so feel free to contribute!
