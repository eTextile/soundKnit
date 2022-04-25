/*
 BROTHER KH-940
 2022 (c) maurin.box@gmail.com
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images
 The images must not be wider than 200 pixels
 */

import processing.serial.*;

Serial myPort;                          // Create object from Serial class
final String PORTNAME = "/dev/ttyUSB0"; // Select your port number

final int BAUDERATE   = 115200;         // Serial port speed
final int HEADER      = 64;             // Header recived evrey knetted row
final int FOOTER      = 255;            // Footer to terminate the list of pixels to knit
final int STITCHES    = 200;            //
final int BLACK       = -1;             //
final int WHITE       = -16777216;      //
final int LAYERS      = 16;             //
final int CANVAS_W    = 800;            //
final int CANVAS_H    = 800;            //

float PADDING = 20;                     // Left & Right space around the image
float PADDING_SIZE = 0;                 //
float PIXEL_SIZE = 0;                   //

int IMAGE_W = 0;                        // The image width in pixel
int IMAGE_H = 0;                        // The image height in pixel
int IMAGE_SIZE = 0;                     // The image size in pixel
int IMAGE_OFFSET = 0;                   // Space to display the image in the middle of the canvas

int BUTTON_COLS = 8;
int BUTTON_ROWS = 8;
int BUTTON_SIZE = 15;
Button buttons[][];

final boolean COMPORT = false;          // Set it true to connect your knitter
final boolean DEBUG   = false;          //

char inputChar;                         // Variable to store incoming data

PImage rawImage;                        // Loded image
byte[]binArray;
byte[][]patternLayers;
byte[] serialData;
int nx = 10;
int ny = 10;

PFont font;
int lineIndex = 0;                      // Store the current row to knitt
byte pixelState = 0;                    // Store the pixel binary state
int selectedPattern = 5;
boolean updateFrame = false;

void setup() {
  size(1500, 800);
  //font = createFont("Georgia", 40);
  //textFont(font);
  rawImage = loadImage("../pictures/petit_jabron.png");
  // Scan all pixels from the imported picture
  rawImage.loadPixels();
  IMAGE_W = rawImage.width;
  if (IMAGE_W > STITCHES) error("IMAGE_WIDTH_TO_LARGE");
  IMAGE_H = rawImage.height;
  IMAGE_SIZE = IMAGE_W * IMAGE_H;
  binArray = new byte[IMAGE_SIZE];
  getPixels(binArray, rawImage);
  PIXEL_SIZE = width / ((PADDING * 2) + STITCHES);
  PADDING_SIZE = PADDING * PIXEL_SIZE;
  // If the loaded image is less than 200 pixel (max size)
  // Set the pattern in the middle of the knitting machine
  IMAGE_OFFSET = int(( STITCHES - IMAGE_W ) / 2);
  lineIndex = round(IMAGE_H / 2);
  patternLayers = new byte[LAYERS][IMAGE_SIZE];
  patternsGenerator(patternLayers, IMAGE_W, IMAGE_H);
  
  if (COMPORT) myPort = new Serial(this, PORTNAME, BAUDERATE);

  displayGrid(lineIndex);
  displayPicture(lineIndex);
  displayLineIndex(lineIndex);
  displayReadLine();

  serialData = new byte[STITCHES];
  if (DEBUG) println("IMAGE_WIDTH: " + IMAGE_W);
  if (DEBUG) println("IMAGE_OFFSET: " + IMAGE_OFFSET);
  if (DEBUG) println("PIXEL_SIZE: " + PIXEL_SIZE);
  if (DEBUG) println("PADDING_SIZE: " + PADDING_SIZE);
  if (DEBUG) println("LINE_INDEX: " + lineIndex);
  
   buttons = new Button[BUTTON_ROWS][BUTTON_COLS];   // buttons array 

  for ( int i=0; i<BUTTON_ROWS; i++ ) {
    for ( int j=0; j<BUTTON_COLS; j++ ) {
      buttons[i][j] = new Button( );  // fill the array with buttons
    }
  }

}

void draw() {
  if (COMPORT) {
    while (myPort.available () > 0) {
      inputChar = myPort.readChar();
      if (inputChar == HEADER && updateFrame == false) {
        lineIndex--;
        println("LINE_INDEX :" + lineIndex);
        if (lineIndex <= BLACK) {
          lineIndex = 0;
        } else {
          updateFrame = true;
        }
      }
    }
  }
  if (updateFrame == true) {
    updateFrame = false;
    displayGrid(lineIndex);
    displayPicture(lineIndex);
    displayLineIndex(lineIndex);
    displayReadLine();
    serialBuffer_clear();
    serialBuffer_fill();
    serialBuffer_write();
  }
}

void serialBuffer_clear() {
  for (int i = 0; i<STITCHES; i++) {
    serialData[i] = 0;
  }
}

void serialBuffer_fill() {
  for (int i=0; i<IMAGE_W; i++) {
    serialData[i] = binArray[lineIndex * IMAGE_W + i];
  }
}

void serialBuffer_write() {
  for (int i=0; i<STITCHES; i++) {
    if (COMPORT) myPort.write(serialData[i]);
    if (DEBUG) print(serialData[i]);
  }
  if (COMPORT) myPort.write(FOOTER);
  if (DEBUG) println(FOOTER);
}

void displayLineIndex(int index) {
  fill(255, 0, 0);
  text(index, 30, height/2 - 10);
}

void displayGrid(int verticalPos) {
  background(255);     // Clear trails
  strokeWeight(0.5);   //
  stroke(0);           // Black lines
  fill(255);
  for (int rowPos=0; rowPos<IMAGE_H; rowPos++) {
    for (int colPos=0; colPos<STITCHES; colPos++) {
      rect(
        (colPos * PIXEL_SIZE) + PADDING_SIZE,
        (rowPos * PIXEL_SIZE) + height/2 - (verticalPos * PIXEL_SIZE),
        PIXEL_SIZE,
        PIXEL_SIZE
        );
    }
  }
}

// Display all pixels
void displayPicture(int verticalPos) {
  strokeWeight(0.5);   //
  stroke(0);           // Black lines
  fill(0);
  for (int rowPos=0; rowPos<IMAGE_H; rowPos++) {
    int rowPixIndex = rowPos * IMAGE_W;
    for (int colPos=0; colPos<IMAGE_W; colPos++) {
      int pixelIndex = rowPixIndex + colPos;
      if (binArray[pixelIndex] == 0) {
        // Default rectMode is CORNER
        rect(
          (colPos * PIXEL_SIZE) + PADDING_SIZE + (IMAGE_OFFSET * PIXEL_SIZE),
          (rowPos * PIXEL_SIZE) + height/2 - (verticalPos * PIXEL_SIZE),
          PIXEL_SIZE,
          PIXEL_SIZE
          );
      }
    }
  }
}

// Draw two red lines to visualise the current frame onto the pattern
void displayReadLine() {
  strokeWeight(1.1);
  stroke(255, 0, 0);
  line(0, height/2, width, height/2);
  line(0, height/2 + PIXEL_SIZE, width, height/2 + PIXEL_SIZE);
}

void mouseClicked() {
  //width - IMAGE_W;
  //height - IMAGE_H;
  // lineIndex
  int posX = int (((mouseX - PADDING_SIZE) / PIXEL_SIZE) - IMAGE_OFFSET);
  int posY = int (((mouseY - height/2 ) / PIXEL_SIZE) + lineIndex);
  if (DEBUG) println("X: " + posX + " Y: " + posY);
  floodFill(rawImage, binArray, patternLayers[selectedPattern], posX, posY);
  displayPicture(lineIndex);
  displayLineIndex(lineIndex);
  displayReadLine();
}

void getPixels(byte[] output, PImage input) {
  for (int rowPos=0; rowPos<IMAGE_H; rowPos++) {
    int rowPixIndex = rowPos * IMAGE_W;
    for (int colPos=0; colPos<IMAGE_W; colPos++) {
      int pixelIndex = rowPixIndex + colPos;
      if (input.pixels[pixelIndex] == BLACK) {
        output[pixelIndex] = 1;
      } else {
        output[pixelIndex] = 0;
      }
    }
  }
}

void patternsGenerator(byte[][] patterns, int patternW, int patternH) {
  for (int pattern=0; pattern<LAYERS; pattern++) {
    for (int rowPos=0; rowPos<patternH; rowPos++) {
      int rowPixIndex = rowPos * patternW;
      for (int colPos=0; colPos<patternW; colPos++) {
        int pixelIndex = rowPixIndex + colPos;
        int backgroundPixel = pixelIndex % (pattern + 2);
        if (backgroundPixel == 0) {
          patterns[pattern][pixelIndex] = 1;
        } else {
          patterns[pattern][pixelIndex] = 0;
        }
      }
    }
  }
}

// Use keys to move the pattern and activate DEBUG mode
void keyPressed() {
  if (key == CODED) {
    if (keyCode == DOWN) {
      if (lineIndex <= 0) {
        lineIndex = 0;
      } else {
        lineIndex--;
        updateFrame = true;
      }
    }
    if (keyCode == UP) {
      if (lineIndex >= IMAGE_H - 1) {
        lineIndex = IMAGE_H - 1;
      } else {
        lineIndex++;
        updateFrame = true;
      }
    }
    if (keyCode == RIGHT) {
      lineIndex = IMAGE_H - 1;
      updateFrame = true;
    }
    if (keyCode == LEFT) {
      lineIndex = 0;
      updateFrame = true;
    }
  }
}

void error(String msg) {
  while (1 > 0) {
    println(msg);
    delay(1000);
  }
}
