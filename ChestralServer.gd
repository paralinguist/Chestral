extends Node2D


#Server listening port
const PORT = 8765

#Create the WebSocketServer instance
var _server = WebSocketServer.new()

var clients = {}

var players = []

var Musician = load("res://Musician.tscn")

#Some weird magic numbers in here - need to lock down the polygon geometry
func arrange_musicians():
	var radius = 350
	var sides = len(clients)
	if sides > 0:
		var angle = -1 * 360 / sides * 2.5
		var x = radius * cos(angle) + radius * 2.2
		var y = radius * sin(angle) + radius * 0.9
		#print(str(x) +','+ str(y))
		var line = 1
		for client_id in clients:
			var client = clients[client_id]
			client.reposition(x,y)
			x = radius * cos(angle + line * 2 * PI / sides) + radius * 2.2
			y = radius * sin(angle + line * 2 * PI / sides) + radius * 0.9
			line = line + 1
			#print(str(x) +','+ str(y))

func create_musician(name, instrument, id):
	var musician = Musician.instance()
	musician.train(name, instrument, id)
	add_child(musician)
	return musician

func _ready():
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	# This signal is emitted when not using the Multiplayer API every time a
	# full packet is received.
	# Alternatively, you could check get_peer(PEER_ID).get_available_packets()
	# in a loop for each connected peer.
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	if err != OK:
		print("Unable to start server")
		set_process(false)
	$Panel/LabelIPs.text = 'Server IP/s: '
	var ip
	for address in IP.get_local_addresses():
		if (address.split('.').size() == 4) and not (address.begins_with('169') or address.begins_with('127')):
			$Panel/LabelIPs.text += ' ( ' + address + ' ) '
	
func _connected(id, proto):
	# This is called when a new peer connects, "id" will be the assigned peer id,
	# "proto" will be the selected WebSocket sub-protocol (which is optional)
	var cnx = "Client %d connected with protocol: %s" % [id, proto]
	$Panel/LabelConnections.text = cnx

func _close_request(id, code, reason):
	# This is called when a client notifies that it wishes to close the connection,
	# providing a reason string and close code.
	var cnx = "Client %d disconnecting with code: %d, reason: %s" % [id, code, reason]
	$Panel/LabelConnections.text = cnx

func _disconnected(id, was_clean = false):
	# This is called when a client disconnects, "id" will be the one of the
	# disconnecting client, "was_clean" will tell you if the disconnection
	# was correctly notified by the remote peer before closing the socket.
	var cnx = "Client %d disconnected, clean: %s" % [id, str(was_clean)]
	$Panel/LabelConnections.text = cnx
	if id in clients:
		$Panel/MessageLog.text += clients[id].playername + ' has left the server.\n'
		remove_child(clients[id])
		clients.erase(id)
		players.remove(players.find(id))
		arrange_musicians()
	$Panel/MessageLog.scroll_vertical=INF

#Returns the id of the next muso in the circle. If last, returns first.
func get_adjacent(id):
	var adjacent = players.find(id) + 1
	if adjacent >= len(players):
		adjacent = 0
	return players[adjacent]

func _on_data(id):
	# Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
	# and not get_packet directly when not using the MultiplayerAPI.
	var pkt = _server.get_peer(id).get_packet()
	var incoming = pkt.get_string_from_utf8()
	var message = 'kay'
	$Panel/LabelStatus.text = incoming
	print("Got data from client %d: %s ... echoing" % [id, pkt.get_string_from_utf8()])
	#_server.get_peer(id).put_packet(pkt)
	if incoming.begins_with('||:'):
		clients[id] = create_musician(incoming.right(3), 'Violin', id)
		players.append(id)
		arrange_musicians()
		$Panel/MessageLog.text += incoming.right(3) + ' has entered the server.\n'
		$Panel/MessageLog.scroll_vertical=INF
		message = '||:' + str(id)
	else:
		if id in clients:
			$Panel/MessageLog.text += clients[id].playername + ': ' + incoming + "\n"
			$Panel/MessageLog.scroll_vertical=INF
		else:
			incoming = ''
	if incoming:
		_server.get_peer(id).put_packet(message.to_utf8())
		if incoming.begins_with('align|'):
			var align_value = int(incoming.right(6))
			#Should pass id so boss can calculate resonance/harmonics
			var align_done = $ChestralBoss.realign(align_value)
			$Panel/MessageLog.text += clients[id].playername + ' aligned: ' + str(align_done) + '\n'
		elif incoming.begins_with('aligm|'):
			var align_value = incoming.right(6)
			align_value = align_value.split('x')
			var align_mag = align_value[0]
			var times = align_value[1]
			var align_done = $ChestralBoss.realign(align_mag, times)
		elif incoming.begins_with('inter|'):
			var inter_value = int(incoming.right(6))
			clients[id].apply_int(inter_value)
		elif incoming.begins_with('adjin|'):
			var inter_value = int(incoming.right(6))
			clients[get_adjacent(id)].apply_int(inter_value)
		elif incoming.begins_with('sooth|'):
			var soothe_value = int(incoming.right(6))
			clients[get_adjacent(id)].apply_soothe(soothe_value, false)
		elif incoming.begins_with('reson|'):
			var reson_value = int(incoming.right(6))
			clients[get_adjacent(id)].apply_resonance(reson_value)
		elif incoming.begins_with('harmo|'):
			var harmo_value = int(incoming.right(6))
			clients[get_adjacent(id)].apply_harmonics(harmo_value)
		elif incoming.begins_with('sooae|'):
			var soothe_value = int(incoming.right(6))
			for client in clients:
				clients[client].apply_soothe(soothe_value, true)
		elif incoming.begins_with('avata|'):
			clients[id].set_avatar(incoming.right(6))
					
		$Panel/MessageLog.scroll_vertical=INF

func _process(delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()


func _on_Button_pressed():
	for client in clients:
		print('attempting to send to ' + str(client))
		if _server.get_peer(client):
			print('Yes, sending.')
			_server.get_peer(client).put_packet('YO!'.to_utf8())
		else:
			print("No sendy?")
