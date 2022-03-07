/*
This sketch read pixels from an image to control a BROTHER knithacked
 The image must be 200 pixels width maximum
 )c( maurin.box@gmail.com
 */

import processing.serial.*;

Serial myPort;               // Create object from Serial class

final int BAUDERATE   = 115200;   // Serial port speed
final int HEADER      = 64;     // header recived evrey knetted row 
final int FOOTER      = 255;    // footer to terminate the list of pixels to knit
final int STITCHES    = 200;    //

final String PORTNAME = "/dev/ttyUSB0";         // Select your port number

int pixelWidth  = 0;         // 
int pixelHeight = 0;         // 
int margin      = 0;         //

char inputChar;              // variable to store incoming data

PImage myImage;
PFont font;

boolean readFrame = false;
int ligneIndex = 0;          // the row to knitt
int pixelState = 0;          // store the colore for picels

byte[] serialData = new byte[STITCHES];

boolean debug = false;
boolean COMPORT = true;  // set it true to connect your knitter

void setup() {

  size(1000, 700);

  pixelWidth = int(width / STITCHES);
  pixelHeight = int(width / STITCHES);

  font = createFont("Georgia", 40);
  textFont(font);

  if (COMPORT) myPort = new Serial(this, PORTNAME, BAUDERATE);

  // .gif, .jpg, .tga, .png
  // Selaect your pattern by writng it name below
  //myImage = loadImage("../pictures/damier.png");
  //myImage = loadImage("../pictures/Hakito.png");
  //myImage = loadImage("../pictures/Pauline.jpg");
  myImage = loadImage("../pictures/petit_jabron.png");

  // Scan all pixels from the imported picture
  // The pixels will be mapped to vector "pixels"
  myImage.loadPixels();
  myImage.updatePixels();

  ligneIndex = myImage.height;

  background(255);
  displayPicture(ligneIndex);
  displayReaadLine();

  // If the pattern is less than 200 pixel (max size)
  // Set the pattern in the middel of the knitting machine
  if (myImage.width < STITCHES) {
    margin = int (( STITCHES - myImage.width ) / 2);
    println("IMAGE_WIDTH: " + myImage.width);    
    println("MARGIN: " + margin);
  }
}

void draw() {

  if (COMPORT) {
    while (myPort.available () > 0) {
      inputChar = myPort.readChar();
      if (inputChar == HEADER && readFrame == false) {
        ligneIndex--;
        println("LINE_INDEX :" + ligneIndex);
        if (ligneIndex <= -1) {
          ligneIndex = 0;
        } else {
          readFrame = true;
        }
      }
    }
  }

  if (readFrame == true) {
    displayPicture(ligneIndex);
    displayReaadLine();
    displayLineIndex(ligneIndex);

    // https://processing.org/reference/PImage.html
    clearLineArray();

    for (int i=0; i<myImage.width; i++) {
      pixelState = myImage.pixels[(myImage.width * ligneIndex) + i];
      if (pixelState == -1) {
        serialData[i + margin] = 1;
      }
    }

    for (int i=0; i<STITCHES; i++) {
      if (COMPORT) myPort.write(serialData[i]);
      if (debug) print(serialData[i]);
    }
    if (COMPORT) myPort.write(FOOTER);
    if (debug) println(FOOTER);
    readFrame = false;
  }
}

void clearLineArray() {
  for (int i = 0; i<STITCHES; i++) {
    serialData[i] = 0;
  }
}

void displayLineIndex(int index) {
  fill(255, 0, 0);
  text(index, 30, height/2 - 10);
}

// Display all pixels 
void displayPicture(int verticalPos) {
  background(255);     // Clear trails
  strokeWeight(0.5);   // 
  stroke(0);           // Black lines 
  for (int rowPos=0; rowPos<myImage.height; rowPos++) {
    int rowPixIndex = rowPos * myImage.width;
    for (int colPos=0; colPos<myImage.width; colPos++) {
      pixelState = myImage.pixels[rowPixIndex + colPos];
      //print(pixelState + " ");
      if (pixelState == -1) {
        fill(255);
      } else { 
        fill(0);
      }
      rect(
      colPos * pixelWidth + ( int( width / 2 ) - ( pixelWidth * int( myImage.width / 2 ) ) ), 
      rowPos * pixelHeight - ( verticalPos * pixelHeight - int( height / 2 ) ), 
      pixelWidth,
      pixelHeight
        );
    }
  }
}

// Draw two red lines to visualise the current frame onto the pattern
void displayReaadLine() {
  strokeWeight(1.1);
  stroke(255, 0, 0);
  line(0, height/2, width, height/2);
  line(0, height/2 + pixelHeight, width, height/2 + pixelHeight);
}

// Use keys to move the pattern and activate debug mode
void keyPressed() {

  if (key == 'd') {
    debug = !debug;
  }

  if (key == CODED) {
    if (keyCode == DOWN) {
      if (ligneIndex <= 0) {
        ligneIndex = 0;
      } else {
        ligneIndex--;
        readFrame = true;
      }
    }
    if (keyCode == UP) {
      if (ligneIndex >= myImage.height - 1) ligneIndex = (myImage.height - 1);
      else {
        ligneIndex++;
        readFrame = true;
      }
    }
    if (keyCode == RIGHT) {
      ligneIndex = myImage.height - 1;
      readFrame = true;
    }
    if (keyCode == LEFT) {
      ligneIndex = 0;
      readFrame = true;
    }
  }
}

