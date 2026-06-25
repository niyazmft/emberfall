@tool
extends EditorPlugin

func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass


func _resource_saved(resource: Resource) -> void:
	if not resource or not resource.resource_path.ends_with(".gd"):
		return

	var global_path: String = ProjectSettings.globalize_path(resource.resource_path)
	var output := []
	var exit_code: int = OS.execute("gdformat", [global_path], output, false)

	if exit_code == 0:
		get_editor_interface().get_resource_filesystem().scan()
	else:
		push_warning("GDScript Formatter: gdformat failed or not found on PATH. Output: %s" % output)
