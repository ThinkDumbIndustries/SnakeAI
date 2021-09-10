class FastHPath {
  Pos start;
  int startPos;
  final int size = GRID_SIZE*GRID_SIZE;
  byte[] tabs;
  int[][] timingGrid;

  Pos cutPos, joinPos;

  FastHPath(Pos start) {
    this.start = start;
    this.startPos = 0;
    tabs = new byte[size];
  }
  FastHPath(Pos start, int startPos, byte[] tabs) {
    this.start = start;
    this.startPos = startPos;
    this.tabs = tabs;
  }
  void setTab(int pos, byte val) {
    tabs[(pos+startPos)%size] = val;
  }
  FastHPath copy() {
    byte[] tabs_copy = new byte[tabs.length];
    System.arraycopy(tabs, 0, tabs_copy, 0, tabs.length);
    return new FastHPath(start.copy(), startPos, tabs_copy);
  }
  void moveCopy(FastHPath src, int srcPos, int desPos, int len) {
    //println("moveCopy(srcPos : ", srcPos, ", desPos :", desPos, ", len :", len, ")");
    srcPos = (src.startPos+srcPos)%src.size;
    desPos = (startPos+desPos)%size;
    while (len > 0) {
      int sections = min(len, src.size - srcPos, size-desPos);
      System.arraycopy(src.tabs, srcPos, tabs, desPos, sections);
      len -= sections;
      srcPos = (srcPos+sections)%src.size;
      desPos = (desPos+sections)%size;
    }
  }
  int pop() {
    int move = tabs[startPos];
    startPos = (startPos+1) % size;
    movePosByDir(start, move);
    return move;
  }
  boolean WAS_COMPUTED = false;
  void computeTimingGrid() {
    WAS_COMPUTED = true;
    timingGrid = new int[GRID_SIZE][GRID_SIZE];
    Pos currentPos = start;
    int time = 0;
    for (int i = 0; i < size; i++) {
      int move = (int)tabs[(i+startPos)%size];
      timingGrid[currentPos.x][currentPos.y] = time;
      movePosByDir(currentPos, move);
      time ++;
    }
  }
  boolean isDirespectful(int[][] grid, int snake_length, Pos food) {
    if (!WAS_COMPUTED) println("checking for respect on uncomputed");
    int timeTillFood = timingGrid[food.x][food.y];
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (start.x == i && start.y == j) continue;
        if (grid[i][j] - timingGrid[i][j] > 0) return true; // this plan will lead to a collision
        if (grid[i][j]-timeTillFood > 0 && grid[i][j] != timingGrid[i][j]) return true;
      }
    }
    return false;
  }
  void show(Pos goal, color c1, color c2, boolean stop) {
    stroke(c1);
    Pos pos = start.copy();
    for (int i = 0; i < size; i++) {
      int move = (int)tabs[(i+startPos)%size];
      if (move == UP) line(20*pos.x, 20*pos.y, 20*pos.x, 20*pos.y-20);
      else if (move == LEFT) line(20*pos.x, 20*pos.y, 20*pos.x-20, 20*pos.y);
      else if (move == DOWN) line(20*pos.x, 20*pos.y, 20*pos.x, 20*pos.y+20);
      else if (move == RIGHT) line(20*pos.x, 20*pos.y, 20*pos.x+20, 20*pos.y);
      movePosByDir(pos, move);
      if (pos.equals(goal)) {
        if (stop) return;
        stroke(c2);
      }
    }
  }
}

interface CutConsumer {
  void consume(Pos cutPos);
}
abstract class CutJoinConsumer {
  FastHPath output_plan;
  abstract boolean consume(FastHPath plan, Pos cutPos, int[] cutQuadrantValues, int[] cutQuadrantPositions, Pos joinPos, int[] joinQuadrantValues, int[] joinQuadrantPositions);
}

FastHPath aHamiltonianPath(Pos pos) {
  FastHPath path = aHamiltonianPath();
  while (!path.start.equals(pos)) path.pop();
  path.computeTimingGrid();
  return path;
}

FastHPath aHamiltonianPath() {
  int[] moves = new int[GRID_SIZE*GRID_SIZE];
  moves[0] = RIGHT;
  int halfgrid = GRID_SIZE/2;
  for (int lrloop = 0; lrloop < halfgrid; lrloop++) {
    int off = lrloop*(2*GRID_SIZE-2);
    for (int x = 0; x < GRID_SIZE-2; x++) moves[1+off+x] = RIGHT;
    moves[off+GRID_SIZE-1] = DOWN;
    for (int x = 0; x < GRID_SIZE-2; x++) moves[off+GRID_SIZE+x] = LEFT;
    moves[off+2*GRID_SIZE-2] = DOWN;
  }
  moves[GRID_SIZE*(GRID_SIZE-1)] = LEFT;
  for (int x = 0; x < GRID_SIZE-1; x++) moves[GRID_SIZE*(GRID_SIZE-1)+1+x] = UP;
  //printArray(moves);
  FastHPath path = new FastHPath(new Pos(0, 0));
  for (int i = 0; i < moves.length; i++) path.setTab(i, (byte)(moves[i]));
  path.computeTimingGrid();
  return path;
}

Pos getQuadrantPos(Pos box, int p) {
  if (p == 0) return box;
  if (p == 1) return new Pos(box.x+1, box.y);
  if (p == 2) return new Pos(box.x, box.y+1);
  if (p == 3) return new Pos(box.x+1, box.y+1);
  else println("YOOOOOO p : ", p);
  return null;
}

boolean boxInBounds(Pos p) {
  //return ! (p.x < 0 || p.y < 0 || p.x >= GRID_SIZE-1 || p.y >= GRID_SIZE-1);
  return p.x >= 0 && p.y >= 0 && p.x < GRID_SIZE-1 && p.y < GRID_SIZE-1;
}
int gridAtThing(int[][] grid, Pos box, int lpos) {
  return grid[box.x+lpos%2][box.y+lpos/2];
}
int dirAtoB(int a, int b) {
  if (b-a == 1) return RIGHT;
  if (b-a == -1) return LEFT;
  if (b-a == 2) return DOWN;
  if (b-a == -2) return UP;
  return -1;
}
int[] getSortedPlanValues(int[][] plan, Pos box) {
  if (plan == null) println("getSortedPlanValues - plan is null");
  return sort4(getQuadrantsAt(plan, box));
}
int[] getSortedPlanPositions(int[][] plan, int[] sorted_plan_values, Pos box) {
  int[] o_plan_values = {
    plan[box.x][box.y], plan[box.x+1][box.y], plan[box.x][box.y+1], plan[box.x+1][box.y+1]
  };
  int[] sorted_positions = new int[4];
  for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) if (sorted_plan_values[i] == o_plan_values[j]) {
    sorted_positions[i] = j;
    break;
  }
  return sorted_positions;
}
int[] getQuadrantsAt(int[][] plan, Pos box) {
  if (plan == null) println("getQuadrantsAt - plan is null");
  if (box == null) println("getQuadrantsAt - box is null");
  return new int[]{
    plan[box.x][box.y], plan[box.x+1][box.y], plan[box.x][box.y+1], plan[box.x+1][box.y+1]
  };
}
int[] sort4(int[] in) {
  int[] out = {in[0], in[1], in[2], in[3]};
  int tmp;
  if (out[0] > out[1]) {
    tmp = out[0];
    out[0] = out[1];
    out[1] = tmp;
  }
  if (out[2] > out[3]) {
    tmp = out[2];
    out[2] = out[3];
    out[3] = tmp;
  }
  if (out[0] > out[2]) {
    tmp = out[0];
    out[0] = out[2];
    out[2] = tmp;
  }
  if (out[1] > out[3]) {
    tmp = out[1];
    out[1] = out[3];
    out[3] = tmp;
  }
  if (out[1] > out[2]) {
    tmp = out[1];
    out[1] = out[2];
    out[2] = tmp;
  }
  return out;
}
