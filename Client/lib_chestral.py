from websocket import create_connection
import threading
import asyncio

active = True
server_message = ''

#variables from server:
#encounter_state (WAITING, IN_PROGRESS, ENDED_FAIL, ENDED_WIN, UDEAD)
#boss_balance (integer - balance remaining)
#num_musos (integer - how many musos are connected)
#muso_list (list - from json - of muso dicts)


#Listener thread receives responses from the server
#It writes to global variables for access via other functions
def listener(server):
  global server_message
  while active:
    server_message = server.recv()
    print(server_message, end='\n> ')

def send(message):
  global server
  server.send(message)

def disconnect():
  global server
  global active
  active = False
  server.close()

#Usernames are sent using ||: as a delimiter
#For robustness in future, should be base64 encoded or similar
def connect(name, ip, port=8765):
  global server
  server = create_connection(f'ws://{ip}:{port}')
  server.send(f'||:{name}')
  conn_id = server.recv()
  print(conn_id)
  message = ''
  listener_thread = threading.Thread(target = listener, args=(server,))
  listener_thread.start()
