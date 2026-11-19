extends Node

const RESULT_PREFIX := "__E2E_RESULTS__:"
const ALLOWED_SUITES := [
	"game_core",
	"e2e_tier1_features",
	"e2e_tier2_boundaries",
	"e2e_tier3_combinations",
	"e2e_tier4_scenarios",
]


func _ready() -> void:
	await get_tree().process_frame
	await _execute_suite()


func _execute_suite() -> void:
	var suite_id := _parse_suite_id()
	if suite_id.is_empty():
		_emit_and_quit(false, "Missing --suite=<id> argument", {})
		return

	if not ALLOWED_SUITES.has(suite_id):
		_emit_and_quit(false, "Unsupported suite id: " + suite_id, {})
		return

	var batch_path := "res://tests/helpers/runtime_batch_%s.gd" % suite_id
	if not ResourceLoader.exists(batch_path):
		_emit_and_quit(false, "Runtime batch script not found: " + batch_path, {})
		return

	var batch_res := ResourceLoader.load(batch_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if batch_res == null or not (batch_res is Script):
		_emit_and_quit(false, "Failed to load Script: " + batch_path, {})
		return

	var batch_script := batch_res as Script
	if not batch_script.can_instantiate():
		_emit_and_quit(false, "Batch script cannot instantiate: " + batch_path, {})
		return

	var batch: Variant = batch_script.new()
	if batch == null or not (batch is Object) or not (batch as Object).has_method("run"):
		_emit_and_quit(false, "Batch script missing run(tree, host) method: " + batch_path, {})
		return

	var raw_result: Variant = await (batch as Object).call("run", get_tree(), self)
	if not (raw_result is Dictionary):
		_emit_and_quit(false, "Batch run() did not return a Dictionary", {})
		return

	var res_dict := raw_result as Dictionary
	var ok: bool = bool(res_dict.get("ok", true))
	var err_msg: String = str(res_dict.get("error", ""))
	var cases_val: Variant = res_dict.get("cases", {})
	var cases: Dictionary = cases_val as Dictionary if cases_val is Dictionary else {}
	_emit_and_quit(ok, err_msg, cases)


func _parse_suite_id() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suite="):
			return arg.substr("--suite=".length()).strip_edges()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--suite="):
			return arg.substr("--suite=".length()).strip_edges()
	return ""


func _emit_and_quit(ok: bool, error_msg: String, cases: Dictionary) -> void:
	var payload := {
		"ok": ok,
		"error": error_msg,
		"cases": cases,
	}
	print(RESULT_PREFIX + JSON.stringify(payload))
	get_tree().quit(0)
