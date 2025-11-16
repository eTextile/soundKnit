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
  int pattern;

  Patterns(int _height_pix) {

    this.height_pix = _height_pix;
    this.pattern_layers = new byte[PATTERN_LAYERS][TOTAL_WIDTH_PIX * this.height_pix];

    int pixel_index;
    int background_pixel = 0;
    for (int pattern=0; pattern<PATTERN_LAYERS; pattern++) {
      for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
        int row_pixel_index = row_pos * TOTAL_WIDTH_PIX;
        for (int col_pos=0; col_pos<TOTAL_WIDTH_PIX; col_pos++) {
          pixel_index = row_pixel_index + col_pos;
          background_pixel = pixel_index % (pattern + 1);
          this.pattern_layers[pattern][pixel_index] = (background_pixel == 0) ? (byte)1 : (byte)0;
        }
      }
    }
  }

  byte[]get(int pattern) {
    return this.pattern_layers[pattern];
  }

  void selector() {
    if (mouseX > 0 && mouseX < GRID_PADDING_SIZE) {
      //this.pattern = (this.pattern + 1) % this.cool_patterns.length;
      this.pattern = (this.pattern + 1) % PATTERN_LAYERS;
      //current_pattern = this.cool_patterns[this.pattern];
      current_pattern = this.pattern;
      println("selected_pattern: " + current_pattern);
    }
  }
}
