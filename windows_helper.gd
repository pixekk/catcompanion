extends Node

signal status_changed(idle_seconds, fullscreen, foreground_app)

const SCRIPT = "res://windows_helper.ps1"
const RUNTIME_SCRIPT = "user://windows_helper.ps1"

var pipe: FileAccess
var helper_pid = -1
var reader = Thread.new()


func start():
	if OS.get_name() != "Windows":
		return
	var runtime_file = FileAccess.open(RUNTIME_SCRIPT, FileAccess.WRITE)
	runtime_file.store_string(FileAccess.get_file_as_string(SCRIPT))
	runtime_file.close()
	var arguments = [
		"-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
		"-File", ProjectSettings.globalize_path(RUNTIME_SCRIPT),
		str(OS.get_process_id()),
	]
	var process = OS.execute_with_pipe("powershell.exe", arguments)
	if process.is_empty():
		push_warning("Windows helper could not start")
		return
	pipe = process["stdio"]
	helper_pid = process["pid"]
	reader.start(read_status)


func read_status():
	while true:
		var line = pipe.get_line()
		if pipe.get_error() != OK:
			return
		call_deferred("parse_status", line)


func parse_status(line):
	var parts = line.strip_edges().split("|")
	if parts.size() == 3:
		status_changed.emit(int(parts[0]), parts[1] == "1", parts[2])


func _exit_tree():
	if helper_pid > 0:
		OS.kill(helper_pid)
	if reader.is_started():
		reader.wait_to_finish()
