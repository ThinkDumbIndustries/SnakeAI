int policy() {
  //println("Asking for policy...");
  int dir = policy_2_adaptive_ham();
  //println("Got policy : "+dir);
  return dir;
  //return policy_1_constant_ham();
}

/////////////////////////////////////////////////////////////

int[] policy_cols;
int NUM_COLS = GRID_SIZE/2-1;

void setupPolicy2() {
  policy_cols = new int[NUM_COLS];
  for (int i = 0; i < NUM_COLS; i++) policy_cols[i] = floor(random(29));
}

int policy_2_adaptive_ham() {
  int x = head.x;
  int y = head.y;
  if (x == 0 && y < 29) return DOWN;
  if (x == 29 && y> 0) return UP;
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
