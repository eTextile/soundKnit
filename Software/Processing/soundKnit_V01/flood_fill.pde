import java.util.ArrayDeque;

ArrayDeque<Point> q = new ArrayDeque<Point>();

void flood_fill(PImage input, byte[]bin_array, byte[]pattern, int pos_x, int pos_y) {

  if (pos_x < 0 || pos_x > image_w - 1 || pos_y < 0 || pos_y > image_h - 1) return;
  input.loadPixels();
  int []pos_xl = input.pixels;

  int select_color = pos_xl[pos_y * image_w + pos_x];
  int replacment_color = (int)(random(1, 0xFFFFFF)) | 0xFF000000;
  
  Point p = new Point(pos_x, pos_y);
  q.add(p);

  int west, east;
  while (!q.isEmpty () ) {
    p = q.removeFirst();

    if (isToFill(p.x, p.y, pos_xl, select_color)) {

      west = east = p.x;

      while ( isToFill(--west, p.y, pos_xl, select_color) );

      while ( isToFill(++east, p.y, pos_xl, select_color) );

      for (int x = west + 1; x < east; x++) {

        int pixel_index = p.y * image_w + x;
        pos_xl[pixel_index] = byte(replacment_color);

        bin_array[pixel_index] = pattern[pixel_index];

        if ( isToFill(x, p.y - 1, pos_xl, select_color) ) {
          //println("x: " + x + " p.y: " + p.y--);
          q.add(new Point(x, p.y - 1));
        }
        if ( isToFill(x, p.y + 1, pos_xl, select_color) ) {
          //println("x: " + x + " p.y: " + p.y++);
          q.add(new Point(x, p.y + 1));
        }
      }
    }
  }
}

// Returns true if the specified pixel requires filling
boolean isToFill(int pos_x, int pos_y, int[] pos_xl, int myColor) {
//boolean isToFill(int pos_x, int pos_y, byte[] pos_xl, int myColor) {

  if (pos_x < 0 || pos_x >= image_w || pos_y < 0 || pos_y >= image_h) {
    return false;
  } else {
    return pos_xl[pos_y * image_w + pos_x] == myColor;
  }
}

// Could use java.awt.Point instead
class Point {
  int x, y;

  public Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
