extends SceneTree

const REPORT_PATH := "res://tests/autoload_benchmark_report.json"

const AUTOLOADS: Array[String] = [
	"SafeZoneManager",
	"ConfigLoader",
	"BurdenManager",
	"CaptionManager",
	"AudioMiddleware",
	"BurdenCaptionDriver",
	"BurdenEventCoordinator",
	"EntityLifecycle",
	"RunManager",
	"GridSystem",
	"LayerManager",
	"ToastManager",
	"FocusManager",
	"SettingsManager",
	"InputRouter",
]

func _init() -> void:
	print("=== Autoload Initialization Benchmark ===")
	call_deferred("_run_benchmark")

func _run_benchmark() -> void:
	var results := {}
	var total_time := 0

	var root := get_root()

	for name: String in AUTOLOADS:
		var node: Node = root.get_node_or_null(name)
		if node:
			# Read the stored initialization time from the node
			var elapsed: int = node.get("init_time_ms")

			results[name] = elapsed
			total_time += elapsed
			print("%s: %d ms" % [name, elapsed])
			if elapsed > 50:
				print("  [WARNING] %s initialization took more than 50ms!" % name)
		else:
			print("%s: NOT FOUND IN ROOT" % name)

	var avg_time := 0.0
	if results.size() > 0:
		avg_time = float(total_time) / results.size()

	print("---------------------------------------")
	print("Total: %d ms" % total_time)
	print("Average: %.1f ms per autoload" % avg_time)

	_export_json(results, total_time, avg_time)
	quit()

func _export_json(results: Dictionary, total: int, average: float) -> void:
	var report := {
		"timestamp": Time.get_datetime_string_from_system(),
		"results": results,
		"summary": {
			"total_ms": total,
			"average_ms": average,
			"count": results.size()
		}
	}

	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
		print("Report exported to %s" % REPORT_PATH)
	else:
		print("Failed to export report to %s" % REPORT_PATH)
