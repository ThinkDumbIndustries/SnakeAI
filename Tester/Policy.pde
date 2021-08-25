boolean PAUSED = false;

interface Policy {
  void reset(Game g);
  int getDir(Game g);
  void updateFood(Game g);
  void show(Game g);
}










//  ______ _____ _             _____  _           
// |___  // ____| |           |  __ \| |          
//    / /| (___ | |_ __ _ _ __| |__) | |_   _ ___ 
//   / /  \___ \| __/ _` | '__|  ___/| | | | / __|
//  / /__ ____) | || (_| | |  | |    | | |_| \__ \
// /_____|_____/ \__\__,_|_|  |_|    |_|\__,_|___/
                                                
                                                


class ZStarPlus implements Policy {
  int[][] planning;

  boolean show_debug = false;
  boolean show_debug2 = false;
  ArrayList<Path> search_debug;
  int[][] debug_astarplan;

  ZStarPlus() {
  }
  void reset(Game g) {
    planning = new int[GRID_SIZE][GRID_SIZE];
  }
  int getDir(Game g) {
    int x = g.head.x;
    int y = g.head.y;
    if (x > 0) if (planning[x][y]+1 == planning[x-1][y]) return LEFT;
    if (x < GRID_SIZE-1) if (planning[x][y]+1 == planning[x+1][y]) return RIGHT;
    if (y > 0) if (planning[x][y]+1 == planning[x][y-1]) return UP;
    if (y < GRID_SIZE-1) if (planning[x][y]+1 == planning[x][y+1]) return DOWN;
    if (DO_DEBUG) println("Couldn't use int[][] planning to figure out where to go next...");
    return -1;
  }

  void updateFood(Game g) {
    int[][] astarplan = findastarplan(g);
    if (DO_DEBUG) debug_astarplan = astarplan;

    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        planning[i][j] = 0;
      }
    }
    Queue<Pos> q = new ArrayDeque<Pos>();
    boolean[][] addedtoq = new boolean[GRID_SIZE][GRID_SIZE];
    q.add(g.food);
    addedtoq[g.food.x][g.food.y] = true;
    stroke(50, 150, 230);
    strokeWeight(4);
    boolean FOUND_ENTIRE_PATH = false;
    while (!q.isEmpty()) {
      Pos p = q.poll();
      planning[p.x][p.y] = astarplan[p.x][p.y];
      if (p.equals(g.head)) FOUND_ENTIRE_PATH = true;
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (astarplan[np.x][np.y] == -1) continue;
        if (astarplan[p.x][p.y]-1 != astarplan[np.x][np.y]) continue;
        if (addedtoq[np.x][np.y]) continue;
        addedtoq[np.x][np.y] = true;
        q.add(np);
      }
    }
    if (FOUND_ENTIRE_PATH) return;
    if (DO_DEBUG) show_debug = true;
    if (DO_DEBUG) show_debug2 = true;
    findPath(g);
  }
  int[][] findastarplan(Game g) {
    int[][] astarplan = new int[GRID_SIZE][GRID_SIZE];
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        planning[i][j] = 0;
        astarplan[i][j] = -1;
      }
    }
    int COUNT = 0;
    PriorityQueue<WaitingPos> q = new PriorityQueue<WaitingPos>();
    q.add(new WaitingPos(g.head.x, g.head.y, 0));
    astarplan[g.head.x][g.head.y] = 0;
    while (!q.isEmpty()) {
      WaitingPos p = q.poll();
      if (astarplan[p.x][p.y] != -1 && astarplan[p.x][p.y] < p.waited) continue;
      for (int d = 0; d < 4; d++) {
        WaitingPos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        np.waited ++;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (g.grid[np.x][np.y] > np.waited) np.waited += 2*((1+g.grid[np.x][np.y]-np.waited)/2);
        if (astarplan[np.x][np.y] != -1 && np.waited >= astarplan[np.x][np.y]) continue;
        astarplan[np.x][np.y] = np.waited;
        q.add(np);
        COUNT++;
      }
    }
    return astarplan;
  }
  Path findPath(Game g) {
    int exploreCount = 0;
    PriorityQueue<Path> q = new PriorityQueue<Path>(1);
    q.add(new Path(g, g.head));
    if (DO_DEBUG) search_debug = new ArrayList<Path>();
    while (!q.isEmpty()) {
      if (exploreCount > 400000) {
        if (DO_DEBUG) println("Ran out of compute!!!");
        show_debug = true;
        PAUSED = true;
        return null;
      }
      Path path = q.poll();
      if (DO_DEBUG) search_debug.add(path);
      exploreCount++;
      if (path.head.equals(g.food)) {
        if (DO_DEBUG) println(path.deviations, exploreCount);
        return path;
      }
      for (int d = 0; d < 4; d++) {
        int dir = -1;
        if (d == 0) dir = RIGHT;
        if (d == 1) dir = DOWN;
        if (d == 2) dir = LEFT;
        if (d == 3) dir = UP;
        Pos nhead = path.head.copy();
        if (d == 0) nhead.x ++;
        if (d == 1) nhead.y ++;
        if (d == 2) nhead.x --;
        if (d == 3) nhead.y --;
        if (nhead.x < 0 || nhead.y < 0 || nhead.x >= GRID_SIZE || nhead.y >= GRID_SIZE) continue;
        if (g.grid[nhead.x][nhead.y] > path.size()+1) continue;
        if (path.occupancyGet(nhead)) continue;
        q.add(new Path(g, path, nhead, dir));
      }
    }
    return null;
  }

  void show(Game g) {
    if (show_debug2) {
      showDebug(g);
      showDebug2(g);
      return;
    }
    if (show_debug) {
      showDebug(g);
      return;
    }
    showGoodPath(g);
  }
  void showGoodPath(Game g) {
    pushMatrix();
    stroke(255);
    strokeWeight(1);
    Pos p = g.head;
    while (!p.equals(g.food)) {
      noFill();
      ellipse(p.x*20, p.y*20, 3, 3);
      boolean doBreak = true;
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (planning[p.x][p.y]+1 != planning[np.x][np.y]) continue;
        line(p.x*20, p.y*20, np.x*20, np.y*20);
        p = np;
        doBreak = false;
        break;
      }
      if (doBreak) break;
    }
    popMatrix();
  }
  void showDebug(Game g) {
    pushMatrix();
    Queue<Pos> q = new ArrayDeque<Pos>();
    boolean[][] addedtoq = new boolean[GRID_SIZE][GRID_SIZE];
    q.add(g.food);
    addedtoq[g.food.x][g.food.y] = true;
    strokeWeight(4);
    while (!q.isEmpty()) {
      Pos p = q.poll();
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (debug_astarplan[np.x][np.y] == -1) continue;
        if (debug_astarplan[p.x][p.y] > debug_astarplan[np.x][np.y]) {
          stroke(80);
          line(p.x*20, p.y*20, np.x*20, np.y*20);
        }
        if (debug_astarplan[p.x][p.y]-1 != debug_astarplan[np.x][np.y]) continue;
        stroke(50, 150, 230);
        line(p.x*20, p.y*20, np.x*20, np.y*20);
        if (addedtoq[np.x][np.y]) continue;
        addedtoq[np.x][np.y] = true;
        q.add(np);
      }
    }
    ////// SAME as code above, but starting from HEAD rather than TAIL, and with a different color
    //q = new ArrayDeque<Pos>();
    //addedtoq = new boolean[GRID_SIZE][GRID_SIZE];
    //q.add(g.head);
    //addedtoq[g.head.x][g.head.y] = true;
    //strokeWeight(4);
    //while (!q.isEmpty()) {
    //  Pos p = q.poll();
    //  for (int d = 0; d < 4; d++) {
    //    Pos np = p.copy();
    //    if (d == 0) np.x ++;
    //    if (d == 1) np.y ++;
    //    if (d == 2) np.x --;
    //    if (d == 3) np.y --;
    //    if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
    //    if (debug_astarplan[np.x][np.y] == -1) continue;
    //    if (debug_astarplan[p.x][p.y] < debug_astarplan[np.x][np.y]) {
    //      stroke(80);
    //      line(p.x*20, p.y*20, np.x*20, np.y*20);
    //    }
    //    if (debug_astarplan[p.x][p.y]+1 != debug_astarplan[np.x][np.y]) continue;
    //    stroke(150, 230, 50);
    //    line(p.x*20, p.y*20, np.x*20, np.y*20);
    //    if (addedtoq[np.x][np.y]) continue;
    //    addedtoq[np.x][np.y] = true;
    //    q.add(np);
    //  }
    //}

    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    for (int j = 0; j < GRID_SIZE; j++) {
      for (int i = 0; i < GRID_SIZE; i++) {
        text(debug_astarplan[i][j], 20*i, 20*j-2);
      }
    }
    popMatrix();
  }
  void showDebug2(Game g) {
    int id = constrain(floor(map(mouseX, 0, width, 0, search_debug.size())), 0, search_debug.size()-1);
    //println("Showing debug ", id, " of ", search_debug.size());
    Path path = search_debug.get(id);
    int x = g.head.x;
    int y = g.head.y;
    stroke(255);
    strokeWeight(1);
    for (int dir : path.dirs) {
      int nx = x;
      int ny = y;
      if (dir == RIGHT) nx ++;
      if (dir == DOWN) ny ++;
      if (dir == LEFT) nx --;
      if (dir == UP) ny --;
      line(x*20, y*20, nx*20, ny*20);
      x = nx;
      y = ny;
    }
  }
}



class Path implements Comparable<Path> {
  Game g;
  Pos head;
  int deviations;
  BitSet occupancy;
  ArrayDeque<Integer> dirs; // Queue<Integer> - must implement Cloneable... Scala's intersections might allow this without specifying the exact class?

  Path(Game g, Pos head) {
    this.g = g;
    this.head = head;
    deviations = 0;
    occupancy = new BitSet(GRID_SIZE*GRID_SIZE);
    occupancySet(head);
    dirs = new ArrayDeque<Integer>();
  }
  Path(Game g, Path parent, Pos nhead, int dir) {
    this.g = g;
    this.head = nhead;
    this.deviations = parent.deviations;
    if (dir == RIGHT && g.food.x <= parent.head.x) deviations++;
    if (dir == DOWN && g.food.y <= parent.head.y) deviations++;
    if (dir == LEFT && g.food.x >= parent.head.x) deviations++;
    if (dir == UP && g.food.y >= parent.head.y) deviations++;
    this.occupancy = (BitSet)parent.occupancy.clone();
    occupancySet(head);
    this.dirs = parent.dirs.clone();
    dirs.add(dir);
  }

  int size() {
    return dirs.size();
  }

  void occupancySet(Pos p) {
    occupancy.set(p.x+p.y*GRID_SIZE);
  }
  boolean occupancyGet(Pos p) {
    return occupancy.get(p.x+p.y*GRID_SIZE);
  }

  int compareTo(Path other) {
    if (deviations != other.deviations) return deviations - other.deviations;
    return distToFood() - other.distToFood();
  }
  int distToFood() {
    return abs(g.food.x-head.x)+abs(g.food.y-head.y);
  }
}



class WaitingPos extends Pos implements Comparable<WaitingPos> {
  int waited;
  WaitingPos(int x, int y, int waited) {
    super(x, y);
    this.waited = waited;
  }
  int compareTo(WaitingPos other) {
    return waited - other.waited;
  }
  WaitingPos copy() {
    return new WaitingPos(x, y, waited);
  }
}



















//  ______ _____ _             
// |___  // ____| |            
//    / /| (___ | |_ __ _ _ __ 
//   / /  \___ \| __/ _` | '__|
//  / /__ ____) | || (_| | |   
// /_____|_____/ \__\__,_|_|   
                             
                             

import java.util.BitSet;
import java.util.Queue;
import java.util.ArrayDeque;

class ZStar implements Policy {
  int[][] planning;

  boolean show_debug = false;
  ArrayList<Path> search_debug;

  ZStar() {
  }
  void reset(Game g) {
    planning = new int[GRID_SIZE][GRID_SIZE];
  }
  int getDir(Game g) {
    int x = g.head.x;
    int y = g.head.y;
    if (x > 0) if (planning[x][y]+1 == planning[x-1][y]) return LEFT;
    if (x < GRID_SIZE-1) if (planning[x][y]+1 == planning[x+1][y]) return RIGHT;
    if (y > 0) if (planning[x][y]+1 == planning[x][y-1]) return UP;
    if (y < GRID_SIZE-1) if (planning[x][y]+1 == planning[x][y+1]) return DOWN;
    // oops - we're out of strategy
    //for (int j = 0; j < GRID_SIZE; j++) {
    //  for (int i = 0; i < GRID_SIZE; i++) {
    //    print(nf(planning[i][j], 2));
    //    print(" ");
    //  }
    //  println();
    //}
    if (DO_DEBUG) println("Couldn't use int[][] planning to figure out where to go next...");
    return -1;
  }

  void updateFood(Game g) {
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        planning[i][j] = 0;
      }
    }
    Path path = findPath(g);
    if (path == null) return;
    //if (path.deviations > 0) PAUSED = true;
    Pos p = g.head;
    Integer[] dirs = new Integer[path.size()];
    path.dirs.toArray(dirs);
    for (int i = 0; i < dirs.length; i++) {
      Pos np = p.copy();
      if (dirs[i] == RIGHT) np.x ++;
      if (dirs[i] == DOWN) np.y ++;
      if (dirs[i] == LEFT) np.x --;
      if (dirs[i] == UP) np.y --;
      planning[np.x][np.y] = i+1;
      p = np;
    }
  }
  Path findPath(Game g) {
    int exploreCount = 0;
    PriorityQueue<Path> q = new PriorityQueue<Path>(1);
    q.add(new Path(g, g.head));
    if (DO_DEBUG) search_debug = new ArrayList<Path>();
    while (!q.isEmpty()) {
      if (exploreCount > 400000) {
        if (DO_DEBUG) println("Ran out of compute!!!");
        show_debug = true;
        PAUSED = true;
        g.policy = new ZStarPlus();
        g.policy.reset(g);
        g.policy.updateFood(g);
        return null;
      }
      Path path = q.poll();
      if (DO_DEBUG) search_debug.add(path);
      exploreCount++;
      if (path.head.equals(g.food)) {
        if (DO_DEBUG) println(path.deviations, exploreCount);
        return path;
      }
      for (int d = 0; d < 4; d++) {
        int dir = -1;
        if (d == 0) dir = RIGHT;
        if (d == 1) dir = DOWN;
        if (d == 2) dir = LEFT;
        if (d == 3) dir = UP;
        Pos nhead = path.head.copy();
        if (d == 0) nhead.x ++;
        if (d == 1) nhead.y ++;
        if (d == 2) nhead.x --;
        if (d == 3) nhead.y --;
        if (nhead.x < 0 || nhead.y < 0 || nhead.x >= GRID_SIZE || nhead.y >= GRID_SIZE) continue;
        if (g.grid[nhead.x][nhead.y] > path.size()+1) continue;
        if (path.occupancyGet(nhead)) continue;
        q.add(new Path(g, path, nhead, dir));
      }
    }
    return null;
  }

  void show(Game g) {
    if (show_debug) {
      showDebug(g);
      return;
    }
    pushMatrix();
    stroke(255);
    strokeWeight(1);
    Pos p = g.head;
    while (!p.equals(g.food)) {
      noFill();
      ellipse(p.x*20, p.y*20, 3, 3);
      boolean doBreak = true;
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (planning[p.x][p.y]+1 != planning[np.x][np.y]) continue;
        line(p.x*20, p.y*20, np.x*20, np.y*20);
        p = np;
        doBreak = false;
        break;
      }
      if (doBreak) break;
    }
    popMatrix();
  }
  void showDebug(Game g) {
    int id = constrain(floor(map(mouseX, 0, width, 0, search_debug.size())), 0, search_debug.size()-1);
    println("Showing debug ", id, " of ", search_debug.size());
    Path path = search_debug.get(id);
    int x = g.head.x;
    int y = g.head.y;
    stroke(255);
    strokeWeight(1);
    for (int dir : path.dirs) {
      int nx = x;
      int ny = y;
      if (dir == RIGHT) nx ++;
      if (dir == DOWN) ny ++;
      if (dir == LEFT) nx --;
      if (dir == UP) ny --;
      line(x*20, y*20, nx*20, ny*20);
      x = nx;
      y = ny;
    }
  }
}

class Path implements Comparable<Path> {
  Game g;
  Pos head;
  int deviations;
  BitSet occupancy;
  ArrayDeque<Integer> dirs; // Queue<Integer> - must implement Cloneable... Scala's intersections might allow this without specifying the exact class?

  Path(Game g, Pos head) {
    this.g = g;
    this.head = head;
    deviations = 0;
    occupancy = new BitSet(GRID_SIZE*GRID_SIZE);
    occupancySet(head);
    dirs = new ArrayDeque<Integer>();
  }
  Path(Game g, Path parent, Pos nhead, int dir) {
    this.g = g;
    this.head = nhead;
    this.deviations = parent.deviations;
    if (dir == RIGHT && g.food.x <= parent.head.x) deviations++;
    if (dir == DOWN && g.food.y <= parent.head.y) deviations++;
    if (dir == LEFT && g.food.x >= parent.head.x) deviations++;
    if (dir == UP && g.food.y >= parent.head.y) deviations++;
    this.occupancy = (BitSet)parent.occupancy.clone();
    occupancySet(head);
    this.dirs = parent.dirs.clone();
    dirs.add(dir);
  }

  int size() {
    return dirs.size();
  }

  void occupancySet(Pos p) {
    occupancy.set(p.x+p.y*GRID_SIZE);
  }
  boolean occupancyGet(Pos p) {
    return occupancy.get(p.x+p.y*GRID_SIZE);
  }

  int compareTo(Path other) {
    if (deviations != other.deviations) return deviations - other.deviations;
    return distToFood() - other.distToFood();
  }
  int distToFood() {
    return abs(g.food.x-head.x)+abs(g.food.y-head.y);
  }
}












//            _____ _             
//     /\    / ____| |            
//    /  \  | (___ | |_ __ _ _ __ 
//   / /\ \  \___ \| __/ _` | '__|
//  / ____ \ ____) | || (_| | |   
// /_/    \_\_____/ \__\__,_|_|   
                                
                                

import java.util.PriorityQueue;
import java.util.Comparator;

class AStar implements Policy {
  int[][] planning;

  AStar() {
  }
  void reset(Game g) {
    planning = new int[GRID_SIZE][GRID_SIZE];
  }

  int getDir(Game g) {
    return getDir(g, true);
  }

  int getDir(Game g, boolean tryAgain) {
    println("STAR "+tryAgain);
    int x = g.head.x;
    int y = g.head.y;
    if (x > 0) if (planning[x][y]+1 == planning[x-1][y]) return LEFT;
    if (x < GRID_SIZE-1) if (planning[x][y]+1 == planning[x+1][y]) return RIGHT;
    if (y > 0) if (planning[x][y]+1 == planning[x][y-1]) return UP;
    if (y < GRID_SIZE-1) if (planning[x][y]+1 == planning[x][y+1]) return DOWN;
    // oops - we're out of strategy
    println("OUT OF STRATEGY!!! also, tryAgain: ", tryAgain);
    if (tryAgain) {
      updateFood(g);
      return getDir(g, false);
    }
    return -1;
  }

  void updateFood(Game g) {
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
        return abs(p.x-g.head.x)+abs(p.y-g.head.y); // Manhattan distance
      }
    };
    PriorityQueue<Pos> q = new PriorityQueue<Pos>(1, c);
    q.add(g.head);
    reachable[g.head.x][g.head.y] = true;
    while (!q.isEmpty()) {
      Pos p = q.poll();
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (g.grid[np.x][np.y] > shortest[p.x][p.y]+1) continue;
        if (reachable[np.x][np.y]) {
          shortest[np.x][np.y] = min(shortest[np.x][np.y], shortest[p.x][p.y]+1);
          continue;
        }
        reachable[np.x][np.y] = true;
        shortest[np.x][np.y] = shortest[p.x][p.y]+1;
        q.add(np);
        //println("Q: added ", nf(np.x, 2), ",", nf(np.y, 2));
        if (np.equals(g.food)) break;
      }
      //break;
    }
    if (reachable[g.food.x][g.food.y]) {
      Pos p = g.food.copy();
      while (!p.equals(g.head)) {
        println("while p : ", p.x, p.y, " (", shortest[p.x][p.y], ")");
        planning[p.x][p.y] = shortest[p.x][p.y];
        for (int d = 0; d < 5; d++) {
          if (d == 4) {
            println("OOOOO");
            p = g.head;
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
    if (shortest[g.food.x][g.food.y] > abs(g.food.x-g.head.x)+abs(g.food.y-g.head.y)) PAUSED = true;
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

  void show(Game g) {
    pushMatrix();
    //translate(-10, -10);
    stroke(255);
    strokeWeight(1);
    Pos p = g.head;
    while (!p.equals(g.food)) {
      noFill();
      ellipse(p.x*20, p.y*20, 3, 3);
      boolean doBreak = true;
      for (int d = 0; d < 4; d++) {
        Pos np = p.copy();
        if (d == 0) np.x ++;
        if (d == 1) np.y ++;
        if (d == 2) np.x --;
        if (d == 3) np.y --;
        if (np.x < 0 || np.y < 0 || np.x >= GRID_SIZE || np.y >= GRID_SIZE) continue;
        if (planning[p.x][p.y]+1 != planning[np.x][np.y]) continue;
        line(p.x*20, p.y*20, np.x*20, np.y*20);
        p = np;
        doBreak = false;
        break;
      }
      if (doBreak) break;
    }
    popMatrix();
  }
}














//   _____                      _   _______       ______           
//  / ____|                    | | |___  (_)     |___  /           
// | (___  _ __ ___   __ _ _ __| |_   / / _  __ _   / / __ _  __ _ 
//  \___ \| '_ ` _ \ / _` | '__| __| / / | |/ _` | / / / _` |/ _` |
//  ____) | | | | | | (_| | |  | |_ / /__| | (_| |/ /_| (_| | (_| |
// |_____/|_| |_| |_|\__,_|_|   \__/_____|_|\__, /_____\__,_|\__, |
//                                           __/ |            __/ |
//                                          |___/            |___/ 


class SmartZigZag implements Policy {
  int[] policy_cols;
  int NUM_COLS = GRID_SIZE/2-1;

  SmartZigZag() {
  }
  void reset(Game g) {
    policy_cols = new int[NUM_COLS];
    for (int i = 0; i < NUM_COLS; i++) policy_cols[i] = floor(random(29));
  }

  void updateFood(Game g) {
    int x = g.head.x;
    int y = g.head.y;
    int col = (x-1)/2;
    int col_food = (g.food.x-1)/2;
    int col_height = 0;
    if (x != 0 && x != 29) col_height = policy_cols[col];

    boolean isLeft = x%2 == 1;
    boolean isUp;
    if (x == 0) isUp = false;
    else if (x == 29) isUp = true;
    else isUp = y <= col_height;

    if (col_food == col) {
      if (!isUp && isLeft) {
        if (g.food.x == x) if (g.food.y > 0) if (g.food.y <= policy_cols[col]) policy_cols[col] = g.food.y-1;
        else {
          if (g.food.y == 0); // do some thinking
          else if (g.food.y <= policy_cols[col]) if (y >= g.grid[x][0]) policy_cols[col] = g.food.y-1;
        }
      }
      if (isUp && !isLeft) {
        if (g.food.x == x) if (g.food.y < 29) if (g.food.y > policy_cols[col]) policy_cols[col] = g.food.y;
        else {
          //if (food.y == 29); // do some thinking
          //else if (food.y > policy_cols[col])PAUSED=true;
          // if (y >= grid[x][0]) policy_cols[col] = food.y-1;
        }
      }
    }
    if (col_food < col) {
      if (g.food.x != 0 && g.food.x !=29) if (g.grid[2*col_food+1][0] == 0 && g.grid[2*col_food+2][0] == 0 && g.grid[2*col_food+1][29] == 0 && g.grid[2*col_food+2][29] == 0) policy_cols[col_food] = min(28, g.food.y);
      for (int i = col-1; i > col_food; i--) {
        if (g.grid[2*i+1][0] != 0 || g.grid[2*i+2][0] != 0 || g.grid[2*i+1][29] != 0 || g.grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 0;
      }
    }
    if (col_food > col) {
      if (g.food.x != 0 && g.food.x !=29) if (g.grid[2*col_food+1][0] == 0 && g.grid[2*col_food+2][0] == 0 && g.grid[2*col_food+1][29] == 0 && g.grid[2*col_food+2][29] == 0) policy_cols[col_food] = max(0, g.food.y-1);
      // There is stuff to do here...
      //if (!isUp) {
      //int minTimeToFood = 0;
      //if (isLeft && head.x > 0) minTimeToFood += policy_cols[col] - head.y;
      //minTimeToFood += GRID_SIZE - head.y;
      //PAUSED = true;
      //}
      for (int i = col+1; i < col_food; i++) {
        if (g.grid[2*i+1][0] != 0 || g.grid[2*i+2][0] != 0 || g.grid[2*i+1][29] != 0 || g.grid[2*i+2][29] != 0) continue;
        policy_cols[i] = 28;
      }
    }
  }

  int getDir(Game g) {
    int x = g.head.x;
    int y = g.head.y;
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
  void show(Game g) {
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













//  _______       ______           
// |___  (_)     |___  /           
//    / / _  __ _   / / __ _  __ _ 
//   / / | |/ _` | / / / _` |/ _` |
//  / /__| | (_| |/ /_| (_| | (_| |
// /_____|_|\__, /_____\__,_|\__, |
//           __/ |            __/ |
//          |___/            |___/ 


class ZigZag implements Policy {
  ZigZag() {
  }
  void reset(Game g) {
  }
  void updateFood(Game g) {
  }
  int getDir(Game g) {
    int x = g.head.x;
    int y = g.head.y;
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
  void show(Game g) {
  }
}

//int dir = DOWN;

//void keyPressed() {
//  if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT) dir = keyCode;
//}
