import lib_chestral

ip = '127.0.0.1'
port = 8765
name = 'MrIhlein'

lib_chestral.connect(name, ip, port)

message = ''

while message != 'quit':
  message = input('> ')
  if message == 'print':
    print(f'My ID: {lib_chestral.connection_id}')
  else:
    lib_chestral.send(message)

lib_chestral.disconnect()
