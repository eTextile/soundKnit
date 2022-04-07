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
#define STITCHES_BYTES        25

//#define STITCHES_PIN        A4       // I2C hardhare / Connected to the IO expander
//#define CLOCK_PIN           A5       // I2C hardhare / Connected to the IO expander

// HARDWARE INPUT SYSTEM
#define ENC_PIN_1             2        // Encoder 1 - stitches encoder (interrupt driven) 
#define DIR_ENC_PIN           3        // Encoder 2 - cariageDir encoder
#define ENC_PIN_3             4        // Encoder 3 - phase encoder
#define END_PIN_R             A0       // End Of Line Right for analog in
#define END_PIN_L             A1       // end Of Line Left for analog in
#define PIEZO_PIN             9        // Not used
#define I2C_ADDR_SOL_1_8      0x20     // IO expander chip addres
#define I2C_ADDR_SOL_9_16     0x21     // IO expander chip addres

// SOFTWARE CONSTANTS
#define THRESHOLD             500      // End lines sensors threshold
#define STITCHE_START_L       1        // 1
#define STITCHE_START_R       199      // 199 
#define HEADER                64       //
#define FOOTER                255      //

boolean phaseEncoderState = false;     // Phase encoder state
boolean lastPhaseEncoderState = false; // Phase encoder last state
boolean cariageDir = false;            // Carriage direction　0:unknown　1:right　2:left
boolean toggel_right = true;           // boolean to sens the RISING age of the phase encoder when the carriage going RIGHT
boolean toggel_left = true;            // boolean to sens the RISING age of the phase encoder when the carriage going LEFT
boolean startLeft = false;
boolean startRight = false;

uint8_t serialData[STITCHES] = {0};       // One byte per stitch

uint8_t stitchBin[STITCHES_BYTES] = {     // One bit per stitch
  255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 
  255, 0, 255, 0, 255, 0, 255, 0, 255, 0,
  255, 0, 255, 0, 255
};

uint8_t byte_index = 0;                // Index for incomming serial bytes
int16_t stitchPos = 0;                  // Carriage stitch position
uint8_t phaseEncoderCount = 0;
uint8_t solenoidesPos = 0;
boolean updateSolenoides = false;
boolean DEBUG = false;                 // boolean for serial DEBUGING

////////////////////////////////////////////////////////////////////////////////
void setup() {

  Wire.begin();

  Serial.begin(BAUDRATE);

  pinMode(ENC_PIN_1, INPUT_PULLUP);
  pinMode(DIR_ENC_PIN, INPUT_PULLUP);
  pinMode(ENC_PIN_3, INPUT_PULLUP);

  attachInterrupt(0, stitches_ISR, RISING); // Interrupt 0 is associated to digital pin 2 (stitches encoder)
}

////////////////////////////////////////////////////////////////////////////////
void loop() {
  // Start from the LEFT and look if LEFT end lignes sensors is passed
  if (cariageDir && analogRead(END_PIN_L) > THRESHOLD && toggel_left == true) {
    toggel_left = false;
    startLeft = true;
    stitchPos = STITCHE_START_L; // Set the stitch count to absolut stitchPosition
    phaseEncoderCount = PHASE_ENCODER_MIN;
    if (DEBUG) Serial.println(), Serial.print(F("START_LEFT = ")), Serial.print(stitchPos);
  }
  // Start from the LEFT and hit the RIGHT end lignes sensors
  // if the sensor is hited then ask to the computer to send the next array of values
  if (cariageDir && analogRead(END_PIN_R) > THRESHOLD && toggel_right == true) {
    toggel_right = false;
    startLeft = false;
    if (DEBUG) Serial.println(), Serial.print(F("STOP_RIGHT = ")), Serial.print(stitchPos);
    if (!DEBUG) Serial.write(HEADER);
    byte_index = 0;
  }
  // Start from the RIGHT and look if the RIGHT end lignes sensors is passed
  if (!cariageDir && analogRead(END_PIN_R) > THRESHOLD && toggel_right == false) {
    toggel_right = true;
    startRight = true;
    stitchPos = STITCHE_START_R; // Set the stitch count to absolut stitchPosition
    phaseEncoderCount = PHASE_ENCODER_MAX;
    if (DEBUG) Serial.println(), Serial.print(F("START_RIGHT = ")), Serial.print(stitchPos);
  }
  // Start from the RIGHT and hit the LEFT end lignes sensors
  // if the sensor is hited then ask to the computer to send the next array of values
  if (!cariageDir && analogRead(END_PIN_L) > THRESHOLD && toggel_left == false) {
    toggel_left = true;
    startRight = false;
    if (DEBUG) Serial.println(), Serial.print(F("STOP_LEFT = ")), Serial.print(stitchPos);
    if (!DEBUG) Serial.write(HEADER);
    byte_index = 0;
  }
  if (updateSolenoides) {
    updateSolenoides = false;
    if (cariageDir && solenoidesPos == 0) {
      writeSolenoides();
    }
    if (!cariageDir && solenoidesPos == 6) {
      writeSolenoides();
    }
  }
}

//////////////////////////////////////////////////////
void serialEvent() {
  uint8_t inputValue = 0;
  if (Serial.available() > 0) {
    inputValue = Serial.read();
    if (inputValue != FOOTER) {
      serialData[byte_index] = inputValue;
      byte_index++;
    } else {
      for (uint8_t bytePos = 0; bytePos < STITCHES_BYTES; bytePos++) {
        for (uint8_t bitPos = 0; bitPos < 8; bitPos++) {
          uint8_t index = (bytePos * 8) + bitPos;
          if (serialData[index] == 1) {
            bitSet(stitchBin[bytePos], bitPos);
          } else {
            bitClear(stitchBin[bytePos], bitPos);
          }
        }
      }
    }
  }
}

void stitches_ISR() {
  cariageDir = digitalRead(DIR_ENC_PIN);
  lastPhaseEncoderState = phaseEncoderState;
  phaseEncoderState = digitalRead(ENC_PIN_3);
  if (startLeft || startRight) {
    updatephaseEncoderCount();
    updateStitchPos();
    updateSolenoides = true;
    if (DEBUG) printOut();
  }
}

inline void updatephaseEncoderCount () {
  if (phaseEncoderState != lastPhaseEncoderState) {
    // Carriage go LEFT to RIGHT
    if (cariageDir && phaseEncoderCount < PHASE_ENCODER_MAX) {
      phaseEncoderCount++;
    }
    // Carriage go RIHT to LEFT
    else if (!cariageDir && phaseEncoderCount > PHASE_ENCODER_MIN) {
      phaseEncoderCount--;
    }
  }
}

inline void updateStitchPos () {
  // Carriage go LEFT to RIGHT
  if (cariageDir && stitchPos < STITCHE_START_R) {
    stitchPos++; // increase stitch count
  }
  // Carriage go RIHT to LEFT
  else if (!cariageDir && stitchPos > STITCHE_START_L) {
    stitchPos--;
  }
  solenoidesPos = (stitchPos % 8);
}

inline void writeSolenoides() {
  if (cariageDir){
    if (!phaseEncoderState) {
      Wire.beginTransmission(I2C_ADDR_SOL_1_8);
      //Wire.write(0xFF);
      Wire.write(stitchBin[phaseEncoderCount]);
      if (DEBUG) Serial.println(), Serial.print(F("WRITE_1_8"));
    } else {
      Wire.beginTransmission(I2C_ADDR_SOL_9_16);
      //Wire.write(0xFF);
      Wire.write(stitchBin[phaseEncoderCount]);
      if (DEBUG) Serial.println(), Serial.print(F("WRITE_9_16"));
    }
  } else {
    if (!phaseEncoderState) {
      Wire.beginTransmission(I2C_ADDR_SOL_9_16);
      //Wire.write(0xFF);
      Wire.write(stitchBin[phaseEncoderCount]);
      if (DEBUG) Serial.println(), Serial.print(F("WRITE_1_8"));
    } else {
      Wire.beginTransmission(I2C_ADDR_SOL_1_8);
      //Wire.write(0xFF);
      Wire.write(stitchBin[phaseEncoderCount]);
      if (DEBUG) Serial.println(), Serial.print(F("WRITE_9_16"));
    }  
  }
  Wire.endTransmission();
}

// Print out DEBUGING values
inline void printOut() {
  Serial.println();
  Serial.print(F(" CariageDir: ")), Serial.print(cariageDir);
  Serial.print(F(" PhaseEncoderState: ")), Serial.print(phaseEncoderState);
  Serial.print(F(" phaseEncoderCount: ")), Serial.print(phaseEncoderCount);
  Serial.print(F(" StitchPos: ")), Serial.print(stitchPos);
  Serial.print(F(" SolenoidesPos: ")), Serial.print(solenoidesPos);
}
