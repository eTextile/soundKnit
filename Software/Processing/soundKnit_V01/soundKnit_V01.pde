/*
 BROTHER KH-940
 2022 (c) maurin.box@gmail.com
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images
 The loded image must not be wider than 200 pixels
 */

import processing.serial.*;

Serial myPort;                          // Create object from Serial class
final String PORTNAME = "/dev/ttyACM0"; // Select your port number

final int BAUDERATE   = 115200;         // Serial port speed
final byte HEADER     = byte(64);       // Header recived evrey knetted row
final byte FOOTER     = byte(33);      // Footer to terminate the list of pixels to knit

final int STITCHES    = 200;            //
//final int STITCHES_BYTES = 25;          // 25 x 8 = 200

final int BLACK       = -1;             //
final int WHITE       = -16777216;      //

final int LAYERS      = 5;              //
final int CANVAS_W    = 800;            //
final int CANVAS_H    = 800;            //

float PADDING = 20;                     // Left & Right space around the image
float PADDING_SIZE = 0;                 //
float PIXEL_SIZE = 0;                   //

int image_w = 0;                        // The image width in pixel
int image_h = 0;                        // The image height in pixel
int IMAGE_PIXEL_OFFSET = 0;             // Space to display the image in the middle of the canvas

int image_bin_array_size = 0;           // The raw image size in pixel

int BUTTON_COLS = 8;
int BUTTON_ROWS = 8;
int BUTTON_SIZE = 15;
Button buttons[][];

char inputChar;                         // Variable to store incoming data
byte[][]pattern_layers;                 //

PImage raw_image;                       // Loded image

byte[]image_bin_array = {0};

PFont font;

int line_index = 0;                      // Store the current row to knitt
int selected_pattern = 4;
boolean update_frame = false;

final boolean COMPORT = true;           // Set it true to connect your knitter
final boolean DEBUG   = true;           //

void setup() {
  size(1000, 600);
  //font = createFont("Georgia", 40);
  //textFont(font);
  //raw_image = loadImage("../pictures/petit_jabron.png");
  //raw_image = loadImage("../pictures/damier.png");
  raw_image = loadImage("../pictures/interdit.png");

  // Scan all pixels from the imported picture
  raw_image.loadPixels();
  image_w = raw_image.width;
  println("IMAGE_WIDTH: " + image_w);
  if (image_w > STITCHES) error("IMAGE_WIDTH_TO_LARGE");

  image_h = raw_image.height;
  image_bin_array_size = image_w * image_h;
  image_bin_array = new byte[image_bin_array_size];

  generate_image_bin_array(image_bin_array, raw_image); // Populate the bin array from image pixels

  PIXEL_SIZE = width / ((PADDING * 2) + STITCHES);
  PADDING_SIZE = PADDING * PIXEL_SIZE;
  
  // If the loaded image is less than 200 pixel (max size)
  // Set the pattern in the middle of the knitting machine
  IMAGE_PIXEL_OFFSET = int(( STITCHES - image_w ) / 2);
  line_index = image_h;

  pattern_layers = new byte[LAYERS][image_bin_array_size];
  patterns_generator(pattern_layers, raw_image);

  if (COMPORT) myPort = new Serial(this, PORTNAME, BAUDERATE);

  display_grid(line_index);
  display_picture(line_index);
  display_line_index(line_index);
  display_read_line();

  if (DEBUG) println("IMAGE_PIXEL_OFFSET: " + IMAGE_PIXEL_OFFSET);
  if (DEBUG) println("PIXEL_SIZE: " + PIXEL_SIZE);
  if (DEBUG) println("PADDING_SIZE: " + PADDING_SIZE);
  if (DEBUG) println("LINE_INDEX: " + line_index);

  /*
  buttons = new Button[BUTTON_ROWS][BUTTON_COLS];   // buttons array

  for ( int i=0; i<BUTTON_ROWS; i++ ) {
    for ( int j=0; j<BUTTON_COLS; j++ ) {
      buttons[i][j] = new Button( );  // fill the array with buttons
    }
  }
  */
}

/////////////////////////////////////////// LOOP
void draw() {
  if (COMPORT) {
    while (myPort.available () > 0) {
      inputChar = myPort.readChar();
      if (inputChar == HEADER && update_frame == false) {
        line_index--;
        if (line_index < 0) line_index = 0;
        println("LINE_INDEX :" + line_index);
        update_frame = true;
      }
    }
  }
  if (update_frame == true) {
    update_frame = false;
    display_grid(line_index);
    display_picture(line_index);
    display_line_index(line_index);
    display_read_line();
    serial_buffer_write(image_bin_array, line_index);
  }
}

void serial_buffer_write(byte[]bin_array_ptr, int line_index_ptr) {

  int pixel_index_start = line_index_ptr * image_w;

  for (int byte_index=pixel_index_start; byte_index<(pixel_index_start + image_w); byte_index++) {
    if (COMPORT) myPort.write(bin_array_ptr[byte_index]);
    if (DEBUG) print(bin_array_ptr[byte_index]);
  }
  delay(20);
  if (COMPORT) myPort.write(FOOTER);
  if (DEBUG) println("FOOTER: " + FOOTER); // Print out: -1 ?
}

void display_line_index(int index) {
  fill(255, 0, 0);
  text(index, 30, height/2 - 10);
}

void display_grid(int vertical_pos) {
  background(255);     // Clear trails
  strokeWeight(0.5);   //
  stroke(0);           // Black lines
  fill(255);
  for (int row_pos=0; row_pos<image_h; row_pos++) {
    for (int col_pos=0; col_pos<STITCHES; col_pos++) {
      rect(
        (col_pos * PIXEL_SIZE) + PADDING_SIZE,
        (row_pos * PIXEL_SIZE) + height/2 - (vertical_pos * PIXEL_SIZE),
        PIXEL_SIZE,
        PIXEL_SIZE
        );
    }
  }
}

// Display all pixels
void display_picture(int vertical_pos) {
  strokeWeight(0.5);   // 
  stroke(0);           // Black lines
  fill(0);

  for (int row_pos=0; row_pos<image_h; row_pos++) {
    int row_pixel_index = row_pos * image_w;

    for (int col_pos=0; col_pos<image_w; col_pos++) {
      int pixel_index = row_pixel_index + col_pos;

      if (image_bin_array[pixel_index] == 0) {
        rect(
          (col_pos * PIXEL_SIZE) + PADDING_SIZE + (IMAGE_PIXEL_OFFSET * PIXEL_SIZE),
          (row_pos * PIXEL_SIZE) + height/2 - (vertical_pos * PIXEL_SIZE),
          PIXEL_SIZE,
          PIXEL_SIZE
          );
      }
    }
  }
}

// Draw two red lines to visualise the current frame onto the pattern
void display_read_line() {
  strokeWeight(1.1);
  stroke(255, 0, 0);
  line(0, height/2, width, height/2);
  line(0, height/2 + PIXEL_SIZE, width, height/2 + PIXEL_SIZE);
}

void mouseClicked() {
  int pos_x = int (((mouseX - PADDING_SIZE) / PIXEL_SIZE) - IMAGE_PIXEL_OFFSET);
  int pos_y = int (((mouseY - height/2 ) / PIXEL_SIZE) + line_index);
  if (DEBUG) println("X: " + pos_x + " Y: " + pos_y);
  flood_fill(raw_image, image_bin_array, pattern_layers[selected_pattern], pos_x, pos_y);

  display_picture(line_index);
  display_line_index(line_index);
  display_read_line();
}

// Place the input image in the middle off the output array
void generate_image_bin_array(byte[] output, PImage input) {
  
  for (int row_pos=0; row_pos<input.height; row_pos++) {
    int input_row_pixel_index = row_pos * input.width;

    for (int col_pos=0; col_pos<input.width; col_pos++) {
      int pixel_index = input_row_pixel_index + col_pos;

      if (input.pixels[pixel_index] == BLACK) {
        output[pixel_index] = byte(1);
      } else {
        output[pixel_index] = byte(0);
      }
    }
  }
}

// Replace it with live patterns generator !?
void patterns_generator(byte[][] patterns, PImage input) {

  for (int pattern=0; pattern<LAYERS; pattern++) {

    for (int row_pos=0; row_pos<input.height; row_pos++) {
      int row_pixel_index = row_pos * input.width;

      for (int col_pos=0; col_pos<input.width; col_pos++) {
        int pixel_index = row_pixel_index + col_pos;

        int background_pixel = pixel_index % (pattern + 2); // ??

        if (background_pixel == 0) {
          patterns[pattern][pixel_index] = byte(1);
        } else {
          patterns[pattern][pixel_index] = byte(0);
        }
      }
    }
  }
}

// Use keys to move the pattern and activate DEBUG mode
void keyPressed() {

  if (key == CODED) {
    if (keyCode == DOWN) {
      if (line_index <= 0) {
        line_index = 0;
      } else {
        line_index--;
        update_frame = true;
      }
    }
    if (keyCode == UP) {
      if (line_index >= image_h - 1) {
        line_index = image_h - 1;
      } else {
        line_index++;
        update_frame = true;
      }
    }
    if (keyCode == RIGHT) {
      line_index = image_h - 1;
      update_frame = true;
    }
    if (keyCode == LEFT) {
      line_index = 0;
      update_frame = true;
    }
  }
}

void error(String msg) {

  while (1 > 0) {
    println(msg);
    delay(1000);
  }
}
