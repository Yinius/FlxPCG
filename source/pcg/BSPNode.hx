package pcg;

/**
 * Rectángulo auxiliar usado para región BSP y habitación real.
 */
typedef Rect = {
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
}

/**
 * Nodo del árbol de partición binaria del espacio (BSP).
 *
 * Cada nodo cubre una región rectangular (`rect`) del mapa en tiles.
 * Los nodos hoja (`isLeaf == true`) reciben una plantilla de habitación
 * (`template`) y registran las coordenadas exactas de dicha habitación
 * dentro de la región (`room`).
 */
class BSPNode {
	/** Región que ocupa este nodo (en tiles, coordenadas del grid global). */
	public var rect:Rect;

	/** Habitación real colocada dentro de `rect` al estampar la plantilla. */
	public var room:Rect;

	/** Hijo izquierdo (o superior en partición horizontal). */
	public var left:BSPNode;

	/** Hijo derecho (o inferior en partición horizontal). */
	public var right:BSPNode;

	/** Plantilla JSON asignada a este nodo hoja. */
	public var template:RoomTemplate;

	/** true cuando el nodo no se subdivide más y contiene una habitación. */
	public var isLeaf:Bool;

	public function new(x:Int, y:Int, w:Int, h:Int) {
		rect = {x: x, y: y, w: w, h: h};
		room = null;
		left = null;
		right = null;
		template = null;
		isLeaf = false;
	}
}
