class MyThread implements Runnable {
  Thread thread;
  String threadName;

  int step_count = 0;
  boolean game_over = false;
  boolean game_won = false;
  Pos head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
  Pos food;
  int snake_length = 1; // includes head and tail. Begins at 1
  int[][] grid = new int[GRID_SIZE][GRID_SIZE];

  void start(int i) {
    if (thread == null) {
      threadName = "Thread "+i;
      thread = new Thread(this, threadName);
      thread.start();
    }
  }

  MyThread() {
    food = newFoodPos();
  }
  void run() {
    try {
      while (true) {
        step(policy());
      }
    }
    catch(Exception e) {
    }
  }

  int policy() {
    int x = head.x;
    int y = head.y;
    if (y == 0) {
      if (x == 0) return DOWN;
      return LEFT;
    }
    if (y == 1) {
      if (x == 29) return UP;
      if (x%2 == 0) return DOWN;
      return RIGHT;
    }
    if (y == 29) {
      if (x%2 == 0) return RIGHT;
      return UP;
    }
    if (x%2 == 0) return DOWN;
    return UP;
  }

  void resetGame() {
    //println("Resetting game...");
    step_count = 0;
    game_over = false;
    game_won = false;
    head = new Pos(GRID_SIZE/2, GRID_SIZE/2);
    snake_length = 1;
    grid = new int[GRID_SIZE][GRID_SIZE];
    food = newFoodPos();
  }

  void step(int dir) {
    if (game_over) return;
    Pos new_head = head.copy();
    if (dir == UP) new_head.y--;
    else if (dir == DOWN) new_head.y++;
    else if (dir == LEFT) new_head.x--;
    else if (dir == RIGHT) new_head.x++;
    else {
      game_over = true;
      //println("Stop right there! I didn't understand your move... stopping game...");
    }
    if (new_head.x < 0 || new_head.y <0 || new_head.x >= GRID_SIZE || new_head.y >= GRID_SIZE) {
      //println("Game Lost to boder");
      game_over = true;
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
        //println("Good job - game won");
        outputRsult(step_count);
        resetGame();
        return;
      }
      food = newFoodPos();
      step_count++;
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

  Pos randomPos() {
    return new Pos(floor(random(GRID_SIZE)), floor(random(GRID_SIZE)));
  }
}
