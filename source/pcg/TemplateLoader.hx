package pcg;

import haxe.Json;
import openfl.Assets;

/**
 * Carga y cachea las plantillas de habitaciones en formato Ogmo Editor 3.
 *
 * Cada archivo JSON exportado por Ogmo 3 contiene al menos dos capas:
 *   - "Tiles"    → capa de tiles con campo `data` (Array<Int>) en orden row-major,
 *                  dimensiones gridCellsX × gridCellsY, con -1 = vacío en Ogmo,
 *                  que aquí se reinterpreta como 0 = vacío.
 *   - "Entities" → capa con array `entities`, cada entidad tiene:
 *                  `name`, `x`, `y` (en píxeles desde el origen de la plantilla).
 *
 * El tamaño de celda se asume 16 px × 16 px (TILE_SIZE del proyecto).
 */
class TemplateLoader {
	/** Paths de todas las plantillas del banco. Añadir aquí nuevas habitaciones. */
	static final ROOM_PATHS:Array<String> = [
		"assets/data/rooms/room_combat_01.json",
		"assets/data/rooms/room_combat_02.json",
		"assets/data/rooms/room_reward_01.json",
		"assets/data/rooms/room_neutral_01.json",
		"assets/data/rooms/room_boss_01.json",
	];

	static inline final CELL_SIZE:Int = 16;

	/** Caché de plantillas ya cargadas (path → RoomTemplate). */
	static var cache:Map<String, RoomTemplate> = new Map();

	/**
	 * Carga todas las plantillas definidas en ROOM_PATHS y devuelve el banco.
	 * Las llamadas subsecuentes retornan los objetos cacheados.
	 */
	public static function loadAll():Array<RoomTemplate> {
		return [for (p in ROOM_PATHS) load(p)];
	}

	/** Carga (o recupera de caché) una plantilla individual. */
	public static function load(path:String):RoomTemplate {
		if (cache.exists(path))
			return cache.get(path);

		var text = Assets.getText(path);
		if (text == null) {
			trace('[TemplateLoader] ERROR: no se pudo cargar "$path"');
			return makeEmptyTemplate(path);
		}

		var data:Dynamic = Json.parse(text);
		var tpl = new RoomTemplate();
		tpl.id = path;

		// Determinar tipo de habitación por nombre de archivo
		var fname = path.split("/").pop().split(".")[0];
		tpl.roomType = if (fname.indexOf("combat") >= 0) "combat"
			else if (fname.indexOf("reward") >= 0) "reward"
			else if (fname.indexOf("boss") >= 0) "boss"
			else "neutral";

		// Parsear capas
		var layers:Array<Dynamic> = cast data.layers;
		for (layer in layers) {
			var layerName:String = layer.name;
			switch (layerName) {
				case "Tiles":
					tpl.widthTiles = Std.int(layer.gridCellsX);
					tpl.heightTiles = Std.int(layer.gridCellsY);
					var rawData:Array<Int> = cast layer.data;
					// Ogmo exporta -1 para celdas vacías; lo mapeamos a 0
					tpl.tileData = rawData.map(v -> v < 0 ? 0 : v);

				case "Entities":
					var entities:Array<Dynamic> = cast layer.entities;
					for (ent in entities) {
						tpl.markers.push({
							name: cast ent.name,
							tx: Std.int(ent.x / CELL_SIZE),
							ty: Std.int(ent.y / CELL_SIZE)
						});
					}

				default: // otras capas se ignoran
			}
		}

		cache.set(path, tpl);
		return tpl;
	}

	/** Genera una plantilla de emergencia (habitación mínima sin entidades). */
	static function makeEmptyTemplate(path:String):RoomTemplate {
		var tpl = new RoomTemplate();
		tpl.id = path;
		tpl.widthTiles = 6;
		tpl.heightTiles = 6;
		// Habitación 6×6 con paredes en el borde y suelo interior
		tpl.tileData = [
			2, 2, 2, 2, 2, 2,
			2, 1, 1, 1, 1, 2,
			2, 1, 1, 1, 1, 2,
			2, 1, 1, 1, 1, 2,
			2, 1, 1, 1, 1, 2,
			2, 2, 2, 2, 2, 2
		];
		cache.set(path, tpl);
		return tpl;
	}
}
