import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.lang.System;

Policy makePolicy() {
  //return new ZigZag();
  //return new SmartZigZag();
  //return new AStar();
  //return new ZStar();
  //return new ZStarPlus();
  //return new LazySpiral();
  //return new LazySpiralModed();
  //return new ReachFromEdge();
  return new HamiltonianPathSA();
}

int MAKE_CHANGES_COUNT = 0;

class HamiltonianPathSA implements Policy {
  Path plan = null;
  int[][] planTimingGrid = new int[0][0];
  int[] cachedPossibilites = new int[0];
  HamiltonianPathSA() {
  }
  void reset(Game g) {
    setPlan(g, aHamiltonianPath(g.head));
    for (int i = 0; i < 100; i++) {
      DEBUG_ID = floor(random(cachedPossibilites.length));
      int encoded = cachedPossibilites[DEBUG_ID];
      setPlan(g, introducePerturbation(plan, encoded));
    }
  }
  Path debug_plan_after_food_update = null;
  float[] debug_scores = new float[0];
  float[] debug_scores_record = new float[0];
  ArrayList<Integer> debug_interesting_perturbations = new ArrayList<Integer>();

  void updateFood(Game g) {
    setPlan(g, plan);
    doAThing(g);
    if (DO_DEBUG) PAUSED = true;
  }
  int getDir(Game g) {
    if (plan == null) return -1;
    if (plan.size() == 0) return -1;
    int move = plan.pop();
    plan.add(move);
    return move;
  }

  void setPlan(Game g, Path newPlan) {
    plan = newPlan;
    planTimingGrid = plan.timingGrid();
    cachedPossibilites = getAllPossibleChanges(g);
    //Arrays.sort(debug_allpossibilities);
    //println("There are ", cachedPossibilites.length, " elements in cachedPossibilites");
    debug_plan_after_food_update = plan.copy();
  }

  void doAThing(Game g) {
    //int[][] planTimingGrid = plan.timingGrid();
    int STEPS = 1000;
    debug_scores = new float[STEPS];
    debug_scores_record = new float[STEPS];
    for (int i = 0; i < STEPS; i++) {
      debug_scores[i] = 0;
      debug_scores_record[i] = 0;
    }
    for (int i = 0; i < STEPS; i++) {
      float temperature = map(i, 0, STEPS/1.5, 0.5, 0);
      Path newPlan = getRandomInterestingPerturbedPlan(g);
      if (newPlan == null) break;
      int[][] newPlanTimingGrid = newPlan.timingGrid();
      debug_scores[i] = newPlanTimingGrid[g.food.x][g.food.y];
      debug_scores_record[i] = planTimingGrid[g.food.x][g.food.y];
      float coef = 0.01;
      float acceptance = exp(coef*(newPlanTimingGrid[g.food.x][g.food.y]-planTimingGrid[g.food.x][g.food.y]));
      if (planTimingGrid[g.food.x][g.food.y] > newPlanTimingGrid[g.food.x][g.food.y] || random(acceptance) < temperature) {
        debug_scores_record[i] = newPlanTimingGrid[g.food.x][g.food.y];
        setPlan(g, newPlan);
        planTimingGrid = newPlanTimingGrid;
      }
    }
  }

  Path getRandomInterestingPerturbedPlan(Game g) {
    debug_interesting_perturbations = new ArrayList<Integer>();
    if (cachedPossibilites.length == 0) return null;
    for (int i = 0; i < 0; i++) {
      int perturbation = cachedPossibilites[floor(random(cachedPossibilites.length))];
      if (perturbationIsInteresting(g, perturbation)) return introducePerturbation(plan, perturbation);
    }
    ArrayList<Integer> interestingPerturbations = new ArrayList<Integer>();
    for (int i = 0; i < cachedPossibilites.length; i++) if (perturbationIsInteresting(g, cachedPossibilites[i])) interestingPerturbations.add(cachedPossibilites[i]);
    if (DO_DEBUG) println("interestingPerturbations.size() /  cachedPossibilites.length: ", interestingPerturbations.size(), " / ", cachedPossibilites.length);
    if (interestingPerturbations.size() == 0) return getRandomPerturbedPlan();
    debug_interesting_perturbations = interestingPerturbations;
    return introducePerturbation(plan, interestingPerturbations.get(floor(random(interestingPerturbations.size()))));
  }
  boolean perturbationIsInteresting(Game g, int encodedPerturbation) {
    Pos joinPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    encodedPerturbation /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    int foodTiming = planTimingGrid[g.food.x][g.food.y];
    if (planTimingGrid[joinPos.x][joinPos.y] <= foodTiming) return true;
    if (planTimingGrid[joinPos.x+1][joinPos.y] <= foodTiming) return true;
    if (planTimingGrid[joinPos.x][joinPos.y+1] <= foodTiming) return true;
    if (planTimingGrid[joinPos.x+1][joinPos.y+1] <= foodTiming) return true;
    if (planTimingGrid[cutPos.x][joinPos.y] <= foodTiming) return true;
    if (planTimingGrid[cutPos.x+1][joinPos.y] <= foodTiming) return true;
    if (planTimingGrid[cutPos.x][joinPos.y+1] <= foodTiming) return true;
    if (planTimingGrid[cutPos.x+1][joinPos.y+1] <= foodTiming) return true;
    return false;
  }
  Path getRandomPerturbedPlan() {
    if (cachedPossibilites.length == 0) return null;
    return introducePerturbation(plan, cachedPossibilites[floor(random(cachedPossibilites.length))]);
  }
  int[] getAllPossibleChanges(Game g) {
    HashSet<Integer> encodedPossibilities = new HashSet<Integer>();
    //int[][] planTimingGrid = plan.timingGrid();
    for (int i = 0; i < GRID_SIZE-1; i++) {
      for (int j = 0; j < GRID_SIZE-1; j++) {
        Pos cutPos = new Pos(i, j);
        int[] cutQuadrantValues = getSortedPlanValues(planTimingGrid, cutPos);
        if (cutQuadrantValues[0]+1 != cutQuadrantValues[1] || cutQuadrantValues[2]+1 != cutQuadrantValues[3]) continue;
        if (cutQuadrantValues[0] < 1) continue; // Not sure if this should be here or not - I remember doing some testing some time ago and it seemed to make things crash less
        int[] cutQuadrantPositions = getSortedPlanPositions(planTimingGrid, cutQuadrantValues, cutPos);
        if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[0]) != 0 || gridAtThing(g.grid, cutPos, cutQuadrantPositions[1]) != 0) continue;
        if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[2]) != 0 || gridAtThing(g.grid, cutPos, cutQuadrantPositions[3]) != 0) continue;
        //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[0]) != 0 && gridAtThing(g.grid, cutPos, cutQuadrantPositions[1]) != 0) continue; // More precise thinking should be done here
        //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[2]) != 0 && gridAtThing(g.grid, cutPos, cutQuadrantPositions[3]) != 0) continue;

        if (abs(gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[0]))-gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[1])))==1) continue;
        if (abs(gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[2]))-gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[3])))==1) continue;

        int dirQ0toQ3 = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3]);
        int dirQ0toQ1 = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[1]);

        Pos posAlongCutLoop = getQuadrantPos(cutPos, cutQuadrantPositions[1]);
        Integer[] loopMoves = (Integer[])subset(plan.moves.toArray(new Integer[0]), cutQuadrantValues[1], cutQuadrantValues[2] - cutQuadrantValues[1]);
        for (int loopMove : loopMoves) {
          Pos nposAlongCutLoop = movePosByDir(posAlongCutLoop, loopMove);
          for (int flip = 0; flip < 2; flip++) {
            Pos joinPos = new Pos(min(posAlongCutLoop.x, nposAlongCutLoop.x), min(posAlongCutLoop.y, nposAlongCutLoop.y));
            if (flip == 1) {
              if (posAlongCutLoop.x == nposAlongCutLoop.x) joinPos.x--;
              if (posAlongCutLoop.y == nposAlongCutLoop.y) joinPos.y--;
            }
            if (!boxInBounds(joinPos)) continue;
            if (joinPos.equals(cutPos)) continue;
            int[] joinQuadrantValues = getSortedPlanValues(planTimingGrid, joinPos);

            if (joinQuadrantValues[0]+1 != joinQuadrantValues[1] || joinQuadrantValues[2]+1 != joinQuadrantValues[3]) continue;
            if (cutQuadrantValues[1] <= joinQuadrantValues[0] && joinQuadrantValues[3] <= cutQuadrantValues[2]) continue;
            //if (joinQuadrantValues[3] < cutQuadrantValues[0]) continue;
            //if (joinQuadrantValues[0] > cutQuadrantValues[3]) continue;
            //if (joinQuadrantValues[0] != cutQuadrantValues[3]) continue;
            //if (gridAtThing(g.grid, joinPos, cutQuadrantPositions[0]) != 0 || gridAtThing(g.grid, joinPos, cutQuadrantPositions[1]) != 0) continue;
            //if (gridAtThing(g.grid, joinPos, cutQuadrantPositions[2]) != 0 || gridAtThing(g.grid, joinPos, cutQuadrantPositions[3]) != 0) continue;
            // and some grid stuff too - like what's above really

            int[] joinQuadrantPositions = getSortedPlanPositions(planTimingGrid, joinQuadrantValues, joinPos);
            if (abs(gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[0]))-gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[1])))==1) continue;
            if (abs(gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[2]))-gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[3])))==1) continue;

            Pos a, b;
            boolean REVERSED = cutQuadrantValues[0] > joinQuadrantValues[0];
            if (!REVERSED) {
              a = cutPos;
              b = joinPos;
              if (joinQuadrantValues[2] - cutQuadrantValues[3] < 0) continue;
              //if (joinQuadrantValues[0] - cutQuadrantValues[1] < 0) continue;
            } else {
              a = joinPos;
              b = cutPos;
              if (joinQuadrantValues[2] - cutQuadrantValues[3] > 0) continue;
              //if (joinQuadrantValues[0] - cutQuadrantValues[1] > 0) continue;
            }
            int encoded = ((a.y*GRID_SIZE + a.x)*GRID_SIZE + b.y)*GRID_SIZE + b.x;
            //if (encoded == 5813) {
            //  println("FOUND ID = "+encoded);
            //  println("REVERSED : ", REVERSED);
            //  println("ting, ", joinQuadrantValues[0] - cutQuadrantValues[1]);
            //}
            if (encodedPossibilities.contains(encoded)) continue;
            encodedPossibilities.add(encoded);
            if (joinQuadrantValues[0] == cutQuadrantValues[0]) {
              println("JKLFMJDKFMDJKLFJDKLJFMDJMFLKD ", encoded);
            }
          }
          posAlongCutLoop = nposAlongCutLoop;
        }
      }
    }
    int[] encodedPossibilitiesOutput = new int[encodedPossibilities.size()];
    int i = 0;
    Iterator<Integer> it = encodedPossibilities.iterator();
    while (it.hasNext()) encodedPossibilitiesOutput[i++] = it.next();
    return encodedPossibilitiesOutput;
  }
  Path introducePerturbation(Path plan, int encodedPerturbation) {
    //int[][] planTimingGrid = plan.timingGrid();
    Path newPlan = new Path(plan.start);
    Pos joinPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    encodedPerturbation /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    int[] cutQuadrantValues = getSortedPlanValues(planTimingGrid, cutPos);
    int[] cutQuadrantPositions = getSortedPlanPositions(planTimingGrid, cutQuadrantValues, cutPos);
    int[] joinQuadrantValues = getSortedPlanValues(planTimingGrid, joinPos);
    int[] joinQuadrantPositions = getSortedPlanPositions(planTimingGrid, joinQuadrantValues, joinPos);
    Integer[] planMoves = plan.moves.toArray(new Integer[0]);
    int stepsFromHeadToCut = cutQuadrantValues[0];
    int stepsFromCutToJoin = joinQuadrantValues[2] - cutQuadrantValues[3];
    int loopStepsFromJoinToCut = cutQuadrantValues[2] - joinQuadrantValues[1];
    int loopStepsFromCutToJoin = joinQuadrantValues[0] - cutQuadrantValues[1];
    int stepsFromJoinToHead = GRID_SIZE*GRID_SIZE - joinQuadrantValues[3];
    //println("stepsFromHeadToCut :     ", stepsFromHeadToCut);
    //println("stepsFromCutToJoin :     ", stepsFromCutToJoin);
    //println("loopStepsFromJoinToCut : ", loopStepsFromJoinToCut);
    //println("loopStepsFromCutToJoin : ", loopStepsFromCutToJoin);
    //println("stepsFromJoinToHead :    ", stepsFromJoinToHead);
    Integer[] newPlanMoves = new Integer[stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1+stepsFromJoinToHead];
    int moveId = 0;
    System.arraycopy(planMoves, 0, newPlanMoves, moveId, stepsFromHeadToCut);
    moveId += stepsFromHeadToCut;
    newPlanMoves[moveId] = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3]);
    moveId ++;
    System.arraycopy(planMoves, cutQuadrantValues[3], newPlanMoves, moveId, stepsFromCutToJoin);
    moveId += stepsFromCutToJoin;
    newPlanMoves[moveId] = dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1]);
    moveId ++;
    System.arraycopy(planMoves, joinQuadrantValues[1], newPlanMoves, moveId, loopStepsFromJoinToCut);
    moveId += loopStepsFromJoinToCut;
    newPlanMoves[moveId] = dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1]);
    moveId ++;
    System.arraycopy(planMoves, cutQuadrantValues[1], newPlanMoves, moveId, loopStepsFromCutToJoin);
    moveId += loopStepsFromCutToJoin;
    newPlanMoves[moveId] = dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3]);
    moveId ++;
    System.arraycopy(planMoves, joinQuadrantValues[3], newPlanMoves, moveId, stepsFromJoinToHead);
    newPlan.moves = new ArrayDeque<Integer>(Arrays.asList(newPlanMoves));
    if (!newPlan.start.equals(newPlan.end)) println("NONONO: !newPlan.start.equals(newPlan.end)");
    if (newPlan.size() != GRID_SIZE*GRID_SIZE) println("NONONO: newPlan.size() != GRID_SIZE*GRID_SIZE");
    return newPlan;
  }
  Pos getQuadrantPos(Pos box, int p) {
    if (p == 0) return box;
    if (p == 1) return new Pos(box.x+1, box.y);
    if (p == 2) return new Pos(box.x, box.y+1);
    if (p == 3) return new Pos(box.x+1, box.y+1);
    return null;
  }

  boolean boxInBounds(Pos p) {
    return ! (p.x < 0 || p.y < 0 || p.x >= GRID_SIZE-1 || p.y >= GRID_SIZE-1);
  }
  int gridAtThing(int[][] grid, Pos box, int lpos) {
    return grid[box.x+lpos%2][box.y+lpos/2];
  }
  int dirAtoB(int a, int b) {
    if (b-a == 1) return RIGHT;
    if (b-a == -1) return LEFT;
    if (b-a == 2) return DOWN;
    if (b-a == -2) return UP;
    println("RETURNING A -1 --------- THIS IS NOT GOOOOD");
    return -1;
  }
  int[] getSortedPlanValues(int[][] plan, Pos box) {
    if (plan == null) println("getSortedPlanValues : plan is null");
    Integer[] sorted_plan_values = getQuadrantsAt(plan, box);
    Arrays.sort(sorted_plan_values);
    return new int[]{
      sorted_plan_values[0], sorted_plan_values[1], sorted_plan_values[2], sorted_plan_values[3],
    };
  }
  int[] getSortedPlanPositions(int[][] plan, int[] sorted_plan_values, Pos box) {
    Integer[] o_plan_values = {
      plan[box.x][box.y], plan[box.x+1][box.y], plan[box.x][box.y+1], plan[box.x+1][box.y+1]
    };
    int[] sorted_positions = new int[4];
    for (int i = 0; i < 4; i++) sorted_positions[i] = Arrays.asList(o_plan_values).indexOf(sorted_plan_values[i]);
    return sorted_positions;
  }
  Integer[] getQuadrantsAt(int[][] plan, Pos box) {
    return new Integer[]{
      plan[box.x][box.y], plan[box.x+1][box.y], plan[box.x][box.y+1], plan[box.x+1][box.y+1]
    };
  }
  int DEBUG_ID = 0;
  void show(Game g) {
    noFill();
    stroke(255);
    strokeWeight(5);
    plan.show(g.food, color(255), color(128), false);

    if (true) return;

    if (debug_interesting_perturbations.size() > 0) {
      //int id = frameCount % debug_allpossibilities.length;
      int id = floor(map(mouseX, 0, width+1, 0, debug_interesting_perturbations.size()));
      //if (frameCount % 2 == 0) DEBUG_ID = floor(random(debug_allpossibilities.length));
      int encoded = debug_interesting_perturbations.get(id);
      Pos joinPos = new Pos(encoded % GRID_SIZE, (encoded/GRID_SIZE) % GRID_SIZE);
      encoded /= GRID_SIZE*GRID_SIZE;
      Pos cutPos = new Pos(encoded % GRID_SIZE, (encoded/GRID_SIZE) % GRID_SIZE);
      strokeWeight(2);
      noStroke();
      fill(255, 0, 0, 128);
      ellipse(20*cutPos.x+10, 20*cutPos.y+10, 40, 40);
      fill(0, 255, 0, 128);
      ellipse(20*joinPos.x+10, 20*joinPos.y+10, 40, 40);

      float ymul = 0;
      if (debug_scores.length > 0) {
        pushMatrix();
        translate(0, height);
        scale(1, -1);
        int w = debug_scores.length;
        float h = 100;
        //for (int i = 0; i < w; i++) h = max(h, debug_scores[i]);
        float xmul = float(width)/w;
        ymul = float(height)/h;
        for (int i = 0; i < w; i++) {
          stroke(255);
          line(i*xmul, debug_scores[i]*ymul, (i+1)*xmul, debug_scores[i]*ymul);
          line(i*xmul, debug_scores_record[max(0, i-1)]*ymul, (i+1)*xmul, debug_scores_record[i]*ymul);
        }
        popMatrix();
      }

      if (debug_plan_after_food_update != null) {
        Path i_plan = introducePerturbation(debug_plan_after_food_update, debug_interesting_perturbations.get(id));
        int[][] i_planTimingGrid = i_plan.timingGrid();
        strokeWeight(2);
        i_plan.show(g.food, color(0, 0, 255), color(0), true);
        strokeWeight(2);
        stroke(0, 0, 255);
        line(0, height-ymul*i_planTimingGrid[g.food.x][g.food.y], width, height-ymul*i_planTimingGrid[g.food.x][g.food.y]);
      }
    }

    stroke(255, 255, 0, 128);
    //for (tin
  }

  class Path {
    //BitSet occupies;
    ArrayDeque<Integer> moves;
    Pos start, end;

    Path(Pos start) {
      //occupies = new BitSet(GRID_SIZE*GRID_SIZE);
      //occupies.set(start.y*GRID_SIZE+start.x);
      this.start = start;
      this.end = start;
      moves = new ArrayDeque<Integer>();
    }
    Path(Path c) {
      this.moves = c.moves.clone();
      this.start = c.start.copy();
      this.end = c.end.copy();
    }
    Path copy() {
      return new Path(this);
    }

    void add(int move) {
      moves.add(move);
      end = movePosByDir(end, move);
      //if (!inBounds(end)) return;
      //occupies.set(end.y*GRID_SIZE+end.x);
    }

    int pop() {
      //occupies.clear(start.y*GRID_SIZE+start.x);
      start = movePosByDir(start, moves.peek());
      return moves.pop();
    }
    int size() {
      return moves.size();
    }
    boolean isInBounds() {
      Pos currentPos = start;
      for (int move : moves.toArray(new Integer[0])) {
        if (!inBounds(currentPos)) return false;
        currentPos = movePosByDir(currentPos, move);
      }
      return inBounds(currentPos);
    }

    void show() {
      if (moves == null) return;
      Pos currentPos = start;
      for (int move : moves.toArray(new Integer[0])) {
        Pos newPos = movePosByDir(currentPos, move);
        line(20*currentPos.x, 20*currentPos.y, 20*newPos.x, 20*newPos.y);
        currentPos = newPos;
      }
    }
    void show(Pos goal, color c1, color c2, boolean stop) {
      if (moves == null) return;
      stroke(c1);
      Pos currentPos = start;
      for (int move : moves.toArray(new Integer[0])) {
        Pos newPos = movePosByDir(currentPos, move);
        line(20*currentPos.x, 20*currentPos.y, 20*newPos.x, 20*newPos.y);
        if (newPos.equals(goal)) {
          if (stop) return;
          stroke(c2);
        }
        currentPos = newPos;
      }
    }
    int[][] timingGrid() {
      int[][] grid = new int[GRID_SIZE][GRID_SIZE];
      for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
          grid[i][j] = -9999;
        }
      }
      Pos currentPos = start;
      int time = 0;
      for (int move : moves.toArray(new Integer[0])) {
        grid[currentPos.x][currentPos.y] = time;
        currentPos = movePosByDir(currentPos, move);
        time ++;
      }
      return grid;
    }
  }

  Path aHamiltonianPath(Pos pos) {
    Path path = aHamiltonianPath();
    while (!path.start.equals(pos)) path.add(path.pop());
    return path;
  }

  Path aHamiltonianPath() {
    Path path = new Path(new Pos(0, 0));
    path.add(RIGHT);
    for (int i = 0; i < GRID_SIZE/2; i++) {
      for (int x = 0; x < GRID_SIZE-2; x++) path.add(RIGHT);
      path.add(DOWN);
      for (int x = 0; x < GRID_SIZE-2; x++) path.add(LEFT);
      if (i < GRID_SIZE/2-1) path.add(DOWN);
    }
    path.add(LEFT);
    for (int x = 0; x < GRID_SIZE-1; x++) path.add(UP);
    return path;
  }
}
