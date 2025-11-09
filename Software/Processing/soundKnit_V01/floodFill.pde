/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

import java.util.ArrayDeque;

class Flood_fill {

  int width_pix;
  int height_pix;

  int layers = 10;
  byte[][]pattern_layers;
  int selected_pattern = 7;

  ArrayDeque<Point> q;

  byte[]bin_array_copy;
  byte[]tmp_bin_array;

  int offset_x_pix;

  String[] pattern_names = {
    "Trame 0 — Damier",
    "Trame 1 — Lignes verticales 1",
    "Trame 2 — Lignes diagonales",
    "Trame 3 — Lignes verticales",
    "Trame 4 — Lignes verticales 2",
    "Trame 5 — Points réguliers diagonales",
    "Trame 6 — Points réguliers",
    "Trame 7 — Points réguliers droits 1",
    "Trame 8 — Points réguliers droits 2",
    "Trame 9 — Motif diagonales ecart"
  };

  Flood_fill(byte[]bin_array, int width_pix, int height_pix) {
    this.width_pix = width_pix;
    this.height_pix = height_pix;

    bin_array_copy = new byte[this.width_pix * this.height_pix];
    System.arraycopy(bin_array, 0, bin_array_copy, 0, this.width_pix * this.height_pix);

    tmp_bin_array = new byte[this.width_pix * this.height_pix];
    System.arraycopy(bin_array, 0, tmp_bin_array, 0, this.width_pix * this.height_pix);

    pattern_layers = new byte[layers][this.width_pix * this.height_pix];

    for (int pattern=0; pattern<layers; pattern++) {
      for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
        int row_pixel_index = row_pos * this.width_pix;
        for (int col_pos=0; col_pos<this.width_pix; col_pos++) {
          int pixel_index = row_pixel_index + col_pos;
          int background_pixel = pixel_index % (pattern + 2);
          pattern_layers[pattern][pixel_index] = (background_pixel == 0) ? (byte)1 : (byte)0;
        }
      }
    }
    q = new ArrayDeque<Point>();
  }

  void run(int _mouseX, int _mouseY) {

    offset_x_pix = (int)((STITCHES - this.width_pix) / 2);
    int pos_x = (int)((_mouseX - (GRID_PADDING_SIZE + (offset_x_pix * PIXEL_SIZE))) / PIXEL_SIZE);
    int pos_y = (int)(((_mouseY - height/2 ) / PIXEL_SIZE) + line_index);

    if (pos_x < 0 || pos_x > this.width_pix - 1 || pos_y < 0 || pos_y > this.height_pix - 1) return;
    byte select_color = bin_array_copy[pos_y * this.width_pix + pos_x];
    byte replacement_color = (byte) (this.selected_pattern + 10); // couleur de remplissage symbolique

    Point p = new Point(pos_x, pos_y);
    q.add(p);

    int west, east;
    while (!q.isEmpty () ) {
      p = q.removeFirst();

      if ( is_to_fill(p.x, p.y, tmp_bin_array, select_color) ) {
        west = east = p.x;
        while ( is_to_fill(--west, p.y, tmp_bin_array, select_color) );
        while ( is_to_fill(++east, p.y, tmp_bin_array, select_color) );

        for (int x = west + 1; x < east; x++) {
          int pixel_index = p.y * this.width_pix + x;
          tmp_bin_array[pixel_index] = replacement_color;
          bin_array_copy[pixel_index] = pattern_layers[this.selected_pattern][pixel_index];
          if ( is_to_fill(x, p.y - 1, tmp_bin_array, select_color) ) {
            q.add(new Point(x, p.y - 1));
          }
          if ( is_to_fill(x, p.y + 1, tmp_bin_array, select_color) ) {
            q.add(new Point(x, p.y + 1));
          }
        }
      }
    }
  }

  // Returns true if the specified pixel requires filling
  boolean is_to_fill(int pos_x, int pos_y, byte[]array, byte my_color) {

    if (pos_x < 0 || pos_x >= this.width_pix || pos_y < 0 || pos_y >= this.height_pix) {
      return false;
    } else {
      return array[pos_y * this.width_pix + pos_x] == my_color;
    }
  }

  byte[] get_array() {
    return bin_array_copy;
  }


  // Display all pixels
  void display(int vertical_pos) {

    strokeWeight(0.5); //
    stroke(0); // Black lines
    fill(0);

    for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
      int row_pixel_index = row_pos * this.width_pix;

      for (int col_pos=0; col_pos<this.width_pix; col_pos++) {
        int pixel_index = row_pixel_index + col_pos;

        // TODO: Set the image positive or negative
        if (this.bin_array_copy[pixel_index] == 1) {
          fill(0);
          rect(
            GRID_PADDING_SIZE + (offset_x_pix * PIXEL_SIZE) + (col_pos * PIXEL_SIZE),
            height/2 + (row_pos * PIXEL_SIZE) - (vertical_pos * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }

  void key_pressed() {
    if (key >= '0' && key <= '9') {
      //Arrays.fill(tmp_bin_array, (byte)0);
      this.selected_pattern = key - '0';
      println("Pattern sélectionné :", pattern_names[this.selected_pattern]);
    }
  }
}

// Could use java.awt.Point instead
class Point {
  int x, y;

  public Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
