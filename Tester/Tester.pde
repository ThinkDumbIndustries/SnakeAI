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
  myGame = new Game(new ZStarPlus());
  //FF = true;
  //PAUSED = false;
  DO_DEBUG = true;
}

int games_won = 0;
boolean FF = false;

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
}

void draw() {
  if (myGame.game_over) return;
  //if (frameCount%64==0)println(frameRate, games_won);
  background(0);
  if (!PAUSED || (keyPressed && key == '=')) {
    int count = 1;
    if (keyPressed && key != 'p') count = 5;
    if (FF && !keyPressed) count = 10000; //1000
    if (count != 1) for (int i = 0; i<count; i++) {
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
