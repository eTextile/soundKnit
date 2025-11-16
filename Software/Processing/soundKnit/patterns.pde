/*
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

final int PATTERN_LAYERS = 30;

class Patterns {

  int height_pix;
  byte[][]pattern_layers;

  int[]cool_patterns = {0, 1, 2, 3, 6, 8, 10, 12, 13, 18, 21, 26};
  int pattern_num;

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


  Patterns(int _height_pix) {

    this.height_pix = _height_pix;
    this.pattern_layers = new byte[PATTERN_LAYERS][TOTAL_WIDTH_PIX * this.height_pix];

    int pixel_index;
    int background_pixel;
    for (int pattern_index=0; pattern_index<PATTERN_LAYERS; pattern_index++) {
      for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
        int row_pixel_index = row_pos * TOTAL_WIDTH_PIX;
        for (int col_pos=0; col_pos<TOTAL_WIDTH_PIX; col_pos++) {
          pixel_index = row_pixel_index + col_pos;
          background_pixel = pixel_index % (pattern_index + 1);
          this.pattern_layers[pattern_index][pixel_index] = (background_pixel == 0) ? (byte)1 : (byte)0;
        }
      }
    }
  }

  byte[]get(int _pattern) {
    return this.pattern_layers[_pattern];
  }

  int selector() {
    if (mouseX > 0 && mouseX < GRID_PADDING_SIZE) {
      this.pattern_num = (this.pattern_num + 1) % this.cool_patterns.length;
      println("selected_pattern: " + this.pattern_num);
    }
    return this.cool_patterns[this.pattern_num];
  }
}
