extends Node2D


#Server listening port
const PORT = 8765

#Create the WebSocketServer instance
var _server = WebSocketServer.new()

var clients = {}
var players = []
var dead_players = []

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

#Consumes buffs, applies them to the alignment or alignment multi and sends through to the boss
func perform_alignments(align, times, id):
    var client = clients[id]
    align = align + int((float(client.resonance) / 100.00 * align))
    client.set_resonance(0, false)
    align = align + client.harmonics
    client.set_harmonics(0, false)
    var align_effect = 0
    for _i in range(times):
        align_effect = $ChestralBoss.realign(align)
        $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ' aligned: ' + str(align_effect) + '\n'

func _on_data(id):
    # Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
    # and not get_packet directly when not using the MultiplayerAPI.
    var pkt = _server.get_peer(id).get_packet()
    var incoming = pkt.get_string_from_utf8()
    var message = 'kay'
    $CanvasLayer/Panel/LabelStatus.text = incoming
    #print("Got data from client %d: %s ... echoing" % [id, pkt.get_string_from_utf8()])
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
    if incoming.begins_with('speak|'):
            clients[id].talk(incoming.right(6))
    if state == WAITING and incoming:
        if incoming.begins_with('start|'):
            state = IN_PROGRESS
        elif incoming.begins_with('avata|'):
            clients[id].set_avatar(incoming.right(6))
    if incoming and state == IN_PROGRESS:
        if dead_players.has(clients[id]):
            return
        _server.get_peer(id).put_packet(message.to_utf8())
        if incoming.begins_with('align|'):
            var align_value = int(incoming.right(6))
            perform_alignments(align_value, 1, id)
            clients[id].get_node("AudioStreamPlayer").play()
            $ChestralBoss.get_attacked(clients[get_adjacent(id)].global_position)
        elif incoming.begins_with('aligm|'):
            var align_value = incoming.right(6)
            align_value = align_value.split('x')
            clients[id].get_node("AudioStreamPlayer").play()
            if len(align_value) == 2:
                var align_mag = int(align_value[0])
                var times = int(align_value[1])
                perform_alignments(align_mag,times,id)
                for i in times:
                    clients[get_adjacent(id)].send_attack($ChestralBoss.global_position)
                    for j in range(6):
                        yield(get_tree(), "idle_frame")
            else:
                $CanvasLayer/Panel/LabelStatus.text = 'Incorrect align multi command'
            #Should animate music notes here - from player to boss
        elif incoming.begins_with('inter|'):
            var inter_value = int(incoming.right(6))
            clients[id].set_interference(inter_value)
        elif incoming.begins_with('adjin|'):
            var inter_value = int(incoming.right(6))
            clients[get_adjacent(id)].set_interference(inter_value)
        elif incoming.begins_with('sooth|'):
            var soothe_value = int(incoming.right(6))
            clients[get_adjacent(id)].set_soothe(soothe_value)
        elif incoming.begins_with('reson|'):
            var reson_value = int(incoming.right(6))
            clients[get_adjacent(id)].set_resonance(reson_value)
        elif incoming.begins_with('harmo|'):
            var harmo_value = int(incoming.right(6))
            clients[get_adjacent(id)].set_harmonics(harmo_value)
        elif incoming.begins_with('sooae|'):
            var soothe_value = int(incoming.right(6))
            for client in clients:
                clients[client].set_soothe(soothe_value, false, false, true)
        elif incoming.begins_with('maest|'):
            send_all_client_data(id)
        elif incoming.begins_with('sh') and incoming[5] == '|':
            var command = incoming.left(5)
            var ids = incoming.right(6)
            ids = ids.split('|')
            if len(ids) == 2:
                var source = clients[int(ids[0])]
                var destination = clients[int(ids[1])]
                if dead_players.has(destination):
                    pass
                elif command == 'shint':
                    var interference = source.interference
                    source.set_interference(0, false)
                    destination.set_interference(interference, true)
                elif command == 'shsoo':
                    var soothe = source.soothe
                    source.set_soothe(0, false)
                    destination.set_soothe(soothe, true)
                elif command == 'shres':
                    var resonance = source.resonance
                    source.set_resonance(0, false)
                    destination.set_resonance(resonance, true)
                elif command == 'shhar':
                    var harmonics = source.harmonics
                    source.set_harmonics(0, false)
                    destination.set_harmonics(harmonics, true)
            else:
                $CanvasLayer/Panel/LabelStatus.text = 'Improper Maestro shift command'

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
    if state == IN_PROGRESS:
        var victim = clients[players[randi() % players.size()]]
        var dissonance = rng.randi_range(10,50)
        print('Squarked at ' + victim.playername + ' for: ' + str(victim.irritate(dissonance)))


#ie start game :P
func _on_Unbalance_pressed():
    if state == WAITING:
        state = IN_PROGRESS
        $ChestralBoss.start_attack_cycle()
    elif state != IN_PROGRESS:
        new_game()


func kill_player(pl):
    dead_players.append(pl)
    if len(dead_players) == len(players):
        state = ENDED_FAIL
        $ChestralBoss.talk("SCRAWWKKKK")
        $ChestralBoss.targetting = false

func new_game():
    state = WAITING
    $ChestralBoss.queue_free()
    dead_players = []
    for id in clients:
        clients[id].current_irritation = 0
        clients[id].interference = 0
        clients[id].soothe = 0
        clients[id].harmonics = 0
        clients[id].dead = false
        clients[id].get_node("AnimationPlayer").play("RESET")
    yield(get_tree(), "idle_frame")
    add_child(load("res://ChestralBoss.tscn").instance())
    $ChestralBoss.position = Vector2(800, 500)
