Policy myPolicy;

interface Policy {
  void reset();
  int getDir();
  void updateFood();
  void show();
}








import java.util.PriorityQueue;
import java.util.Comparator;

class AStar implements Policy {
  int[][] planning;

  void AStar() {
  }
  void reset() {
    planning = new int[GRID_SIZE][GRID_SIZE];
  }

  int getDir() {
    return getDir(true);
  }

  int getDir(boolean tryAgain) {
    println("STAR "+tryAgain);
    int x = head.x;
    int y = head.y;
    if (x > 0) if (planning[x][y]+1 == planning[x-1][y]) return LEFT;
    if (x < GRID_SIZE-1) if (planning[x][y]+1 == planning[x+1][y]) return RIGHT;
    if (y > 0) if (planning[x][y]+1 == planning[x][y-1]) return UP;
    if (y < GRID_SIZE-1) if (planning[x][y]+1 == planning[x][y+1]) return DOWN;
    // oops - we're out of strategy
    println("OUT OF STRATEGY!!! also, tryAgain: ", tryAgain);
    if (tryAgain) {
      updateFood();
      return getDir(false);
    }
    return -1;
  }

  void updateFood() {
    int[][] shortest = new int[GRID_SIZE][GRID_SIZE];
    boolean[][] reachable = new boolean[GRID_SIZE][GRID_SIZE];
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        planning[i][j] = 0;
        shortest[i][j] = 0;
        reachable[i][j] = false;
      }
    }
    Comparator<Pos> c = new Comparator<Pos>() {
      int compare(Pos p1, Pos p2) {
        //return d(p1)-d(p2);
        return shortest[p1.x][p1.y] - shortest[p2.x][p2.y];
      }
      int d(Pos p) {
        return abs(p.x-head.x)+abs(p.y-head.y); // Manhattan distance
      }
    };
    PriorityQueue<Pos> q = new PriorityQueue<Pos>(1, c);
    q.add(head);
    reachable[head.x][head.y] = true;
    while (!q.isEmpty()) {
      Pos p = q.poll();
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (grid[np.x][np.y] > shortest[p.x][p.y]+1) continue;
        if (reachable[np.x][np.y]) {
          shortest[np.x][np.y] = min(shortest[np.x][np.y], shortest[p.x][p.y]+1);
          continue;
        }
        reachable[np.x][np.y] = true;
        shortest[np.x][np.y] = shortest[p.x][p.y]+1;
        q.add(np);
        //println("Q: added ", nf(np.x, 2), ",", nf(np.y, 2));
        if (np.equals(food)) break;
      }
      //break;
    }
    if (reachable[food.x][food.y]) {
      Pos p = food.copy();
      while (!p.equals(head)) {
        println("while p : ", p.x, p.y, " (", shortest[p.x][p.y], ")");
        planning[p.x][p.y] = shortest[p.x][p.y];
        for (int d = 0; d < 5; d++) {
          if (d == 4) {
            println("OOOOO");
            p = head;
            break;
          }
          Pos np = p.copy();
          if (d == 0) np.x ++;
          if (d == 1) np.y ++;
          if (d == 2) np.x --;
          if (d == 3) np.y --;
          if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
          //println("for d : ", d, " np : ", np.x, np.y);
          if (shortest[np.x][np.y]+1 != shortest[p.x][p.y]) continue;
          p = np;
          break;
        }
      }
    }
    if (shortest[food.x][food.y] > abs(food.x-head.x)+abs(food.y-head.y)) PAUSED = true;
    for (int j = 0; j < GRID_SIZE; j++) {
      for (int i = 0; i < GRID_SIZE; i++) {
        print(nf(shortest[i][j], 2));
        print(" ");
      }
      println();
    }
    println("UPDATED");
    println(frameCount);
  }

  void show() {
    pushMatrix();
    //translate(-10, -10);
    stroke(255);
    strokeWeight(1);
    int x = head.x;
    int y = head.y;
    int lastPlan = planning[x][y];
    int endPlan = planning[food.x][food.y];
    endPlan = 1;
    //println("LASTPLAN : "+lastPlan);
    while (true) {
      noFill();
      ellipse(x*20, y*20, 3, 3);
      if (x > 0) if (lastPlan+1 == planning[x-1][y]) {
        line(x*20, y*20, x*20-20, y*20);
        x--;
        lastPlan++;
        continue;
      }
      if (x < GRID_SIZE-1) if (lastPlan+1 == planning[x+1][y]) {
        line(x*20, y*20, x*20+20, y*20);
        x++;
        lastPlan++;
        continue;
      }
      if (y > 0) if (lastPlan+1 == planning[x][y-1]) {
        line(x*20, y*20, x*20, y*20-20);
        y--;
        lastPlan++;
        continue;
      }
      if (y < GRID_SIZE-1) if (lastPlan+1 == planning[x][y+1]) {
        line(x*20, y*20, x*20, y*20+20);
        y++;
        lastPlan++;
        continue;
      }
      break;
    }
    popMatrix();
  }
}














class SmartZigZag implements Policy {
  int[] policy_cols;
  int NUM_COLS = GRID_SIZE/2-1;

  SmartZigZag() {
    reset();
  }
  void reset() {
    policy_cols = new int[NUM_COLS];
    for (int i = 0; i < NUM_COLS; i++) policy_cols[i] = floor(random(29));
  }

  void updateFood() {
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

    if (col_food == col) {
      if (!isUp && isLeft) {
        if (food.x == x) if (food.y > 0) if (food.y <= policy_cols[col]) policy_cols[col] = food.y-1;
        else {
          if (food.y == 0); // do some thinking
          else if (food.y <= policy_cols[col]) if (y >= grid[x][0]) policy_cols[col] = food.y-1;
        }
      }
      if (isUp && !isLeft) {
        if (food.x == x) if (food.y < 29) if (food.y > policy_cols[col]) policy_cols[col] = food.y;
        else {
          //if (food.y == 29); // do some thinking
          //else if (food.y > policy_cols[col])PAUSED=true;
          // if (y >= grid[x][0]) policy_cols[col] = food.y-1;
        }
      }
    }
    if (col_food < col) {
      if (food.x != 0 && food.x !=29) if (grid[2*col_food+1][0] == 0 && grid[2*col_food+2][0] == 0 && grid[2*col_food+1][29] == 0 && grid[2*col_food+2][29] == 0) policy_cols[col_food] = min(28, food.y);
      for (int i = col-1; i > col_food; i--) {
        if (grid[2*i+1][0] != 0 || grid[2*i+2][0] != 0 || grid[2*i+1][29] != 0 || grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 0;
      }
    }
    if (col_food > col) {
      if (food.x != 0 && food.x !=29) if (grid[2*col_food+1][0] == 0 && grid[2*col_food+2][0] == 0 && grid[2*col_food+1][29] == 0 && grid[2*col_food+2][29] == 0) policy_cols[col_food] = max(0, food.y-1);
      // There is stuff to do here...
      //if (!isUp) {
      //int minTimeToFood = 0;
      //if (isLeft && head.x > 0) minTimeToFood += policy_cols[col] - head.y;
      //minTimeToFood += GRID_SIZE - head.y;
      //PAUSED = true;
      //}
      for (int i = col+1; i < col_food; i++) {
        if (grid[2*i+1][0] != 0 || grid[2*i+2][0] != 0 || grid[2*i+1][29] != 0 || grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 28;
      }
    }
  }

  int getDir() {
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
  void show() {
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
}













class ZigZag implements Policy {
  ZigZag() {
  }
  void reset() {
  }
  void updateFood() {
  }
  int getDir() {
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
  void show() {
  }
}

//int dir = DOWN;

//void keyPressed() {
//  if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT) dir = keyCode;
//}
