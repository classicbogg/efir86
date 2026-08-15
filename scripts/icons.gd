class_name Icons
extends Object
## Штампы из res://assets/icons. Если файла нет — null, сцена рисует запасной примитив.

static var _cache: Dictionary = {}


static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var loaded: Texture2D = load(path)
	_cache[path] = loaded
	return loaded


static func truck(kind: String) -> Texture2D:
	return tex("res://assets/icons/trucks/%s.png" % kind)


static func token(id: String) -> Texture2D:
	return tex("res://assets/icons/tokens/%s.png" % id)


static func node_icon(id: String) -> Texture2D:
	return tex("res://assets/icons/nodes/%s.png" % id)


static func ui(name: String) -> Texture2D:
	return tex("res://assets/icons/ui/%s.png" % name)


static func blit(canvas: CanvasItem, texture: Texture2D, dest: Rect2) -> bool:
	if texture == null:
		return false
	canvas.draw_texture_rect(texture, dest, false)
	return true
