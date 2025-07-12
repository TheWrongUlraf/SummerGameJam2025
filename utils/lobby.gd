# autoload as Lobby

extends Node

const TEST_SERVER_IP = "192.168.1.221"
const SERVER_PORT = 8021
const MAX_ALLOWED_CLIENTS = 10

func _ready():
	print("Initializing the networking")
	var ip = _get_ip()
	print("Our IP is ", ip)
	
	var is_server = OS.get_cmdline_args().has("-server")

	if is_server:
		print("We think we are the server")
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(SERVER_PORT, MAX_ALLOWED_CLIENTS)
		multiplayer.multiplayer_peer = peer
	else:
		print("We think we are a client")
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(TEST_SERVER_IP, SERVER_PORT)
		multiplayer.multiplayer_peer = peer

func _get_ip():
	for ip in IP.get_local_addresses():
		# ipv4 localhost
		if ip == "127.0.0.1":
			continue
		# ipv6 localhost
		if ip == "0:0:0:0:0:0:0:1":
			continue
		# skip any ipv6
		if ip.contains(":"):
			continue

		return ip
