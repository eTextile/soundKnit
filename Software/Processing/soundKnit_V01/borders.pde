/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class Borders {

  float left_pos_x;
  int left_pos_x_pix;

  int width_pix;
  float _width;

  int height_pix;
  float _height;

  float x_offset;
  int x_offset_pix;

  float borders_pos_y;

  float border_width;
  int border_width_pix;

  int layers = 10;
  byte[][]pattern_layers;
  int selected_pattern = 3;

  Borders(int module_width_pix, int module_height_pix, int border_width_pix_default) {

    this.width_pix = module_width_pix;
    this._width = this.width_pix * PIXEL_SIZE;

    this.height_pix = module_height_pix;
    this._height = this.height_pix * PIXEL_SIZE;

    this.border_width_pix = border_width_pix_default;
    this.border_width = this.border_width_pix * PIXEL_SIZE;

    this.x_offset = GRID_PADDING_SIZE + ((STITCHES - this.width_pix) / 2) * PIXEL_SIZE;
    this.x_offset_pix = (int)(this.x_offset / PIXEL_SIZE);

    this.left_pos_x = this.x_offset - border_width;
    this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);

    pattern_layers = new byte[layers][this.x_offset_pix * this.height_pix];

    for (int pattern=0; pattern<layers; pattern++) {
      for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
        int row_pixel_index = row_pos * this.x_offset_pix;
        for (int col_pos=0; col_pos<this.x_offset_pix; col_pos++) {
          int pixel_index = row_pixel_index + col_pos;
          int background_pixel = pixel_index % (pattern + 2);
          pattern_layers[pattern][pixel_index] = (background_pixel == 0) ? (byte)1 : (byte)0;
        }
      }
    }
  }

  void display(int vertical_pos) {

    borders_pos_y = (height / 2) - vertical_pos * PIXEL_SIZE;
    fill(0);

    for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
      int row_pixel_index = row_pos * this.x_offset_pix;

      for (int col_pos=0; col_pos<this.border_width_pix; col_pos++) {
        int pixel_index = row_pixel_index + col_pos;

        if (pattern_layers[this.selected_pattern][pixel_index] == 1) {

          // Left border
          rect(
            this.x_offset - (col_pos + 1) * PIXEL_SIZE,
            borders_pos_y + row_pos * PIXEL_SIZE,
            PIXEL_SIZE,
            PIXEL_SIZE
            );

          // Reight border
          rect(
            this.x_offset + this._width + col_pos * PIXEL_SIZE,
            borders_pos_y + row_pos * PIXEL_SIZE,
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }

  void dragged(float left_rule_pos_x) {
    this.left_pos_x = left_rule_pos_x;
    this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);
    this.border_width = this.x_offset - this.left_pos_x;
    this.border_width_pix = (int)(this.border_width / PIXEL_SIZE);
  }

  byte[]pattern() {
    if (mouseX > this.left_pos_x && mouseX < this.left_pos_x + this.border_width) {
      this.selected_pattern = (this.selected_pattern + 1) % 10;
    }
    return pattern_layers[this.selected_pattern];
  }
}
