package pcg;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.math.FlxRandom;
import flixel.tile.FlxTilemap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import pcg.QuotaManager.QuotaConfig;

/**
 * Resultado de una ejecución del pipeline de generación.
 */
typedef GenerationResult = {
	/** FlxTilemap listo para agregar al estado de juego. */
	var tilemap:FlxTilemap;

	/** Grupo de enemigos instanciados (FlxSprite). */
	var enemies:FlxGroup;

	/** Grupo de recompensas instanciadas (FlxSprite). */
	var rewards:FlxGroup;

	/** Número de semillas utilizadas (1 = sin re-semillado). */
	var seedsUsed:Int;

	/** Tiempo total de generación en milisegundos. */
	var generationMs:Float;

	/** Número de habitaciones generadas. */
	var roomCount:Int;
}

/**
 * Orquestador principal del pipeline de Generación Procedural Controlada (FlxPCG).
 *
 * Implementa las cuatro fases descritas en §2 del artículo:
 *
 *   Fase 1 (off-line) — Carga de plantillas JSON de Ogmo Editor 3.
 *   Fase 2 (runtime)  — Partición BSP + estampado de plantillas + conexión de pasillos.
 *   Validación         — Flood Fill; re-semillado automático si hay regiones inalcanzables.
 *   Población          — Sistema de cuotas sobre FlxGroup (QuotaManager).
 *
 * Métricas objetivo (Tabla 1 del artículo):
 *   - Tiempo de generación < 16 ms en grilla 80×80, ≤ 20 habitaciones.
 *   - 60 FPS sostenidos durante el ensamblaje.
 *   - 100 % de conectividad mediante re-semillado (promedio 1.3 iteraciones).
 *
 * Referencias: Baron (2017), Vieira et al. (2025), Campos Escalera (2019).
 */
class MapGenerator {
	// ─── Constantes de configuración ─────────────────────────────────────────

	/** Ancho del grid en tiles. */
	public static inline final GRID_W:Int = 80;

	/** Alto del grid en tiles. */
	public static inline final GRID_H:Int = 80;

	/** Tamaño de cada tile en píxeles. */
	public static inline final TILE_SIZE:Int = 16;

	/** Profundidad máxima del árbol BSP (controla número de habitaciones). */
	static inline final BSP_DEPTH:Int = 4;

	/** Número máximo de re-semillados antes de entregar el mapa en el estado actual. */
	static inline final MAX_RESEED:Int = 15;

	// Valores de tile
	static inline final VOID:Int = 0;
	static inline final FLOOR:Int = 1;
	static inline final WALL:Int = 2;

	// ─── Estado ──────────────────────────────────────────────────────────────

	var templates:Array<RoomTemplate>;
	var rng:FlxRandom;
	var quotaConfig:QuotaConfig;

	// Clave de la gráfica de tiles generada proceduralmente
	static var tileGraphicKey:String = null;

	/**
	 * @param quotaConfig  Configuración de cuotas (dificultad) para el sistema de entidades.
	 */
	public function new(quotaConfig:QuotaConfig) {
		this.quotaConfig = quotaConfig;
		rng = new FlxRandom();

		// FASE 1 — Carga de plantillas JSON (off-line, con caché)
		templates = TemplateLoader.loadAll();
		trace('[MapGenerator] Banco de plantillas: ${templates.length} habitaciones disponibles.');
	}

	/**
	 * Ejecuta el pipeline completo y devuelve un GenerationResult listo para
	 * ser añadido al FlxState activo.
	 *
	 * @param seed  Semilla inicial (-1 = aleatoria). El re-semillado usa semillas
	 *              derivadas automáticamente si el mapa resultante no es conexo.
	 */
	public function generate(seed:Int = -1):GenerationResult {
		var t0 = haxe.Timer.stamp();

		if (seed >= 0)
			rng.initialSeed = seed;

		var grid:Array<Array<Int>> = null;
		var leaves:Array<BSPNode> = null;
		var seedsUsed = 0;

		// ─── FASE 2 + VALIDACIÓN: loop de re-semillado ───────────────────────
		do {
			seedsUsed++;

			// Nueva semilla en iteraciones subsecuentes
			if (seedsUsed > 1)
				rng.initialSeed = Std.int(Math.random() * 999999) + seedsUsed;

			// Inicializar grid con vacío
			grid = [for (_ in 0...GRID_H) [for (_ in 0...GRID_W) VOID]];

			// Partición BSP del espacio
			var tree = new BSPTree(GRID_W, GRID_H, rng);
			tree.split(BSP_DEPTH);
			leaves = tree.getLeaves();

			// Estampar plantillas en nodos hoja
			for (leaf in leaves)
				stampRoom(leaf, grid);

			// Generar pasillos entre nodos hermanos (recorrido post-orden)
			connectRooms(tree.root, grid);

			// VALIDACIÓN — Flood Fill
		} while (!isConnected(grid) && seedsUsed < MAX_RESEED);

		// ─── FASE 4: Construcción del FlxTilemap ─────────────────────────────
		var flatGrid:Array<Int> = [];
		for (row in grid)
			for (cell in row)
				flatGrid.push(cell);

		var tilemap = new FlxTilemap();
		tilemap.loadMapFromArray(flatGrid, GRID_W, GRID_H, getTileGraphic(), TILE_SIZE, TILE_SIZE, null, 0, 0, WALL);

		// ─── FASE 4: Población de entidades (sistema de cuotas) ──────────────
		var enemies = new FlxGroup();
		var rewards = new FlxGroup();
		var quota = new QuotaManager(quotaConfig);

		for (leaf in leaves)
			quota.populate(leaf, grid, enemies, rewards, TILE_SIZE);

		var elapsed = (haxe.Timer.stamp() - t0) * 1000;

		trace('[MapGenerator] Generación completada: ${elapsed}ms, $seedsUsed semilla(s), ${leaves.length} habitaciones.');

		return {
			tilemap: tilemap,
			enemies: enemies,
			rewards: rewards,
			seedsUsed: seedsUsed,
			generationMs: elapsed,
			roomCount: leaves.length
		};
	}

	// ─── Métodos privados ─────────────────────────────────────────────────────

	/**
	 * Selecciona una plantilla del banco que quepa en la región del nodo,
	 * la centra dentro de la región y la escribe en el grid global.
	 */
	function stampRoom(node:BSPNode, grid:Array<Array<Int>>):Void {
		// Filtrar plantillas que caben con margen de 2 tiles en cada eje
		var candidates = templates.filter(t -> t.widthTiles <= node.rect.w - 2 && t.heightTiles <= node.rect.h - 2);

		if (candidates.length == 0) {
			// Fallback: habitación mínima generada proceduralmente
			stampSimpleRoom(node, grid);
			return;
		}

		var tpl = candidates[rng.int(0, candidates.length - 1)];
		node.template = tpl;

		// Centrar la plantilla dentro de la región del nodo
		var ox = node.rect.x + Std.int((node.rect.w - tpl.widthTiles) / 2);
		var oy = node.rect.y + Std.int((node.rect.h - tpl.heightTiles) / 2);
		node.room = {x: ox, y: oy, w: tpl.widthTiles, h: tpl.heightTiles};

		// Escribir tiles de la plantilla en el grid global
		for (ty in 0...tpl.heightTiles) {
			for (tx in 0...tpl.widthTiles) {
				var tile = tpl.getTile(tx, ty);
				if (tile == VOID)
					continue; // no sobrescribir con vacío
				var gx = ox + tx;
				var gy = oy + ty;
				if (gx >= 0 && gy >= 0 && gx < GRID_W && gy < GRID_H)
					grid[gy][gx] = tile;
			}
		}
	}

	/**
	 * Genera una habitación rectangular mínima cuando ninguna plantilla cabe
	 * en la región del nodo. Sin marcadores de entidades.
	 */
	function stampSimpleRoom(node:BSPNode, grid:Array<Array<Int>>):Void {
		var rw = Std.int(Math.min(node.rect.w - 2, 8));
		var rh = Std.int(Math.min(node.rect.h - 2, 8));
		if (rw < 3 || rh < 3)
			return;

		var ox = node.rect.x + 1;
		var oy = node.rect.y + 1;
		node.room = {x: ox, y: oy, w: rw, h: rh};

		for (ty in 0...rh) {
			for (tx in 0...rw) {
				var tile = (tx == 0 || tx == rw - 1 || ty == 0 || ty == rh - 1) ? WALL : FLOOR;
				grid[oy + ty][ox + tx] = tile;
			}
		}
	}

	/**
	 * Genera pasillos en forma de L entre los centros de las habitaciones
	 * de dos nodos hermanos. Recorre el árbol BSP en post-orden.
	 */
	function connectRooms(node:BSPNode, grid:Array<Array<Int>>):Void {
		if (node == null || node.isLeaf)
			return;
		connectRooms(node.left, grid);
		connectRooms(node.right, grid);

		var ca = getRoomCenter(node.left);
		var cb = getRoomCenter(node.right);
		if (ca == null || cb == null)
			return;

		// Pasillo horizontal (de ca.x hasta cb.x en ca.y)
		var x1 = ca.x;
		var x2 = cb.x;
		var minX = Std.int(Math.min(x1, x2));
		var maxX = Std.int(Math.max(x1, x2));
		for (x in minX...maxX + 1) {
			if (x >= 1 && x < GRID_W - 1 && ca.y >= 1 && ca.y < GRID_H - 1) {
				if (grid[ca.y][x] != FLOOR)
					grid[ca.y][x] = FLOOR;
			}
		}

		// Pasillo vertical (de ca.y hasta cb.y en cb.x)
		var y1 = ca.y;
		var y2 = cb.y;
		var minY = Std.int(Math.min(y1, y2));
		var maxY = Std.int(Math.max(y1, y2));
		for (y in minY...maxY + 1) {
			if (cb.x >= 1 && cb.x < GRID_W - 1 && y >= 1 && y < GRID_H - 1) {
				if (grid[y][cb.x] != FLOOR)
					grid[y][cb.x] = FLOOR;
			}
		}
	}

	/** Devuelve el centro en tiles de la habitación de un nodo (o de su primer descendiente hoja). */
	function getRoomCenter(node:BSPNode):Null<{x:Int, y:Int}> {
		if (node == null)
			return null;
		if (node.isLeaf && node.room != null)
			return {x: node.room.x + Std.int(node.room.w / 2), y: node.room.y + Std.int(node.room.h / 2)};
		var c = getRoomCenter(node.left);
		if (c != null)
			return c;
		return getRoomCenter(node.right);
	}

	/** Verifica la conectividad del grid mediante Flood Fill. */
	function isConnected(grid:Array<Array<Int>>):Bool {
		var start = FloodFill.findStart(grid);
		if (start == null)
			return false;
		return FloodFill.validate(grid, start.x, start.y);
	}

	/**
	 * Construye (o recupera de caché) la gráfica de tiles del tileset procedural.
	 *
	 * Tileset de 3 tiles × 16 px = 48×16 px:
	 *   Tile 0 (vacío/void):  negro   #000000
	 *   Tile 1 (suelo/floor): gris claro #C8C8C8
	 *   Tile 2 (muro/wall):   gris oscuro #444444
	 *
	 * El FlxTilemap usa drawIndex=0, collideIndex=2:
	 *   → tiles 0 y 1 se dibujan sin colisión
	 *   → tiles ≥ 2 se dibujan con colisión (muros)
	 */
	static function getTileGraphic():FlxGraphic {
		if (tileGraphicKey != null) {
			var cached = FlxG.bitmap.get(tileGraphicKey);
			if (cached != null)
				return cached;
		}

		var bmd = new BitmapData(TILE_SIZE * 3, TILE_SIZE, false, 0xFF000000);

		// Tile 1 — suelo (gris claro)
		bmd.fillRect(new Rectangle(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), 0xFFC8C8C8);

		// Tile 2 — muro (gris oscuro con borde más claro para dar volumen)
		bmd.fillRect(new Rectangle(TILE_SIZE * 2, 0, TILE_SIZE, TILE_SIZE), 0xFF444444);
		// Borde superior e izquierdo más claro (efecto bisel)
		bmd.fillRect(new Rectangle(TILE_SIZE * 2, 0, TILE_SIZE, 1), 0xFF666666);
		bmd.fillRect(new Rectangle(TILE_SIZE * 2, 0, 1, TILE_SIZE), 0xFF666666);

		tileGraphicKey = "FlxPCG_TileSet";
		var graphic = FlxGraphic.fromBitmapData(bmd, false, tileGraphicKey);
		return graphic;
	}
}
