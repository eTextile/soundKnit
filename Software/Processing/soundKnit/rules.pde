/*
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class Rules {

  float mod_width;
  int mod_width_pix;

  float mod_height;
  int mod_height_pix;


  float right_pos_x;
  float left_pos_x;
  int left_pos_x_pix;

  int border_width_pix;
  float border_width;

  boolean moving_rules = false;

  int min_pos = 0;

  Rules(int _mod_width_pix, int _mod_height_pix) {

    this.mod_width_pix = _mod_width_pix;
    this.mod_height_pix = _mod_height_pix;

    this.mod_width = this.mod_width_pix * PIXEL_SIZE;
    this.mod_height  = this.mod_height_pix * PIXEL_SIZE;

    if (this.mod_width_pix + BORDER_WIDTH_PIX * 2 < STITCHES) {
      this.border_width_pix = BORDER_WIDTH_PIX;
    } else {
      this.border_width_pix = (int)((STITCHES - this.mod_width_pix) / 2);
    }
    this.border_width = this.border_width_pix * PIXEL_SIZE;
    
    this.left_pos_x = mod_offset_x - this.border_width;
    this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);

    this.right_pos_x = mod_offset_x + this.mod_width + this.border_width;
  }

  void display(int line_index) {

    textSize(34);
    strokeWeight(1.1);

    stroke(255, 0, 0);

    // Curent row
    line(0, height/2, width, height/2);
    line(0, height/2 + PIXEL_SIZE, width, height/2 + PIXEL_SIZE);
    fill(255, 0, 0);
    text(line_index, 15, height/2 + 40);

    // Left & right vertical red lines
    line(mod_offset_x, 0, mod_offset_x, height);
    line(mod_offset_x + this.mod_width, 0, mod_offset_x + this.mod_width, height);

    strokeWeight(2);
    stroke(0, 0, 190);
    line(this.left_pos_x, 0, this.left_pos_x, height);
    line(this.right_pos_x, 0, this.right_pos_x, height);

    if (this.left_pos_x_pix >= GRID_PADDING_PIX) {
      this.min_pos = (STITCHES / 2) - this.left_pos_x_pix + GRID_PADDING_PIX;
    }
    fill(0, 0, 190);
    text(this.min_pos, 15, height/2 - (line_index + 2) * PIXEL_SIZE);
  }

  void pressed() {
    // Si on clique proche de la ligne, on peut la déplacer
    if (abs(mouseX - this.left_pos_x) < 10) {
      this.moving_rules = true;
    }
  }

  float dragged() {

    if (this.moving_rules) {
      this.left_pos_x = (float)(PIXEL_SIZE * (int)(mouseX / PIXEL_SIZE));
      this.left_pos_x_pix = (int)(this.left_pos_x / PIXEL_SIZE);
      this.right_pos_x = mod_offset_x + this.mod_width + (mod_offset_x - this.left_pos_x);
    }
    return this.left_pos_x;
  }

  void released() {
    this.moving_rules = false;
  }
}
