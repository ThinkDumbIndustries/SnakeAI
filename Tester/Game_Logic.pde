int step_count = 0;
boolean game_over = false;
boolean game_won = false;
Pos head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
Pos food;
int snake_length = 1; // includes head and tail. Begins at 1
int[][] grid = new int[GRID_SIZE][GRID_SIZE];

void resetGame() {
  //println("Resetting game...");
  step_count = 0;
  game_over = false;
  game_won = false;
  head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
  snake_length = 1;
  grid = new int[GRID_SIZE][GRID_SIZE];
  food = newFoodPos();
  updatePolicy_food();
}

int pdir = -1;
void step(int dir) {
  if (game_over) return;
  //println("stepping...");
  pdir = dir;
  Pos new_head = head.copy();
  if (dir == UP) new_head.y--;
  else if (dir == DOWN) new_head.y++;
  else if (dir == LEFT) new_head.x--;
  else if (dir == RIGHT) new_head.x++;
  else {
    game_over = true;
    println("Stop right there! I didn't understand your move... stopping game...");
    return;
  }
  if (new_head.x < 0 || new_head.y <0 || new_head.x >= GRID_SIZE || new_head.y >= GRID_SIZE) {
    game_over = true;
    println("Game Lost to border");
    step_count++;
    return;
  }
  if (grid[new_head.x][new_head.y] != 0) {
    game_over = true;
    println("Game lost - collision with tail");
    step_count++;
    return;
  }
  head = new_head;
  if (head.equals(food)) {
    snake_length++;
    grid[head.x][head.y] = snake_length;
    if (snake_length == GRID_SIZE*GRID_SIZE) {
      food = null;
      step_count++;
      game_over = true;
      game_won = true;
      println("Good job - game won");
      outputRsult(step_count);
      games_won++;
      resetGame();
      return;
    }
    food = newFoodPos();
    step_count++;
    updatePolicy_food();
    return;
  }
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (grid[i][j]>0)grid[i][j]--;
    }
  }
  grid[head.x][head.y] = snake_length;
  step_count++;
  return;
}
