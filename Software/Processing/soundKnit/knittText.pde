/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class KnittText {
  String text;
  PFont font;
  int size;

  int width_pix;
  int height_pix;

  int text_offset_x_pix = 0;

  String[]lignes;
  int total_line_width_pix;
  int line_height_pix;

  byte[]bin_array;

  KnittText(String input_text, String typo, int typo_size) {

    text = input_text;
    size = typo_size;
    lignes = split(text, '\n');
    font = createFont(typo, size);
    textFont(font);
    textSize(size);
    line_height_pix = (int)(textAscent() + textDescent());

    int line_count = 0;
    for (String ligne : lignes) {
      total_line_width_pix = (int)textWidth(ligne);
      if (total_line_width_pix > this.width_pix) {
        this.width_pix = total_line_width_pix;
      }
      line_count++;
    }

    // If the loaded image is less than 200 pixel (max size)
    if (this.width_pix > STITCHES) {
      error("Image width is to large!");
    } else {

      this.height_pix = line_count * line_height_pix; // TODO: add a litle space betwen lines
      text_offset_x_pix = (int)((STITCHES - this.width_pix) / 2); // Set the text in the middle of the 200 pix width grid

      this.bin_array = new byte[this.width_pix * this.height_pix];

      if (DEBUG) println("Line_count: " + line_count + " | total_line_width_pix: " + total_line_width_pix + " | line_height_pix: " + line_height_pix);

      line_count = 0;
      for (String ligne : lignes) {

        total_line_width_pix = (int)textWidth(ligne);

        PGraphics pg = createGraphics(total_line_width_pix, line_height_pix);
        pg.noSmooth();
        pg.beginDraw();
        pg.background(0);
        pg.fill(255);
        pg.textFont(font);
        pg.textAlign(LEFT, BASELINE);
        pg.text(ligne, 0, textAscent()); // Aligner le text correctement
        pg.endDraw();
        pg.loadPixels();

        for (int row_pos=0; row_pos<line_height_pix; row_pos++) {

          int pg_row_pixel_index = row_pos * total_line_width_pix;
          int row_pixel_index = row_pos * this.width_pix + (line_count * line_height_pix * this.width_pix);

          for (int col_pos=0; col_pos<total_line_width_pix; col_pos++) {

            int pg_pixel_index = pg_row_pixel_index + col_pos;
            int pixel_index = row_pixel_index + col_pos;

            color c = pg.pixels[pg_pixel_index];
            this.bin_array[pixel_index] = (byte)((brightness(c) > 10) ? 1 : 0);
          }
        }
        line_count++;
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
            GRID_PADDING_SIZE + (text_offset_x_pix * PIXEL_SIZE) + (col_pos * PIXEL_SIZE),
            height/2 + (row_pos * PIXEL_SIZE) - (vertical_pos * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }
}
