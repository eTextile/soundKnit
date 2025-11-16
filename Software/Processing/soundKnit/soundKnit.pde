/*
 coucouc
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

// TODO: add save/load pattern to a .txt file

import java.util.Arrays;
import processing.serial.*;

Serial myPort;
final String PORTNAME = "/dev/ttyACM0";

final int BAUDERATE   = 115200;    // Serial port speed
final byte HEADER     = (byte)64;  // Header recived evrey knetted row
final byte FOOTER     = (byte)33;  // Footer to terminate the list of pixels to knit

final int STITCHES    = 200;       //
final int BLACK       = -1;        //
final int WHITE       = -16777216; //

final int GRID_PADDING_PIX = 20;         // Left & right space around the grid
final int BORDER_WIDTH_PIX = 10;         // Default value left & right borders

float PIXEL_SIZE;
float GRID_PADDING_SIZE;
int TOTAL_WIDTH_PIX = STITCHES + GRID_PADDING_PIX * 2;

char input_char;                   // Variable to store serial incoming data

byte[]pattern;
byte[]bin_array;
byte[]background_array;
byte[]merged_array;
byte[]line_array;


//KnittPict _module;
KnittText _module;

Grid grid;
Flood_fill background;
Rules rules;
Borders borders;
Patterns patterns;

float mod_offset_x;
int mod_offset_x_pix;

int total_line_width_pix;
int line_index;               // The current row to knitt

final boolean COMPORT = false; // Set it true to connect your knitter
final boolean DEBUG   = true; //

void setup() {
  noLoop();
  size(1400, 600);
  if (COMPORT) myPort = new Serial(this, PORTNAME, BAUDERATE);
  PIXEL_SIZE = (width / ((GRID_PADDING_PIX * 2) + STITCHES));
  GRID_PADDING_SIZE = (GRID_PADDING_PIX * PIXEL_SIZE);

  // Pixellari.ttf
  // pixelated.ttf
  // dogica.ttf
  _module = new KnittText(" \n Pourquoi \n  faire   simple  \n  quand   on  \n  peut    faire \n  complique \n ", "../typo/pixelated.ttf", 15);
  //_module = new KnittText(" \n complique \n ", "../typo/pixelated.ttf", 15);
  //_module = new KnittText(" \n complique \n ", "../typo/dogica.ttf", 8);

  //_module = new KnittPict(loadImage("../pictures/Pauline.png"));
  //_module = new KnittPict(loadImage("../pictures/jabron2.png"));

  //The left position of the module in the window
  mod_offset_x = GRID_PADDING_SIZE + ((STITCHES - _module.width_pix) / 2) * PIXEL_SIZE;
  mod_offset_x_pix = (int)(mod_offset_x / PIXEL_SIZE);

  patterns = new Patterns(_module.height_pix);
  pattern = patterns.get(patterns.selector());

  bin_array = _module.get_array();
  merged_array = new byte[_module.width_pix * _module.height_pix];

  line_array = new byte[STITCHES];
  line_index = _module.height_pix - 1;

  grid = new Grid(STITCHES, _module.height_pix);

  background = new Flood_fill(bin_array, _module.width_pix, _module.height_pix);
  rules = new Rules(_module.width_pix, _module.height_pix);

  borders = new Borders(pattern, _module.width_pix, _module.height_pix);
  total_line_width_pix = _module.width_pix + (borders.border_width_pix * 2);


  background.run(pattern, line_index);
  background.display(line_index);
  grid.display(line_index);

  background_array = background.bin_array_copy;
  
  merged_array = merge3Images(
    pattern, borders.border_width_pix,
    background_array, _module.width_pix,
    pattern, borders.border_width_pix,
    _module.height_pix
    );
  redraw();
}

/////////////////////////////////////////// LOOP
void draw() {
  background(255); // Clear
  borders.display(line_index);
  background.display(line_index);
  grid.display(line_index);
  rules.display(line_index);
}

void serialEvent(Serial myPort) {

  if (COMPORT) {
    while (myPort.available () > 0) {
      input_char = myPort.readChar();
      if (input_char == HEADER) {
        if (line_index > 0) {
          line_index--;
          serial_buffer_write(line_index);
          redraw();
        }
      }
    }
  }
}

void serial_buffer_write(int vertical_pos) {

  int start_pos_source = vertical_pos * total_line_width_pix;

  for (int line_array_index = 0; line_array_index < total_line_width_pix; line_array_index++) {
    int bin_array_index = start_pos_source + (total_line_width_pix - line_array_index); // Revers the line index
    line_array[line_array_index] = merged_array[bin_array_index];
  }

  if (COMPORT) {
    for (int i = 0; i < total_line_width_pix; i++) {
      myPort.write(line_array[i]);
      delay(1);
    }
    myPort.write(line_array);
    delay(20);
    myPort.write(FOOTER);
  }

  if (DEBUG) {
    print("LINE_INDEX: " + vertical_pos + " - ");
    for (int i = 0; i < total_line_width_pix; i++) {
      print(line_array[i] + "");
    }
    println(" - FOOTER: " + FOOTER);
  }
}

void mouseClicked() {

  pattern = patterns.get(patterns.selector());

  borders.update(pattern);

  background.raz(bin_array);
  background.run(pattern, line_index);
  redraw();
}

void mousePressed() {
  rules.pressed();
}

void mouseDragged() {
  float left_rule_pos_x = rules.dragged();
  borders.dragged(left_rule_pos_x);
  total_line_width_pix = _module.width_pix + (borders.border_width_pix * 2);
  redraw();
}

void mouseReleased() {
  rules.released();
  background_array = background.bin_array_copy;

  merged_array = merge3Images(
    pattern, borders.border_width_pix,
    background_array, _module.width_pix,
    pattern, borders.border_width_pix,
    _module.height_pix
    );
}

// Use keys to move the pattern
void keyPressed() {

  if (key == CODED) {
    if (keyCode == DOWN) {
      if (line_index <= 0) {
        line_index = 0;
      } else {
        line_index--;
      }
      serial_buffer_write(line_index);
      redraw();
    }
    if (keyCode == UP) {
      if (line_index >= _module.height_pix - 1) {
        line_index = _module.height_pix - 1;
      } else {
        line_index++;
      }
      serial_buffer_write(line_index);
      redraw();
    }
    if (keyCode == RIGHT) {
      line_index = _module.height_pix - 1;
      redraw();
    }
    if (keyCode == LEFT) {
      line_index = 0;
      redraw();
    }
  }
}

byte[]merge3Images(byte[]left, int wL, byte[]center, int wC, byte[]right, int wR, int h) {

  int totalW = wL + wC + wR;
  byte[]result = new byte[h * totalW];

  for (int y = 0; y < h; y++) {
    // --- Copier image gauche ---
    for (int x = 0; x < wL; x++) {
      result[y * totalW + x] = left[y * wL + x];
    }
    // --- Copier image centrale ---
    for (int x = 0; x < wC; x++) {
      result[y * totalW + (x + wL)] = center[y * wC + x];
    }
    // --- Copier image droite ---
    for (int x = 0; x < wR; x++) {
      result[y * totalW + (x + wL + wC)] = right[y * wR + x];
    }
  }
  return result;
}


void error(String msg) {

  while (1 > 0) {
    println(msg);
    delay(1000);
  }
}
