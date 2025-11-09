/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class Rules {

  float reight_pos_x;

  float left_pos_x;
  int left_pos_x_pix;

  float _width;
  int width_pix;

  float _height;
  int height_pix;

  float offset_x;
  int offset_x_pix;

  float border_width;
  int border_width_pix;

  boolean moving_rules = false;

  Rules(int _module_width_pix, int _module_height_pix) {

    this.width_pix = _module_width_pix;
    this.height_pix = _module_height_pix;

    this._width = this.width_pix * PIXEL_SIZE;
    this._height = this.height_pix * PIXEL_SIZE;

    this.border_width_pix = BORDER_WIDTH_PIX;

    this.offset_x = GRID_PADDING_SIZE + ((STITCHES - this.width_pix) / 2) * PIXEL_SIZE;
    this.offset_x_pix = (int)(this.offset_x / PIXEL_SIZE);

    this.left_pos_x = this.offset_x - this.border_width_pix * PIXEL_SIZE;
    this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);

    this.reight_pos_x = this.offset_x + this._width + this.border_width_pix * PIXEL_SIZE;
  }

  // Draw two red lines to visualise the current frame onto the pattern
  // ...
  void display(int line_index) {

    textSize(34);
    strokeWeight(1.1);
    stroke(255, 0, 0);

    // Curent row
    line(0, height/2, width, height/2);
    line(0, height/2 + PIXEL_SIZE, width, height/2 + PIXEL_SIZE);
    text(line_index, 30, height/2 - 10);

    // _module left & reight vertical lines
    line(this.offset_x, 0, this.offset_x, height);
    line(this.offset_x + this._width, 0, this.offset_x + this._width, height);

    strokeWeight(2);
    stroke(0, 0, 190);
    line(this.left_pos_x, 0, this.left_pos_x, height);
    line(this.reight_pos_x, 0, this.reight_pos_x, height);

    text(((STITCHES / 2) - this.left_pos_x_pix) + GRID_PADDING,
      this.left_pos_x - 60, height/2 - (line_index + 2) * PIXEL_SIZE);
  }

  void pressed() {
    // Si on clique proche de la ligne, on peut la déplacer
    if (abs(mouseX - this.left_pos_x) < 10) {
      moving_rules = true;
    }
  }

  float dragged(float _mouseX) {
    if (moving_rules) {
      this.border_width = this.offset_x - _mouseX;
      this.left_pos_x = (float)(PIXEL_SIZE * (int)(_mouseX / PIXEL_SIZE));
      this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);
      this.reight_pos_x = this.offset_x + this._width + (this.offset_x - left_pos_x);
    }
    return this.left_pos_x;
  }

  void released() {
    moving_rules = false;
  }
}
