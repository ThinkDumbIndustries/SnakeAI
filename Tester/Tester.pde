int GRID_SIZE = 30;

void setup() {
  size(600, 620);
  pixelDensity(2);
  //frameRate(5);

  //myPolicy = new ZigZag();
  //myPolicy = new SmartZigZag();
  myPolicy = new AStar();
  resetGame();
}

int games_won = 0;
boolean FF = false;
boolean PAUSED = false;

void mousePressed() {
  FF = !FF;
  if (PAUSED) {
    PAUSED = false;
    FF = true;
  }
}
void keyPressed() {
  if (key == 'p') PAUSED = !PAUSED;
}

void draw() {
  if (game_over) return;
  //if (frameCount%64==0)println(frameRate, games_won);
  background(0);
  if (!PAUSED || (keyPressed && key == '=')) {
    int count = 1;
    if (keyPressed && key != 'p') count = 5;
    if (FF && !keyPressed) count = 10000; //1000
    if (count != 1) for (int i = 0; i<count; i++) {
      step();
      if (PAUSED)break;
    } else if (frameCount % 12 == 0) step();
  }
  //if (true) return; // skip drawing!
  translate(10, 10);
  // Head
  noStroke();
  fill(0, 255, 0);
  ellipse(head.x*20, head.y*20, 20, 20);
  // Body
  stroke(0, 255, 0);
  for (int i = 0; i < GRID_SIZE-1; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (grid[i][j] == 0) continue;
      if (grid[i+1][j] == 0) continue;
      if (abs(grid[i][j]-grid[i+1][j]) != 1) continue;
      strokeWeight(map(min(grid[i][j], grid[i+1][j]), 1, snake_length, 5, 20));
      line(i*20, j*20, i*20+20, j*20);
    }
  }
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE-1; j++) {
      if (grid[i][j] == 0) continue;
      if (grid[i][j+1] == 0) continue;
      if (abs(grid[i][j]-grid[i][j+1]) != 1) continue;
      strokeWeight(map(min(grid[i][j], grid[i][j+1]), 1, snake_length, 5, 20));
      line(i*20, j*20, i*20, j*20+20);
    }
  }
  // Food
  noStroke();
  fill(255, 0, 0);
  rectMode(CENTER);
  if (food != null)rect(food.x*20, food.y*20, 16, 16);
  //
  myPolicy.show();

  // Step Counter
  translate(-10, -10);
  translate(0, 600);
  textSize(20);
  fill(255);
  textAlign(LEFT, CENTER);
  text(step_count, 5, 7);
  text(snake_length, 100, 7);
}

void outputRsult(int i) {
}
