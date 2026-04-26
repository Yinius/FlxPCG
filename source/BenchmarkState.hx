import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import pcg.MapGenerator;
import pcg.QuotaManager;
import pcg.QuotaManager.QuotaConfig;
import sys.io.File;

/**
 * Estado de benchmark automático.
 *
 * Ejecuta N_SEEDS generaciones por cada configuración de dificultad,
 * registra las métricas y escribe benchmark_results.csv en el
 * directorio de trabajo del ejecutable.
 *
 * USO TEMPORAL: cambiar PlayState → BenchmarkState en Main.hx,
 * ejecutar `lime test windows`, recuperar el CSV y restaurar PlayState.
 */
class BenchmarkState extends FlxState {
	// ─── Configuración del benchmark ─────────────────────────────────────────

	/** Número de semillas a probar por configuración de dificultad. */
	static inline final N_SEEDS:Int = 100;

	/** Nombre del archivo de salida (se crea junto al ejecutable). */
	static inline final OUTPUT_FILE:String = "benchmark_results.csv";

	/** Las mismas tres configuraciones de la Tabla 2 del artículo. */
	static final CONFIGS:Array<QuotaConfig> = [
		{maxEnemiesPerRoom: 2, maxRewardsPerRoom: 2, minDistance: 3.0}, // baja
		{maxEnemiesPerRoom: 4, maxRewardsPerRoom: 2, minDistance: 2.5}, // estandar
		{maxEnemiesPerRoom: 6, maxRewardsPerRoom: 1, minDistance: 2.0}, // alta
	];

	static final DIFF_LABELS:Array<String> = ["baja", "estandar", "alta"];

	// ─── Estado interno ───────────────────────────────────────────────────────

	var statusText:FlxText;
	var benchmarkRan:Bool = false;

	// ─── create ──────────────────────────────────────────────────────────────

	override public function create():Void {
		super.create();
		bgColor = 0xFF111111;

		statusText = new FlxText(30, 30, FlxG.width - 60, "", 13);
		statusText.color = FlxColor.WHITE;
		add(statusText);

		statusText.text = "FlxPCG — Benchmark\n\n"
			+ 'Semillas por dificultad: $N_SEEDS\n'
			+ 'Total de mapas: ${N_SEEDS * CONFIGS.length}\n\n'
			+ "Iniciando en el próximo frame...";
	}

	// ─── update ──────────────────────────────────────────────────────────────

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// Esperar un frame para que el texto de "Iniciando" sea visible
		if (!benchmarkRan) {
			benchmarkRan = true;
			runBenchmark();
		}
	}

	// ─── Benchmark ───────────────────────────────────────────────────────────

	function runBenchmark():Void {
		statusText.text = "Ejecutando benchmark... (la ventana puede congelarse)\n\n";

		var out = File.write(OUTPUT_FILE, false);

		// Encabezado del CSV
		out.writeString("seed,dificultad,tiempo_ms,semillas_usadas,habitaciones,enemigos,recompensas\n");

		var globalT0 = haxe.Timer.stamp();

		for (di in 0...CONFIGS.length) {
			var diffLabel = DIFF_LABELS[di];
			var generator = new MapGenerator(CONFIGS[di]);

			var diffT0 = haxe.Timer.stamp();

			for (seed in 1...N_SEEDS + 1) {
				var result = generator.generate(seed);

				var ms = Math.round(result.generationMs * 1000) / 1000; // 3 decimales
				var enemies = result.enemies.countLiving();
				var rewards = result.rewards.countLiving();

				out.writeString('$seed,$diffLabel,$ms,${result.seedsUsed},${result.roomCount},$enemies,$rewards\n');

				// Limpiar objetos para no acumular memoria
				result.tilemap.destroy();
				result.enemies.destroy();
				result.rewards.destroy();
			}

			var diffMs = Math.round((haxe.Timer.stamp() - diffT0) * 1000);
			statusText.text += '✓ Dificultad "$diffLabel" — ${N_SEEDS} mapas en ${diffMs} ms\n';
		}

		out.close();

		var totalMs = Math.round((haxe.Timer.stamp() - globalT0) * 1000);

		statusText.text += '\n─────────────────────────────\n'
			+ '✓ Benchmark completado en ${totalMs} ms\n\n'
			+ 'Archivo generado:\n  $OUTPUT_FILE\n\n'
			+ 'Busca el CSV junto al ejecutable:\n'
			+ '  Export/windows/bin/benchmark_results.csv\n\n'
			+ '[Cierra la ventana para continuar]';

		trace('[BenchmarkState] CSV escrito: $OUTPUT_FILE');
	}
}
