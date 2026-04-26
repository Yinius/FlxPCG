package entities;

import flixel.FlxSprite;

/**
 * Entidad de recompensa instanciada por QuotaManager a partir de marcadores
 * "Spawn_Reward" en las plantillas JSON de Ogmo Editor 3.
 *
 * Visual: rombo amarillo dorado #FFD700 de 10×10 px.
 */
class Reward extends FlxSprite {
	public function new(x:Float, y:Float) {
		super(x, y);
		makeGraphic(10, 10, 0xFFFFD700);

		// Centrar dentro del tile
		offset.set(3, 3);
	}
}
