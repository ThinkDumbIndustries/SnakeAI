Pos rotatePos90(Pos p) {
  if (p == null) return null;
  return new Pos(GRID_SIZE-1-p.y, p.x);
}
Pos rotatePos180(Pos p) {
  if (p == null) return null;
  return new Pos(GRID_SIZE-1-p.x, GRID_SIZE-1-p.y);
}
Pos rotatePos270(Pos p) {
  if (p == null) return null;
  return new Pos(p.y, GRID_SIZE-1-p.x);
}
boolean onEdge(Pos p) {
  if (p == null) return false;
  return p.x == 0 || p.y == 0 || p.x == GRID_SIZE-1 || p.y == GRID_SIZE - 1;
}
boolean inBounds(Pos p) {
  if (p == null) return false;
  return p.x >= 0 && p.y >= 0 && p.x < GRID_SIZE && p.y < GRID_SIZE;
}
int gridAtPos(int[][] grid, Pos p) {
  return grid[p.x][p.y];
}
Pos movePosByDir(Pos p, int dir) {
  if (p == null) return null;
  if (dir == UP) return new Pos(p.x, p.y - 1);
  if (dir == LEFT) return new Pos(p.x - 1, p.y);
  if (dir == DOWN) return new Pos(p.x, p.y + 1);
  if (dir == RIGHT) return new Pos(p.x + 1, p.y);
  return null;
}
int rotateDir90(int dir) {
  if (dir == UP) return LEFT;
  if (dir == LEFT) return DOWN;
  if (dir == DOWN) return RIGHT;
  if (dir == RIGHT) return UP;
  return -1;
}
int rotateDir180(int dir) {
  if (dir == UP) return DOWN;
  if (dir == LEFT) return RIGHT;
  if (dir == DOWN) return UP;
  if (dir == RIGHT) return LEFT;
  return -1;
}
int rotateDir270(int dir) {
  if (dir == UP) return RIGHT;
  if (dir == RIGHT) return DOWN;
  if (dir == DOWN) return LEFT;
  if (dir == LEFT) return UP;
  return -1;
}
