class MyThread implements Runnable {
  Thread thread;
  String threadName;

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
    setupPolicy2();
    resetGame();
    while (true) {
      step(policy());
    }
  }

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
        //println("Good job - game won");
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

  int policy() {
    //println("Asking for policy...");
    int dir = policy_2_adaptive_ham();
    //println("Got policy : "+dir);
    return dir;
    //return policy_1_constant_ham();
  }

  void updatePolicy_food() {
    updatePolicy2();
  }

  /////////////////////////////////////////////////////////////

  int[] policy_cols;
  int NUM_COLS = GRID_SIZE/2-1;

  void setupPolicy2() {
    policy_cols = new int[NUM_COLS];
    for (int i = 0; i < NUM_COLS; i++) policy_cols[i] = floor(random(29));
  }

  void showPolicy2() {
    pushMatrix();
    translate(-10, -10);
    stroke(255);
    strokeWeight(1);
    for (int i = 0; i < NUM_COLS; i++) {
      int y = 20*policy_cols[i]+20;
      line(i*40+20, y, i*40+60, y);
      line(i*40+40, 0, i*40+40, y-20);
      line(i*40+40, y+20, i*40+40, 600);
    }
    for (int i = 0; i < NUM_COLS-1; i++) {
      int y1 = 20*policy_cols[i]+20;
      int y2 = 20*policy_cols[i+1]+20;
      //line(i*40+60, y1, i*40+60, y2);
    }
    for (int x = 20; x < 600; x+=40) line(x, 20, x, 580);
    popMatrix();
  }

  void updatePolicy2() {
    int x = head.x;
    int y = head.y;
    int col = (x-1)/2;
    int col_food = (food.x-1)/2;
    int col_height = 0;
    if (x != 0 && x != 29) col_height = policy_cols[col];
    boolean isLeft = x%2 == 1;
    boolean isUp;
    if (x == 0) isUp = false;
    else if (x == 29) isUp = true;
    else isUp = y <= col_height;
    if (col_food < col) {
      if (food.x != 0 && food.x !=29) if (grid[2*col_food+1][0] == 0 && grid[2*col_food+2][0] == 0 && grid[2*col_food+1][29] == 0 && grid[2*col_food+2][29] == 0) policy_cols[col_food] = min(28, food.y);
      for (int i = col-1; i > col_food; i--) {
        if (grid[2*i+1][0] != 0 || grid[2*i+2][0] != 0 || grid[2*i+1][29] != 0 || grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 0;
      }
    }
    if (col_food > col) {
      if (food.x != 0 && food.x !=29) if (grid[2*col_food+1][0] == 0 && grid[2*col_food+2][0] == 0 && grid[2*col_food+1][29] == 0 && grid[2*col_food+2][29] == 0) policy_cols[col_food] = max(0, food.y-1);
      for (int i = col+1; i < col_food; i++) {
        if (grid[2*i+1][0] != 0 || grid[2*i+2][0] != 0 || grid[2*i+1][29] != 0 || grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 28;
      }
    }
  }

  int policy_2_adaptive_ham() {
    int x = head.x;
    int y = head.y;
    if (x == 0 && y < 29) return DOWN;
    if (x == 29 && y > 0) return UP;
    if (y == 0 && x%2 == 1) return LEFT;
    if (y == 29 && x%2 == 0) return RIGHT;
    int col = (x-1)/2;
    int col_height = policy_cols[col];
    boolean isLeft = x%2 == 1;
    if (y < col_height) {
      if (isLeft) return UP;
      return DOWN;
    }
    if (y == col_height) {
      if (isLeft) return UP;
      else return LEFT;
    }
    if (y == col_height+1) {
      if (isLeft) return RIGHT;
      return DOWN;
    }
    if (y > col_height+1) {
      if (isLeft) return UP;
      return DOWN;
    }
    return -1;
  }


  /////////////////////////////////////////////////////////////

  int policy_1_constant_ham() {
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
