package pcg;

import flixel.math.FlxRandom;

/**
 * Árbol de partición binaria del espacio (BSP).
 *
 * Subdivide recursivamente el área del mapa en regiones rectangulares.
 * Cada región hoja recibirá una plantilla de habitación JSON.
 * Los pasillos se generan conectando los centros de las habitaciones
 * de nodos hermanos (ver MapGenerator.connectRooms).
 *
 * Referencia: Baron (2017) — BSP Room Placement.
 */
class BSPTree {
	/** Tamaño mínimo de un nodo en tiles (ancho Y alto). */
	static inline final MIN_SIZE:Int = 14;

	/** Nodo raíz del árbol. */
	public var root:BSPNode;

	var rng:FlxRandom;

	/**
	 * @param width   Ancho total del grid en tiles.
	 * @param height  Alto total del grid en tiles.
	 * @param rng     Fuente de aleatoriedad compartida con el generador.
	 */
	public function new(width:Int, height:Int, rng:FlxRandom) {
		this.rng = rng;
		// Margen de 1 tile en cada borde para el muro perimetral
		root = new BSPNode(1, 1, width - 2, height - 2);
	}

	/**
	 * Ejecuta la subdivisión recursiva hasta `maxDepth` niveles.
	 * Limita el número máximo de habitaciones a 2^maxDepth.
	 */
	public function split(maxDepth:Int = 4):Void {
		splitNode(root, maxDepth);
	}

	/** Devuelve todos los nodos hoja del árbol. */
	public function getLeaves():Array<BSPNode> {
		var leaves:Array<BSPNode> = [];
		collectLeaves(root, leaves);
		return leaves;
	}

	// ─── Privados ───────────────────────────────────────────────────────────

	function splitNode(node:BSPNode, depth:Int):Void {
		// Condición de parada: profundidad agotada o región demasiado pequeña
		if (depth == 0) {
			node.isLeaf = true;
			return;
		}
		if (node.rect.w < MIN_SIZE * 2 && node.rect.h < MIN_SIZE * 2) {
			node.isLeaf = true;
			return;
		}

		// Decidir orientación del corte
		var horizontal:Bool;
		if (node.rect.w < MIN_SIZE * 2)
			horizontal = true;
		else if (node.rect.h < MIN_SIZE * 2)
			horizontal = false;
		else
			horizontal = rng.bool(); // 50 % de probabilidad

		if (horizontal) {
			if (node.rect.h < MIN_SIZE * 2) {
				node.isLeaf = true;
				return;
			}
			// Punto de corte en Y, dejando MIN_SIZE tiles en cada mitad
			var splitY = rng.int(node.rect.y + MIN_SIZE, node.rect.y + node.rect.h - MIN_SIZE);
			node.left = new BSPNode(node.rect.x, node.rect.y, node.rect.w, splitY - node.rect.y);
			node.right = new BSPNode(node.rect.x, splitY, node.rect.w, node.rect.y + node.rect.h - splitY);
		} else {
			if (node.rect.w < MIN_SIZE * 2) {
				node.isLeaf = true;
				return;
			}
			// Punto de corte en X
			var splitX = rng.int(node.rect.x + MIN_SIZE, node.rect.x + node.rect.w - MIN_SIZE);
			node.left = new BSPNode(node.rect.x, node.rect.y, splitX - node.rect.x, node.rect.h);
			node.right = new BSPNode(splitX, node.rect.y, node.rect.x + node.rect.w - splitX, node.rect.h);
		}

		splitNode(node.left, depth - 1);
		splitNode(node.right, depth - 1);
	}

	function collectLeaves(node:BSPNode, out:Array<BSPNode>):Void {
		if (node == null)
			return;
		if (node.isLeaf) {
			out.push(node);
			return;
		}
		collectLeaves(node.left, out);
		collectLeaves(node.right, out);
	}
}
