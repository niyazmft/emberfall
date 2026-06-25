@tool
extends EditorPlugin

var _fs: EditorFileSystem


func _enter_tree() -> void:
	_fs = get_editor_interface().get_resource_filesystem()
	if _fs and not _fs.resource_saved.is_connected(_on_resource_saved):
		_fs.resource_saved.connect(_on_resource_saved)


func _exit_tree() -> void:
	if _fs and _fs.resource_saved.is_connected(_on_resource_saved):
		_fs.resource_saved.disconnect(_on_resource_saved)


func _on_resource_saved(resource: Resource) -> void:
	if not resource or not resource.resource_path.ends_with(".gd"):
		return

	var global_path: String = ProjectSettings.globalize_path(resource.resource_path)
	var output := []
	var exit_code: int = OS.execute("gdformat", [global_path], output, false)

	if exit_code == 0:
		get_editor_interface().get_resource_filesystem().scan()
	else:
		push_warning("GDScript Formatter: gdformat failed or not found on PATH. Output: %s" % output)
