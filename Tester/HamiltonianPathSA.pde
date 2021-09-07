import java.util.Arrays; //<>//
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
  FastHPath plan = null;
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
  FastHPath debug_plan_after_food_update = null;
  float[] debug_scores = new float[0];
  float[] debug_scores_record = new float[0];
  FastHPath[] debug_plans = new FastHPath[0];
  FastHPath debug_me_please = null;
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
    return move;
  }

  void setPlan(Game g, FastHPath newPlan) {
    plan = newPlan;
    planTimingGrid = plan.timingGrid();
    cachedPossibilites = getAllPossibleChanges(g);
    //println("There are ", cachedPossibilites.length, " elements in cachedPossibilites");
    debug_plan_after_food_update = plan.copy();
  }

  void doAThing(Game g) {
    int STEPS = 1000;
    debug_scores = new float[STEPS];
    debug_scores_record = new float[STEPS];
    debug_plans = new FastHPath[STEPS];
    for (int i = 0; i < STEPS; i++) {
      debug_scores[i] = 0;
      debug_scores_record[i] = 0;
    }
    for (int i = 0; i < STEPS; i++) {
      float temperature = map(i, 0, STEPS/1.1, 0.5, 0);
      FastHPath newPlan = getRandomInterestingPerturbedPlan(g);
      if (newPlan == null) break;
      int[][] newPlanTimingGrid = newPlan.timingGrid();
      debug_scores[i] = newPlanTimingGrid[g.food.x][g.food.y];
      debug_scores_record[i] = planTimingGrid[g.food.x][g.food.y];
      float coef = 0.003;
      float acceptance = exp(coef*(newPlanTimingGrid[g.food.x][g.food.y]-planTimingGrid[g.food.x][g.food.y]));
      if (planTimingGrid[g.food.x][g.food.y] > newPlanTimingGrid[g.food.x][g.food.y] || random(acceptance) < temperature) {
        debug_scores_record[i] = newPlanTimingGrid[g.food.x][g.food.y];
        setPlan(g, newPlan);
        planTimingGrid = newPlanTimingGrid;
      }
      debug_plans[i] = plan;
    }
  }

  FastHPath getRandomInterestingPerturbedPlan(Game g) {
    debug_interesting_perturbations = new ArrayList<Integer>();
    if (cachedPossibilites.length == 0) return null;
    for (int i = 0; i < 100; i++) {
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
  FastHPath getRandomPerturbedPlan() {
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
        Integer[] loopMoves = (Integer[])subset(plan.movesToArray(), cutQuadrantValues[1], cutQuadrantValues[2] - cutQuadrantValues[1]);
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
            if (encodedPossibilities.contains(encoded)) continue;
            encodedPossibilities.add(encoded);
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
  FastHPath introducePerturbation(FastHPath plan, int encodedPerturbation) {
    //int[][] planTimingGrid = plan.timingGrid();
    Pos joinPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    encodedPerturbation /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    int[] cutQuadrantValues = getSortedPlanValues(planTimingGrid, cutPos);
    int[] cutQuadrantPositions = getSortedPlanPositions(planTimingGrid, cutQuadrantValues, cutPos);
    int[] joinQuadrantValues = getSortedPlanValues(planTimingGrid, joinPos);
    int[] joinQuadrantPositions = getSortedPlanPositions(planTimingGrid, joinQuadrantValues, joinPos);
    Integer[] planMoves = plan.movesToArray();
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
    if (stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1+stepsFromJoinToHead != GRID_SIZE*GRID_SIZE) println("fdjjklmjjjjjjkljk");
    //Integer[] newPlanMoves = new Integer[stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1+stepsFromJoinToHead];
    FastHPath newPlan = new FastHPath(plan.getStart());
    int moveId = 0;
    newPlan.moveCopy(plan, 0, moveId, stepsFromHeadToCut);
    //newPlan.System.arraycopy(planMoves, 0, newPlanMoves, moveId, stepsFromHeadToCut);
    moveId += stepsFromHeadToCut;
    newPlan.setTab(moveId+newPlan.startPos, (byte)(dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3])-LEFT));
    //newPlan.moveCopy(move2path(dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3])), 0, moveId, 1);
    //newPlanMoves[moveId] = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3]);
    moveId ++;
    newPlan.moveCopy(plan, cutQuadrantValues[3], moveId, stepsFromCutToJoin);
    //System.arraycopy(planMoves, cutQuadrantValues[3], newPlanMoves, moveId, stepsFromCutToJoin);
    moveId += stepsFromCutToJoin;
    newPlan.setTab(moveId+newPlan.startPos, (byte)(dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1])-LEFT));
    //newPlan.moveCopy(move2path(dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1])), 0, moveId, 1);
    //newPlanMoves[moveId] = dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1]);
    moveId ++;
    newPlan.moveCopy(plan, joinQuadrantValues[1], moveId, loopStepsFromJoinToCut);
    //System.arraycopy(planMoves, joinQuadrantValues[1], newPlanMoves, moveId, loopStepsFromJoinToCut);
    moveId += loopStepsFromJoinToCut;
    newPlan.setTab(moveId+newPlan.startPos, (byte)(dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1])-LEFT));
    //newPlan.moveCopy(move2path(dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1])), 0, moveId, 1);
    //newPlanMoves[moveId] = dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1]);
    moveId ++;
    newPlan.moveCopy(plan, cutQuadrantValues[1], moveId, loopStepsFromCutToJoin);
    //System.arraycopy(planMoves, cutQuadrantValues[1], newPlanMoves, moveId, loopStepsFromCutToJoin);
    moveId += loopStepsFromCutToJoin;
    newPlan.setTab(moveId+newPlan.startPos, (byte)(dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3])-LEFT));
    //newPlan.moveCopy(move2path(dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3])), 0, moveId, 1);
    //newPlanMoves[moveId] = dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3]);
    moveId ++;
    newPlan.moveCopy(plan, joinQuadrantValues[3], moveId, stepsFromJoinToHead);
    //System.arraycopy(planMoves, joinQuadrantValues[3], newPlanMoves, moveId, stepsFromJoinToHead);
    //HPath newPlan = new SlowHPath(plan.getStart(), new ArrayDeque<Integer>(Arrays.asList(newPlanMoves)));
    //if (!newPlan.start.equals(newPlan.end)) println("NONONO: !newPlan.start.equals(newPlan.end)");
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
    //plan.show(g.food, color(255), color(128), false);

    if (!DO_DEBUG) return;
    showMousePlan(g);
    //showScores();
    //showMousePeturbations();
  }

  void showMousePlan(Game g) {
    FastHPath newPlan;
    if (debug_plans.length == 0) {
      newPlan = plan;
    } else {
      //int id = frameCount % debug_allpossibilities.length;
      int id = floor(map(mouseX, 0, width+1, 0, debug_plans.length));
      noFill();
      stroke(255);
      strokeWeight(5);
      newPlan = debug_plans[id];
    }
    newPlan.show(g.food, color(255), color(128), false);

    //newPlan.show(g.food, color(128), color(32), false);
    /// DEBUGGING;
    //FastHPath fplan = new FastHPath(newPlan.getStart());
    //for (int move : newPlan.movesToArray()) fplan.add(move);
    //fplan.show(g.food, color(255), color(128), false);
  }

  void showMousePeturbations() {
    if (debug_interesting_perturbations.size() == 0) return;
    //int id = frameCount % debug_allpossibilities.length;
    int id = floor(map(mouseX, 0, width+1, 0, debug_interesting_perturbations.size()));
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
  }

  void showScores() {
    if (debug_scores.length == 0) return;
    pushMatrix();
    translate(0, height);
    scale(1, -1);
    int w = debug_scores.length;
    float h = 100;
    //for (int i = 0; i < w; i++) h = max(h, debug_scores[i]);
    float xmul = float(width)/w;
    float ymul = float(height)/h;
    strokeWeight(1);
    stroke(255);
    for (int i = 0; i < w; i++) {
      line(i*xmul, debug_scores[i]*ymul, (i+1)*xmul, debug_scores[i]*ymul);
      line(i*xmul, debug_scores_record[max(0, i-1)]*ymul, (i+1)*xmul, debug_scores_record[i]*ymul);
    }
    popMatrix();
  }

  class FastHPath {
    Pos start;
    int startPos;
    final int size = GRID_SIZE*GRID_SIZE;
    int[] tabs;

    FastHPath(Pos start) {
      this.start = start;
      this.startPos = 0;
      tabs = new int[ceil(float(GRID_SIZE*GRID_SIZE)/16)];
    }
    FastHPath(Pos start, int startPos, int[] tabs) {
      this.start = start;
      this.startPos = startPos;
      this.tabs = tabs;
    }

    byte getTab(int pos) {
      return (byte)((tabs[pos>>4]>>((pos&0x0f)<<1))&0x03);
    }
    void setTab(int pos, byte val) {
      //println("Set Tab,   pos : ", pos, " \tpos>>4 : ", pos>>4, "   (pos&0x0f)<<1 : ", (pos&0x0f)<<1, "   val : ", val, "\t   tabs[pos>>4] : ", binary(tabs[pos>>4]));
      tabs[pos>>4] &= 9223372036854775807L ^ (0x03 << ((pos&0x0f)<<1));
      tabs[pos>>4] |= (val << ((pos&0x0f)<<1));
    }
    Pos getStart() {
      return start;
    }
    Integer[] movesToArray() {
      Integer[] moves = new Integer[size];
      for (int i = 0; i < size; i++) moves[i] = LEFT+getTab((i+startPos)%size);
      return moves;
    }
    FastHPath copy() {
      int[] tabs_copy = new int[tabs.length];
      System.arraycopy(tabs, 0, tabs_copy, 0, tabs.length);
      return new FastHPath(start.copy(), startPos, tabs_copy);
    }
    void moveCopy(FastHPath src, int srcPos, int desPos, int len) {
      //println("moveCopy(srcPos : ", srcPos, ", desPos :", desPos, ", len :", len, ")");
      srcPos = (src.startPos+srcPos)%src.size;
      desPos = (startPos+desPos)%size;
      while (len > 0) {
        int i_s = srcPos>>4;
        int i_d = desPos>>4;
        //println(srcPos, desPos, i_s, i_d);
        int j_s = srcPos&0x0f;
        int j_d = desPos&0x0f;
        int sections = min(16-max(j_s, j_d), min(len, src.size-srcPos, size-desPos));

        //println(srcPos, "->", desPos, "    \t[", i_s, "] -> [", i_d, "]\t", j_s, " -> ", j_d, "  \t sections = ", sections, "\t", "XXXXXXXXXXXXXXXX".substring(16-sections));
        tabs[i_d] |= (src.tabs[i_s] >>> (j_s<<1) & 0xffffffff >>> ((16-sections)<<1)) << (j_d<<1); // >> ((16-sections)>>1)
        //println(binary(tabs[i_d]));
        len -= sections;
        srcPos = (srcPos+sections)%src.size;
        desPos = (desPos+sections)%size;
      }
    }
    int pop() {
      int move = LEFT+getTab(startPos);
      startPos = (startPos+1) % size;
      start = movePosByDir(start, move);
      return move;
    }
    int size() {
      return size;
    }
    //@Override int[][] timingGrid() {
    //}
    int[][] timingGrid() {
      int[][] grid = new int[GRID_SIZE][GRID_SIZE];
      for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
          grid[i][j] = -9999;
        }
      }
      Pos currentPos = getStart();
      int time = 0;
      for (int move : movesToArray()) {
        grid[currentPos.x][currentPos.y] = time;
        currentPos = movePosByDir(currentPos, move);
        time ++;
      }
      return grid;
    }
    void show() {
      Pos currentPos = getStart();
      for (int move : movesToArray()) {
        Pos newPos = movePosByDir(currentPos, move);
        line(20*currentPos.x, 20*currentPos.y, 20*newPos.x, 20*newPos.y);
        currentPos = newPos;
      }
    }
    void show(Pos goal, color c1, color c2, boolean stop) {
      stroke(c1);
      Pos currentPos = getStart();
      for (int move : movesToArray()) {
        Pos newPos = movePosByDir(currentPos, move);
        line(20*currentPos.x, 20*currentPos.y, 20*newPos.x, 20*newPos.y);
        if (newPos.equals(goal)) {
          if (stop) return;
          stroke(c2);
        }
        currentPos = newPos;
      }
    }
  }

  FastHPath aHamiltonianPath(Pos pos) {
    FastHPath path = aHamiltonianPath();
    while (!path.getStart().equals(pos)) path.pop();
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
    for (int i = 0; i < moves.length; i++) path.setTab(i, (byte)(moves[i]-LEFT));
    return path;
  }
}
