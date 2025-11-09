/*
 BROTHER KH-940
 2025 (c) maurin@etextile.org
 Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
 This sketch read and knitt images & text
 The loded image must not be wider than 200 pixels
 */

class KnittPict {

  int width_pix;
  int height_pix;

  byte[]bin_array;

  int image_pixel_offset = 0;

  KnittPict(PImage input_image) {

    // If the loaded image is less than 200 pixel (max size)
    if (input_image.width > STITCHES) {
      error("Image width is to large!");
    } else {

      // Compute offset to set the pattern in the middle of the knitting machine
      image_pixel_offset = int(( STITCHES - input_image.width ) / 2);
      line_index = (input_image.height - 1);

      input_image.loadPixels();
      this.width_pix = input_image.width;
      this.height_pix = input_image.height;

      this.bin_array = new byte[this.width_pix * this.height_pix];

      if (DEBUG) println("Image - width: " + this.width_pix + " height: " + this.height_pix);

      for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
        int input_row_pixel_index = row_pos * this.width_pix;

        for (int col_pos=0; col_pos<this.width_pix; col_pos++) {
          int pixel_index = input_row_pixel_index + col_pos;

          this.bin_array[pixel_index] = (input_image.pixels[pixel_index] == BLACK) ? (byte)1 : (byte)0;
        }
      }
    }
  }

  byte[] get_array() {
    return this.bin_array;
  }

  // Display all pixels
  void display(int vertical_pos) {

    strokeWeight(0.5);
    stroke(0);           // Black lines
    fill(0);             // Black pisels 

    for (int row_pos=0; row_pos<this.height_pix; row_pos++) {
      int row_pixel_index = row_pos * this.width_pix;

      for (int col_pos=0; col_pos<this.width_pix; col_pos++) {
        int pixel_index = row_pixel_index + col_pos;

        if (this.bin_array[pixel_index] == 0) {
          rect(
            (col_pos * PIXEL_SIZE) + GRID_PADDING_SIZE + (image_pixel_offset * PIXEL_SIZE),
            height/2 + (row_pos * PIXEL_SIZE) - (vertical_pos * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
            );
        }
      }
    }
  }
}
