# ECLIPSE — Audio Asset Inventory & Integration Manifest

Comprehensive documentation of all 136 audio assets present in the project (`res://assets/audio/` and `res://assets/sfx/`), detailing format specifications, acoustic metadata, intended roles, event assignments, and unused asset categorizations.

---

## 1. Primary Game Event to Audio Mapping Table

| Event / Trigger | Audio File Path | Format | Duration | Audio Bus | Description & Justification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Main Menu BGM** | `res://assets/audio/the_field_of_dreams.mp3` | MP3 | 84.64s | Music | *The Field of Dreams* (Paulius Jurgelevicius, CC0). Ethereal, contemplative, celestial harmony framing the title screen and ruins. |
| **Normal Mode BGM** | `res://assets/audio/NES_TheOldTowerInn.mp3` | MP3 | 100.96s | Music | *The Old Tower Inn* (173 BPM chiptune). Warm, cheerful, curious retro NES adventure theme active while exploring as the mortal Wanderer. |
| **Eclipse Mode BGM** | `res://assets/audio/into_the_ruined_temple.mp3` | MP3 | 146.75s | Music | *Into the Ruined Temple*. Ominous, reverberant, dark atmospheric score active during Shadow realm traversal. Crossfades smoothly over 0.8s. |
| **UI Button Hover** | `res://assets/sfx/impactSoft_medium_000.ogg` | Ogg | 0.12s | SFX | Ultra-subtle, low-frequency tactile tick providing quiet non-distracting button focus feedback. |
| **UI Button Click / Select** | `res://assets/sfx/impactGeneric_light_002.ogg` | Ogg | 0.14s | SFX | Crisp, distinct tactile button confirmation click for Play, Credits, and Mute buttons. |
| **Credits Navigation / Back**| `res://assets/sfx/impactGeneric_light_001.ogg` | Ogg | 0.12s | SFX | Light, clean dismissal click when closing the retro credits overlay. |
| **Summon Shadow ([P] Key)** | `res://assets/sfx/magical_4.ogg` | Ogg | 2.41s | SFX | Ascending mystic portal chime triggered upon successfully stepping into the Eclipse realm. |
| **Return to Wanderer ([P] Key)** | `res://assets/sfx/impactBell_heavy_002.ogg` | Ogg | 0.70s | SFX | Resonant, calming bell chime grounding the player back into mortal physical form. |
| **Ancient Inscription / Tablet** | `res://assets/sfx/impactMining_000.ogg` | Ogg | 0.94s | SFX | Resonant deep stone strike with acoustic ring, triggered when reading ancient tablet riddles. |
| **Parchment Note / Lore** | `res://assets/sfx/impactSoft_medium_001.ogg` | Ogg | 0.18s | SFX | Delicate paper/cloth tactile rustle when reading traveller notes. |
| **Mechanism / Lever Pull** | `res://assets/sfx/clank1.wav` | WAV | 0.67s | SFX | Heavy mechanical iron/stone lock clank, played strictly when the Shadow throws the lever. |
| **Exit Gate Unlocked / Open** | `res://assets/sfx/stone_door.ogg` | Ogg | 1.63s | SFX | Deep grinding ancient stone doorway sliding open, unblocking the exit portal. |
| **Shadow Autonomous Movement**| `res://assets/sfx/impactBell_heavy_000.ogg` | Ogg | 1.48s | SFX | Heavy, ominous tolling bell strike with deep reverberation decay during the Level 2 ending scare. |
| **Timed Laser Active Beam** | *(Synchronized SFX Player)* | N/A | Loop | SFX | Dedicated `AudioStreamPlayer2D` in `scenes/timed_laser.tscn` configured on SFX bus at -18 dB, strictly synchronized with `State.ACTIVE` and silenced during INACTIVE/WARNING. (See missing assets section). |

---

## 2. Complete Asset Inventory by Category

### A. Music Tracks (`res://assets/audio/`)
- `res://assets/audio/NES_TheOldTowerInn.mp3` (100.96s, MP3) — **Assigned**: Normal Mode exploration BGM.
- `res://assets/audio/into_the_ruined_temple.mp3` (146.75s, MP3) — **Assigned**: Eclipse Mode Shadow BGM.
- `res://assets/audio/the_field_of_dreams.mp3` (84.64s, MP3) — **Assigned**: Main Menu Title Screen BGM.

### B. Discrete Puzzle & Magic Interaction Audio (`res://assets/sfx/`)
- `res://assets/sfx/clank1.wav` (0.67s, WAV) — **Assigned**: Lever/mechanism activation.
- `res://assets/sfx/magical_4.ogg` (2.41s, OGG) — **Assigned**: Shadow summoning portal effect.
- `res://assets/sfx/stone_door.ogg` (1.63s, OGG) — **Assigned**: Ancient exit gate opening.

### C. UI & Tactile Audio (`res://assets/sfx/`)
- `res://assets/sfx/impactSoft_medium_000.ogg` (0.12s, OGG) — **Assigned**: UI Button hover.
- `res://assets/sfx/impactGeneric_light_002.ogg` (0.14s, OGG) — **Assigned**: UI Button select/confirm.
- `res://assets/sfx/impactGeneric_light_001.ogg` (0.12s, OGG) — **Assigned**: Credits back button click.
- `res://assets/sfx/impactSoft_medium_001.ogg` (0.18s, OGG) — **Assigned**: Parchment note reading.
- `res://assets/sfx/impactMining_000.ogg` (0.94s, OGG) — **Assigned**: Ancient tablet riddle reading.
- `res://assets/sfx/impactBell_heavy_002.ogg` (0.70s, OGG) — **Assigned**: Return to Wanderer form.
- `res://assets/sfx/impactBell_heavy_000.ogg` (1.48s, OGG) — **Assigned**: Level 2 ending autonomous shadow scare.

---

## 3. Unused Asset Catalog & Rationale

The remaining 123 Kenney audio files are physical impact and footsteps variations. They are intentionally left unassigned to discrete puzzle events to prevent inappropriate sonic substitution (e.g., using a punch or wood scrape for an electric laser or magical puzzle):

1. **Footstep Packs (25 files)**:
   - `footstep_carpet_000` to `004` (5 files)
   - `footstep_concrete_000` to `004` (5 files)
   - `footstep_grass_000` to `004` (5 files)
   - `footstep_snow_000` to `004` (5 files)
   - `footstep_wood_000` to `004` (5 files)
   *Rationale*: Discrete footfall sounds designed for procedural player movement loops, not puzzle triggers.

2. **Physical Impact Packs (98 files)**:
   - `impactBell_heavy_001, 003, 004` (3 files) — Alternate bell tones.
   - `impactGeneric_light_000, 003, 004` (3 files) — Subtle alternative clicks.
   - `impactGlass_heavy/light/medium` (15 files) — Glass breaking/impacts.
   - `impactMetal_heavy/light/medium` (15 files) — Weapon/metal clatter.
   - `impactMining_001` to `004` (4 files) — Alternate pickaxe mining strikes.
   - `impactPlank_medium` (5 files) — Wooden plank thuds.
   - `impactPlate_heavy/light/medium` (15 files) — Metal dish/plate impacts.
   - `impactPunch_heavy/medium` (10 files) — Melee punch impacts.
   - `impactSoft_heavy/medium` (8 files) — Soft cloth/cushion impacts.
   - `impactTin_medium` (5 files) — Metallic tin clicks.
   - `impactWood_heavy/light/medium` (15 files) — Wooden furniture/block impacts.
   *Rationale*: These physical impact sounds are reserved for physical object collisions or destruction mechanics and are not suitable for ethereal dimension shifts or electrical laser hums.

---

## 4. Missing Audio Assets

- **Timed Laser Electrical Hum / Energy Beam Sound**:
  *Status*: None of the files in `res://assets/sfx/` or `res://assets/audio/` contain a continuous electrical hum, buzzing transformer, or energy-beam drone.
  *Action Taken*: Rather than substituting an obviously incorrect sound (such as a footstep or glass shatter), `scenes/timed_laser.tscn` and `scripts/timed_laser.gd` implement a dedicated `AudioStreamPlayer2D` (`LaserAudio`) routed to the `SFX` bus at `-18 dB`. The player strictly synchronizes with `State.ACTIVE` (starting when active, stopping on warning/inactive) and is ready to receive a dedicated looping electrical hum asset (`sfx_laser_hum.ogg` or `.wav`).
