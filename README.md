# FlxPCG — Procedural Controlled Generation for HaxeFlixel

![HaxeFlixel](https://img.shields.io/badge/HaxeFlixel-5.x-orange?style=flat-square&logo=haxe)
![Haxe](https://img.shields.io/badge/Haxe-4.3-blue?style=flat-square&logo=haxe)
![License](https://img.shields.io/badge/License-Research-lightgrey?style=flat-square)
![CITCA](https://img.shields.io/badge/CITCA-2025-green?style=flat-square)
![Universidad de Colima](https://img.shields.io/badge/Universidad_de_Colima-FIME-red?style=flat-square)

> Research prototype accompanying the paper *"Procedural Controlled Generation of Levels and Entities in 2D Using the HaxeFlixel Framework"*, submitted to **CITCA 2025**.
> Developed at the Facultad de Ingeniería Mecánica y Eléctrica, Universidad de Colima.

---

## Overview

FlxPCG implements a **four-phase hybrid pipeline** that formally separates topological generation from entity distribution in 2D procedural level design:

```
┌─────────────────┐    ┌──────────────┐    ┌────────────┐    ┌──────────────┐
│  Room Templates │───▶│  BSP Assembly│───▶│ Flood Fill │───▶│ Quota System │
│  (Ogmo 3 JSON)  │    │  + Corridors │    │ Validation │    │   Entities   │
└─────────────────┘    └──────────────┘    └────────────┘    └──────────────┘
     Off-line                    Runtime                           Runtime
```

| Phase | Description |
|---|---|
| **1 — Room Templates** | Pre-designed in Ogmo Editor 3, exported as JSON with semantic spawn markers (`Spawn_Enemy_Tier_1`, `Spawn_Reward`, etc.) |
| **2 — BSP Assembly** | Binary space partitioning stamps templates into leaf nodes and generates L-shaped corridors via post-order traversal |
| **3 — Flood Fill** | BFS confirms full connectivity before delivering the map to the game state; triggers re-seeding if isolated regions are detected |
| **4 — Quota System** | Parameterized entity manager instantiates `FlxSprite` objects within verified spaces using a minimum-distance heuristic |

---

## Empirical Results

Benchmark: **100 maps per difficulty configuration** (seeds 1–100), **300 maps total**.

### Generation Performance

| Metric | Value |
|---|---|
| Mean generation time | **0.657 ms** (σ = 0.588 ms) |
| Maximum generation time | 4.0 ms |
| 95th percentile | 1.0 ms |
| Sustained framerate | 60 FPS |
| Maps with full connectivity | 300 / 300 **(100%)** |
| Re-seedings required | **0** |
| Mean rooms per map | 12.84 (range: 10–16) |

> FlxPCG runs ~15× faster than the BSP reference of ~10 ms reported by Baron (2017), on a larger grid (80×80 vs 60×60), by delegating room geometry to pre-designed JSON templates.

### Entity Distribution by Difficulty

| Configuration | Rooms (mean) | Enemies/room (mean) | Enemies/room (ratio max.) | Rewards/room (mean) |
|---|---|---|---|---|
| Low | 12.84 | 1.17 | 1.87 | 0.20 |
| Standard | 12.84 | 2.33 | 3.73 | 0.20 |
| High | 12.84 | 2.73 | 4.33 | 0.20 |

---

## Requirements

| Tool | Version |
|---|---|
| [Haxe](https://haxe.org/download/) | 4.3.x |
| [HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) | 5.x |
| [Ogmo Editor 3](https://ogmo-editor-3.github.io/) | 3.4+ *(to edit room templates)* |

---

## Installation

```bash
# 1. Install HaxeFlixel
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-addons
haxelib run lime setup flixel

# 2. Clone the repository
git clone https://github.com/YOUR_USER/FlxPCG.git
cd FlxPCG

# 3. Build and run
lime test html5      # browser
lime test windows    # desktop (Windows)
lime test linux      # desktop (Linux)
```

---

## Controls

| Key | Action |
|---|---|
| `R` | Regenerate map (new random seed) |
| `1` | Low difficulty (≤2 enemies/room, ≤2 rewards/room) |
| `2` | Standard difficulty (≤4 enemies/room, ≤2 rewards/room) |
| `3` | High difficulty (≤6 enemies/room, ≤1 reward/room) |
| `WASD` / `↑↓←→` | Pan camera |
| `+` / `-` | Zoom |

The HUD displays generation time (ms), seeds used, room count, and entity totals in real time.

---

## Project Structure

```
FlxPCG/
├── Project.xml                   # lime/HaxeFlixel config
├── source/
│   ├── Main.hx                   # Entry point
│   ├── PlayState.hx              # Main game state + HUD
│   ├── BenchmarkState.hx         # Automated benchmark (writes CSV)
│   ├── pcg/
│   │   ├── BSPNode.hx            # BSP tree node (Rect, room, template)
│   │   ├── BSPTree.hx            # Recursive binary space partitioning
│   │   ├── RoomTemplate.hx       # Template data (tiles + spawn markers)
│   │   ├── TemplateLoader.hx     # JSON loader with cache
│   │   ├── FloodFill.hx          # BFS connectivity validator
│   │   ├── QuotaManager.hx       # Entity quota system
│   │   └── MapGenerator.hx       # Pipeline orchestrator
│   └── entities/
│       ├── Enemy.hx              # FlxSprite — Tier 1/2 enemies
│       └── Reward.hx             # FlxSprite — rewards
├── assets/data/rooms/
│   ├── room_combat_01.json       # 10×10 — 4 Tier-1 spawns, pillar pairs
│   ├── room_combat_02.json       # 12×8  — Tier-2 elite + 4 Tier-1
│   ├── room_reward_01.json       # 8×8   — 2 reward spawns, no enemies
│   ├── room_neutral_01.json      # 10×10 — open room, no entities
│   └── room_boss_01.json         # 12×12 — 4-pillar layout, 2 Tier-2
└── analizar_benchmark.py         # Statistical analysis → paper tables + charts
```

---

## Running the Benchmark

```bash
# 1. In Main.hx, switch PlayState → BenchmarkState, then build
lime test windows

# 2. Collect the CSV (generated next to the executable)
#    Export/windows/bin/benchmark_results.csv

# 3. Analyze and generate paper tables + charts
python analizar_benchmark.py Export/windows/bin/benchmark_results.csv
```

Output: `resumen_articulo.txt`, `boxplot_tiempos.png`, `boxplot_entidades.png`, `histograma_resemillados.png`.

---

## Adding New Room Templates (Ogmo Editor 3)

1. Open Ogmo Editor 3 — cell size **16×16 px**
2. Create two layers:
   - **Tiles** — tile layer with 3 tiles: `0` void · `1` floor · `2` wall
   - **Entities** — entity layer with types: `Spawn_Enemy_Tier_1`, `Spawn_Enemy_Tier_2`, `Spawn_Reward`
3. Export as `.json` → `assets/data/rooms/`
4. Register the path in `TemplateLoader.ROOM_PATHS`

File naming convention: `room_{type}_{nn}.json` — types: `combat`, `reward`, `boss`, `neutral`.

---

## Citation

If you use this code in your research, please cite:

```
Sánchez-Ung, E.Y., Sánchez-Lozano, L.A. and Mata-López, W.A. (2025).
'Procedural controlled generation of levels and entities in 2D using the
HaxeFlixel framework'. CITCA 2025.
```

---

## Authors

**Elian Y. Sánchez-Ung · Luis A. Sánchez-Lozano · Walter A. Mata-López**
Facultad de Ingeniería Mecánica y Eléctrica — Ingeniería en Computación Inteligente
Universidad de Colima · Coquimatlán, Colima, México
`{esanchez58, lsanchez37, wmata}@ucol.mx`
