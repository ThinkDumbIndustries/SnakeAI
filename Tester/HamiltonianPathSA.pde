import java.util.HashSet; //<>//
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
  int STEPS_ANNEAL = 200;

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
  float[] debug_energy = new float[0];
  float[] debug_energy_record = new float[0];
  int[] debug_encoded_possibilities_along_plan = new int[0];
  FastHPath[] debug_plans = new FastHPath[0];
  FastHPath[] debug_plans_old = new FastHPath[0];
  boolean[] debug_accepted = new boolean[0];
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
    if (plan.timingGrid == null) println("setPlan - plan.timingGrid is null");
    cachedPossibilites = getAllPossibleChanges(g);
    //println("There are ", cachedPossibilites.length, " elements in cachedPossibilites");
    debug_plan_after_food_update = plan.copy();
    debug_plan_after_food_update.computeTimingGrid();
  }

  float energy(Game g, FastHPath p) {
    //return energy_timetofood(g, p);
    //return energy_numConsecutiveASTARMoves(g, p);
    return energy_timetofood(g, p) + 20 * energy_numConsecutiveASTARMoves(g, p);
  }
  float energy_timetofood(Game g, FastHPath p) {
    return p.timingGrid[g.food.x][g.food.y]-abs(g.food.x-p.start.x)-abs(g.food.y-p.start.y);
  }
  float energy_numConsecutiveASTARMoves(Game g, FastHPath p) {
    Pos pos = p.start.copy();
    for (int i = 0; i < p.size; i++) {
      int move = (int)p.tabs[(i+p.startPos)%p.size];
      if (move == UP && g.food.y >= pos.y) return abs(g.food.x-p.start.x)+abs(g.food.y-p.start.y)-i;
      if (move == LEFT && g.food.x >= pos.x) return abs(g.food.x-p.start.x)+abs(g.food.y-p.start.y)-i;
      if (move == DOWN && g.food.y <= pos.y) return abs(g.food.x-p.start.x)+abs(g.food.y-p.start.y)-i;
      if (move == RIGHT && g.food.x <= pos.x) return abs(g.food.x-p.start.x)+abs(g.food.y-p.start.y)-i;
      movePosByDir(pos, move);
    }
    return 0;
  }
  void anneal(Game g) {
    debug_energy = new float[STEPS_ANNEAL];
    debug_energy_record = new float[STEPS_ANNEAL];
    debug_plans = new FastHPath[STEPS_ANNEAL];
    debug_plans_old = new FastHPath[STEPS_ANNEAL];
    debug_accepted = new boolean[STEPS_ANNEAL];
    int disrespect_count = 0;
    int restarts_count = 0;
    FastHPath recordPlan = plan.copy();
    float recordEnergy = plan.timingGrid[g.food.x][g.food.y];
    for (int i = 0; i < STEPS_ANNEAL; i++) {
      debug_energy[i] = 0;
      debug_energy_record[i] = 0;
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
      if (newPlan == null || newPlan.isDirespectful(g.grid, g.snake_length, g.food)) {
        newPlan = plan.copy();
        newPlan.computeTimingGrid();
      }
      float currentEnergy = energy(g, plan);
      float newEnergy = energy(g, newPlan);
      debug_energy[i] = newEnergy;
      debug_energy_record[i] = recordEnergy;
      float coef = 0.01;
      float acceptance = exp(coef*(newEnergy-currentEnergy));
      boolean accepted = newEnergy < currentEnergy || random(acceptance) < temperature_worse_overall;
      debug_plans_old[i] = plan;
      if (accepted) {
        debug_energy_record[i] = newPlan.timingGrid[g.food.x][g.food.y];
        setPlan(g, newPlan);
        if (newEnergy <= recordEnergy) {
          recordEnergy = newEnergy;
          recordPlan = newPlan.copy();
          recordPlan.computeTimingGrid();
        }
      }
      float planEnergy = energy(g, plan);

      float restartProb = (planEnergy-recordEnergy)/2000.0;
      if (restartProb <= 0) restartProb = 0;
      else restartProb /= restartProb+1;
      if (random(1) < restartProb) {
        recordPlan.computeTimingGrid();
        setPlan(g, recordPlan);
        restarts_count++;
      }
      debug_plans[i] = newPlan;
      debug_accepted[i] = accepted;
    }
    println(round(float(100)*disrespect_count/STEPS_ANNEAL)+"% disrespectful, "+restarts_count+" restarts");
    plan = plan.copy();
    plan.computeTimingGrid();
    if (plan.timingGrid == null) println("plan = plan.copy(); - plan.timingGrid is null");
  }

  ArrayList<Pos> debug_getPerturbedPlanAlongPlannedPath;
  FastHPath getPerturbedPlanAlongPlannedPath(Game g, boolean skipIfNotShortcut, boolean forbidCuttingTail) {
    return getPerturbedPlanAlongPlannedPath(g, skipIfNotShortcut, forbidCuttingTail, false);
  }
  FastHPath getPerturbedPlanAlongPlannedPath(Game g, boolean skipIfNotShortcut, boolean forbidCuttingTail, boolean doDebug) {
    if (doDebug) debug_getPerturbedPlanAlongPlannedPath = new ArrayList<Pos>();
    HashSet<Integer> encodedPossibilities = new HashSet<Integer>();
    Pos pos = plan.start.copy();
    Pos cutPos = new Pos(0, 0);
    for (int i = 0; i < plan.size; i++) {
      int move = (int)plan.tabs[(i+plan.startPos)%plan.size];
      movePosByDir(pos, move);
      for (int flip = 0; flip < 2; flip++) {
        if (move == UP) {
          cutPos.x = pos.x+flip;
          cutPos.y = pos.y+1;
        } else if (move == DOWN) {
          cutPos.x = pos.x+flip;
          cutPos.y = pos.y;
        } else if (move == LEFT) {
          cutPos.x = pos.x+1;
          cutPos.y = pos.y+flip;
        } else if (move == RIGHT) {
          cutPos.x = pos.x;
          cutPos.y = pos.y+flip;
        }
        //if (!boxInBounds(cutPos)) continue;
        //}
        if (doDebug) debug_getPerturbedPlanAlongPlannedPath.add(cutPos.copy());
        exploreEncodedPossibilitiesAtCutPosAndAddToHashSet(g, cutPos.copy(), encodedPossibilities, skipIfNotShortcut, forbidCuttingTail);
      }
      if (pos.equals(g.food)) break;
      //ppos.x = pos.x;
      //ppos.y = pos.y;
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
    if (plan.timingGrid == null) println("exploreEncodedPossibilitiesAtCutPosAndAddToHashSet - plan.timingGrid is null");
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
    if (plan.timingGrid == null) println("introducePerturbation - plan.timingGrid is null");
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
    newPlan.cutPos = cutPos;
    newPlan.joinPos = joinPos;
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
    else println("YOOOOOO p : ", p);
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
  int DEBUG_ID = 0;
  void show(Game g) {
    //showDebugPossibilitiesAlongPlan(g);

    noFill();
    stroke(255);
    strokeWeight(5);
    //plan.show(g.food, color(255), color(128), false);

    //if (!DO_DEBUG) return;
    if (mouseY < 100) {
      plan.show(g.food, color(255), color(64), false);
      getPerturbedPlanAlongPlannedPath(g, true, true, true);
      for (int i = 0; i < debug_getPerturbedPlanAlongPlannedPath.size(); i++) {
        Pos pos = debug_getPerturbedPlanAlongPlannedPath.get(i);
        if (i == 0) println(pos.x, pos.y);
        noStroke();
        fill(0, 0, 255, 64);
        rect(pos.x*20-10, pos.y*20-10, 30, 30, 5);
      }
    } else showMousePlan(g);
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
    color col = color(255);
    if (debug_plans.length == 0) {
      newPlan = plan;
    } else {
      //int id = frameCount % debug_allpossibilities.length;
      int id = floor(map(mouseX, 0, width+1, 0, debug_plans.length));
      newPlan = debug_plans[id];
      col = debug_accepted[id] ? color(255) : color(128);
      noFill();
      strokeWeight(1);
      debug_plans_old[id].show(g.food, color(255), color(128, 30), false);
      strokeWeight(5);
    }
    newPlan.show(g.food, col, color(128, 30), false);

    noStroke();
    fill(255, 0, 0, 128);
    if (newPlan.cutPos != null) ellipse(20*newPlan.cutPos.x+10, 20*newPlan.cutPos.y+10, 40, 40);
    fill(0, 255, 0, 128);
    if (newPlan.joinPos != null) ellipse(20*newPlan.joinPos.x+10, 20*newPlan.joinPos.y+10, 40, 40);

    fill(255);
    text("energy : "+energy(g, newPlan), width/2-5, width-3);
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
    if (debug_energy.length == 0) return;
    pushMatrix();
    translate(0, height);
    scale(1, -1);
    int w = debug_energy.length;
    float h = 100;
    //for (int i = 0; i < w; i++) h = max(h, debug_scores[i]);
    float xmul = float(width)/w;
    float ymul = float(height)/h;
    strokeWeight(1);
    stroke(255);
    for (int i = 0; i < w; i++) {
      line(i*xmul, debug_energy[i]*ymul, (i+1)*xmul, debug_energy[i]*ymul);
      line(i*xmul, debug_energy_record[max(0, i-1)]*ymul, (i+1)*xmul, debug_energy_record[i]*ymul);
    }
    popMatrix();
  }

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
