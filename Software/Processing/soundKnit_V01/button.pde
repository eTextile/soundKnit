class Button {
  int size;
  boolean buttonState;
  int buttonLabel;

  // INIT
  Button() {
    size = width/18;
    buttonState = false;

  }

  void onClic( int mX, int mY, int pY, int pX ) {
    if ( mX>pX*size && mX<pX*size+size && mY>pY*size && mY<pY*size+size ) {
      buttonState =! buttonState;
      //
    }
  }

  void display( int pY, int pX ) {
    
    fill( 0 );
    rect( pX*size, pY*size, size, size, 3 );
    fill( 255 );
    text( buttonLabel, pX*size+size/3, pY*size+size/3-3 );
  }
}
