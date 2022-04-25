import java.util.ArrayDeque;

ArrayDeque<Point> q = new ArrayDeque<Point>();

void floodFill(PImage input, byte[]binArray, byte[]pattern, int posX, int posY) {
  if (posX < 0 || posX > IMAGE_W - 1 || posY < 0 || posY > IMAGE_H - 1) return;
  input.loadPixels();
  int []pxl = input.pixels;
  int selectColor = pxl[posY * IMAGE_W + posX];
  int replacmentColor = (int)(random(1, 0xFFFFFF)) | 0xFF000000;
  
  Point p = new Point(posX, posY);
  //append(q, p);
  q.add(p);

  int west, east;
  while (!q.isEmpty () ) {
    p = q.removeFirst();

    if (isToFill(p.x, p.y, pxl, selectColor)) {

      west = east = p.x;

      while ( isToFill(--west, p.y, pxl, selectColor) );
      while ( isToFill(++east, p.y, pxl, selectColor) );

      for (int x = west + 1; x < east; x++) {

        int pixelIndex = p.y * IMAGE_W + x;
        pxl[pixelIndex] = replacmentColor;
        binArray[pixelIndex] = pattern[pixelIndex];

        if ( isToFill(x, p.y - 1, pxl, selectColor) ) {
          //println("x: " + x + " p.y: " + p.y--);
          q.add(new Point(x, p.y - 1));
        }
        if ( isToFill(x, p.y + 1, pxl, selectColor) ) {
          //println("x: " + x + " p.y: " + p.y++);
          q.add(new Point(x, p.y + 1));
        }
      }
    }
  }
}

// Returns true if the specified pixel requires filling
boolean isToFill(int posX, int posY, int[] pxl, int myColor) {
  if (posX < 0 || posX >= IMAGE_W || posY < 0 || posY >= IMAGE_H) {
    return false;
  } else {
    return pxl[posY * IMAGE_W + posX] == myColor;
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
