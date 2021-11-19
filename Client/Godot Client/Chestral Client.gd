extends Node2D

const PORT: int = 8765

const URL: String = "ws://localhost:%s" % PORT

var client = WebSocketClient.new()

var server_id

func _ready() -> void:
    client.connect_to_url(URL)
    client.connect("connection_closed", self, "_closed")
    client.connect("connection_error", self, "_closed")
    client.connect("connection_established", self, "_connected")
    # This signal is emitted when not using the Multiplayer API every time
    # a full packet is received.
    # Alternatively, you could check get_peer(1).get_available_packets() in a loop.
    client.connect("data_received", self, "_on_data")


func _closed():
    $Panel/LogTextbox.text = 'Lost connection to server...'

func _process(_delta: float) -> void:
    client.poll()

func _on_data() -> void:
    var pkt = client.get_peer(1).get_packet()
    var incoming = pkt.get_string_from_utf8()
    print('Server says: ' + incoming)
    $Panel/LogTextbox.text = incoming
    
func _connected(protocol: String) -> void:
    var message = '||:GodotKid'
    var packet: PoolByteArray = message.to_utf8()
    client.get_peer(1).put_packet(packet)

func _on_Button_pressed():
    client.get_peer(1).put_packet('||:GodotKid'.to_utf8())
