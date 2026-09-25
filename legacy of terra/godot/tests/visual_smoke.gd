extends SceneTree
## Optional graphical check. Launch with -- --capture-dir=/absolute/output/path.

const MainScene = preload("res://scenes/main.tscn")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var output: String = "user://"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			output = argument.trim_prefix("--capture-dir=")
	if DisplayServer.get_name() == "headless":
		printerr("Visual capture needs a graphical display, not --headless.")
		quit(1)
		return
	var main: Control = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(output.path_join("terra-starting-board.png"))
	main.load_fixture(1)
	main.area_buttons["tile-a:nw"].pressed.emit()
	main.area_buttons["tile-b:nw"].pressed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	result = result if result != OK else root.get_texture().get_image().save_png(output.path_join("terra-support-path.png"))
	main._open_battle_lab()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	result = result if result != OK else root.get_texture().get_image().save_png(output.path_join("terra-battle-cards.png"))
	for step: int in range(50):
		if main.battle_lab.battle_state.step == "finished": break
		if main.battle_lab.action_buttons.is_empty():
			result = FAILED
			break
		main.battle_lab.action_buttons[0].pressed.emit()
		await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	result = result if result != OK else root.get_texture().get_image().save_png(output.path_join("terra-battle-outcome.png"))
	print("Visual capture: " + ("passed" if result == OK else "failed"))
	main.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
