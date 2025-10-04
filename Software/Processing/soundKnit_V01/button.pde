class Button {
  int size;
  boolean buttonState;
  int buttonLabel;

  // INIT
  Button() {
    size = width/18;
    buttonState = false;

  }

  void onClic( int mX, int mY, int pos_y, int pos_x ) {
    if ( mX>pos_x*size && mX<pos_x*size+size && mY>pos_y*size && mY<pos_y*size+size ) {
      buttonState =! buttonState;
      //
    }
  }

  void display( int pos_y, int pos_x ) {
    
    fill( 0 );
    rect( pos_x*size, pos_y*size, size, size, 3 );
    fill( 255 );
    text( buttonLabel, pos_x*size+size/3, pos_y*size+size/3-3 );
  }
}
