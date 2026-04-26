package pcg;

/**
 * Marcador semántico de entidad depositado por el diseñador en Ogmo Editor 3.
 * Almacena nombre del tipo ("Spawn_Enemy_Tier_1", "Spawn_Reward", etc.)
 * y coordenadas en tiles relativas al origen de la plantilla.
 */
typedef SpawnMarker = {
	var name:String;
	var tx:Int; // coordenada X en tiles (relativa al origen de la plantilla)
	var ty:Int; // coordenada Y en tiles (relativa al origen de la plantilla)
}

/**
 * Datos de una plantilla de habitación exportada desde Ogmo Editor 3.
 *
 * La capa "Tiles" define la geometría (0=vacío, 1=suelo, 2=muro).
 * La capa "Entities" define los marcadores semánticos de entidades.
 *
 * Las instancias se generan por TemplateLoader.loadAll() y se
 * reutilizan durante toda la sesión (cache por path).
 */
class RoomTemplate {
	/** Ruta del archivo JSON de origen (sirve como clave de caché). */
	public var id:String;

	/** Ancho de la plantilla en tiles. */
	public var widthTiles:Int;

	/** Alto de la plantilla en tiles. */
	public var heightTiles:Int;

	/**
	 * Datos de tiles en orden fila-mayor (row-major).
	 * Índice = ty * widthTiles + tx.
	 * Valores: 0 = vacío, 1 = suelo, 2 = muro.
	 */
	public var tileData:Array<Int>;

	/** Marcadores de entidades (enemigos, recompensas, trampas…). */
	public var markers:Array<SpawnMarker>;

	/**
	 * Tipo de habitación derivado del nombre del archivo.
	 * Valores: "combat" | "reward" | "boss" | "neutral"
	 */
	public var roomType:String;

	public function new() {
		tileData = [];
		markers = [];
		roomType = "neutral";
	}

	/** Devuelve el valor de tile en (tx, ty) o 0 si está fuera de rango. */
	public inline function getTile(tx:Int, ty:Int):Int {
		if (tx < 0 || ty < 0 || tx >= widthTiles || ty >= heightTiles)
			return 0;
		return tileData[ty * widthTiles + tx];
	}
}
