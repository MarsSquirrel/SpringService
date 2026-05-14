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

```lua
Spring.Instance
```

### Response: `number`
Essentially how "snappy" the spring feels.

The higher the `response`, the slower the `Spring` feels. The `response` is somewhat inversely related to the frequency:

> $f = \frac{2\pi}{response}$

The `response` doesn't necesarily mean the "duration", it's just how fast the `Spring` feels. Some simple examples:
* `response = 0.3` - Quick, "snappy", tighter UI (Great for buttons)
* `response = 0.6` - Slower, "smooth" (Great for larger changes in motion)

```lua
Spring.Response
```

### Damping: `number`
The `damping` or "dampingRatio" is basically how "bouncy" the `Spring` is.

The `damping` of the `Spring` is a coefficient in the `Spring` equation:

> $ζ = damping$

Basic value examples:
* `damping = 0` - Infinite bouncing
* `damping = 0.5` - Very bouncy (underdamped)
* `damping = 1` - No bounce (critically damped)
* `damping > 1` - Slower and smoother, no overshooting or "bounce"

Damping controls how the `Spring` settles.

```lua
Spring.Damping
```

### Target: `{[string]: any}`
The target properties of the `Spring` - Defined from the `properties` parameter.

This works the same as `TweenService` properties. Some examples:
* `{[Position] = Udim2.new(.5,0,.5,0)}`
* `{[AnchorPoint] = Vector2.new(.5,.5), [Size] = Udim2.new(.25,0,.3,0)}`

As shown above, multiple properties can be given in the `properties` array.

The above would show what the "inputted" properties would look like. The outputted would look like this:
* `[Position] = {.5,0}, {.5,0}`
* `[AnchorPoint] = {.5,.5}, [Size] = {.25,0}, {.3,0}`

```lua
Spring.Target
```

### Velocity: `number`
The current instantaneous velocity of the `Spring`. This value is used when adjusting the properties of the `Spring` during motion to maintain a smooth animation.

The `velocity` is derived directly from the position equation and takes into account the `SpringForce` (acceleration towards the target) and the `DampingRato` or `damping` (resistance against the force).

The equation can be written like so:

> $v(t) = \frac{d}{dt}x(t)$

The physics is essentially a combination of the `SpringForce` and the `DampingForce` to define the `acceleration`:

> $F_{spring} = -k(x)$

> $F_{damping} = -c(v)$

> $a = \frac{F_{spring} + F_{damping}}{m}$

Then the velocity is taken from the acceleration over time.

However, the direct equation from above ( $v(t)$ ) is the way that velocity is calculated in this system to maintain smooth and stable motion.

```lua
Spring.Velocity
```

### Time: `number`
The current time, in seconds, of the animation. This value is clamped to the `TimeLength` and can never exceed that value.

```lua
Spring.Time
```

### TimeLength: `number`
The total time, in seconds, of the animation.

Calculated by figuring out when the motion is no longer visible to the viewer using this formula:

> $x(t) \le e^{−ζωt}*X_{max}$

$x(t)$ must be a positive value and is represented by a tolerance symbol: $ϵ$

The time can then be solved for using algebra:

> $t = \frac{ln(X_{max}/ϵ)}{ζω}$

```lua
Spring.TimeLength
```

### Finished: `RBXScriptSignal`
Fired when the animation is finished (`Time` = `TimeLength`)

```lua
Spring.Finsished
```

### Stopped: `RBXScriptSignal`
Fired when the animation is stopped using the `Stop()` method

```lua
Spring.Stopped
```

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
