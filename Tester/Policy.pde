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
