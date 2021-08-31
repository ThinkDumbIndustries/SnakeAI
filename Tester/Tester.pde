int GRID_SIZE = 30;
Game myGame;

void setup() {
  size(600, 620);
  pixelDensity(2);
  //frameRate(5);
  reset();
}

void reset() {
  //myGame = new Game(new ZigZag());
  //myGame = new Game(new SmartZigZag());
  //myGame = new Game(new AStar());
  //myGame = new Game(new ZStar());
  //myGame = new Game(new ZStarPlus());
  //myGame = new Game(new LazySpiral());
  //myGame = new Game(new LazySpiralModed());
  myGame = new Game(new ReachFromEdge());
  FF = false;
  PAUSED = false;
  DO_DEBUG = true;

  //for (int i = 0; i < 1000000; i++) {
  //  if (myGame.step()) break;
  //  //if (myGame.snake_length > 100) break;
  //}
}

int games_won = 0;

void mousePressed() {
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
  }
  if (keyCode == 50) {
    FF = true;
    FF_SPEED = 1;
  }
  if (keyCode == 51) {
    FF = true;
    FF_SPEED = 2;
  }
  if (keyCode == 52) {
    FF = true;
    FF_SPEED = 3;
  }
}
void keyReleased() {
  FF = false;
}

void draw() {
  //if (frameCount%20==0)println(frameRate, games_won);
  background(0);
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
