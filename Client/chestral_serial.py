import lib_chestral
import serial

ip = '127.0.0.1'
port = 8765
name = 'Me Except Arduino'

#This will vary based on OS and hardware.
#"Universal" Serial Bus indeed
#serial_address = "/dev/tty.usbmodem14102"
serial_address = 'COM6'
baud = 115200

device = serial.Serial(serial_address)
device.baudrate = baud

lib_chestral.connect(name, ip, port)

message = ''

while message != 'quit':
  if (device.inWaiting()>0):
    char = device.read().decode()
    if char == '~':
      lib_chestral.send(message)
      if message != 'quit':
        message = ''
    else:
      message += char

lib_chestral.disconnect()
