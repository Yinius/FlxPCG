package pcg;

import flixel.group.FlxGroup;
import entities.Enemy;
import entities.Reward;

/**
 * Parámetros de cuota configurables por nivel de dificultad.
 * Corresponde a las tres configuraciones descritas en la Tabla 2 del artículo.
 */
typedef QuotaConfig = {
	/** Número máximo de enemigos que se instancian por habitación. */
	var maxEnemiesPerRoom:Int;

	/** Número máximo de recompensas que se instancian por habitación. */
	var maxRewardsPerRoom:Int;

	/**
	 * Distancia mínima en tiles entre cualquier par de entidades instanciadas
	 * dentro de una misma habitación. Previene la superposición en zonas estrechas.
	 */
	var minDistance:Float;
}

/**
 * Sistema de cuotas para la distribución controlada de entidades.
 *
 * Opera sobre los marcadores semánticos depositados por el diseñador en
 * Ogmo Editor 3 y aplica límites parametrizados (maxEnemiesPerRoom,
 * maxRewardsPerRoom) y heurística de distancia mínima entre instancias.
 *
 * La separación formal entre este módulo y el pipeline topológico (BSP +
 * FloodFill) permite ajustar la dificultad sin modificar los algoritmos
 * de generación del mapa. (§2.4 del artículo)
 */
class QuotaManager {
	var config:QuotaConfig;

	public function new(config:QuotaConfig) {
		this.config = config;
	}

	/**
	 * Puebla una habitación (nodo hoja BSP) leyendo sus marcadores JSON
	 * e instanciando entidades en los FlxGroup correspondientes.
	 *
	 * @param node      Nodo hoja BSP con `template` y `room` asignados.
	 * @param grid      Grid global 2D (para verificar que el tile destino sea suelo).
	 * @param enemies   FlxGroup de enemigos al que se añaden las instancias.
	 * @param rewards   FlxGroup de recompensas al que se añaden las instancias.
	 * @param tileSize  Tamaño de cada tile en píxeles (para calcular posición mundo).
	 */
	public function populate(node:BSPNode, grid:Array<Array<Int>>, enemies:FlxGroup, rewards:FlxGroup, tileSize:Int):Void {
		if (node.template == null || node.room == null)
			return;

		var enemyCount = 0;
		var rewardCount = 0;

		// Posiciones ya ocupadas en esta habitación (para distancia mínima)
		var placed:Array<{x:Int, y:Int}> = [];

		for (marker in node.template.markers) {
			// Traducir coordenadas template-locales a coordenadas del grid global
			var wx = node.room.x + marker.tx;
			var wy = node.room.y + marker.ty;

			// Descartar si está fuera de los límites del grid
			if (wx < 0 || wy < 0 || wy >= grid.length || wx >= grid[0].length)
				continue;

			// El tile destino debe ser suelo navegable
			if (grid[wy][wx] != 1)
				continue;

			// Verificar distancia mínima respecto a entidades ya colocadas
			if (!checkMinDistance(wx, wy, placed))
				continue;

			var markerName:String = marker.name;

			if (markerName.indexOf("Enemy") >= 0) {
				if (enemyCount >= config.maxEnemiesPerRoom)
					continue;
				var tier = markerName.indexOf("Tier_2") >= 0 ? 2 : 1;
				var e = new Enemy(wx * tileSize, wy * tileSize, tier);
				enemies.add(e);
				placed.push({x: wx, y: wy});
				enemyCount++;
			} else if (markerName.indexOf("Reward") >= 0 || markerName.indexOf("reward") >= 0) {
				if (rewardCount >= config.maxRewardsPerRoom)
					continue;
				var r = new Reward(wx * tileSize, wy * tileSize);
				rewards.add(r);
				placed.push({x: wx, y: wy});
				rewardCount++;
			}
			// Otros marcadores (trampas, puertas jefe, etc.) se pueden añadir aquí
		}
	}

	/**
	 * Verifica que (x, y) esté a distancia >= config.minDistance de todos
	 * los puntos en `placed`. Usa distancia euclídea en tiles.
	 */
	function checkMinDistance(x:Int, y:Int, placed:Array<{x:Int, y:Int}>):Bool {
		for (p in placed) {
			var dx = x - p.x;
			var dy = y - p.y;
			if (Math.sqrt(dx * dx + dy * dy) < config.minDistance)
				return false;
		}
		return true;
	}
}
