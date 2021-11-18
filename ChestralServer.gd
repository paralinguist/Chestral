extends Node2D


#Server listening port
const PORT = 8765

#Create the WebSocketServer instance
var _server = WebSocketServer.new()

var clients = {}

var Musician = load("res://Musician.tscn")

func arrange_musicians():
	var radius = 300
	var sides = len(clients)
	if sides > 0:
		var angle = -1 * 360 / sides * 2.5
		var x = radius * cos(angle) + radius * 3
		var y = radius * sin(angle) + radius
		print(str(x) +','+ str(y))
		var line = 1
		for client_id in clients:
			var client = clients[client_id]
			client.reposition(x,y)
			x = radius * cos(angle + line * 2 * PI / sides) + radius * 3
			y = radius * sin(angle + line * 2 * PI / sides) + radius * 2
			line = line + 1
			print(str(x) +','+ str(y))

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
	$Panel/MessageLog.text += clients[id].playername + ' has left the server.\n'
	remove_child(clients[id])
	clients.erase(id)
	arrange_musicians()
	$Panel/MessageLog.scroll_vertical=INF

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
		arrange_musicians()
		$Panel/MessageLog.text += incoming.right(3) + ' has entered the server.\n'
		$Panel/MessageLog.scroll_vertical=INF
		message = '||:' + str(id)
	else:
		$Panel/MessageLog.text += clients[id].playername + ': ' + incoming + "\n"
		$Panel/MessageLog.scroll_vertical=INF
	if incoming:
		_server.get_peer(id).put_packet(message.to_utf8())
		if incoming.begins_with('align|'):
			var align_value = int(incoming.right(6))
			var damage_done = $ChestralBoss.realign(align_value)
			$Panel/MessageLog.text += clients[id].playername + ' did damage: ' + str(damage_done) + '\n'
		elif incoming.begins_with('inter|'):
			var inter_value = int(incoming.right(6))
			clients[id].apply_int(inter_value)
		elif incoming.begins_with('adjin|'):
			var inter_value = int(incoming.right(6))
			clients[id].apply_int(inter_value)
			#This should be a function - return an adjacent muso
			#Good GOD this code needs robust testing. It makes my skin crawl.
			#Maybe use an array referencing IDs when adding children instead?
			var next = false
			for client in clients:
				if next:
					clients[client].apply_int(inter_value)
				if id == client:
					next = true
			if !next:
				clients[clients.values().back()].apply_int(inter_value)
		elif incoming.begins_with('sooae|'):
			#Need to implement this as instant
			var soothe_value = int(incoming.right(6))
			for client in clients:
				clients[client].apply_soothe(soothe_value)
					
		$Panel/MessageLog.scroll_vertical=INF

func _process(delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()


func _on_Button_pressed():
	for client in clients:
		if _server.get_peer(client):
		  _server.get_peer(client).put_packet('YO!'.to_utf8())
		else:
		  print("No sendy?")
