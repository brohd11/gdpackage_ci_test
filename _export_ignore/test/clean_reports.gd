extends SceneTree
## Workspaces reuse their import cache, so old reports must not hide a runner that failed to start.


func _initialize() -> void:
	_remove("res://addons/gdpackage_ci_test/_export_ignore/test/reports")
	DirAccess.make_dir_recursive_absolute("res://addons/gdpackage_ci_test/_export_ignore/test/reports")
	quit(0)


func _remove(path:String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for dir in DirAccess.get_directories_at(path):
		_remove(path.path_join(dir))
	DirAccess.remove_absolute(path)
