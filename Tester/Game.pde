boolean DO_DEBUG = false;

class Game {
  int step_count = 0;
  boolean game_over = false;
  boolean game_won = false;
  Pos head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
  Pos food;
  int snake_length = 1; // includes head and tail. Begins at 1
  int[][] grid = new int[GRID_SIZE][GRID_SIZE];
  int out_hammingdist_to_food;

  String output = "";
  Policy policy;

  Game(Policy policy) {
    this.policy = policy;
    resetGame();
  }

  void resetGame() {
    //println("Resetting game...");
    step_count = 0;
    game_over = false;
    game_won = false;
    head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
    snake_length = 1;
    grid = new int[GRID_SIZE][GRID_SIZE];
    makeFood();
    policy.reset(this);
    policy.updateFood(this);
  }

  void makeFood() {
    food = newFoodPos();
    out_hammingdist_to_food = abs(head.x - food.x) + abs(head.y - food.y);
  }

  int pdir = -1;
  boolean step() {
    int dir = policy.getDir(this);
    if (game_over) return true;
    //println("stepping...");
    pdir = dir;
    Pos new_head = head.copy();
    if (dir == UP) new_head.y--;
    else if (dir == DOWN) new_head.y++;
    else if (dir == LEFT) new_head.x--;
    else if (dir == RIGHT) new_head.x++;
    else {
      game_over = true;
      if (DO_DEBUG) println("Stop right there! I didn't understand your move... stopping game...");
      return true;
    }
    if (new_head.x < 0 || new_head.y <0 || new_head.x >= GRID_SIZE || new_head.y >= GRID_SIZE) {
      game_over = true;
      if (DO_DEBUG) println("Game Lost to border");
      step_count++;
      return true;
    }
    if (grid[new_head.x][new_head.y] > 1) {
      game_over = true;
      if (DO_DEBUG) println("Game lost - collision with tail");
      step_count++;
      return true;
    }
    head = new_head;
    if (head.equals(food)) {
      output += "(" + out_hammingdist_to_food + "," + (step_count+1) + ") ";
      snake_length++;
      grid[head.x][head.y] = snake_length;
      if (snake_length == GRID_SIZE*GRID_SIZE) {
        food = null;
        step_count++;
        game_over = true;
        game_won = true;
        if (DO_DEBUG) println("Good job - game won");
        games_won++;
        resetGame();
        return true;
      }
      makeFood();
      step_count++;
      policy.updateFood(this);
      return false;
    }
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j]>0)grid[i][j]--;
      }
    }
    grid[head.x][head.y] = snake_length;
    step_count++;
    return false;
  }

  void show() {
    //if (true) return; // skip drawing!
    translate(10, 10);
    policy.show(this);
    // Head
    noStroke();
    fill(0, 255, 0);
    ellipse(head.x*20, head.y*20, 20, 20);
    // Body
    for (int i = 0; i < GRID_SIZE-1; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j] == 0) continue;
        if (grid[i+1][j] == 0) continue;
        if (abs(grid[i][j]-grid[i+1][j]) != 1) continue;
        strokeWeight(map(min(grid[i][j], grid[i+1][j]), 1, snake_length, 5, 20));
        stroke(0, map(max(grid[i][j], grid[i+1][j]), 1, snake_length, 190, 255), 0);
        line(i*20, j*20, i*20+20, j*20);
      }
    }
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE-1; j++) {
        if (grid[i][j] == 0) continue;
        if (grid[i][j+1] == 0) continue;
        if (abs(grid[i][j]-grid[i][j+1]) != 1) continue;
        strokeWeight(map(min(grid[i][j], grid[i][j+1]), 1, snake_length, 5, 20));
        stroke(0, map(max(grid[i][j], grid[i][j+1]), 1, snake_length, 190, 255), 0);
        line(i*20, j*20, i*20, j*20+20);
      }
    }
    // Food
    noStroke();
    fill(255, 0, 0);
    rectMode(CENTER);
    if (food != null)rect(food.x*20, food.y*20, 16, 16);
  }

  Pos newFoodPos() {
    for (int i = 0; i < 40; i++) {
      Pos candidate = randomPos();
      if (candidate.equals(head)) continue;
      if (grid[candidate.x][candidate.y]>0) continue;
      return candidate;
    }
    ArrayList<Pos> candidates = new ArrayList<Pos>(0);
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (grid[i][j] == 0) candidates.add(new Pos(i, j));
      }
    }
    if (candidates.isEmpty()) {
      println("HEY! the game is done here!!! something's gone wrong - we shouldn't be trying to find a new food pos...");
      return null;
    }
    return candidates.get(floor(random(candidates.size())));
  }
}
