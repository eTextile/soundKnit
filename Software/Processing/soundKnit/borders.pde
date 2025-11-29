/*
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class Borders {

  int mod_width_pix;
  float mod_width;
  int mod_height_pix;
  float mod_height;

  float border_left_pos_x;
  int border_left_pos_x_pix;
  float borders_pos_y;
  float border_width;
  int border_width_pix;

  byte[]pattern;

  Borders(byte[]_pattern, int _mod_width_pix, int _mod_height_pix) {

    this.pattern = _pattern;

    this.mod_width_pix = _mod_width_pix;
    this.mod_width = this.mod_width_pix * PIXEL_SIZE;

    this.mod_height_pix = _mod_height_pix;
    this.mod_height = this.mod_height_pix * PIXEL_SIZE;

    if (this.mod_width_pix + BORDER_WIDTH_PIX * 2 < STITCHES) {
      this.border_width_pix = BORDER_WIDTH_PIX;
    } else {
      this.border_width_pix = (int)((STITCHES - this.mod_width_pix) / 2);
    }
    this.border_width = this.border_width_pix * PIXEL_SIZE;

    this.border_left_pos_x = mod_offset_x - this.border_width;
    this.border_left_pos_x_pix = (int)(this.border_left_pos_x / PIXEL_SIZE);

}

  void display(int vertical_pos) {

    this.borders_pos_y = (height / 2) - vertical_pos * PIXEL_SIZE;

    fill(0);

    // Left border
    for (int row_pos=0; row_pos<this.mod_height_pix; row_pos++) {
      int pattern_row_pixel_index = row_pos * TOTAL_WIDTH_PIX;

      for (int col_pos=this.border_left_pos_x_pix; col_pos<mod_offset_x_pix; col_pos++) {
        int pattern_pixel_index = pattern_row_pixel_index + col_pos;

        if (this.pattern[pattern_pixel_index] == 1) {

          rect(
            (this.border_left_pos_x_pix + (col_pos - this.border_left_pos_x_pix)) * PIXEL_SIZE,
            this.borders_pos_y + row_pos * PIXEL_SIZE,
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }

    // Right border
    for (int row_pos=0; row_pos<this.mod_height_pix; row_pos++) {
      int pattern_row_pixel_index = row_pos * TOTAL_WIDTH_PIX;

      for (int col_pos = this.border_left_pos_x_pix + this.mod_width_pix; col_pos < this.border_left_pos_x_pix + this.mod_width_pix + this.border_width_pix; col_pos++) {
        int pattern_pixel_index = pattern_row_pixel_index + col_pos;

        if (this.pattern[pattern_pixel_index] == 1) {

          // Left border
          rect(
            col_pos * PIXEL_SIZE + this.border_width,
            this.borders_pos_y + row_pos * PIXEL_SIZE,
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }
  
  void update(byte[]pattern) {
    if (mouseX > this.border_left_pos_x && mouseX < (this.border_left_pos_x + this.border_width) ||
      mouseX > this.border_left_pos_x + this.mod_width && mouseX < this.border_left_pos_x + this.mod_width + this.border_width * 2) {
       this.pattern = pattern;
    }
  }
  
  
  void dragged(float left_rule_pos_x) {
    this.border_left_pos_x = left_rule_pos_x;

    if (this.border_left_pos_x >= GRID_PADDING_SIZE) {
      this.border_left_pos_x_pix = (int)(this.border_left_pos_x / PIXEL_SIZE);
      this.border_width = mod_offset_x - this.border_left_pos_x;
      this.border_width_pix = (int)(this.border_width / PIXEL_SIZE);
    }
  }
}
