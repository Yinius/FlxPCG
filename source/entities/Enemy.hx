package entities;

import flixel.FlxSprite;

/**
 * Entidad enemiga instanciada por QuotaManager a partir de marcadores
 * "Spawn_Enemy_Tier_N" en las plantillas JSON de Ogmo Editor 3.
 *
 * Tier 1 → naranja #FF8800 (enemigo estándar)
 * Tier 2 → rojo    #FF2222 (enemigo élite / jefe)
 *
 * El tamaño visual (12×12 px) se centra dentro del tile (16×16 px).
 */
class Enemy extends FlxSprite {
	public var tier:Int;

	public function new(x:Float, y:Float, tier:Int = 1) {
		super(x, y);
		this.tier = tier;

		var color = tier >= 2 ? 0xFFFF2222 : 0xFFFF8800;
		makeGraphic(12, 12, color);

		// Centrar sprite dentro del tile
		offset.set(2, 2);
	}
}
