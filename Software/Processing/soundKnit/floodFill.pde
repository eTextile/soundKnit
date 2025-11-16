/*
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

import java.util.ArrayDeque;

class Flood_fill {

  int mod_width_pix;
  float mod_width;

  int mod_height_pix;

  float mod_padding_x;
  int mod_padding_x_pix;

  ArrayDeque<Point> q;

  byte[]bin_array_copy;
  byte[]tmp_bin_array;


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

  byte replacement_color = 0;

  Flood_fill(byte[]bin_array, int _mod_width_pix, int _mod_height_pix) {

    this.mod_width_pix = _mod_width_pix;
    //this.mod_width = _mod_width_pix / PIXEL_SIZE;

    this.mod_height_pix = _mod_height_pix;

    this.mod_padding_x_pix = (int)((STITCHES - this.mod_width_pix) / 2);
    this.mod_padding_x = this.mod_padding_x_pix * PIXEL_SIZE;

    this.bin_array_copy = new byte[this.mod_width_pix * this.mod_height_pix];
    System.arraycopy(bin_array, 0, this.bin_array_copy, 0, this.mod_width_pix * this.mod_height_pix);

    this.tmp_bin_array = new byte[this.mod_width_pix * this.mod_height_pix];
    System.arraycopy(bin_array, 0, this.tmp_bin_array, 0, this.mod_width_pix * this.mod_height_pix);

    q = new ArrayDeque<Point>();
  }

  void run(byte[]pattern, int _line_index) {

    this.mod_padding_x_pix = (int)((STITCHES - this.mod_width_pix) / 2);
    this.mod_padding_x = this.mod_padding_x_pix * PIXEL_SIZE;

    int pos_x = (int)((mouseX - (GRID_PADDING_SIZE + this.mod_padding_x)) / PIXEL_SIZE);
    int pos_y = (int)(((mouseY - height/2 ) / PIXEL_SIZE) + _line_index);

    if (pos_x < 0 || pos_x > this.mod_width_pix - 1 || pos_y < 0 || pos_y > this.mod_height_pix - 1) return;

    byte select_color = this.bin_array_copy[pos_y * this.mod_width_pix + pos_x];
    this.replacement_color = (byte)((this.replacement_color + 10) % 256); // couleur de remplissage symbolique

    Point p = new Point(pos_x, pos_y);
    q.add(p);

    int west, east;
    while (!q.isEmpty () ) {
      p = q.removeFirst();

      if ( is_to_fill(p.x, p.y, this.tmp_bin_array, select_color) ) {
        west = east = p.x;
        while ( is_to_fill(--west, p.y, this.tmp_bin_array, select_color) );
        while ( is_to_fill(++east, p.y, this.tmp_bin_array, select_color) );

        for (int x = west + 1; x < east; x++) {

          int pixel_index = p.y * this.mod_width_pix + x;
          int pattern_pixel_index = p.y * TOTAL_WIDTH_PIX + x;

          this.tmp_bin_array[pixel_index] = this.replacement_color;
          this.bin_array_copy[pixel_index] = pattern[pattern_pixel_index];

          if ( is_to_fill(x, p.y - 1, this.tmp_bin_array, select_color) ) {
            q.add(new Point(x, p.y - 1));
          }
          if ( is_to_fill(x, p.y + 1, this.tmp_bin_array, select_color) ) {
            q.add(new Point(x, p.y + 1));
          }
        }
      }
    }
  }

  // Returns true if the specified pixel requires filling
  boolean is_to_fill(int pos_x, int pos_y, byte[]array, byte my_color) {

    if (pos_x < 0 || pos_x >= this.mod_width_pix || pos_y < 0 || pos_y >= this.mod_height_pix) {
      return false;
    } else {
      return array[pos_y * this.mod_width_pix + pos_x] == my_color;
    }
  }

  // Display all pixels
  void display(int vertical_pos) {

    strokeWeight(0.5); //
    stroke(0); // Black lines
    fill(0);

    for (int row_pos=0; row_pos<this.mod_height_pix; row_pos++) {
      int row_pixel_index = row_pos * this.mod_width_pix;

      for (int col_pos=0; col_pos<this.mod_width_pix; col_pos++) {
        int pixel_index = row_pixel_index + col_pos;

        if (this.bin_array_copy[pixel_index] == 1) {
          fill(0);
          rect(
            GRID_PADDING_SIZE + this.mod_padding_x + (col_pos * PIXEL_SIZE),
            height/2 + (row_pos * PIXEL_SIZE) - (vertical_pos * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }

  void raz(byte[]source_array) {
    System.arraycopy(source_array, 0, this.tmp_bin_array, 0, this.mod_width_pix * this.mod_height_pix);
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
