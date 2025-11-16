/*
 BROTHER KH-910 / KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

final boolean DEBUG_TEXT = true;

class KnittText {

  int width_pix;
  int height_pix;

  int text_padding_x_pix;
  float text_padding_x;

  String[]lines;
  int line_count;
  int line_width_pix;
  int line_height_pix;

  PFont font;

  byte[]bin_array;

  KnittText(String input_text, String typo, int typo_size) {

    this.lines = split(input_text, '\n');
    this.font = createFont(typo, typo_size);

    textFont(this.font);
    textSize(typo_size);

    this.line_height_pix = (int)(textAscent() + textDescent());

    this.line_count = 0;
    for (String line : this.lines) {
      this.line_width_pix = (int)textWidth(line);
      println("LINE_PIX_COUNT: " + this.line_width_pix);
      if (this.line_width_pix > this.width_pix) {
        this.width_pix = this.line_width_pix;
      }
      this.line_count++;
    }

    // If the loaded image is less than 200 pixel (max size)
    if (this.width_pix > STITCHES) {
      error("Image width is to large!");
    } else {

      this.height_pix = this.line_count * this.line_height_pix;
      this.text_padding_x_pix = (int)((STITCHES - this.width_pix) / 2); // Set the text in the middle of the 200 pix width grid
      this.text_padding_x = this.text_padding_x_pix * PIXEL_SIZE;

      this.bin_array = new byte[this.width_pix * this.height_pix];

      if (DEBUG_TEXT) println("line_count: " + this.line_count + " | this.width_pix: " + this.width_pix + " | line_height_pix: " + this.line_height_pix);

      this.line_count = 0;
      for (String line : this.lines) {

        this.line_width_pix = (int)textWidth(line);

        PGraphics pg = createGraphics(this.line_width_pix, this.line_height_pix);
        //pg.noSmooth();
        pg.beginDraw();
        pg.background(0);
        pg.fill(255);
        pg.textFont(this.font);
        pg.textAlign(LEFT, BASELINE);
        pg.text(line, 0, textAscent()); // Aliner le text correctement
        pg.endDraw();
        pg.loadPixels();

        for (int row_pos=0; row_pos<this.line_height_pix; row_pos++) {

          int pg_row_pixel_index = row_pos * this.line_width_pix;
          int row_pixel_index = row_pos * this.width_pix + (this.line_count * this.line_height_pix * this.width_pix);

          for (int col_pos=0; col_pos<this.line_width_pix; col_pos++) {

            int pg_pixel_index = pg_row_pixel_index + col_pos;
            int pixel_index = row_pixel_index + col_pos;

            color c = pg.pixels[pg_pixel_index];
            this.bin_array[pixel_index] = (byte)((brightness(c) > 10) ? 1 : 0);
          }
        }
        this.line_count++;
      }
    }
  }

  byte[] get_array() {
    return this.bin_array;
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
        if (this.bin_array[pixel_index] == 1) {
          fill(0);
          rect(
            GRID_PADDING_SIZE + text_padding_x_pix + (col_pos * PIXEL_SIZE),
            height/2 + (row_pos * PIXEL_SIZE) - (vertical_pos * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }
}
