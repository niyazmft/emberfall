class_name QAVisionCapture
extends RefCounted
## Captures the main viewport as a screenshot and encodes it for transmission.
## Supports PNG/JPEG encoding and optional down-scaling to reduce API payload size.
##
## Usage:
##   var capture: QAVisionCapture = QAVisionCapture.new()
##   var b64: String = capture.captureBase64()

const DEFAULT_QUALITY: int = 85
const DEFAULT_MAX_WIDTH: int = 1024

## If true, screenshots are saved to user://qa_screenshots/ for local debugging.
var saveLocal: bool = false

## Encode format: "png" (lossless, larger) or "jpeg" (smaller).
var format: String = "jpeg"

## JPEG quality (0-100). Ignored for PNG.
var quality: int = DEFAULT_QUALITY

## Max width in pixels; height is scaled proportionally. Set to 0 to disable.
var maxWidth: int = DEFAULT_MAX_WIDTH


func captureBase64() -> String:
	var image: Image = _captureViewport()
	if image == null:
		return ""
	if maxWidth > 0 and image.get_width() > maxWidth:
		var ratio: float = float(maxWidth) / float(image.get_width())
		var new_h: int = max(1, int(float(image.get_height()) * ratio))
		image.resize(maxWidth, new_h, Image.INTERPOLATE_LANCZOS)

	var buffer: PackedByteArray
	if format == "png":
		buffer = image.save_png_to_buffer()
	else:
		buffer = image.save_jpg_to_buffer(quality)

	if saveLocal:
		_saveToDisk(buffer)

	return Marshalls.raw_to_base64(buffer)


func _captureViewport() -> Image:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("QAVisionCapture: SceneTree is null, cannot capture viewport")
		return null
	var viewport: Viewport = tree.root.get_viewport()
	if viewport == null:
		push_error("QAVisionCapture: Viewport is null, cannot capture image")
		return null
	return viewport.get_texture().get_image()


func _saveToDisk(buffer: PackedByteArray) -> void:
	var dir: String = "user://qa_screenshots/"
	var err: Error = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("QAVisionCapture: failed to create screenshot directory")
		return
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-")
	var ext: String = "png" if format == "png" else "jpg"
	var path: String = dir + "shot_" + ts + "." + ext
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(buffer)
		f.close()
