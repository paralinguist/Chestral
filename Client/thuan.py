import random
import os
from english_words import english_words_lower_set
import lib_chestral

ip = '127.0.0.1'
port = 8765
name = 'xXZohanXx'

lib_chestral.connect(name, ip, port)
lib_chestral.send('avata|thuan_maracas.png')
message = ''
score = 0
har = 0
soo = 0
int = 0
loop = 0

while loop < 1:
  words = random.sample(english_words_lower_set, 3)

  print("Score:", score)
  print("Here:", words)
  choice = input("Type one word or allocate score: ")
  if choice in words:
    os.system('clear')
    print('legit!\n')
    score += len(choice)*10
    if len(choice) > 8:
      score = score+50
  elif choice == "Har":
    os.system('clear')
    har = score
    print("You allocated all your score to Harmonics.\nHarmonics:", har, "\n")
    lib_chestral.send(f'harmo|{har}')
    score = 0
  elif choice == "Soo":
    os.system('clear')
    soo = score
    print("You allocated all your score to Soothe.\nSoothe:", soo, "\n")
    lib_chestral.send(f'sooth|{soo}')
  elif choice == "Int":
    os.system('clear')
    int = score  
    print("You allocated all your score to Interrupt.\nInterrupt:", int, "\n")
    score = 0
    lib_chestral.send(f'inter|{int}')  
    score = 0
  elif choice == "Quit":
    break
  else:
    os.system('clear')
    print("typo!")
