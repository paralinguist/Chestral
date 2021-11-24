#include <Esplora.h>

void setup()
{
  Serial.begin(115200);
}

void loop()
{
  int up = Esplora.readButton(SWITCH_UP);
  int down = Esplora.readButton(SWITCH_DOWN);
  int left = Esplora.readButton(SWITCH_LEFT);
  int right = Esplora.readButton(SWITCH_RIGHT);
  int joybutton = Esplora.readJoystickSwitch();
  
  if(up == LOW)
  {
    Serial.print("avata|ryan_synth.png~");
    delay(500);
  }
  
  if(down == LOW)
  {
    Serial.print("inter|50~");
    delay(500);
  }

  if(left == LOW)
  {
    Serial.print("align|100~");
    delay(500);
  }

  if(right == LOW)
  {
    Serial.print("sooth|20~");
    delay(500);
  }

  if(joybutton == LOW)
  {
    Serial.print("quit~");
    delay(500);
  }
}
