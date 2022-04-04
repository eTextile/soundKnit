
#include <Wire.h>

void setup() {
  Wire.begin();
  delay(500);
  
  Wire.beginTransmission(0x20);
  Wire.write(0xFF);
  Wire.endTransmission();

  Wire.beginTransmission(0x21);
  Wire.write(0x0);
  Wire.endTransmission();
}

void loop() {
  // put your main code here, to run repeatedly:

}
