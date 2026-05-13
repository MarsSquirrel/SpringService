# SpringService
A Roblox UI spring module designed using the same parameters as TweenService.

# API
## Constructors
### new()
Creates a new `Spring` object with 4 parameters:
* `instance`: `Instance`
* `response`: `number`
* `damping`: `number`
* `properties`: `{[string]: any}`
```lua
Spring.new(instance, response, damping, properties)
```

## Properties
### Instance: `Instance`
The `Spring` object's `Instance` to animate

### Response: `number`

### Damping: `number`

### Target: `{[string]: any}`
The target properties of the `Spring` - Defined from the `properties` parameter.

### Velocity: `number`
The current instantaneous velocity of the `Spring`

### Time: `number`
The current time, in seconds, of the animation

### TimeLength: `number`
The total time, in seconds, of the animation

### Finished: `RBXScriptSignal`
Fired when the animation is finished (`Time` = `TimeLength`)

### Stopped: `RBXScriptSignal`
Fired when the animation is stopped using the `Stop()` method

## Methods
### Play()
Animates the `Spring` object
```lua
Spring:Play()
```

### SetTarget()
Updates the `Target` property of the `Spring` using a new `properties` parameter:
* `properties`: `{[string]: any}`
```lua
Spring:SetTarget(properties)
```

### PlayAndWait()
Plays the `Spring` animation and halts further script execution until the `Spring` has finished. (Works the same as using `Spring:Play()` and then waiting until `Spring.Finished` is fired, but is done in a single method)
```lua
Spring:PlayAndWait()
```

### Stop()
Stops the `Spring` animation wherever it's at. The `Stopped` signal is also fired. To start playing again, simply call the `Play()` method again.
```lua
Spring:Stop()
```
