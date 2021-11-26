extends Node2D


#Server listening port
const PORT = 8765

#Create the WebSocketServer instance
var _server = WebSocketServer.new()

var clients = {}
var players = []

var Musician = load("res://Musician.tscn")

var rng : RandomNumberGenerator = RandomNumberGenerator.new()


const WAITING: int = 0
const IN_PROGRESS: int = 1
const ENDED_FAIL: int = 2
const ENDED_WIN: int = 3


var state: int = 0

#Some weird magic numbers in here - need to lock down the polygon geometry
func arrange_musicians():
    var radius = 500
    var sides = len(clients)
    var center = Vector2(800, 500)
    var count: int = 0
    for client_id in clients:
        var client = clients[client_id]
        var angle = count * (TAU/sides) - TAU/4
        var new_position = center + radius * Vector2(cos(angle), sin(angle)*0.65)
        client.reposition(new_position.x, new_position.y, angle)
        count += 1

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
    $CanvasLayer/Panel/LabelIPs.text = 'Server IP/s: '
    var ip
    for address in IP.get_local_addresses():
        if (address.split('.').size() == 4) and not (address.begins_with('169') or address.begins_with('127')):
            $CanvasLayer/Panel/LabelIPs.text += ' ( ' + address + ' ) '
    
    rng.randomize()
    
func _connected(id, proto):
    # This is called when a new peer connects, "id" will be the assigned peer id,
    # "proto" will be the selected WebSocket sub-protocol (which is optional)
    var cnx = "Client %d connected with protocol: %s" % [id, proto]
    $CanvasLayer/Panel/LabelConnections.text = cnx

func _close_request(id, code, reason):
    # This is called when a client notifies that it wishes to close the connection,
    # providing a reason string and close code.
    var cnx = "Client %d disconnecting with code: %d, reason: %s" % [id, code, reason]
    $CanvasLayer/Panel/LabelConnections.text = cnx

func _disconnected(id, was_clean = false):
    # This is called when a client disconnects, "id" will be the one of the
    # disconnecting client, "was_clean" will tell you if the disconnection
    # was correctly notified by the remote peer before closing the socket.
    var cnx = "Client %d disconnected, clean: %s" % [id, str(was_clean)]
    $CanvasLayer/Panel/LabelConnections.text = cnx
    if id in clients:
        $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ' has left the server.\n'
        remove_child(clients[id])
        clients.erase(id)
        players.remove(players.find(id))
        arrange_musicians()
    $CanvasLayer/Panel/MessageLog.scroll_vertical=INF

#Returns the id of the next muso in the circle. If last, returns first.
func get_adjacent(id):
    var adjacent = players.find(id) + 1
    if adjacent >= len(players):
        adjacent = 0
    return players[adjacent]

func send_all_client_data(id):
    var client_states = {}
    for client in clients:
        client_states[client] = clients[client].get_state()
    var client_states_string = 'allcli|' + JSON.print(client_states)
    _server.get_peer(id).put_packet(client_states_string.to_utf8())
        

func _on_data(id):
    # Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
    # and not get_packet directly when not using the MultiplayerAPI.
    var pkt = _server.get_peer(id).get_packet()
    var incoming = pkt.get_string_from_utf8()
    var message = 'kay'
    $CanvasLayer/Panel/LabelStatus.text = incoming
    print("Got data from client %d: %s ... echoing" % [id, pkt.get_string_from_utf8()])
    #_server.get_peer(id).put_packet(pkt)
    if incoming.begins_with('||:'):
        if clients.has(id):
            clients[id].rename(incoming.right(3))
        elif state != 1:
            clients[id] = create_musician(incoming.right(3), 'Violin', id)
            players.append(id)
            arrange_musicians()
            $CanvasLayer/Panel/MessageLog.text += incoming.right(3) + ' has entered the server.\n'
            $CanvasLayer/Panel/MessageLog.scroll_vertical=INF
            message = '||:' + str(id)
    else:
        if id in clients:
            $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ': ' + incoming + "\n"
            $CanvasLayer/Panel/MessageLog.scroll_vertical=INF
        else:
            incoming = ''
    if state == WAITING and incoming:
        if incoming.begins_with('start|'):
            state = IN_PROGRESS
    if incoming and state == IN_PROGRESS:
        _server.get_peer(id).put_packet(message.to_utf8())
        if incoming.begins_with('align|'):
            var align_value = int(incoming.right(6))
            #Should pass id so boss can calculate resonance/harmonics
            var align_done = $ChestralBoss.realign(align_value)
            $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ' aligned: ' + str(align_done) + '\n'
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
        elif incoming.begins_with('speak|'):
            clients[id].talk(incoming.right(6))
        elif incoming.begins_with('maest|'):
            send_all_client_data(id)

        $CanvasLayer/Panel/MessageLog.scroll_vertical=INF

func _process(delta):
    # Call this in _process or _physics_process.
    # Data transfer, and signals emission will only happen when calling this function.
    _server.poll()


func _on_ServerDataPulse_timeout():
    for client in clients:
        var client_state = 'state|' + JSON.print(clients[client].get_state())
        _server.get_peer(client).put_packet(client_state.to_utf8())

#Debugging tools
func _on_Button_pressed():
    if state == WAITING:
        var victim = clients[players[randi() % players.size()]]
        var dissonance = rng.randi_range(10,50)
        print('Squarked at ' + victim.playername + ' for: ' + str(victim.irritate(dissonance)))

func _on_Unbalance_pressed():
    state = IN_PROGRESS
    $ChestralBoss.realign(2000)
