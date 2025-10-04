/*
  BROTHER KH-940 && KH-910
  2023- (c) maurin.box@etextile.org
  Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
*/

#include <Wire.h>

// HARDWARE CONSTANTS
#define LED_PIN_A 5        // green LED
#define LED_PIN_B 6        // yellow LED
#define PIEZO_PIN 9        //
#define STITCHE_ENC_PIN 2  // Encoder 1 - stitches encoder (interrupt driven)  (AYAB: ENC_PIN_A)
#define DIR_ENC_PIN 3      // Encoder 2 - cariage_dir encoder (AYAB : ENC_PIN_B)
#define PHASE_ENC_PIN 4    // Encoder 3 - phase encoder (AYAB: ENC_PIN_C)
#define EOL_R_PIN A0       // End Of Line Right
#define EOL_L_PIN A1       // End Of Line Left

#define I2C_ADDR_SOL_0_7 0x21   // IO expander chip addres
#define I2C_ADDR_SOL_8_15 0x20  // IO expander chip addres

// SOFTWARE CONSTANTS
#define BAUDRATE 115200
#define STITCHES 200             // Number of stitches
#define STITCHES_BYTES (25 + 1)  // 25 x 8 = 200 (+1 to avode overflowing)

#define STITCHES_START_L -1
#define STITCHES_START_R 200

#define PHASE_ENCODER_START_L -3
#define PHASE_ENCODER_START_R 26

#define EOL_THRESHOLD_R 200  // End of lines sensors threshold value
#define EOL_THRESHOLD_L 200  // End of lines sensors threshold value

#define HEADER 64
#define FOOTER 33

#define BIP_TIME 80

const uint8_t reverse[256] PROGMEM = {
  0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
  0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
  0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
  0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
  0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
  0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
  0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
  0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
  0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
  0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
  0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
  0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
  0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
  0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
  0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
  0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
};

typedef enum cariage_status_code_e {
  GOING_RIGHT,
  GOING_LEFT,
  UNKNOWN
} cariage_status_code_t;

cariage_status_code_t cariage_dir = UNKNOWN;

typedef enum solenoides_status_code_e {
  CHUNK_0_7,
  CHUNK_8_15,
  WRITE_DONE
} solenoides_status_code_t;

solenoides_status_code_t update_solenoides_chunc = WRITE_DONE;

typedef enum eol_status_code_e {
  START,
  STOP
} eol_status_code_t;

eol_status_code_t going_right = STOP;
eol_status_code_t going_left = STOP;

uint8_t serial_data[STITCHES] = { 0 };
uint8_t stitch_bit_array[STITCHES] = { 0 };         // 200 stitchs
uint8_t stitch_byte_array[STITCHES_BYTES] = { 0 };  // Eight stitchs per byte

int16_t stitch_pos = NULL;  // Carriage stitch position

bool phase_encoder_state = false;
bool last_phase_encoder_state = true;

int8_t phase_encoder_pos = 0;  //
//int8_t solenoide_pos = 0;    //

boolean led_state_A = true;
boolean led_state_B = false;

unsigned long int bip_timer = 0;

//boolean print_out = false;
//#define DEBUG ;  // Print significantes values to the serial port

////////////////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(BAUDRATE);
  Wire.begin();

  pinMode(STITCHE_ENC_PIN, INPUT_PULLUP);
  pinMode(DIR_ENC_PIN, INPUT_PULLUP);
  pinMode(PHASE_ENC_PIN, INPUT_PULLUP);

  // THIS SHOULD BE ON ENCODERS !?
  attachInterrupt(digitalPinToInterrupt(STITCHE_ENC_PIN), stitches_ISR, RISING);  // Interrupt 0 is associated to digital pin 2 (stitches encoder)

  pinMode(LED_PIN_A, OUTPUT);
  pinMode(LED_PIN_B, OUTPUT);

  digitalWrite(LED_PIN_A, led_state_A);
  digitalWrite(LED_PIN_B, led_state_B);

  pinMode(PIEZO_PIN, OUTPUT);
  digitalWrite(PIEZO_PIN, HIGH);
}

void loop() {
  update_knitter();
  write_solenoides();
  make_bip();
#ifdef DEBUG
  print_all_sensors();
#endif
}

//////////////////////////////////////////////////////
void serialEvent() {

  static uint8_t serial_byte_index = 0;  // Index for serial incomming bytes

  if (Serial.available() > 0) {
    uint8_t input_value = Serial.read();
    if (input_value != FOOTER) {
      if(serial_byte_index < STITCHES) {
        serial_data[serial_byte_index] = input_value;
        serial_byte_index++;
      }
    } else {
      // Center the recived image in the stitch_bit_array[200]
      uint8_t stitch_byte_offset = (uint8_t)((STITCHES - serial_byte_index) / 2);
      for (uint8_t byte_index = 0; byte_index < serial_byte_index; byte_index++) {
        stitch_bit_array[stitch_byte_offset + byte_index] = serial_data[byte_index];
      }

      // Concatanate stitch_bit_array[200] into stitch_byte_array[25]
      uint8_t stitch_byte_index = 0;
      uint8_t stitch_bit_index = 0;
      for (uint8_t stitch_index = 0; stitch_index < STITCHES; stitch_index++) {
        stitch_bit_index = stitch_index % 8;
        if (stitch_bit_array[stitch_index] == 1) {
          bitSet(stitch_byte_array[stitch_byte_index], stitch_bit_index);
        } else {
          bitClear(stitch_byte_array[stitch_byte_index], stitch_bit_index);
        }
        if (stitch_bit_index == 7) stitch_byte_index++;
      }
      
      serial_byte_index = 0;
      led_state_A = !led_state_A;
      digitalWrite(LED_PIN_A, led_state_A);
      led_state_B = !led_state_B;
      digitalWrite(LED_PIN_B, led_state_B);
      bip_timer = millis();
    }
  }
}

inline void update_knitter() {
  switch (cariage_dir) {

    case GOING_RIGHT:  // Carriage going LEFT to RIGHT
      // Test if the LEFT end of ligne sensor is passed
      if (analogRead(EOL_L_PIN) > EOL_THRESHOLD_L && going_right == STOP) {
        going_right = START;
        stitch_pos = STITCHES_START_L;
        phase_encoder_pos = PHASE_ENCODER_START_L;
        //bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print(F("LEFT / START / stitch_pos: ")), Serial.print(stitch_pos);
#endif
      }
      // Test if the RIGHT end of ligne sensor is passed
      // If passed: request new row values
      if (analogRead(EOL_R_PIN) < EOL_THRESHOLD_R && going_right == START) {
        going_right = STOP;
        //bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print(F("RIGHT / STOP / stitch_pos: ")), Serial.print(stitch_pos);
#else
        Serial.write(HEADER);  // Data request!
#endif
      }
      break;

    case GOING_LEFT:  // Carriage gogin RIGHT to LEFT
      // Test if RIGHT end of ligne sensor is passed
      if (analogRead(EOL_R_PIN) < EOL_THRESHOLD_R && going_left == STOP) {
        going_left = START;
        stitch_pos = STITCHES_START_R;
        phase_encoder_pos = PHASE_ENCODER_START_R;
        //bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print(F("RIGHT / START / stitch_pos: ")), Serial.print(stitch_pos);
#endif
      }
      // Test if LEFT end of ligne sensor is passed
      // If passed: request new row values
      if (analogRead(EOL_L_PIN) > EOL_THRESHOLD_L && going_left == START) {
        going_left = STOP;
        //bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print(F("LEFT / STOP / stitch_pos: ")), Serial.print(stitch_pos);
#else
        Serial.write(HEADER);  // Data request!
#endif
      }
      break;
  }
}

void stitches_ISR() {

  if (digitalRead(DIR_ENC_PIN)) {
    cariage_dir = GOING_RIGHT;
  } else {
    cariage_dir = GOING_LEFT;
  }

  update_phase_encoder_pos();

  /*
  if (going_right == START || going_left == START) {
    update_stitch_pos();
  }
  */
}

inline void update_phase_encoder_pos() {

  last_phase_encoder_state = phase_encoder_state;
  phase_encoder_state = digitalRead(PHASE_ENC_PIN);

  switch (cariage_dir) {
    case GOING_RIGHT:
      if (!last_phase_encoder_state && phase_encoder_state) {  // Rising
        update_solenoides_chunc = CHUNK_0_7;
        phase_encoder_pos++;
        //print_out = true;
      } else if (last_phase_encoder_state && !phase_encoder_state) {  // Falling
        update_solenoides_chunc = CHUNK_8_15;
        phase_encoder_pos++;
        //print_out = true;
      }
      break;
    case GOING_LEFT:
      if (!last_phase_encoder_state && phase_encoder_state) {  // Rising
        update_solenoides_chunc = CHUNK_8_15;
        phase_encoder_pos--;
        //print_out = true;
      } else if (last_phase_encoder_state && !phase_encoder_state) {  // Falling
        update_solenoides_chunc = CHUNK_0_7;
        phase_encoder_pos--;
        //print_out = true;
      }
      break;
  }
}

/*
inline void update_stitch_pos() {
  switch (cariage_dir) {
    case GOING_RIGHT:  // Carriage going LEFT to RIGHT
      if (going_right == START) {
        stitch_pos++;
      }
      break;
    case GOING_LEFT:  // Carriage going RIGHT to LEFT
      if (going_left == START) {
        stitch_pos--;
      }
      break;
  }
  //print_out = true;
}
*/

inline void write_solenoides() {
  switch (update_solenoides_chunc) {
    case CHUNK_0_7:
      if (phase_encoder_pos >= PHASE_ENCODER_START_L && phase_encoder_pos < PHASE_ENCODER_START_R) {
        Wire.beginTransmission(I2C_ADDR_SOL_0_7);
        Wire.write(reverse[stitch_byte_array[phase_encoder_pos]]);
        Wire.endTransmission();
        update_solenoides_chunc = WRITE_DONE;
#ifdef DEBUG
        Serial.println();
        Serial.print(F("Phase_encoder_pos: ")), Serial.print(phase_encoder_pos);
        Serial.print(F(" - write to 0_7: 0x")), Serial.print(serial_data[phase_encoder_pos], HEX);
#endif
      }
      break;
    case CHUNK_8_15:
      if (phase_encoder_pos >= PHASE_ENCODER_START_L && phase_encoder_pos < PHASE_ENCODER_START_R) {
        Wire.beginTransmission(I2C_ADDR_SOL_8_15);
        Wire.write(reverse[stitch_byte_array[phase_encoder_pos]]);
        Wire.endTransmission();
        update_solenoides_chunc = WRITE_DONE;
#ifdef DEBUG
        Serial.println();
        Serial.print(F("Phase_encoder_pos: ")), Serial.print(phase_encoder_pos);
        Serial.print(F(" - write to 8_15: 0x")), Serial.print(serial_data[phase_encoder_pos], HEX);
#endif
      }
      break;
    case WRITE_DONE:
      // Nothing to do
      break;
  }
}

/*
// Print out DEBUGING values
inline void print_all_sensors() {
  if (print_out) {
    print_out = false;
    Serial.println();
    Serial.print(F("cariage_dir: ")), Serial.print(get_dir_name(cariage_dir));
    Serial.print(F("\tPE_pos: ")), Serial.print(phase_encoder_pos);
    Serial.print(F(" ST_pos: ")), Serial.print(stitch_pos);
    //Serial.print(F(" solenoide_pos: ")), Serial.print(solenoide_pos);
  }
}
*/

inline void make_bip() {
  if (millis() - bip_timer < BIP_TIME) {
    digitalWrite(PIEZO_PIN, LOW);
  } else if (millis() - bip_timer > BIP_TIME) {
    digitalWrite(PIEZO_PIN, HIGH);
  }
}

const char* get_dir_name(cariage_status_code_t code) {
  const char* char_code = NULL;
  switch (code) {
    case GOING_RIGHT: char_code = "GOING_RIGHT"; break;
    case GOING_LEFT: char_code = "GOING_LEFT"; break;
  }
  return char_code;
};
