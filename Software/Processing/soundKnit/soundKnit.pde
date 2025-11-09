/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

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

int GRID_PADDING = 20;             // Left & right space around the grid
float PIXEL_SIZE;
float GRID_PADDING_SIZE;
int BORDER_WIDTH_PIX;

char input_char;                   // Variable to store serial incoming data

byte[]bin_array;
byte[]background_array;
byte[]merged_array;

byte[]border_array;
byte[]merged_borders_array;

//KnittPict _module;
KnittText _module;

Grid grid;
Flood_fill background;
Rules rules;
Borders borders;

int line_index;               // The current row to knitt
float left_rule_pos_x;

final boolean COMPORT = false; // Set it true to connect your knitter
final boolean DEBUG   = true; //

void setup() {
  noLoop();
  size(1500, 600);
  if (COMPORT) myPort = new Serial(this, PORTNAME, BAUDERATE);
  PIXEL_SIZE = (width / ((GRID_PADDING * 2) + STITCHES));
  GRID_PADDING_SIZE = (GRID_PADDING * PIXEL_SIZE);
  BORDER_WIDTH_PIX = 8;

  // Pixellari.ttf
  // pixelated.ttf
  // dogica.ttf
  _module = new KnittText("  Pourquoi \n  faire   simple  \n  quand   on  \n  peut    faire \n  complique ", "./typo/pixelated.ttf", 15);

  //_module = new KnittPict(loadImage("../pictures/stop test 200pix.png"));

  this.bin_array = _module.get_array();
  merged_array = new byte[_module.width_pix * _module.height_pix];
  line_index = _module.height_pix - 1 ;

  grid = new Grid(STITCHES, _module.height_pix);
  grid.display(line_index);

  background = new Flood_fill(this.bin_array, _module.width_pix, _module.height_pix);
  background.run(width/2, height/2);
  background.display(line_index);
  background_array = background.get_array();

  rules = new Rules(_module.width_pix, _module.height_pix);

  borders = new Borders(_module.width_pix, _module.height_pix);

  border_array = borders.pattern();

  //merged_array = merge_arrays(this.bin_array, background_array, "union"); // NOT NEAD!?
  //merged_array = merge_arrays(this.bin_array, background_array, "intersection");
  merged_array = merge_arrays(this.bin_array, background_array, "addition");

  merged_borders_array = merge3Images(
    border_array, borders.border_width_pix,
    merged_array, background.width_pix,
    border_array, borders.border_width_pix,
    background.height_pix
    );

  redraw();
}

/////////////////////////////////////////// LOOP
void draw() {

  grid.display(line_index);
  borders.display(line_index);
  background.display(line_index);
  rules.display(line_index);
}

void serialEvent(Serial myPort) {

  if (COMPORT) {

    while (myPort.available () > 0) {
      input_char = myPort.readChar();
      if (input_char == HEADER) {
        if (line_index > 0) {
          line_index--;
          serial_buffer_write(_module.width_pix, line_index);
        }
      }
    }
  }
}

void serial_buffer_write(int source_width_pix, int vertical_pos) {

  int border_width_pix = borders.border_width_pix;
  int total_line_width_pix = source_width_pix + border_width_pix * 2;
  byte[]line_array = new byte[total_line_width_pix];

  int start_pos_source = vertical_pos * total_line_width_pix;

  for (int pixel_index = 0; pixel_index < total_line_width_pix; pixel_index++) {
    int bin_array_index = start_pos_source + (total_line_width_pix - pixel_index - 1); // Revers the line index
    line_array[pixel_index] = merged_borders_array[bin_array_index];
  }

  if (COMPORT) {
    /*
    for (int i = 0; i < total_line_width_pix; i++) {
     myPort.write(line_array[i]);
     delay(5); // délai de 5 ms entre chaque byte
     }
     */
    myPort.write(line_array);
    delay(20);
    myPort.write(FOOTER);
  }

  if (DEBUG) {
    print("LINE_INDEX: " + line_index + " - ");
    for (int i = 0; i < total_line_width_pix; i++) {
      print(line_array[i] + " ");
    }
    println("FOOTER: " + FOOTER);
  }
}

void mouseClicked() {
  background.run(mouseX, mouseY);
  background_array = background.get_array();

  border_array = borders.pattern();

  merged_array = merge_arrays(this.bin_array, background_array, "union");
  //merged_array = merge_arrays(this.bin_array, background_array, "intersection");
  //merged_array = merge_arrays(this.bin_array, background_array, "addition");

  merged_borders_array = merge3Images(
    border_array, borders.border_width_pix,
    merged_array, background.width_pix,
    border_array, borders.border_width_pix,
    background.height_pix
    );

  redraw();
}

void mousePressed() {
  rules.pressed();
}

void mouseDragged() {
  left_rule_pos_x = rules.dragged(mouseX);
  borders.dragged(left_rule_pos_x);
  redraw();
}

void mouseReleased() {

  rules.released();
}

// Use keys to move the pattern and activate DEBUG mode
void keyPressed() {

  background.key_pressed(bin_array);

  if (key == CODED) {
    if (keyCode == DOWN) {
      if (line_index <= 0) {
        line_index = 0;
      } else {
        line_index--;
      }
    }
    if (keyCode == UP) {
      if (line_index >= _module.height_pix - 1) {
        line_index = _module.height_pix - 1;
      } else {
        line_index++;
      }
    }
    if (keyCode == RIGHT) {
      line_index = _module.height_pix - 1;
    }
    if (keyCode == LEFT) {
      line_index = 0;
    }
    serial_buffer_write(_module.width_pix, line_index);
  }
  redraw();
}

// Fusion de deux tableaux de bytes (même taille)
byte[] merge_arrays(byte[]array1, byte[]array2, String mode) {

  if (array1.length != array2.length) {
    println("Erreur : les tableaux n'ont pas la même taille !");
    return null;
  }

  byte[]merged = new byte[array1.length];

  for (int i = 0; i < array1.length; i++) {
    if (mode.equals("union")) {
      merged[i] = (byte)((array1[i] == 1 || array2[i] == 1) ? 1 : 0);
    } else if (mode.equals("intersection")) {
      merged[i] = (byte)((array1[i] == 1 && array2[i] == 1) ? 1 : 0);
    } else if (mode.equals("addition")) {
      merged[i] = (byte) min(1, array1[i] + array2[i]); // Exemple : addition simple (max 1)
    }
  }
  return merged;
}

byte[] merge3Images(byte[]left, int wL, byte[]center, int wC, byte[]right, int wR, int h) {

  int totalW = wL + wC + wR;
  byte[] result = new byte[h * totalW];

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
