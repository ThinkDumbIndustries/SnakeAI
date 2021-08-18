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
