HaxeFlixel 5.x | Haxe 4.3 | CITCA 2025 | Universidad de Colima

FlxPCG — Procedural Controlled Generation for HaxeFlixel
Research prototype accompanying the paper "Procedural Controlled Generation of Levels and Entities in 2D Using the HaxeFlixel Framework", submitted to CITCA 2025. Developed at the Facultad de Ingeniería Mecánica y Eléctrica, Universidad de Colima.
The system implements a four-phase pipeline that separates topological generation from entity distribution:

Room templates — Pre-designed in Ogmo Editor 3, exported as JSON with semantic spawn markers.
BSP assembly — Binary space partitioning places templates and generates L-shaped corridors via post-order traversal.
Flood Fill validation — BFS confirms full connectivity before the map is delivered to the game state.
Quota system — A parameterized entity manager instantiates enemies and rewards within verified spaces using a minimum-distance heuristic.

Empirical results (300 maps, seeds 1–100 per difficulty configuration)
MetricValueMean generation time0.657 ms (σ = 0.588 ms)Maximum generation time4.0 msMaps with full connectivity300 / 300 (100%)Re-seedings required0Room count per map10–16 (mean 12.84)
Repository structure
source/pcg/          # BSPTree, FloodFill, QuotaManager, MapGenerator
source/entities/     # Enemy, Reward (FlxSprite subclasses)
assets/data/rooms/   # Five Ogmo Editor 3 JSON room templates
analizar_benchmark.py  # Statistical analysis script for the paper tables
How to run
bashhaxelib install flixel
haxelib install flixel-addons
lime test windows   # or html5 / linux / mac
Press R to regenerate, 1/2/3 to change difficulty, WASD to pan.
Citation
If you use this code in your research, please cite:
Sánchez-Ung, E.Y., Sánchez-Lozano, L.A. and Mata-López, W.A. (2025). 'Procedural controlled generation of levels and entities in 2D using the HaxeFlixel framework'. CITCA 2025.
