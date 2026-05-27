class_name Graph
extends RefCounted
var nodes: Dictionary = {}
var adjacency: Dictionary = {}
var edge_list: Array[Dictionary] = []
var directed: bool = false
func _init(is_directed: bool = false) -> void:
	directed = is_directed
func add_node(id: int, label: String, pos: Vector2, behavior: String = "neutral", extra_data: Dictionary = {}) -> void:
	nodes[id] = {
		"label": label,
		"pos": pos,
		"behavior": behavior,
		"avatar": extra_data.get("avatar", ""),
		"bio": extra_data.get("bio", "Usuario de la red social")
	}
	adjacency[id] = []
func add_edge(from_id: int, to_id: int, weight: float = 1.0) -> void:
	if not nodes.has(from_id) or not nodes.has(to_id):
		return
	var edge := { "from": from_id, "to": to_id, "weight": weight }
	adjacency[from_id].append(edge)
	edge_list.append(edge)
	if not directed:
		var reverse_edge := { "from": to_id, "to": from_id, "weight": weight }
		adjacency[to_id].append(reverse_edge)
func get_neighbors(id: int) -> Array:
	if adjacency.has(id):
		return adjacency[id]
	return []
func node_count() -> int:
	return nodes.size()
func dijkstra(source: int) -> Dictionary:
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var queue: Array[int] = []
	for u in nodes:
		dist[u] = INF
		prev[u] = -1
		queue.append(u)
	dist[source] = 0.0
	while queue.size() > 0:
		var u: int = queue[0]
		for node in queue:
			if dist[node] < dist[u]:
				u = node
		queue.erase(u)
		if dist[u] == INF:
			break
		for edge in adjacency[u]:
			var v: int = edge["to"]
			var alt: float = dist[u] + edge["weight"]
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
	return { "dist": dist, "prev": prev }
func reconstruct_path(prev: Dictionary, source: int, target: int) -> Array[int]:
	var path: Array[int] = []
	var u: int = target
	if prev.has(u) or u == source:
		while u != -1:
			path.insert(0, u)
			u = prev.get(u, -1)
	if path.size() > 0 and path[0] == source:
		return path
	return []
func kruskal() -> Array[Dictionary]:
	var mst: Array[Dictionary] = []
	var sorted_edges := edge_list.duplicate()
	sorted_edges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: 
		return a["weight"] < b["weight"]
	)
	var parent: Dictionary = {}
	for u in nodes:
		parent[u] = u
	var find_func = func(u: int, self_func: Callable) -> int:
		if parent[u] == u:
			return u
		parent[u] = self_func.call(parent[u], self_func)
		return parent[u]
	for edge in sorted_edges:
		var root_u = find_func.call(edge["from"], find_func)
		var root_v = find_func.call(edge["to"], find_func)
		if root_u != root_v:
			mst.append(edge)
			parent[root_u] = root_v
	return mst
func prim(start_node: int) -> Array[Dictionary]:
	var mst: Array[Dictionary] = []
	if not nodes.has(start_node):
		return mst
	var visited: Dictionary = {}
	visited[start_node] = true
	while visited.size() < nodes.size():
		var min_edge: Dictionary = {}
		var min_weight: float = INF
		for u in visited:
			for edge in adjacency[u]:
				var v: int = edge["to"]
				if not visited.has(v) and edge["weight"] < min_weight:
					min_weight = edge["weight"]
					min_edge = edge
		if min_weight == INF:
			break
		mst.append(min_edge)
		visited[min_edge["to"]] = true
	return mst
func ford_fulkerson(source: int, sink: int) -> Dictionary:
	var capacity: Dictionary = {}
	for u in nodes:
		capacity[u] = {}
		for v in nodes:
			capacity[u][v] = 0.0
	for edge in edge_list:
		capacity[edge["from"]][edge["to"]] += edge["weight"]
	var max_flow: float = 0.0
	var flow_log: Array[Dictionary] = []
	while true:
		var parent: Dictionary = {}
		var visited: Dictionary = {}
		var queue: Array[int] = [source]
		visited[source] = true
		parent[source] = -1
		var path_found: bool = false
		while queue.size() > 0:
			var u: int = queue.pop_front()
			if u == sink:
				path_found = true
				break
			for v in capacity[u]:
				if not visited.has(v) and capacity[u][v] > 0.0:
					visited[v] = true
					parent[v] = u
					queue.append(v)
		if not visited.has(sink):
			break
		var path_flow: float = INF
		var v: int = sink
		var current_path: Array[int] = []
		while v != source:
			current_path.insert(0, v)
			var u: int = parent[v]
			path_flow = min(path_flow, capacity[u][v])
			v = u
		current_path.insert(0, source)
		v = sink
		while v != source:
			var u: int = parent[v]
			capacity[u][v] -= path_flow
			capacity[v][u] += path_flow
			v = u
		max_flow += path_flow
		flow_log.append({
			"path": current_path,
			"bottleneck": path_flow
		})
	return { "max_flow": max_flow, "flow_log": flow_log }
