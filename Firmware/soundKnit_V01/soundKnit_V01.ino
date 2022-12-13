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
#define STITCHE_START_R       201      // 199

#define RIGHT_LEFT            0        //
#define LEFT_RIGHT            1        //

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

uint8_t byte_index = 0;                   // Index for incomming serial bytes
int16_t stitchPos = 0;                    // Carriage stitch position
uint8_t phaseEncoderCount = 0;            //
uint8_t solenoidesPos = 0;                //
boolean updateSolenoides = false;         //

#define  DEBUG;                           // serial DEBUGING

////////////////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(BAUDRATE);
  Wire.begin();
  pinMode(ENC_PIN_1, INPUT_PULLUP);
  pinMode(DIR_ENC_PIN, INPUT_PULLUP);
  pinMode(ENC_PIN_3, INPUT_PULLUP);
  attachInterrupt(0, stitches_ISR, RISING); // Interrupt 0 is associated to digital pin 2 (stitches encoder)
  pinMode(PIEZO_PIN, OUTPUT);
}

void loop() {
  switch (cariageDir) {
    case LEFT_RIGHT: // Carriage go LEFT to RIGHT
      // Start from the LEFT and look if LEFT end ligne sensor is passed
      if (analogRead(END_PIN_L) > THRESHOLD && toggel_left == true) {
        toggel_left = false;
        startLeft = true;
        stitchPos = STITCHE_START_L; // Set the stitch count to the left start position
        phaseEncoderCount = PHASE_ENCODER_MIN;
        #ifdef DEBUG
          Serial.printf("\nSTART_LEFT / stitchPos: %d", stitchPos);
        #endif
      }
      // Start from the LEFT and look if RIGHT end ligne sensor is passed
      // if the sensor is hited then ask to the computer to send the next array of values
      if (analogRead(END_PIN_R) > THRESHOLD && toggel_right == true) {
        toggel_right = false;
        startLeft = false;
        #ifdef DEBUG
          Serial.printf("\nSTOP_RIGHT / stitchPos: %d", stitchPos);
        #else
          Serial.write(HEADER);
        #endif
        byte_index = 0;
      }
      break;
    case RIGHT_LEFT: // Carriage go RIGHT to LEFT
      // Start from the RIGHT and look if the RIGHT end ligne sensor is passed
      if (analogRead(END_PIN_R) > THRESHOLD && toggel_right == false) {
        toggel_right = true;
        startRight = true;
        stitchPos = STITCHE_START_R; // Set the stitch count to the right start position
        phaseEncoderCount = PHASE_ENCODER_MAX;
        #ifdef DEBUG
          Serial.printf("\nSTART_RIGHT = %d", stitchPos);
        #endif
      }
      // Start from the RIGHT and look if the LEFT end ligne sensor is passed
      // if the sensor is hited then ask to the computer to send the next array of values
      if (analogRead(END_PIN_L) > THRESHOLD && toggel_left == false) {
        toggel_left = true;
        startRight = false;
        #ifdef DEBUG
          Serial.printf("\nSTOP_LEFT = %d", stitchPos);
        #else
          Serial.write(HEADER);
        #endif
        byte_index = 0;
      }
      break;
  }

  if (updateSolenoides) {
    updateSolenoides = false;
    switch (cariageDir) {
      case LEFT_RIGHT: // Carriage go LEFT to RIGHT
        if (solenoidesPos == 0) writeSolenoides();
        break;
      case RIGHT_LEFT: // Carriage go RIGHT to LEFT
        if (solenoidesPos == 6) writeSolenoides();
        break;
    }
  }
}

//////////////////////////////////////////////////////
void serialEvent() {
  static uint8_t byte_index = 0;                // Index for incomming serial bytes

  uint8_t inputValue = 0;
  uint8_t stitchBin_bitIndex = 0;
  uint8_t stitchBin_byteIndex = 0;

  if (Serial.available() > 0) {
    inputValue = Serial.read();
    if (inputValue != FOOTER) {
      serialData[byte_index] = inputValue;
      byte_index++;
    } else {
      for (uint8_t byteIndex = 0; byteIndex < STITCHES_BYTES; byteIndex++) {
        stitchBin_bitIndex = byteIndex % 8;
        if (serialData[byteIndex] == 1) {
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
  lastPhaseEncoderState = phaseEncoderState;
  phaseEncoderState = digitalRead(ENC_PIN_3);
  if (startLeft || startRight) {
    updatephaseEncoderCount();
    updateStitchPos();
    updateSolenoides = true;
    #ifdef DEBUG
      printOut();
    #endif
  }
}

inline void updatephaseEncoderCount() {
  if (phaseEncoderState != lastPhaseEncoderState) {
    switch (cariageDir) {
      case LEFT_RIGHT: // Carriage go LEFT to RIGHT
        if (phaseEncoderCount < PHASE_ENCODER_MAX) phaseEncoderCount++;
        break;
      case RIGHT_LEFT:
        if (phaseEncoderCount > PHASE_ENCODER_MIN) phaseEncoderCount--;
        break;
    }
  }
}

inline void updateStitchPos() {
  switch (cariageDir) {
    case LEFT_RIGHT: // Carriage go LEFT to RIGHT
      if (stitchPos < STITCHE_START_R) stitchPos++; // Increase stitch count
      break;
    case RIGHT_LEFT: // Carriage go RIHT to LEFT
      if (stitchPos > STITCHE_START_L) stitchPos--; // Decrease stitch count
      break;
  }
  solenoidesPos = (stitchPos % 8);
}

inline void writeSolenoides() {
  switch (cariageDir) {
    case LEFT_RIGHT: // Carriage go LEFT to RIGHT
    if (!phaseEncoderState) {
      Wire.beginTransmission(I2C_ADDR_SOL_1_8);
      Wire.write(stitchBin[phaseEncoderCount]);
      #ifdef DEBUG
        Serial.printf("\nWRITE_1_8 : %b", stitchBin[phaseEncoderCount]);
      #endif
    }
    else {
      Wire.beginTransmission(I2C_ADDR_SOL_9_16);
      Wire.write(stitchBin[phaseEncoderCount]);
      #ifdef DEBUG
        Serial.printf("\nWRITE_9_16 : %b", stitchBin[phaseEncoderCount]);
      #endif
    }      
    break;
    case RIGHT_LEFT: // Carriage go RIHT to LEFT
    if (!phaseEncoderState) {
      Wire.beginTransmission(I2C_ADDR_SOL_9_16);
      Wire.write(stitchBin[phaseEncoderCount]);
      #ifdef DEBUG
        Serial.printf("\nWRITE_9_16 : %b", stitchBin[phaseEncoderCount]);
      #endif
    } else {
      Wire.beginTransmission(I2C_ADDR_SOL_1_8);
      Wire.write(stitchBin[phaseEncoderCount]);
      #ifdef DEBUG
        Serial.printf("\nWRITE_1_8 : %b", stitchBin[phaseEncoderCount]);
      #endif
    }      
    break;
  }
  Wire.endTransmission();
}

// Print out DEBUGING values
inline void printOut() {
  Serial.printf("\nCariageDir: %d / PhaseEncoderState: %d / PhaseEncoderState: %d / PhaseEncoderCount: %d / StitchPos: %d / SolenoidesPos: %d ",
                cariageDir, phaseEncoderState, phaseEncoderState, phaseEncoderCount, stitchPos, solenoidesPos);
}
