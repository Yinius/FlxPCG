package pcg;

/**
 * Validador de conectividad topológica mediante búsqueda por inundación (BFS).
 *
 * Implementa la capa de diagnóstico descrita en §2.3 del artículo:
 * recorre todas las celdas de suelo accesibles desde un punto de inicio
 * y verifica que su número coincida con el total de celdas de suelo del mapa.
 * Si hay discrepancia, existen regiones inalcanzables y el mapa se descarta.
 *
 * Complejidad: O(n) donde n = número de celdas de suelo (tile == 1).
 *
 * Referencia: Campos Escalera (2019) — necesidad de validación de accesibilidad.
 */
class FloodFill {
	/** Valor de tile que se considera suelo/navegable. */
	static inline final FLOOR:Int = 1;

	/**
	 * Verifica que todas las celdas de suelo del `grid` sean alcanzables
	 * desde (`startX`, `startY`) mediante movimiento en 4 direcciones.
	 *
	 * @param grid    Grid 2D [fila][columna]. 0=vacío, 1=suelo, 2=muro.
	 * @param startX  Columna de inicio (debe ser una celda de suelo).
	 * @param startY  Fila de inicio.
	 * @return true si el mapa está completamente conectado.
	 */
	public static function validate(grid:Array<Array<Int>>, startX:Int, startY:Int):Bool {
		var h = grid.length;
		var w = grid[0].length;

		// Contar total de celdas de suelo
		var totalFloor = 0;
		for (y in 0...h)
			for (x in 0...w)
				if (grid[y][x] == FLOOR)
					totalFloor++;

		if (totalFloor == 0)
			return false;
		if (grid[startY][startX] != FLOOR)
			return false;

		// BFS desde el punto de inicio
		var visited = [for (_ in 0...h) [for (_ in 0...w) false]];
		var queue:Array<{x:Int, y:Int}> = [{x: startX, y: startY}];
		visited[startY][startX] = true;
		var reached = 0;

		// Direcciones cardinales (4-conectividad)
		final dirs = [{x: 1, y: 0}, {x: -1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

		while (queue.length > 0) {
			var cur = queue.shift();
			reached++;
			for (d in dirs) {
				var nx = cur.x + d.x;
				var ny = cur.y + d.y;
				if (nx >= 0 && ny >= 0 && nx < w && ny < h && !visited[ny][nx] && grid[ny][nx] == FLOOR) {
					visited[ny][nx] = true;
					queue.push({x: nx, y: ny});
				}
			}
		}

		return reached == totalFloor;
	}

	/**
	 * Busca la primera celda de suelo en el grid (orden raster) para
	 * usarla como punto de inicio del Flood Fill.
	 *
	 * @return Coordenadas {x, y} o null si no hay ninguna celda de suelo.
	 */
	public static function findStart(grid:Array<Array<Int>>):Null<{x:Int, y:Int}> {
		for (y in 0...grid.length)
			for (x in 0...grid[y].length)
				if (grid[y][x] == FLOOR)
					return {x: x, y: y};
		return null;
	}
}
