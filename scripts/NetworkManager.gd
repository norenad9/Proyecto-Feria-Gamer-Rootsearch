extends Node
const PORT := 7777
const MAX_CLIENTES := 1
enum Role { NONE, DETECTIVE, INFORMATICO }
var my_role: Role = Role.NONE
var partner_peer_id: int = -1
signal partner_joined
signal partner_left
signal pistas_synced(pistas: Dictionary)
signal chat_received(sender: String, text: String)
signal algorithm_result_received(result_text: String)
signal mission_synced(mission_idx: int)
signal connection_failed
signal victory_triggered
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed_internal)
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTES)
	if err != OK:
		push_error("[Red] Error al crear servidor: " + str(err))
		return err
	multiplayer.multiplayer_peer = peer
	my_role = Role.DETECTIVE
	print("[Red] Servidor iniciado. Esperando Informático en puerto " + str(PORT))
	return OK
func join_game(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("[Red] Error al conectar: " + str(err))
		return err
	multiplayer.multiplayer_peer = peer
	my_role = Role.INFORMATICO
	print("[Red] Conectando a " + ip + ":" + str(PORT))
	return OK
func disconnect_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	my_role = Role.NONE
	partner_peer_id = -1
func is_detective() -> bool:
	return my_role == Role.DETECTIVE
func is_informatico() -> bool:
	return my_role == Role.INFORMATICO
func is_multiplayer_active() -> bool:
	return my_role != Role.NONE
func has_partner() -> bool:
	return partner_peer_id != -1
func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"
func _on_peer_connected(id: int) -> void:
	print("[Red] Compañero conectado: ID=" + str(id))
	partner_peer_id = id
	partner_joined.emit()
func _on_peer_disconnected(id: int) -> void:
	print("[Red] Compañero desconectado: ID=" + str(id))
	partner_peer_id = -1
	partner_left.emit()
func _on_connected_to_server() -> void:
	partner_peer_id = 1
	print("[Red] Conectado al servidor como Informático.")
	partner_joined.emit()
func _on_connection_failed_internal() -> void:
	push_error("[Red] Conexión fallida.")
	my_role = Role.NONE
	connection_failed.emit()
@rpc("any_peer", "call_local", "reliable")
func _rpc_sync_pistas(pistas: Dictionary) -> void:
	MisionFinal.pistas_descubiertas = pistas
	pistas_synced.emit(pistas)
func sync_pistas_to_partner() -> void:
	broadcast_pistas()
func broadcast_pistas() -> void:
	if not is_multiplayer_active() or multiplayer.multiplayer_peer == null:
		return
	_rpc_sync_pistas.rpc(MisionFinal.pistas_descubiertas)
@rpc("any_peer", "call_local", "reliable")
func _rpc_chat(sender: String, text: String) -> void:
	chat_received.emit(sender, text)
func send_chat(text: String) -> void:
	if not is_multiplayer_active() or multiplayer.multiplayer_peer == null:
		return
	var sender := "🕵️ Detective" if is_detective() else "💻 Informático"
	_rpc_chat.rpc(sender, text)
@rpc("any_peer", "call_local", "reliable")
func _rpc_algorithm_result(result_text: String) -> void:
	algorithm_result_received.emit(result_text)
func send_algorithm_result(result_text: String) -> void:
	if not is_multiplayer_active() or multiplayer.multiplayer_peer == null:
		return
	_rpc_algorithm_result.rpc(result_text)
@rpc("any_peer", "call_local", "reliable")
func _rpc_sync_mission(mission_idx: int) -> void:
	MisionFinal.mision_actual = mission_idx as MisionFinal.Misiones
	mission_synced.emit(mission_idx)
func broadcast_mission() -> void:
	if not is_multiplayer_active() or multiplayer.multiplayer_peer == null:
		return
	_rpc_sync_mission.rpc(MisionFinal.mision_actual as int)
@rpc("any_peer", "call_local", "reliable")
func _rpc_trigger_victory() -> void:
	get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn")
func broadcast_victory() -> void:
	if not is_multiplayer_active():
		get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn")
		return
	_rpc_trigger_victory.rpc()
