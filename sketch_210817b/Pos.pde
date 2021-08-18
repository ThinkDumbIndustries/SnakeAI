class Pos {
  int x, y;
  Pos(int x, int y) {
    this.x=x;
    this.y=y;
  }
  Pos copy() {
    return new Pos(x, y);
  }
  boolean equals(Pos other) {
    if (other == null) return false;
    return x==other.x && y==other.y;
  }
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
