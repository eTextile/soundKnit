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
#define EOL_R_PIN             A0       // End Of Line Right for analog in
#define EOL_L_PIN             A1       // end Of Line Left for analog in
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
      // Test if LEFT end ligne sensor is passed
      // if passed ...
      if (analogRead(EOL_L_PIN) > THRESHOLD && toggel_left == true) {
        toggel_left = false;
        startLeft = true;
        stitchPos = STITCHE_START_L; // Set the stitch count to the left start position
        phaseEncoderCount = PHASE_ENCODER_MIN;
        blip();
        #ifdef DEBUG
          Serial.println();
          Serial.print("LEFT / START / stitchPos: " + stitchPos);
        #endif
      }
      // Test if RIGHT end ligne sensor is passed
      // If passed then ask to the computer to send the next array of values
      if (analogRead(EOL_R_PIN) > THRESHOLD && toggel_right == true) {
        toggel_right = false;
        startLeft = false;
        byte_index = 0;
        blip();
        #ifdef DEBUG
          Serial.println();
          Serial.print("RIGHT / STOP / stitchPos: " + stitchPos);
        #else
          Serial.write(HEADER); // Data request!
        #endif
      }
      break;
    case RIGHT_LEFT: // Carriage go RIGHT to LEFT
      // Test if the RIGHT end ligne sensor is passed
      // if passed set all default values 
      if (analogRead(EOL_R_PIN) > THRESHOLD && toggel_right == false) {
        toggel_right = true;
        startRight = true;
        stitchPos = STITCHE_START_R; // Set the stitch count to the right start position
        phaseEncoderCount = PHASE_ENCODER_MAX;
        blip();
        #ifdef DEBUG
          Serial.println();
          Serial.print("RIGHT / START / stitchPos: " + stitchPos);
        #endif
      }
      // Test if the LEFT end ligne sensor is passed
      // if passed then ask to the computer to send the next array of values
      if (analogRead(EOL_L_PIN) > THRESHOLD && toggel_left == false) {
        toggel_left = true;
        startRight = false;
        byte_index = 0;
        blip();
        #ifdef DEBUG
          Serial.println();
          Serial.print("LEFT / STOP / stitchPos: " + stitchPos);
        #else
          Serial.write(HEADER); // Data request!
        #endif
      }
      break;
  }

  writeSolenoides();
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
  lastPhaseEncoderState = phaseEncoderState;
  phaseEncoderState = digitalRead(ENC_PIN_3);
  if (startLeft || startRight) {
    updatephaseEncoderPos();
    updateStitchPos();
    updateSolenoides = true;
    #ifdef DEBUG
      printOut();
    #endif
  }
}

inline void updatephaseEncoderPos() {
  if (phaseEncoderState != lastPhaseEncoderState) {
    switch (cariageDir) {
      case LEFT_RIGHT: // Carriage go LEFT to RIGHT
        if (phaseEncoderCount < PHASE_ENCODER_MAX) phaseEncoderCount++;
        break;
      case RIGHT_LEFT: // Carriage go RIHT to LEFT
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
  if (updateSolenoides) {
    updateSolenoides = false;
    switch (cariageDir) {
    case LEFT_RIGHT: // Carriage go LEFT to RIGHT
      if (solenoidesPos == 0){
        if (!phaseEncoderState) {
          Wire.beginTransmission(I2C_ADDR_SOL_1_8);
          Wire.write(stitchBin[phaseEncoderCount]);
          #ifdef DEBUG
            Serial.println();
            Serial.print("WRITE_1_8: " + stitchBin[phaseEncoderCount]);
          #endif
        }
        else {
          Wire.beginTransmission(I2C_ADDR_SOL_9_16);
          Wire.write(stitchBin[phaseEncoderCount]);
          #ifdef DEBUG
            Serial.println();
            Serial.print("WRITE_9_16: " + stitchBin[phaseEncoderCount]);
          #endif
        }
        Wire.endTransmission();
      }     
      break;
    
    case RIGHT_LEFT: // Carriage go RIHT to LEFT
      if (solenoidesPos == 0){
        if (!phaseEncoderState) {
          Wire.beginTransmission(I2C_ADDR_SOL_9_16);
          Wire.write(stitchBin[phaseEncoderCount]);
          #ifdef DEBUG
            Serial.println();
            Serial.print("WRITE_9_16: " + stitchBin[phaseEncoderCount]);
          #endif
        } else {
          Wire.beginTransmission(I2C_ADDR_SOL_1_8);
          Wire.write(stitchBin[phaseEncoderCount]);
          #ifdef DEBUG
            Serial.println();
            Serial.print("WRITE_1_8: " + stitchBin[phaseEncoderCount]);
          #endif
        }
        Wire.endTransmission();
      }
      break;
    }
  }
}

// Print out DEBUGING values
inline void printOut() {
  Serial.println();
  Serial.print("CariageDir: " + cariageDir);
  Serial.print(" PhaseEncoderState: " + phaseEncoderState);
  Serial.print(" PhaseEncoderCount: " + phaseEncoderCount);
  Serial.print(" StitchPos: " + stitchPos);
  Serial.print(" SolenoidesPos: " + solenoidesPos);
}

inline void blip(){
  digitalWrite(PIEZO_PIN, HIGH);
  delay(30);
  digitalWrite(PIEZO_PIN, LOW);
}
