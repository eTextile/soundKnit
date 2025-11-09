class Grid {
  int my_width_pix = 0;
  int my_height_pix = 0;

  /*
 BROTHER KH-940
   2025 (c) maurin@etextile.org
   Used hardwear : AYAB shield V1.0 https://github.com/AllYarnsAreBeautiful/ayab-hardware
   This sketch read and knitt images & text
   The loded image must not be wider than 200 pixels
   */
   
  Grid(int grid_width, int grid_height) {

    my_width_pix = grid_width;
    my_height_pix = grid_height;
  }

  void display(int vertical_pos) {

    background(255);     // Clear trails
    strokeWeight(0.5);   //
    stroke(0);           // Black lines
    fill(255);
    for (int row_pos=0; row_pos<my_height_pix; row_pos++) {
      for (int col_pos=0; col_pos<my_width_pix; col_pos++) {
        rect(
          (col_pos * PIXEL_SIZE) + GRID_PADDING_SIZE,
          (row_pos * PIXEL_SIZE) + height/2 - (vertical_pos * PIXEL_SIZE),
          PIXEL_SIZE,
          PIXEL_SIZE
          );
      }
    }
  }
}
