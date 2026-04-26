import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import pcg.MapGenerator;
import pcg.QuotaManager.QuotaConfig;

/**
 * Estado principal de juego del prototipo FlxPCG.
 *
 * Gestiona el ciclo de generación, renderizado y medición de métricas.
 * Controles:
 *   [R]          → Regenerar mapa (semilla aleatoria)
 *   [1] [2] [3]  → Cambiar dificultad (baja / estándar / alta)
 *   [WASD / ↑↓←→]→ Desplazar cámara
 *   [+] [-]      → Zoom de cámara
 *
 * Las tres configuraciones de QuotaConfig reproducen las filas de la
 * Tabla 2 del artículo (enemigos/habitación y recompensas/habitación).
 */
class PlayState extends FlxState {
	// ─── Configuraciones de dificultad (Tabla 2 del artículo) ────────────────

	static final CONFIGS:Array<QuotaConfig> = [
		// Baja: media 1.2 enemigos/hab, máx 2, media 1.8 recompensas
		{maxEnemiesPerRoom: 2, maxRewardsPerRoom: 2, minDistance: 3.0},
		// Estándar: media 2.4 enemigos/hab, máx 4, media 1.2 recompensas
		{maxEnemiesPerRoom: 4, maxRewardsPerRoom: 2, minDistance: 2.5},
		// Alta: media 3.6 enemigos/hab, máx 6, media 0.7 recompensas
		{maxEnemiesPerRoom: 6, maxRewardsPerRoom: 1, minDistance: 2.0},
	];

	static final DIFF_LABELS = ["Baja", "Estándar", "Alta"];

	// ─── Estado ──────────────────────────────────────────────────────────────

	var currentDifficulty:Int = 1; // 0=baja, 1=estándar, 2=alta
	var generator:MapGenerator;
	var mapGroup:FlxGroup; // contiene tilemap + entidades del mapa actual

	// Overlay de estadísticas (fijo en pantalla, ignora scroll de cámara)
	var statsText:FlxText;
	var controlsText:FlxText;
	var diffText:FlxText;

	// ─── create ──────────────────────────────────────────────────────────────

	override public function create():Void {
		super.create();
		bgColor = FlxColor.BLACK;

		// Instanciar generador con dificultad inicial
		generator = new MapGenerator(CONFIGS[currentDifficulty]);

		// Grupo para el contenido del mapa (se destruye en cada regeneración)
		mapGroup = new FlxGroup();
		add(mapGroup);

		// HUD — textos fijos en pantalla (scrollFactor = 0)
		statsText = makeHudText(4, 4, 0);
		controlsText = makeHudText(4, FlxG.height - 36, 0);
		controlsText.text = "[R] Regenerar mapa\n[1][2][3] Dificultad  [WASD/Flechas] Cámara  [+/-] Zoom";

		diffText = makeHudText(FlxG.width - 150, 4, 150);
		diffText.alignment = FlxTextAlign.RIGHT;

		generateMap();
	}

	// ─── update ──────────────────────────────────────────────────────────────

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		handleCamera(elapsed);

		// Regenerar mapa
		if (FlxG.keys.justPressed.R)
			generateMap();

		// Cambiar dificultad
		if (FlxG.keys.justPressed.ONE)
			setDifficulty(0);
		if (FlxG.keys.justPressed.TWO)
			setDifficulty(1);
		if (FlxG.keys.justPressed.THREE)
			setDifficulty(2);
	}

	// ─── Generación ──────────────────────────────────────────────────────────

	function generateMap():Void {
		// Destruir contenido anterior
		mapGroup.destroy();
		mapGroup = new FlxGroup();
		// Re-insertar al principio del render (debajo del HUD)
		members.insert(0, mapGroup);

		var result = generator.generate(); // semilla aleatoria

		mapGroup.add(result.tilemap);
		mapGroup.add(result.enemies);
		mapGroup.add(result.rewards);

		// Configurar límites de la cámara para el nuevo mapa
		FlxG.camera.setScrollBoundsRect(0, 0, MapGenerator.GRID_W * MapGenerator.TILE_SIZE, MapGenerator.GRID_H * MapGenerator.TILE_SIZE, true);

		// Actualizar overlay de estadísticas
		var ms = Math.round(result.generationMs * 10) / 10;
		statsText.text = 'Tiempo de generación: ${ms} ms\n'
			+ 'Semillas usadas: ${result.seedsUsed}\n'
			+ 'Habitaciones: ${result.roomCount}\n'
			+ 'Enemigos: ${result.enemies.countLiving()}\n'
			+ 'Recompensas: ${result.rewards.countLiving()}';

		diffText.text = 'Dificultad: ${DIFF_LABELS[currentDifficulty]}';
	}

	function setDifficulty(d:Int):Void {
		currentDifficulty = d;
		generator = new MapGenerator(CONFIGS[currentDifficulty]);
		generateMap();
	}

	// ─── Cámara ──────────────────────────────────────────────────────────────

	function handleCamera(elapsed:Float):Void {
		final CAM_SPEED = 300.0;

		if (FlxG.keys.pressed.W || FlxG.keys.pressed.UP)
			FlxG.camera.scroll.y -= CAM_SPEED * elapsed;
		if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN)
			FlxG.camera.scroll.y += CAM_SPEED * elapsed;
		if (FlxG.keys.pressed.A || FlxG.keys.pressed.LEFT)
			FlxG.camera.scroll.x -= CAM_SPEED * elapsed;
		if (FlxG.keys.pressed.D || FlxG.keys.pressed.RIGHT)
			FlxG.camera.scroll.x += CAM_SPEED * elapsed;

		// Zoom
		if (FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.NUMPADPLUS)
			FlxG.camera.zoom = Math.min(4.0, FlxG.camera.zoom + 0.25);
		if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.NUMPADMINUS)
			FlxG.camera.zoom = Math.max(0.25, FlxG.camera.zoom - 0.25);
	}

	// ─── Utilidades ──────────────────────────────────────────────────────────

	function makeHudText(x:Float, y:Float, width:Int):FlxText {
		var t = new FlxText(x, y, width, "", 9);
		t.color = FlxColor.WHITE;
		t.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
		t.scrollFactor.set(0, 0); // fijo en pantalla, sin scroll de cámara
		add(t);
		return t;
	}
}
