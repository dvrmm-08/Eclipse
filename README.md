# ECLIPSE

A 2D atmospheric pixel-art puzzle-horror game built in **Godot 4**.

---

## 🎮 Controls

| Action | Primary Key | Secondary Key |
| :--- | :--- | :--- |
| **Move Up** | `W` | `Up Arrow` |
| **Move Down** | `S` | `Down Arrow` |
| **Move Left** | `A` | `Left Arrow` |
| **Move Right** | `D` | `Right Arrow` |
| **The Eclipse Switch** | `P` | *Transfers control between Wanderer & Shadow* |
| **Interact / Inspect** | `E` | *Inspect tablets, notes, pull levers, enter gates* |
| **Restart Level** | `R` | *Quick level restart if needed* |

---

## 🌒 Core Mechanics

### 1. The Eclipse Switch (`P`)
- **Normal World**: You control the ivory-robed **Wanderer**. The physical body can walk on grass, dirt, and stone flagstones, but cannot cross the bottomless dark void chasm.
- **The Eclipse**: Pressing `P` summons the **Shadow** from the Wanderer's location. The physical body remains stationary at its exact coordinates, while control transfers to the Shadow form.
- **Shared Coordinates**: The two forms occupy corresponding coordinates across dimensions. Neither form resets on switching, and neither form can accidentally bump into or push the other.
- **Cyan Runic Bridges**: Dormant stone paths over the void ignite with radiant cyan glyphs in Eclipse mode, enabling the Shadow form to cross the chasm.

### 2. The Shield of Flesh (Laser Physics)
- Sinister gargoyle statues cast line-of-sight red laser beams.
- The laser raycast queries **Solid Walls (Layer 1)** and **The Wanderer's Physical Body (Layer 3)**.
- If the Shadow touches an unblocked laser beam, it is repelled back to the physical body.
- When the stationary physical body is placed in the beam's line-of-sight, the raycast terminates directly on the body, shielding the cyan bridge behind it and creating a safe corridor for the Shadow.

---

## 🗺️ Levels & Progression

1. **Level 1 — Awakening**
   - Introduces movement, tablets, and the Eclipse switch (`P`).
   - A void chasm separates you from a heavy lever.
   - Switch to Shadow, cross the radiant cyan bridge, pull the lever, switch back, and exit through the open gate.
   - *Optional Note*: Hidden in the lower path: *"Use it carefully. It remembers."*

2. **Level 2 — The Shield of Flesh**
   - Introduces the red laser beam emitted by an ancient stone idol.
   - Position the Wanderer to block the beam.
   - Switch to Shadow, safely cross behind your physical body, and pull the mechanism.
   - *The First Betrayal*: Upon switching back to your physical body, the Shadow refuses to return and takes a deliberate step toward you on its own.

3. **Level 3 — Betrayal & Pursuit**
   - A multi-stage trial with dual laser statues requiring dynamic repositioning of the physical body.
   - Guide the Shadow across the bridges to activate the final seal.
   - *The Pursuit*: Once the final mechanism is pulled, the Shadow breaks free and begins relentlessly pursuing the Wanderer. Sprint to the open gate to escape!

4. **Epilogue — The Reflection**
   - The opening ruins return, but the connection is permanent.
   - When you move, your shadow moves in reverse. Press `R` to replay.

---

## 🚀 How to Run the Game

### In the Godot Editor
1. Open **Godot 4.7+** and select `res://project.godot`.
2. Press **F5** (or the **Play** button in the top-right corner).
3. The game will launch directly into **Level 1**.

### Via Terminal
```powershell
& "D:\Achievements\Godot_v4.7.2-stable_win64_console.exe" --path "D:\Achievements\Projects\Eclipse"
```
