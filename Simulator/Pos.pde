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
