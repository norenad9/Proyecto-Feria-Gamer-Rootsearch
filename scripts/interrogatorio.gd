extends Node
var ui_layer: CanvasLayer
var bg_rect: TextureRect
var sprite_personaje: TextureRect
var sprite_detective: TextureRect
var panel_sospechosos: Panel
var vbox_sospechosos: VBoxContainer
var panel_preguntas: Panel
var vbox_preguntas: VBoxContainer
var dialog_box: Panel
var name_label: Label
var dialog_text: RichTextLabel
var btn_volver: Button
var panel_polaroids: Panel
var grid_polaroids: GridContainer
var is_typing: bool = false
var sospechoso_actual: String = ""
var shake_time: float = 0.0
var shake_intensity: float = 15.0
var original_bg_pos: Vector2 = Vector2.ZERO
var panel_alerta_desbloqueo: Panel
var label_alerta_texto: Label
var mostrar_alerta_timer: float = 0.0
var base_datos = {
	"rafa": {
		"nombre": "Rafa",
		"avatar": "res://avatars/rafa_avatar.png",
		"saludos": ["Tienes una orden, viejo?", "No me molestes.", "Habla rapido, no tengo tu tiempo."],
		"preguntas_m1": {
			"Donde estabas el dia del ataque informatico?": "Estaba en los laboratorios de ingenieria, pero yo no toque ningun sistema. Preguntale a Santi, el siempre maneja las credenciales maestras...",
			"Conoces los lazos de comunicacion de la red?": "Yo solo hablo con Camila. De hecho, vi un intercambio de mensajes muy extrano en su red de contactos privados.",
			"Que relacion tienes con Yolanda?": "Ninguna directa. Pero escuche que ella descubrio algo masivo sobre el servidor central y alguien la amenazo para que guardara silencio."
		},
		"preguntas_m2": {
			"Quien configuro las rutas de red?": "Santi las diseno todas. El sabe exactamente por donde pasa cada paquete. Si quieren rastrear algo, el es el unico que conoce los caminos.",
			"Que sabes sobre la topologia de red?": "Todo pasa por el nodo central de Yolanda. Ella es la administradora, sin su acceso no se puede llegar a Alex."
		},
		"preguntas_m3": {
			"En quien confias de los involucrados?": "Solo en Yolanda. Ella siempre ha sido recta. Santi me cae mal desde que manipulo los datos del laboratorio.",
			"Que opinas de las relaciones entre el grupo?": "Santi y Camila eran cercanos, demasiado. Yolanda mantenIa distancia de todos profesionalmente."
		},
		"preguntas_m4": {
			"Sabes la capacidad del servidor?": "Una vez vi el panel cuando ayudaba a Yolanda. Marca 15.0 MB/s como maximo. Si alguien supera eso, el sistema se cae.",
			"Quien conoce bien los limites de la red?": "Yolanda configura todo. Ella ajusto los limites de ancho de banda personalmente."
		}
	},
	"camila": {
		"nombre": "Camila",
		"avatar": "res://avatars/camila_avatar.png",
		"saludos": ["Hola Detective... estoy un poco nerviosa.", "De verdad cree que yo tengo algo que ver?", "Por favor, resolvamos esto pronto."],
		"preguntas_m1": {
			"Por que tu usuario registra tanta actividad sospechosa?": "Alguien debio suplantarme! Yo sigo los protocolos. Aunque alguien me pidio prestada mi clave de acceso el lunes para una supuesta actualizacion de rutina.",
			"Quien esta detras de la red de acoso digital?": "No lo se con certeza, pero el flujo de datos siempre pasa cerca del equipo de alguien que conoce bien los servidores.",
			"Que sabes sobre el ataque final?": "Hubo un rastro digital inmenso. Quien lo hizo conocia perfectamente la infraestructura de la universidad para camuflar el rastro."
		},
		"preguntas_m2": {
			"Desde donde podriamos cortar el ataque?": "Si Yolanda te diera acceso a su terminal, podrian intervenir desde ahi. Ella tiene el panel de control principal de la red.",
			"Hay alguna ruta segura hacia Alex?": "Todo el trafico converge en el nodo de Yolanda primero, luego a Rafa, despues a Santi... y de ahi a Alex."
		},
		"preguntas_m3": {
			"Que tan fuerte es tu relacion con Santi?": "Creia que era mi amigo, pero me uso para obtener acceso a los servidores. Ahora no confio en el.",
			"Y con los demas?": "Con Yolanda tengo una relacion profesional nada mas. Rafa siempre fue distante pero respetuoso."
		},
		"preguntas_m4": {
			"Sabes algo de la capacidad del servidor?": "Yolanda me mostro el panel de monitoreo una vez. Tiene marcado 15.0 MB/s como el limite operativo.",
			"Quien podria saber como colapsar el sistema?": "Santi siempre estaba preguntando a Yolanda sobre los limites del cortafuegos. Creo que buscaba un punto debil."
		}
	},
	"yolanda": {
		"nombre": "Yolanda",
		"avatar": "res://avatars/yolanda_avatar.png",
		"saludos": ["Se perfectamente por que estas aqui.", "Las evidencias no mienten, Detective.", "Alguien cometio un error grave."],
		"preguntas_m1": {
			"Que encontraste en los registros de seguridad?": "Descubri que Rafa no actuaba solo, fue manipulado. Alguien borro los rastros de conexiones para incriminarlo directamente.",
			"Quien crees que esta detras de todo esto?": "Husmee en carpetas protegidas y vi algo preocupante. Alguien uso credenciales que no le correspondian.",
			"Tienes alguna prueba concreta?": "Extrajee un historial de accesos de la base de datos antes de que bloquearan mi terminal."
		},
		"preguntas_m2": {
			"Desde tu terminal se puede intervenir?": "Si, mi terminal es el nodo central. Si me autorizan, puedo abrir una ruta directa hacia el servidor de Alex para cortar la propagacion.",
			"Quien mas tiene acceso a la red principal?": "Santi tiene credenciales de administrador desde hace meses. Yo nunca autorice ese permiso. Debe haberlas conseguido ilegalmente."
		},
		"preguntas_m3": {
			"Como describirias la confianza entre todos?": "Rafa y yo mantenemos una relacion profesional. Camila era cercana a Santi. Andres es un externo que Santi metio al grupo.",
			"Quienes tienen los lazos mas fragiles?": "Andres y Santi. Andres solo esta ahi porque Santi lo trajo. Si ese lazo se rompe, todo se desmorona."
		},
		"preguntas_m4": {
			"Que capacidad tiene el servidor?": "Yo misma configure el limite en 15.0 MB/s. Es lo maximo que soporta antes de que el cortafuegos falle.",
			"Podria alguien sobrepasar ese limite?": "Si coordinaran multiples ataques desde diferentes nodos, si. El trafico combinado podria superar los 15 MB/s."
		}
	},
	"santi": {
		"nombre": "Santi",
		"avatar": "res://avatars/santi_avatar.png",
		"saludos": ["Buscando pistas, Detective?", "Yo solo ayudo a mantener la red de la universidad segura.", "Hay algun problema con mis reportes?"],
		"preguntas_m1": {
			"Por que todos los lazos de sospecha apuntan a ti?": "Es una trampa de los demas para salvarse. Yo solo diseno las rutas de comunicacion.",
		"Tuviste acceso a las credenciales de Camila y Rafa?": "Ellos son descuidados con sus cuentas. Si obtuve acceso a sus perfiles, fue para demostrar vulnerabilidades del sistema.",
			"Que hacias conectado durante el corte masivo?": "(Se pone tenso) Estaba... monitoreando la estabilidad del servidor."
		},
		"preguntas_m2": {
			"Como trazaste las rutas de red?": "Disene toda la topologia. Se exactamente como llegar desde cualquier nodo hasta Alex. Pero no esperes que te ayude a cortar mi propio plan.",
			"Yolanda tiene el control real de la red?": "Yolanda cree que controla todo, pero yo tengo accesos que ella desconoce. Rutas alternas que no aparecen en ningun diagrama oficial."
		},
		"preguntas_m3": {
			"En quien confias realmente?": "En nadie. Camila me era util, Rafa un estorbo, Yolanda una amenaza y Andres un titera.",
			"Que opinas de los lazos de amistad en el grupo?": "No existen. Solo intereses. Yo me asegure de que cada uno necesitara algo de mi para mantenerlos cerca."
		},
		"preguntas_m4": {
			"Conoces la capacidad del servidor?": "Claro. 15 MB/s. Y se exactamente cuantos frentes de ataque se necesitan para superar ese limite y tumbar todo el sistema.",
			"Que hace falta para colapsar la red?": "Solo decirte que si calculas mal el flujo, el cortafuegos no va a contener el ataque. Pero no esperes que te de la respuesta."
		}
	},
	"andres": {
		"nombre": "Andres",
		"avatar": "res://avatars/andres_avatar.png",
		"saludos": ["Eh, detective. Yo solo vine a declarar.", "No tengo nada que ocultar.", "Pregunte lo que quiera."],
		"preguntas_m1": {
			"Donde estabas la noche del ataque?": "Estaba jugando en linea toda la noche. Dije que estaba con Santi para cubrirme, no quiero problemas con el.",
			"Santi te pidio que mintieras?": "Si... Me dijo que si alguien preguntaba, dijera que estabamos juntos estudiando.",
			"Que mas sabes sobre lo que planeaba Santi?": "Solo se que llevaba semanas raro, preguntando sobre los horarios del servidor."
		},
		"preguntas_m2": {
			"Como te conectas a la red de la universidad?": "Santi me configuró el acceso desde mi laptop personal. Tengo un punto de entrada limitado, no como el de Yolanda que tiene acceso total.",
			"Santi te hablo sobre las rutas de red?": "Una vez lo vi con un diagrama enorme. Senalo el nodo de Yolanda y dijo 'por ahi entra todo'. No entendi mucho la verdad."
		},
		"preguntas_m3": {
			"Que tan cercano eres a Santi?": "Creia que eramos amigos, pero solo me usaba para tener coartadas y acceso a mi computadora para sus movimientos raros.",
			"Y con los demas?": "Apenas conozco a Camila y Rafa. Yolanda siempre me vio como un intruso. Solo Santi me incluyo en el grupo."
		},
		"preguntas_m4": {
			"Sabes algo de los servidores?": "Solo se que Yolanda siempre dice que el sistema no aguanta mas de 15 algo. No se si son megas, gigas o que.",
			"Viste a Santi hacer pruebas de carga?": "Si, varias veces lo vi ejecutar programas que mandaban un monton de datos al servidor. Como si estuviera probando cuanto aguantaba."
		}
	}
}
func _ready() -> void:
	_construir_interfaz_base()
	_generar_botones_sospechosos()
func _construir_interfaz_base() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	bg_rect = TextureRect.new()
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://backgrounds/bg_campus.png"):
		bg_rect.texture = load("res://backgrounds/bg_campus.png")
	ui_layer.add_child(bg_rect)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.35)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(overlay)
	original_bg_pos = bg_rect.position
	sprite_personaje = TextureRect.new()
	sprite_personaje.position = Vector2(680, 20)
	sprite_personaje.size = Vector2(360, 440)
	sprite_personaje.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_personaje.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_personaje.modulate = Color(1, 1, 1, 0)
	ui_layer.add_child(sprite_personaje)
	sprite_detective = TextureRect.new()
	sprite_detective.position = Vector2(20, 20)
	sprite_detective.size = Vector2(140, 200)
	sprite_detective.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_detective.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://sprites/detective_neutro.png"):
		sprite_detective.texture = load("res://sprites/detective_neutro.png")
	sprite_detective.modulate = Color(1, 1, 1, 0)
	ui_layer.add_child(sprite_detective)
	panel_sospechosos = Panel.new()
	panel_sospechosos.position = Vector2(20, 230)
	panel_sospechosos.size = Vector2(180, 240)
	var st_sos := StyleBoxFlat.new()
	st_sos.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	st_sos.border_color = Color(0.4, 0.4, 0.5)
	st_sos.border_width_left = 1; st_sos.border_width_top = 1
	st_sos.border_width_right = 1; st_sos.border_width_bottom = 1
	panel_sospechosos.add_theme_stylebox_override("panel", st_sos)
	ui_layer.add_child(panel_sospechosos)
	var lbl_sos = Label.new()
	lbl_sos.text = "SOSPECHOSOS"
	lbl_sos.position = Vector2(10, 8)
	lbl_sos.add_theme_font_size_override("font_size", 11)
	lbl_sos.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	panel_sospechosos.add_child(lbl_sos)
	vbox_sospechosos = VBoxContainer.new()
	vbox_sospechosos.position = Vector2(10, 28)
	vbox_sospechosos.size = Vector2(160, 200)
	panel_sospechosos.add_child(vbox_sospechosos)
	dialog_box = Panel.new()
	dialog_box.position = Vector2(220, 20)
	dialog_box.size = Vector2(440, 300)
	var st_db := StyleBoxFlat.new()
	st_db.bg_color = Color(0.04, 0.04, 0.07, 0.96)
	st_db.border_width_top = 4
	st_db.border_color = Color(0.78, 0.52, 0.18)
	st_db.corner_radius_top_left = 6
	st_db.corner_radius_top_right = 6
	dialog_box.add_theme_stylebox_override("panel", st_db)
	ui_layer.add_child(dialog_box)
	name_label = Label.new()
	name_label.position = Vector2(16, 12)
	name_label.text = "Detective"
	name_label.add_theme_font_size_override("font_size", 16)
	dialog_box.add_child(name_label)
	dialog_text = RichTextLabel.new()
	dialog_text.position = Vector2(16, 42)
	dialog_text.size = Vector2(408, 240)
	dialog_text.bbcode_enabled = true
	dialog_text.add_theme_font_size_override("normal_font_size", 15)
	dialog_text.text = "Selecciona un sospechoso de la lista para iniciar el interrogatorio."
	dialog_box.add_child(dialog_text)
	panel_preguntas = Panel.new()
	panel_preguntas.position = Vector2(220, 340)
	panel_preguntas.size = Vector2(440, 200)
	panel_preguntas.visible = false
	var st_preg := StyleBoxFlat.new()
	st_preg.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	st_preg.border_color = Color(0.5, 0.5, 0.6)
	st_preg.border_width_left = 1; st_preg.border_width_top = 1
	st_preg.border_width_right = 1; st_preg.border_width_bottom = 1
	panel_preguntas.add_theme_stylebox_override("panel", st_preg)
	ui_layer.add_child(panel_preguntas)
	vbox_preguntas = VBoxContainer.new()
	vbox_preguntas.position = Vector2(10, 10)
	vbox_preguntas.size = Vector2(420, 180)
	panel_preguntas.add_child(vbox_preguntas)
	btn_volver = Button.new()
	btn_volver.text = "Regresar a la Oficina"
	btn_volver.position = Vector2(1060, 660)
	btn_volver.size = Vector2(200, 45)
	btn_volver.pressed.connect(_on_btn_volver_pressed)
	ui_layer.add_child(btn_volver)
	panel_alerta_desbloqueo = Panel.new()
	panel_alerta_desbloqueo.position = Vector2(220, 325)
	panel_alerta_desbloqueo.size = Vector2(440, 36)
	panel_alerta_desbloqueo.visible = false
	var st_alerta := StyleBoxFlat.new()
	st_alerta.bg_color = Color(0.15, 0.05, 0.05)
	st_alerta.border_color = Color(0.9, 0.2, 0.2)
	st_alerta.border_width_bottom = 2
	st_alerta.border_width_top = 2
	panel_alerta_desbloqueo.add_theme_stylebox_override("panel", st_alerta)
	ui_layer.add_child(panel_alerta_desbloqueo)
	label_alerta_texto = Label.new()
	label_alerta_texto.text = "EVIDENCIA EXTRAIDA - SINCRONIZADA CON EL INFORMATICO"
	label_alerta_texto.set_anchors_preset(Control.PRESET_CENTER)
	label_alerta_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_alerta_texto.add_theme_font_size_override("font_size", 12)
	panel_alerta_desbloqueo.add_child(label_alerta_texto)
func _generar_botones_sospechosos() -> void:
	for id in base_datos:
		var btn := Button.new()
		btn.text = base_datos[id]["nombre"]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func(): _seleccionar_sospechoso(id))
		vbox_sospechosos.add_child(btn)
func _seleccionar_sospechoso(id: String) -> void:
	sospechoso_actual = id
	panel_preguntas.visible = true
	var data = base_datos[id]
	var saludo_random = data["saludos"][randi() % data["saludos"].size()]
	if ResourceLoader.exists(data["avatar"]):
		sprite_personaje.texture = load(data["avatar"])
		if ResourceLoader.exists("res://sprites/detective_enfrentando.png"):
			if ResourceLoader.exists("res://sprites/detective_enfrentando.png"): sprite_detective.texture = load("res://sprites/detective_enfrentando.png")
			else: sprite_detective.texture = load("res://sprites/detective_rabioso.png")
		else:
			sprite_detective.texture = load("res://sprites/detective_neutro.png")
		sprite_personaje.modulate = Color(1, 1, 1, 1)
		sprite_detective.modulate = Color(1, 1, 1, 1)
	_mostrar_dialogo(data["nombre"], saludo_random)
	_generar_botones_preguntas()
func _generar_botones_preguntas() -> void:
	for child in vbox_preguntas.get_children():
		child.queue_free()
	var mision: int = MisionFinal.mision_actual
	var key_preguntas: String = ""
	match mision:
		MisionFinal.Misiones.M1_ORIGEN: key_preguntas = "preguntas_m1"
		MisionFinal.Misiones.M2_RUTA: key_preguntas = "preguntas_m2"
		MisionFinal.Misiones.M3_RED: key_preguntas = "preguntas_m3"
		MisionFinal.Misiones.M4_IMPACTO: key_preguntas = "preguntas_m4"
	var preguntas = base_datos[sospechoso_actual].get(key_preguntas, {})
	if preguntas.is_empty():
		var lbl := Label.new()
		lbl.text = "Este sospechoso no tiene informacion relevante para esta fase."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.custom_minimum_size = Vector2(400, 80)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox_preguntas.add_child(lbl)
		return
	for preg in preguntas:
		var btn := Button.new()
		btn.text = preg
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): _hacer_pregunta(preg, preguntas[preg]))
		vbox_preguntas.add_child(btn)
func _hacer_pregunta(pregunta: String, respuesta: String) -> void:
	if sospechoso_actual == "santi" or "Santi" in respuesta:
		_disparar_efecto_desbloqueo()
	_mostrar_dialogo("Detective", pregunta)
	await get_tree().create_timer(1.0).timeout
	_mostrar_dialogo(base_datos[sospechoso_actual]["nombre"], respuesta)
	_inyectar_pista_narrativa(pregunta)
func _inyectar_pista_narrativa(pregunta: String) -> void:
	var mision: int = MisionFinal.mision_actual
	var actor: String = base_datos[sospechoso_actual]["nombre"]
	var clave_existente: String = _clave_para_pregunta(pregunta, mision)
	if clave_existente != "" and MisionFinal.pistas_descubiertas.has(clave_existente):
		return
	match mision:
		MisionFinal.Misiones.M1_ORIGEN:
			if "informatico" in pregunta or "noche del ataque" in pregunta or "Donde estabas" in pregunta or "ataque" in pregunta:
				MisionFinal.pistas_descubiertas["chat_01"] = "[" + actor + "] Alguien mas maneja las credenciales maestras del sistema."
			elif "actividad sospechosa" in pregunta or "detras" in pregunta:
				MisionFinal.pistas_descubiertas["camila_1"] = "[" + actor + "] Alguien pidio prestada su clave de acceso."
			elif "registros" in pregunta or "crees" in pregunta:
				MisionFinal.pistas_descubiertas["log_admin"] = "[" + actor + "] Hay un estudiante con acceso a los servidores centrales."
				MisionFinal.yolanda_delato_a_rafa = true
			elif "mintieras" in pregunta or "planeaba" in pregunta:
				MisionFinal.pistas_descubiertas["ip_andres"] = "[" + actor + "] Le pidieron mentir sobre la coartada."
			elif "pruebas" in pregunta:
				MisionFinal.pistas_descubiertas["ataque_final"] = "[" + actor + "] Extrajo un historial de accesos con un patron anomalo."
		MisionFinal.Misiones.M2_RUTA:
			if "ruta" in pregunta or "topologia" in pregunta or "acceso a la red" in pregunta:
				MisionFinal.pistas_descubiertas["m2_ruta_intel"] = "[" + actor + "] El nodo central de Yolanda es clave para la ruta de intervencion."
			elif "configuro" in pregunta or "trazaste" in pregunta or "conectas" in pregunta:
				MisionFinal.pistas_descubiertas["m2_config"] = "[" + actor + "] Santi diseno las rutas y tiene accesos alternos no documentados."
		MisionFinal.Misiones.M3_RED:
			if "confias" in pregunta or "cercano" in pregunta or "lazos" in pregunta:
				MisionFinal.pistas_descubiertas["m3_confianza"] = "[" + actor + "] " + actor.split(" ")[0] + " describe los niveles de confianza entre el grupo."
				MisionFinal.pistas_descubiertas["m3_red_intel"] = "Niveles de confianza: " + actor.split(" ")[0] + " describe las relaciones del grupo."
			elif "relacion" in pregunta or "opinion" in pregunta:
				MisionFinal.pistas_descubiertas["m3_relaciones"] = "[" + actor + "] Relato sobre las dinamicas sociales del grupo."
				MisionFinal.pistas_descubiertas["m3_red_intel"] = "Dinamicas sociales: " + actor.split(" ")[0] + " relata los vinculos del grupo."
		MisionFinal.Misiones.M4_IMPACTO:
			if "capacidad" in pregunta or "limite" in pregunta:
				MisionFinal.pistas_descubiertas["m4_capacidad"] = "[" + actor + "] El limite del servidor es 15.0 MB/s."
				MisionFinal.pistas_descubiertas["m4_impacto_intel"] = "Capacidad del servidor: 15.0 MB/s. Cortafuegos configurable."
			elif "colapsar" in pregunta or "sobrepasar" in pregunta or "pruebas" in pregunta:
				MisionFinal.pistas_descubiertas["m4_ataque"] = "[" + actor + "] Un ataque coordinado desde multiples nodos puede superar el cortafuegos."
				MisionFinal.pistas_descubiertas["m4_impacto_intel"] = "Ataque coordinado: multiples nodos pueden superar el cortafuegos."
	if NetworkManager.is_multiplayer_active():
		NetworkManager.sync_pistas_to_partner()
func _clave_para_pregunta(pregunta: String, mision: int) -> String:
	match mision:
		MisionFinal.Misiones.M1_ORIGEN:
			if "informatico" in pregunta or "noche del ataque" in pregunta or "Donde estabas" in pregunta or "ataque" in pregunta: return "chat_01"
			if "actividad sospechosa" in pregunta or "detras" in pregunta: return "camila_1"
			if "registros" in pregunta or "crees" in pregunta: return "log_admin"
			if "mintieras" in pregunta or "planeaba" in pregunta: return "ip_andres"
			if "pruebas" in pregunta: return "ataque_final"
		MisionFinal.Misiones.M2_RUTA:
			if "ruta" in pregunta or "topologia" in pregunta or "acceso a la red" in pregunta: return "m2_ruta_intel"
			if "configuro" in pregunta or "trazaste" in pregunta or "conectas" in pregunta: return "m2_config"
		MisionFinal.Misiones.M3_RED:
			if "confias" in pregunta or "cercano" in pregunta or "lazos" in pregunta: return "m3_confianza"
			if "relacion" in pregunta or "opinion" in pregunta: return "m3_relaciones"
		MisionFinal.Misiones.M4_IMPACTO:
			if "capacidad" in pregunta or "limite" in pregunta: return "m4_capacidad"
			if "colapsar" in pregunta or "sobrepasar" in pregunta or "pruebas" in pregunta: return "m4_ataque"
	return ""
func _disparar_efecto_desbloqueo() -> void:
	shake_time = 0.6
	mostrar_alerta_timer = 3.0
	panel_alerta_desbloqueo.visible = true
func _process(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		bg_rect.position = original_bg_pos + offset
		if shake_time <= 0: bg_rect.position = original_bg_pos
	if mostrar_alerta_timer > 0:
		mostrar_alerta_timer -= delta
		if mostrar_alerta_timer <= 0:
			panel_alerta_desbloqueo.visible = false
			_generar_botones_preguntas()
func _mostrar_dialogo(speaker: String, text: String) -> void:
	name_label.text = speaker
	name_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0) if speaker == "Detective" else Color(1.0, 0.4, 0.4))
	_typewriter(text)
func _typewriter(full_text: String) -> void:
	is_typing = true
	dialog_text.text = full_text
func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
