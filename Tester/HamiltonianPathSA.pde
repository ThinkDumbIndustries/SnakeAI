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
  int STEPS_RANDOMIZE = 100;
  int STEPS_ANNEAL = 100;

  FastHPath plan = null;
  int[] cachedPossibilites = new int[0];
  HamiltonianPathSA() {
  }
  void reset(Game g) {
    setPlan(g, aHamiltonianPath(g.head));
    for (int i = 0; i < STEPS_RANDOMIZE; i++) {
      DEBUG_ID = floor(random(cachedPossibilites.length));
      int encoded = cachedPossibilites[DEBUG_ID];
      setPlan(g, introducePerturbation(plan, encoded));
    }
  }
  FastHPath debug_plan_after_food_update = null;
  float[] debug_scores = new float[0];
  float[] debug_scores_record = new float[0];
  int[] debug_encoded_possibilities_along_plan = new int[0];
  FastHPath[] debug_plans = new FastHPath[0];
  FastHPath debug_me_please = null;
  ArrayList<Integer> debug_interesting_perturbations = new ArrayList<Integer>();

  boolean DEBUG_DONT = false;
  void updateFood(Game g) {
    setPlan(g, plan);
    if (DEBUG_DONT) anneal(g);
    DEBUG_DONT = true;
    if (DO_DEBUG) PAUSED = true;
  }
  int getDir(Game g) {
    int move = plan.pop();
    plan.computeTimingGrid();
    return move;
  }

  void setPlan(Game g, FastHPath newPlan) {
    plan = newPlan;
    cachedPossibilites = getAllPossibleChanges(g);
    //println("There are ", cachedPossibilites.length, " elements in cachedPossibilites");
    debug_plan_after_food_update = plan.copy();
    debug_plan_after_food_update.computeTimingGrid();
  }

  void anneal(Game g) {
    debug_scores = new float[STEPS_ANNEAL];
    debug_scores_record = new float[STEPS_ANNEAL];
    debug_plans = new FastHPath[STEPS_ANNEAL];
    int disrespect_count = 0;
    int restarts_count = 0;
    FastHPath recordPlan = plan.copy();
    float recordEnergy = plan.timingGrid[g.food.x][g.food.y];
    for (int i = 0; i < STEPS_ANNEAL; i++) {
      debug_scores[i] = 0;
      debug_scores_record[i] = 0;
    }
    for (int i = 0; i < STEPS_ANNEAL; i++) {
      float temperature_worse_overall = map(i, 0, STEPS_ANNEAL/1.1, 0.5, 0);
      float temperature_do_short = map(i, 0, STEPS_ANNEAL/1.1, 0.5, 0);
      float temperature_do_short_NOTskipIfNotShortcut = map(i, 0, STEPS_ANNEAL/1.1, 0.5, 0);
      float temperature_do_short_allowTailCutting = map(i, 0, STEPS_ANNEAL/1.1, 0.5, 0);
      FastHPath newPlan;
      boolean Do_Short_Opti = random(1) < temperature_do_short;
      if (Do_Short_Opti) {
        boolean skipIfNotShortcut = ! (random(1) < temperature_do_short_NOTskipIfNotShortcut);
        boolean forbidTailCutting = random(1) < temperature_do_short_allowTailCutting;
        newPlan = getPerturbedPlanAlongPlannedPath(g, skipIfNotShortcut, forbidTailCutting);
        if (newPlan == null) newPlan = getRandomInterestingPerturbedPlan(g);
      } else {
        newPlan = getRandomInterestingPerturbedPlan(g);
      }
      //newPlan = getRandomPerturbedPlan();
      if (newPlan == null) break;
      if (newPlan.isDirespectful(g.grid, g.snake_length, g.food)) {
        disrespect_count ++;
        //println(i, " disrespectful");
        debug_plans[i] = plan;
        continue;
      }
      debug_scores[i] = newPlan.timingGrid[g.food.x][g.food.y];
      debug_scores_record[i] = plan.timingGrid[g.food.x][g.food.y];
      float coef = 0.01;
      float newPlanEnergy = newPlan.timingGrid[g.food.x][g.food.y];
      float acceptance = exp(coef*(newPlanEnergy-plan.timingGrid[g.food.x][g.food.y]));
      if (plan.timingGrid[g.food.x][g.food.y] > newPlan.timingGrid[g.food.x][g.food.y] || random(acceptance) < temperature_worse_overall) {
        debug_scores_record[i] = newPlan.timingGrid[g.food.x][g.food.y];
        setPlan(g, newPlan);
        if (newPlanEnergy <= recordEnergy) {
          recordEnergy = newPlanEnergy;
          recordPlan = newPlan.copy();
          recordPlan.computeTimingGrid();
        }
      }
      float planEnergy = energy(g, plan);

      float restartProb = (planEnergy-recordEnergy)/2000.0;
      if (restartProb <= 0) restartProb = 0;
      else restartProb /= restartProb+1;
      if (random(1) < restartProb) {
        setPlan(g, recordPlan);
        restarts_count++;
      }
      debug_plans[i] = plan;
    }
    println(round(float(100)*disrespect_count/STEPS_ANNEAL)+"% disrespectful, "+restarts_count+" restarts");
    plan = plan.copy();
    plan.computeTimingGrid();
  }

  FastHPath getPerturbedPlanAlongPlannedPath(Game g, boolean skipIfNotShortcut, boolean forbidCuttingTail) {
    HashSet<Integer> encodedPossibilities = new HashSet<Integer>();
    Pos currentPos = plan.start;
    for (int i = 0; i < plan.size; i++) {
      int move = (int)plan.tabs[(i+plan.startPos)%plan.size];
      Pos newPos = movePosByDirCopy(currentPos, move);
      if (newPos.equals(g.food)) break;
      for (int flip = 0; flip < 2; flip++) {
        Pos cutPos = new Pos(min(currentPos.x, newPos.x), min(currentPos.y, newPos.y));
        if (flip == 1) {
          if (currentPos.x == newPos.x) cutPos.x--;
          if (currentPos.y == newPos.y) cutPos.y--;
        }
        exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(g, cutPos, encodedPossibilities, skipIfNotShortcut, forbidCuttingTail);
        currentPos = newPos;
      }
    }
    int[] encodedPossibilitiesOutput = new int[encodedPossibilities.size()];
    int i = 0;
    Iterator<Integer> it = encodedPossibilities.iterator();
    while (it.hasNext()) encodedPossibilitiesOutput[i++] = it.next();
    debug_encoded_possibilities_along_plan = encodedPossibilitiesOutput;
    if (encodedPossibilitiesOutput.length == 0) return null;
    int r_id = floor(random(encodedPossibilitiesOutput.length));
    return introducePerturbation(plan, encodedPossibilitiesOutput[r_id]);
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
    int foodTiming = plan.timingGrid[g.food.x][g.food.y];
    if (plan.timingGrid[joinPos.x][joinPos.y] <= foodTiming) return true;
    if (plan.timingGrid[joinPos.x+1][joinPos.y] <= foodTiming) return true;
    if (plan.timingGrid[joinPos.x][joinPos.y+1] <= foodTiming) return true;
    if (plan.timingGrid[joinPos.x+1][joinPos.y+1] <= foodTiming) return true;
    if (plan.timingGrid[cutPos.x][joinPos.y] <= foodTiming) return true;
    if (plan.timingGrid[cutPos.x+1][joinPos.y] <= foodTiming) return true;
    if (plan.timingGrid[cutPos.x][joinPos.y+1] <= foodTiming) return true;
    if (plan.timingGrid[cutPos.x+1][joinPos.y+1] <= foodTiming) return true;
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
        exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(g, cutPos, encodedPossibilities);
      }
    }
    int[] encodedPossibilitiesOutput = new int[encodedPossibilities.size()];
    int i = 0;
    Iterator<Integer> it = encodedPossibilities.iterator();
    while (it.hasNext()) encodedPossibilitiesOutput[i++] = it.next();
    return encodedPossibilitiesOutput;
  }
  void exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(Game g, Pos cutPos, HashSet<Integer> encodedPossibilities) {
    exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(g, cutPos, encodedPossibilities, false, false);
  }
  void exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(Game g, Pos cutPos, HashSet<Integer> encodedPossibilities, boolean skipIfNotShortcut, boolean forbidCuttingTail) {
    if (!boxInBounds(cutPos)) return;
    int[] cutQuadrantValues = getSortedPlanValues(plan.timingGrid, cutPos);
    if (cutQuadrantValues[0]+1 != cutQuadrantValues[1] || cutQuadrantValues[2]+1 != cutQuadrantValues[3]) return;
    //if (cutQuadrantValues[0] < 1) return; // Not sure if this should be here or not - I remember doing some testing some time ago and it seemed to make things crash less
    int[] cutQuadrantPositions = getSortedPlanPositions(plan.timingGrid, cutQuadrantValues, cutPos);
    //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[0]) != 0 || gridAtThing(g.grid, cutPos, cutQuadrantPositions[1]) != 0) continue;
    //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[2]) != 0 || gridAtThing(g.grid, cutPos, cutQuadrantPositions[3]) != 0) continue;
    //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[0]) != 0 && gridAtThing(g.grid, cutPos, cutQuadrantPositions[1]) != 0) continue; // More precise thinking should be done here
    //if (gridAtThing(g.grid, cutPos, cutQuadrantPositions[2]) != 0 && gridAtThing(g.grid, cutPos, cutQuadrantPositions[3]) != 0) continue;

    // Do I want these?
    if (abs(gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[0]))-gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[1])))==1) return;
    if (abs(gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[2]))-gridAtPos(g.grid, getQuadrantPos(cutPos, cutQuadrantPositions[3])))==1) return;

    if (skipIfNotShortcut && cutQuadrantValues[3] > plan.timingGrid[g.food.x][g.food.y]) return;

    //int dirQ0toQ3 = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3]);
    //int dirQ0toQ1 = dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[1]);

    Pos posAlongCutLoop = getQuadrantPos(cutPos, cutQuadrantPositions[1]);
    int loopMove_n = cutQuadrantValues[2] - cutQuadrantValues[1];
    for (int loopMove_i = 0; loopMove_i < loopMove_n; loopMove_i++) {
      int loopMove = (int)plan.tabs[(loopMove_i+plan.startPos+cutQuadrantValues[1])%plan.size];
      Pos nposAlongCutLoop = movePosByDirCopy(posAlongCutLoop, loopMove);
      for (int flip = 0; flip < 2; flip++) {
        Pos joinPos = new Pos(min(posAlongCutLoop.x, nposAlongCutLoop.x), min(posAlongCutLoop.y, nposAlongCutLoop.y));
        if (flip == 1) {
          if (posAlongCutLoop.x == nposAlongCutLoop.x) joinPos.x--;
          if (posAlongCutLoop.y == nposAlongCutLoop.y) joinPos.y--;
        }
        if (!boxInBounds(joinPos)) continue;
        if (joinPos.equals(cutPos)) continue;
        int[] joinQuadrantValues = getSortedPlanValues(plan.timingGrid, joinPos);

        if (joinQuadrantValues[0]+1 != joinQuadrantValues[1] || joinQuadrantValues[2]+1 != joinQuadrantValues[3]) continue; // needs to be cutable
        if (cutQuadrantValues[1] <= joinQuadrantValues[0] && joinQuadrantValues[3] <= cutQuadrantValues[2]) continue;
        //if (gridAtThing(g.grid, joinPos, cutQuadrantPositions[0]) != 0 || gridAtThing(g.grid, joinPos, cutQuadrantPositions[1]) != 0) continue;
        //if (gridAtThing(g.grid, joinPos, cutQuadrantPositions[2]) != 0 || gridAtThing(g.grid, joinPos, cutQuadrantPositions[3]) != 0) continue;
        // and some grid stuff too - like what's above really

        int[] joinQuadrantPositions = getSortedPlanPositions(plan.timingGrid, joinQuadrantValues, joinPos);
        if (forbidCuttingTail && gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[2])) != 0) continue;
        //if (abs(gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[0]))-gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[1])))==1) continue;
        //if (abs(gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[2]))-gridAtPos(g.grid, getQuadrantPos(joinPos, joinQuadrantPositions[3])))==1) continue;

        Pos a, b;
        boolean REVERSED = cutQuadrantValues[0] > joinQuadrantValues[0];
        if (!REVERSED) {
          a = cutPos;
          b = joinPos;
          if (joinQuadrantValues[2] - cutQuadrantValues[3] < 0) continue;
        } else {
          a = joinPos;
          b = cutPos;
          if (joinQuadrantValues[2] - cutQuadrantValues[3] > 0) continue;
        }
        int encoded = ((a.y*GRID_SIZE + a.x)*GRID_SIZE + b.y)*GRID_SIZE + b.x;
        if (encodedPossibilities.contains(encoded)) continue;
        encodedPossibilities.add(encoded);
      }
      posAlongCutLoop = nposAlongCutLoop;
    }
  }
  FastHPath introducePerturbation(FastHPath plan, int encodedPerturbation) {
    Pos joinPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    encodedPerturbation /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    int[] cutQuadrantValues = getSortedPlanValues(plan.timingGrid, cutPos);
    int[] cutQuadrantPositions = getSortedPlanPositions(plan.timingGrid, cutQuadrantValues, cutPos);
    int[] joinQuadrantValues = getSortedPlanValues(plan.timingGrid, joinPos);
    int[] joinQuadrantPositions = getSortedPlanPositions(plan.timingGrid, joinQuadrantValues, joinPos);
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
    //if (stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1+stepsFromJoinToHead != GRID_SIZE*GRID_SIZE) println("fdjjklmjjjjjjkljk");
    //Integer[] newPlanMoves = new Integer[stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1+stepsFromJoinToHead];
    FastHPath newPlan = new FastHPath(plan.start);
    int moveId = 0;
    newPlan.moveCopy(plan, 0, moveId, stepsFromHeadToCut);
    moveId += stepsFromHeadToCut;
    newPlan.setTab(moveId, (byte)(dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3])));
    moveId ++;
    newPlan.moveCopy(plan, cutQuadrantValues[3], moveId, stepsFromCutToJoin);
    moveId += stepsFromCutToJoin;
    newPlan.setTab(moveId, (byte)(dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1])));
    moveId ++;
    newPlan.moveCopy(plan, joinQuadrantValues[1], moveId, loopStepsFromJoinToCut);
    moveId += loopStepsFromJoinToCut;
    newPlan.setTab(moveId, (byte)(dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1])));
    moveId ++;
    newPlan.moveCopy(plan, cutQuadrantValues[1], moveId, loopStepsFromCutToJoin);
    moveId += loopStepsFromCutToJoin;
    newPlan.setTab(moveId, (byte)(dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3])));
    moveId ++;
    newPlan.moveCopy(plan, joinQuadrantValues[3], moveId, stepsFromJoinToHead);
    newPlan.computeTimingGrid();
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
    return -1;
  }
  int[] getSortedPlanValues(int[][] plan, Pos box) {
    Integer[] sorted_plan_values = getQuadrantsAt(plan, box);
    Arrays.sort(sorted_plan_values);
    return new int[]{
      sorted_plan_values[0], sorted_plan_values[1], sorted_plan_values[2], sorted_plan_values[3],
    };
    //sort4(getQuadrantsAt(plan, box));
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
    //showDebugPossibilitiesAlongPlan(g);

    noFill();
    stroke(255);
    strokeWeight(5);
    //plan.show(g.food, color(255), color(128), false);

    if (!DO_DEBUG) return;
    showMousePlan(g);
    //showScores();
    //showMousePeturbations();
  }

  void showDebugPossibilitiesAlongPlan(Game g) {
    if (debug_encoded_possibilities_along_plan.length == 0) return;
    int id = floor(map(mouseX, 0, width+1, 0, debug_encoded_possibilities_along_plan.length));
    int encoding = debug_encoded_possibilities_along_plan[id];
    FastHPath planAlongPlan = introducePerturbation(debug_plan_after_food_update, encoding);
    strokeWeight(7);
    planAlongPlan.show(g.food, color(0, 0, 255), color(0, 0, 128), true);
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
    newPlan.show(g.food, color(255), color(128, 30), false);
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
    byte[] tabs;
    int[][] timingGrid;

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
      Pos pos = start;
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
}
