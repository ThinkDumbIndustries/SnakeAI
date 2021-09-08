final int GRID_SIZE = 30;
Game myGame;

void setup() {
  size(600, 620);
  pixelDensity(2);
  //frameRate(5);
  reset();
}

void reset() {
  myGame = new Game(makePolicy());
  FF = false;
  PAUSED = true;
  DO_DEBUG = true;

  int START_SNAKE_LENGTH = 1;
  myGame.snake_length = START_SNAKE_LENGTH;
  for (int i = 0; i < 1000000; i++) {
    if (myGame.step()) break;
    if (myGame.snake_length > START_SNAKE_LENGTH) break;
  }
}

int games_won = 0;

void mousePressed() {
  MAKE_CHANGES_COUNT++;
  if (true)return;
  FF = !FF;
  if (PAUSED) {
    PAUSED = false;
    FF = true;
  }
}

void keyPressed() {
  if (key == 'p') PAUSED = !PAUSED;
  if (key == 'r') reset();
  if (keyCode == 49) {
    FF = true;
    FF_SPEED = 0;
    PAUSED = false;
  }
  if (keyCode == 50) {
    FF = true;
    FF_SPEED = 1;
    PAUSED = false;
  }
  if (keyCode == 51) {
    FF = true;
    FF_SPEED = 2;
    PAUSED = false;
  }
  if (keyCode == 52) {
    FF = true;
    FF_SPEED = 3;
    PAUSED = false;
  }
  if (keyCode == 53) {
    for (int i = 0; i < 1000000; i++) {
      if (myGame.step()) break;
    }
    PAUSED = true;
  }
}
void keyReleased() {
  FF = false;
}

void draw() {
  //if (frameCount%20==0)println(frameRate, games_won);
  noStroke();
  fill(0, 60);
  //fill(255, 0, 0);
  rect(0, 0, 2*width, 2*height);
  //background(0);
  if (!myGame.game_over) if (!PAUSED || (keyPressed && key == '=')) {
    int count = 1;
    //if (keyPressed && key != 'p' && keyCode == SHIFT) count = 5;
    //if (FF && !keyPressed) count = 10000; //1000
    if (FF_SPEED == 0) count = 1;
    if (FF_SPEED == 1) count = 5;
    if (FF_SPEED == 2) count = 30;
    if (FF_SPEED == 3) count = 900;
    if (FF) for (int i = 0; i<count; i++) {
      if (myGame.step()) break;
      if (PAUSED) break;
    } else if (frameCount % 12 == 0) myGame.step();
  }
  myGame.show();

  // Step Counter
  pushMatrix();
  translate(-10, -10);
  translate(0, 600);
  textSize(20);
  fill(255);
  textAlign(LEFT, CENTER);
  text(myGame.step_count, 5, 7);
  text(myGame.snake_length, 100, 7);
  popMatrix();
}
