@tool
extends RefCounted

const DRIVER_SCENE_PATH := "res://tests/helpers/e2e_runtime_driver.tscn"
const RESULT_PREFIX := "__E2E_RESULTS__:"


static func run_headless_batch(suite_id: String) -> Dictionary:
	var project_dir := ProjectSettings.globalize_path("res://")
	if project_dir.ends_with("/") or project_dir.ends_with("\\"):
		project_dir = project_dir.left(project_dir.length() - 1)

	var godot_exe := OS.get_executable_path()
	if godot_exe.is_empty():
		return {
			"ok": false,
			"error": "OS.get_executable_path() returned empty string",
			"cases": {},
		}

	var args: PackedStringArray = PackedStringArray([
		"--headless",
		"--fixed-fps",
		"60",
		"--path",
		project_dir,
		DRIVER_SCENE_PATH,
		"--",
		"--suite=" + suite_id,
	])

	var output: Array = []
	var exit_code: int = OS.execute(godot_exe, args, output, true)
	var raw_output := ""
	if output.size() > 0:
		raw_output = str(output[0])

	var parsed := _parse_results_from_output(raw_output)
	if parsed.is_empty():
		return {
			"ok": false,
			"error": "Missing or invalid %s JSON (exit_code=%d). Output: %s" % [
				RESULT_PREFIX,
				exit_code,
				raw_output.left(1000),
			],
			"cases": {},
		}

	if exit_code != 0 and bool(parsed.get("ok", false)):
		parsed["ok"] = false
		parsed["error"] = "Headless driver exited with code %d: %s" % [exit_code, str(parsed.get("error", ""))]

	if not parsed.has("cases") or not (parsed["cases"] is Dictionary):
		parsed["cases"] = {}
	if not parsed.has("error"):
		parsed["error"] = ""
	if not parsed.has("ok"):
		parsed["ok"] = false
	return parsed


static func _parse_results_from_output(raw_output: String) -> Dictionary:
	var normalized := raw_output.replace("\r\n", "\n")
	var lines := normalized.split("\n", false)
	for i in range(lines.size() - 1, -1, -1):
		var line := lines[i].strip_edges()
		var idx := line.find(RESULT_PREFIX)
		if idx != -1:
			var json_str := line.substr(idx + RESULT_PREFIX.length()).strip_edges()
			var json := JSON.new()
			var err := json.parse(json_str)
			if err == OK and json.data is Dictionary:
				return json.data as Dictionary
	return {}


static func load_resource_ignore_cache(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


static func instantiate_scene(path: String) -> Node:
	var res := load_resource_ignore_cache(path)
	if res == null or not (res is PackedScene):
		return null
	return (res as PackedScene).instantiate()


static func find_node_by_name_or_script(root: Node, target_name: String, script_suffix: String = "") -> Node:
	if root == null:
		return null
	var matches_name := (not target_name.is_empty()) and (String(root.name) == target_name)
	var matches_script := (not script_suffix.is_empty()) and _node_has_script_suffix(root, script_suffix)
	if matches_name or matches_script:
		return root
	for child in root.get_children():
		var found := find_node_by_name_or_script(child, target_name, script_suffix)
		if found != null:
			return found
	return null


static func collect_nodes_with_script_suffix(root: Node, script_suffix: String) -> Array[Node]:
	var result: Array[Node] = []
	if root == null or script_suffix.is_empty():
		return result
	_collect_script_suffix_recursive(root, script_suffix, result)
	return result


static func _collect_script_suffix_recursive(node: Node, script_suffix: String, out: Array[Node]) -> void:
	if _node_has_script_suffix(node, script_suffix):
		out.append(node)
	for child in node.get_children():
		_collect_script_suffix_recursive(child, script_suffix, out)


static func _node_has_script_suffix(node: Node, script_suffix: String) -> bool:
	var scr: Variant = node.get_script()
	if scr is Script:
		return (scr as Script).resource_path.ends_with(script_suffix)
	return false


static func script_has_method(scr: Script, method_name: String) -> bool:
	var cur := scr
	while cur != null:
		for m in cur.get_script_method_list():
			if str(m.get("name", "")) == method_name:
				return true
		cur = cur.get_base_script()
	return false


static func script_has_signal(scr: Script, sig_name: String) -> bool:
	var cur := scr
	while cur != null:
		for s in cur.get_script_signal_list():
			if str(s.get("name", "")) == sig_name:
				return true
		cur = cur.get_base_script()
	return false


static func script_has_property(scr: Script, prop_name: String) -> bool:
	var cur := scr
	while cur != null:
		for p in cur.get_script_property_list():
			if str(p.get("name", "")) == prop_name:
				return true
		cur = cur.get_base_script()
	return false


static func get_case_result(batch: Dictionary, case_id: String) -> Dictionary:
	if not bool(batch.get("ok", false)):
		return {
			"passed": false,
			"detail": "Batch failed: " + str(batch.get("error", "unknown error")),
		}
	var cases: Variant = batch.get("cases", null)
	if not (cases is Dictionary):
		return {
			"passed": false,
			"detail": "Batch missing 'cases' Dictionary",
		}
	var cases_dict: Dictionary = cases
	if not cases_dict.has(case_id):
		return {
			"passed": false,
			"detail": "Missing runtime case '%s' in batch results" % case_id,
		}
	var entry: Variant = cases_dict[case_id]
	if not (entry is Dictionary):
		return {
			"passed": false,
			"detail": "Invalid result entry type for case '%s'" % case_id,
		}
	var entry_dict: Dictionary = entry
	return {
		"passed": bool(entry_dict.get("passed", false)),
		"detail": str(entry_dict.get("detail", "")),
	}


static func collect_nodes_by_class(root: Node, class_name_str: String) -> Array[Node]:
	var result: Array[Node] = []
	if root == null:
		return result
	_collect_by_class_recursive(root, class_name_str, result)
	return result


static func _collect_by_class_recursive(node: Node, class_name_str: String, out: Array[Node]) -> void:
	if node.is_class(class_name_str):
		out.append(node)
	for child in node.get_children():
		_collect_by_class_recursive(child, class_name_str, out)


static func collect_nodes_in_group(root: Node, group_name: String) -> Array[Node]:
	var result: Array[Node] = []
	if root == null:
		return result
	_collect_in_group_recursive(root, group_name, result)
	return result


static func _collect_in_group_recursive(node: Node, group_name: String, out: Array[Node]) -> void:
	if node.is_in_group(group_name):
		out.append(node)
	for child in node.get_children():
		_collect_in_group_recursive(child, group_name, out)
