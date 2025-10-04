// Use this sketch to set up the THRESHOLD value in the main Arduino code
// #define THRESHOLD 400 // end lines sensors threshold

#define EOL_R_PIN A0  // End Of Line Right
#define EOL_L_PIN A1  // End Of Line Left

#define EOL_THRESHOLD_L 200  // End lines sensors threshold
#define EOL_THRESHOLD_R 200  // End lines sensors threshold

bool toggle_right = true;  // boolean to sens the RISING age of the phase encoder when the carriage going RIGHT
bool toggle_left = true;   // boolean to sens the RISING age of the phase encoder when the carriage going LEFT

void setup() {
  Serial.begin(115200);
}

void loop() {

  int right_end_off_line_sensor = analogRead(EOL_R_PIN);
  int left_end_off_line_sensor = analogRead(EOL_L_PIN);

  Serial.print(right_end_off_line_sensor);
  Serial.print("\t");
  Serial.println(left_end_off_line_sensor);

  // Test if the RIGHT end ligne sensor is passed
  if (right_end_off_line_sensor < EOL_THRESHOLD_R && toggle_right) {
    toggle_right = false;
    toggle_left = true;
    Serial.println("end_line_right");
    delay(5000);
  }

  // Test if the LEFT end ligne sensor is passed
  if (left_end_off_line_sensor > EOL_THRESHOLD_L && toggle_left) {
    toggle_left = false;
    toggle_right = true;
    Serial.println("end_line_left");
    delay(5000);
  }
}
