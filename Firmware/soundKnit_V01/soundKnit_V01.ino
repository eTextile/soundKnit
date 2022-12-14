/*
  BROTHER KH-940
  2022 (c) maurin.box@gmail.com
  Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
*/

#include <Wire.h>

// HARDWARE CONSTANTS
#define BAUDRATE              115200   //
#define STITCHES              200      // Number of stitches
#define PHASE_ENCODER_MIN     0        //
#define PHASE_ENCODER_MAX     24       //
#define STITCHES_BYTES        25       // 25 x 8 = 200

// HARDWARE INPUT SYSTEM
#define ENC_PIN_1             2        // Encoder 1 - stitches encoder (interrupt driven)  (AYAB: ENC_PIN_A)
#define DIR_ENC_PIN           3        // Encoder 2 - cariageDir encoder (AYAB : ENC_PIN_B)
#define ENC_PIN_3             4        // Encoder 3 - phase encoder (AYAB: ENC_PIN_C)

#define EOL_R_PIN             A0       // End Of Line Right
#define EOL_L_PIN             A1       // End Of Line Left

#define PIEZO_PIN             9        // Not used
#define I2C_ADDR_SOL_1_8      0x20     // IO expander chip addres
#define I2C_ADDR_SOL_9_16     0x21     // IO expander chip addres

// SOFTWARE CONSTANTS
#define THRESHOLD             400      // End lines sensors threshold

#define STITCHE_START_L       -1       // 1
#define STITCHE_START_R       200      // 199

#define GO_RIGHT              0        //
#define GO_LEFT               1        //

#define CHUNK_0_7             0
#define CHUNK_8_15            1

#define HEADER                64       //
#define FOOTER                255      //

#define BIP_TIME              100

boolean phaseEncoderState = false;     // Phase encoder state
boolean lastPhaseEncoderState = false; // Phase encoder last state
boolean cariageDir = false;            // Carriage direction　0:unknown　1:right　2:left

boolean toggel_right = true;           // boolean to sens the RISING age of the phase encoder when the carriage going RIGHT
boolean toggel_left = true;            // boolean to sens the RISING age of the phase encoder when the carriage going LEFT
boolean startRight = false;
boolean startLeft = false;

uint8_t serialData[STITCHES] = {0};       // One byte per stitch

uint8_t stitchBin[STITCHES_BYTES] = {     // One bit per stitch
  255, 0, 255, 0, 255, 0, 255, 0, 255, 0,
  255, 0, 255, 0, 255, 0, 255, 0, 255, 0,
  255, 0, 255, 0, 255
};

uint8_t byte_index = 0;                   // Index for incomming serial bytes
int16_t stitchPos = 0;                    // Carriage stitch position
uint8_t phaseEncoderCount = 0;            //
uint8_t solenoidesPos = 0;                //

uint8_t update_solenoides_chunc = 0;
boolean write_solenoides = false;         //

unsigned long int bip_timer = 0;

boolean debug_print = false;

//#define  DEBUG;                           // serial DEBUGING

////////////////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(BAUDRATE);
  Wire.begin();
  pinMode(ENC_PIN_1, INPUT_PULLUP);
  pinMode(DIR_ENC_PIN, INPUT_PULLUP);
  pinMode(ENC_PIN_3, INPUT_PULLUP);

  attachInterrupt(0, stitches_ISR, RISING); // Interrupt 0 is associated to digital pin 2 (stitches encoder)
  //attachInterrupt(0, stitches_ISR, CHANGE); // Interrupt 0 is associated to digital pin 2 (stitches encoder)

  pinMode(PIEZO_PIN, OUTPUT);
  digitalWrite(PIEZO_PIN, HIGH);
}

void loop() {
  switch (cariageDir) {
    case GO_LEFT: // Carriage go LEFT to RIGHT
      // Test if LEFT end ligne sensor is passed
      // if passed ...
      if (analogRead(EOL_L_PIN) > THRESHOLD && toggel_left == true) {
        toggel_left = false;
        startLeft = true;
        stitchPos = STITCHE_START_L; // Set the stitch count to the left start position
        phaseEncoderCount = PHASE_ENCODER_MIN;
        bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print("LEFT / START / stitchPos: ");
        Serial.print(stitchPos);
#endif
      }
      // Test if RIGHT end ligne sensor is passed
      // If passed then ask to the computer to send the next array of values
      if (analogRead(EOL_R_PIN) < THRESHOLD && toggel_right == true) {
        toggel_right = false;
        startLeft = false;
        byte_index = 0;
        bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print("RIGHT / STOP / stitchPos: ");
        Serial.print(stitchPos);
#else
        Serial.write(HEADER); // Data request!
#endif
      }
      break;

    case GO_RIGHT: // Carriage go RIGHT to LEFT
      // Test if the RIGHT end ligne sensor is passed
      // If passed set all default values
      if (analogRead(EOL_R_PIN) < THRESHOLD && toggel_right == false) {
        toggel_right = true;
        startRight = true;
        stitchPos = STITCHE_START_R; // Set the stitch count to the right start position
        phaseEncoderCount = PHASE_ENCODER_MAX;
        bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print("RIGHT / START / stitchPos: ");
        Serial.print(stitchPos);
#endif
      }
      // Test if the LEFT end ligne sensor is passed
      // If passed then ask to the computer to send the next array of values
      if (analogRead(EOL_L_PIN) > THRESHOLD && toggel_left == false) {
        toggel_left = true;
        startRight = false;
        byte_index = 0;
        bip_timer = millis();
#ifdef DEBUG
        Serial.println();
        Serial.print("LEFT / STOP / stitchPos: ");
        Serial.print(stitchPos);
#else
        Serial.write(HEADER); // Data request!
#endif
      }
      break;
  }
  writeSolenoides();
  make_bip();
  printOut();
}

//////////////////////////////////////////////////////
void serialEvent() {
  static uint8_t byte_index = 0; // Index for incomming serial bytes

  uint8_t inputValue = 0;
  uint8_t stitchBin_bitIndex = 0;
  uint8_t stitchBin_byteIndex = 0;

  if (Serial.available() > 0) {
    inputValue = Serial.read();
    if (inputValue != FOOTER) {
      serialData[byte_index] = inputValue;
      byte_index++;
    } else {
      for (uint8_t index = 0; index < STITCHES; index++) {
        stitchBin_bitIndex = index % 8;
        if (serialData[index] == 1) {
          bitSet(stitchBin[stitchBin_byteIndex], stitchBin_bitIndex);
        } else {
          bitClear(stitchBin[stitchBin_byteIndex], stitchBin_bitIndex);
        }
        if (stitchBin_bitIndex == 7) stitchBin_byteIndex++;
      }
      byte_index = 0;
    }
  }
}

void stitches_ISR() {
  cariageDir = digitalRead(DIR_ENC_PIN);
  //phaseEncoderState = digitalRead(ENC_PIN_3);
  if (startLeft || startRight) {
    updateStitchPos();
  }
}

inline void updateStitchPos() {
  switch (cariageDir) {
    case GO_RIGHT: // Carriage go RIHT to LEFT
      //if (stitchPos > STITCHE_START_L) stitchPos--; // Decrease stitch count
      stitchPos--; // Decrease stitch count
      solenoidesPos = (stitchPos % 16);
      if (solenoidesPos == 15) {
        phaseEncoderCount--;
        update_solenoides_chunc = CHUNK_0_7;
        write_solenoides = true;
      }
      else if (solenoidesPos == 8) {
        phaseEncoderCount--;
        update_solenoides_chunc = CHUNK_8_15;
        write_solenoides = true;
      }
      break;
    case GO_LEFT: // Carriage go LEFT to RIGHT
      //if (stitchPos < STITCHE_START_R) stitchPos++; // Increase stitch count
      stitchPos++; // Increase stitch count
      solenoidesPos = (stitchPos % 16);
      if (solenoidesPos == 0) {
        phaseEncoderCount++;
        update_solenoides_chunc = CHUNK_8_15;
        write_solenoides = true;
      }
      else if (solenoidesPos == 8) {
        phaseEncoderCount++;
        update_solenoides_chunc = CHUNK_0_7;
        write_solenoides = true;
      }
      break;
  }
}

inline void writeSolenoides() {
  if (write_solenoides) {
    switch (update_solenoides_chunc) {
      case CHUNK_0_7:
        Wire.beginTransmission(I2C_ADDR_SOL_1_8);
        Wire.write(stitchBin[phaseEncoderCount]);
#ifdef DEBUG
        Serial.println();
        Serial.print("WRITE_1_8: ");
        Serial.print(stitchBin[phaseEncoderCount], BIN);
#endif
        break;
      case CHUNK_8_15: // Carriage go RIHT to LEFT
        Wire.beginTransmission(I2C_ADDR_SOL_9_16);
        Wire.write(stitchBin[phaseEncoderCount]);
#ifdef DEBUG
        Serial.println();
        Serial.print("WRITE_9_16: ");
        Serial.print(stitchBin[phaseEncoderCount], BIN);
#endif
        break;
    }
  }
}

// Print out DEBUGING values
inline void printOut() {
#ifdef DEBUG
  if (debug_print) {
    debug_print = false;
    Serial.println();
    Serial.print(F("CariageDir: ")), Serial.print(cariageDir);
    Serial.print(F(" PE_State: ")), Serial.print(phaseEncoderState);
    Serial.print(F(" PE_Count: ")), Serial.print(phaseEncoderCount);
    Serial.print(F(" StitchPos: ")), Serial.print(stitchPos);
    Serial.print(F(" SolenoidesPos: ")), Serial.print(solenoidesPos);
  }
#endif
}

inline void make_bip() {
  if (millis() - bip_timer < BIP_TIME) {
    digitalWrite(PIEZO_PIN, LOW);
  }
  if (millis() - bip_timer > BIP_TIME) {
    digitalWrite(PIEZO_PIN, HIGH);
  }
}
