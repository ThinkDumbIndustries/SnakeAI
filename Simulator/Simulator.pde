PrintWriter output;

int GRID_SIZE = 30;

int THREAD_COUNT = 6;
MyThread[] threads = new MyThread[THREAD_COUNT];

void setup() {
  DO_DEBUG = false;
  //size(600, 620);
  //pixelDensity(2);
  //frameRate(5);

  output = createWriter(getNewFilename());
  output.println(makePolicy().getClass().getSimpleName());
  for (int i = 0; i < THREAD_COUNT; i++) {
    threads[i] = new MyThread();
    threads[i].start(i);
    println(i);
  }
}

String getNewFilename() {
  String filename;
  int i = 0;
  do {
    filename = "/Users/maximilientirard/Documents/Processing/SnakeAI/policies2/policy"+i+".txt";
    i++;
  } while ((new File(filename)).exists());
  return filename;
}

synchronized void outputRsult(String txt) {
  games_won++;
  games_won_total++;
  output.println(txt.trim());
  output.flush();
}

//int dir = DOWN;

//void keyPressed() {
//  if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT) dir = keyCode;
//}

int games_won = 0;
int games_won_total = 0;

void draw() {
  if (frameCount%60==0) {
    println(frameRate, games_won_total, games_won);
    games_won = 0;
  }
  background(0);
  fill(255);
  textAlign(LEFT, TOP);
  for (int i = 0; i < THREAD_COUNT; i++) {
    text(threads[i].game.snake_length, 2, 2+15*i);
  }
  if (games_won_total > 100) exit();
}

void gui() {
  //translate(10, 10);
  //// Head
  //noStroke();
  //fill(0, 255, 0);
  //ellipse(head.x*20, head.y*20, 20, 20);
  //// Body
  //stroke(0, 255, 0);
  //for (int i = 0; i < GRID_SIZE-1; i++) {
  //  for (int j = 0; j < GRID_SIZE; j++) {
  //    if (grid[i][j] == 0) continue;
  //    if (grid[i+1][j] == 0) continue;
  //    if (abs(grid[i][j]-grid[i+1][j]) != 1) continue;
  //    strokeWeight(map(min(grid[i][j], grid[i+1][j]), 1, snake_length, 5, 20));
  //    line(i*20, j*20, i*20+20, j*20);
  //  }
  //}
  //for (int i = 0; i < GRID_SIZE; i++) {
  //  for (int j = 0; j < GRID_SIZE-1; j++) {
  //    if (grid[i][j] == 0) continue;
  //    if (grid[i][j+1] == 0) continue;
  //    if (abs(grid[i][j]-grid[i][j+1]) != 1) continue;
  //    strokeWeight(map(min(grid[i][j], grid[i][j+1]), 1, snake_length, 5, 20));
  //    line(i*20, j*20, i*20, j*20+20);
  //  }
  //}
  //// Food
  //noStroke();
  //fill(255, 0, 0);
  //rectMode(CENTER);
  //if (food != null)rect(food.x*20, food.y*20, 16, 16);
  //// Step Counter
  //translate(-10, -10);
  //translate(0, 600);
  //textSize(20);
  //fill(255);
  //textAlign(LEFT, CENTER);
  //text(step_count, 5, 7);
}
