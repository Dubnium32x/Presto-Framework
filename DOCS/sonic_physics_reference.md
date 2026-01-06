# Sonic Physics Reference - SPG Based

## Fixed-Point Conversion (Classic Genesis)
Classic Sonic games use 8.8 fixed-point format where:
- `256 subpixels` = 1 pixel
- Values are given as pixels.subpixels
- Example: 0.046875 = 12/256 subpixels per frame

## Character Physics Constants (from SPG)

### All Characters (Sonic, Tails, Knuckles)
```c
// Ground Movement
topSpeed        = 6.0;        // pixels/frame
acceleration    = 0.046875;   // 12 subpixels/frame²
deceleration    = 0.5;        // 128 subpixels/frame²
friction        = 0.046875;   // 12 subpixels/frame²

// Air Movement  
airAcceleration = 0.09375;    // 24 subpixels/frame² (2x ground)
gravity         = 0.21875;    // 56 subpixels/frame²

// Jump Forces
jumpForce_Sonic  = -6.5;      // pixels/frame (upward)
jumpForce_Tails  = -6.5;      // pixels/frame (same as Sonic)
jumpForce_Knux   = -6.0;      // pixels/frame (weaker)

// Rolling Physics
rollFriction     = 0.0234375; // 6 subpixels/frame²
rollDeceleration = 0.125;     // 32 subpixels/frame²
```

### Super Speed Mode (Speed Shoes/Super Form)
```c
topSpeed        = 12.0;       // Double normal speed
acceleration    = 0.09375;    // Double normal acceleration  
friction        = 0.09375;    // Double normal friction
airAcceleration = 0.1875;     // Double normal air acceleration
rollFriction    = 0.046875;   // Double normal roll friction
```

## Key Physics Behaviors (from SPG)

### Ground Movement
- **Acceleration**: When holding direction matching movement
- **Deceleration**: When holding direction opposite to movement (10x faster than acceleration!)
- **Friction**: Applied when no input (same rate as acceleration)
- **Deceleration Quirk**: When speed crosses zero, set to 0.5 pixels/frame in opposite direction

### Air Movement
- **No friction** in air (unlike Sonic Mania)
- **Double acceleration** compared to ground (0.09375 vs 0.046875)
- **Same top speed** as ground (6 pixels/frame)
- **Gravity** constantly applied (0.21875 pixels/frame²)

### Rolling Physics
- **Cannot accelerate** while rolling
- **Can only decelerate** by holding opposite direction
- **Rolling friction** applied constantly (half of normal friction)
- **Can turn around** while rolling due to deceleration quirk

### Slope Physics
- **Ground Speed** preserved regardless of angle
- **Slope Force**: 0.125 * sin(angle) applied to ground speed
- **360° Movement**: X/Y velocity calculated from ground speed and angle
- **Slip Threshold**: If ground speed < 2.5 and angle > 35°, player slips

## Angle System (SPG Hex Angles)

### Conversion
```c
// SPG uses 0-255 angles (256 = full circle)
float hexToRadians(int hexAngle) {
    return hexAngle * (M_PI / 128.0f);
}

int radiansToHex(float radians) {
    return (int)(radians * (128.0f / M_PI)) & 0xFF;
}
```

### Angle Ranges
- **0° (255)**: Flat ground, facing right
- **64 (90°)**: Steep upward slope  
- **128 (180°)**: Ceiling
- **192 (270°)**: Steep downward slope

## Collision Modes (SPG)
1. **Floor Mode (0)**: Normal ground collision
2. **Left Wall (1)**: Walking on left walls
3. **Ceiling (2)**: Walking on ceilings  
4. **Right Wall (3)**: Walking on right walls

## Implementation Notes

### Frame Rate Consideration
- All values are **per frame** assuming 60 FPS
- For different frame rates: `value * (targetFPS / 60.0f)`
- Use `deltaTime` scaling in your update functions

### Critical SPG Behaviors
1. **Deceleration is 10x faster** than acceleration (0.5 vs 0.046875)
2. **Air acceleration is 2x ground** acceleration 
3. **No air friction** (unlike modern games)
4. **Ground speed preserved** on slopes via angle conversion
5. **Rolling cannot accelerate**, only decelerate or maintain speed

### Physics State Machine
```c
if (player->onGround) {
    if (player->rolling) {
        UpdateRollingMovement();
    } else {
        UpdateGroundMovement();
    }
    ApplySlopeForce();
} else {
    UpdateAirMovement();  
    ApplyGravity();
}
ConvertGroundSpeedToVelocity();
UpdatePosition();
```

This gives you the **authentic classic Sonic physics** feel as documented in the comprehensive SPG guide!