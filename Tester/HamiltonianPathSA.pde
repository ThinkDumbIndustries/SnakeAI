import java.util.HashSet; //<>//
import java.util.Iterator;
import java.lang.System;

class HamiltonianPathSA implements Policy {
  int STEPS_RANDOMIZE = 1000;
  int STEPS_ANNEAL_ON_FOOD_UPDATE = 100; //300
  int STEPS_ANNEAL_DIR = 10;
  float MAX_TEMPERATURE = 4500;

  FastHPath plan = null;
  Game g;
  int[][] astarplan;

  HamiltonianPathSA() {
  }

  void reset(Game g) {
    this.g = g;
    setPlan(aHamiltonianPath(g.head));
    for (int i = 0; i < STEPS_RANDOMIZE; i++) setPlan(generateRandomCutJoin(g, plan));
  }

  boolean DEBUG_DONT = !DO_DEBUG;
  ArrayList<FastHPath> debug_disrespectful;
  ArrayList<FastHPath> debug_annealing_plans;
  ArrayList<Float> debug_annealing_energy;
  ArrayList<Boolean> debug_annealing_accepted;
  ArrayList<Boolean> debug_annealing_restart;

  void updateFood(Game g) {
    debug_annealing_plans = new ArrayList<FastHPath>();
    debug_annealing_energy = new ArrayList<Float>();
    debug_annealing_accepted = new ArrayList<Boolean>();
    debug_annealing_restart = new ArrayList<Boolean>();
    debug_disrespectful = new ArrayList<FastHPath>();

    setPlan(plan);
    if (DEBUG_DONT) anneal(g, STEPS_ANNEAL_ON_FOOD_UPDATE);
    DEBUG_DONT = true;
    //if (DO_DEBUG) PAUSED = true;
  }

  int getDir(Game g) {
    astarplan = findastarplan(g);
    if (DEBUG_DONT) anneal(g, STEPS_ANNEAL_DIR);
    int move = plan.pop();
    plan.computeTimingGrid();
    return move;
  }

  void setPlan(FastHPath newPlan) {
    plan = newPlan;
    astarplan = findastarplan(g);
    //if (plan.timingGrid == null) println("setPlan - plan.timingGrid is null");
  }

  float energy(Game g, FastHPath p) {
    //return energy_timetofood(g, p) + energy_expectation_nplusone(g, p);
    return energy_timetofood(g, p);
    //return energy_astarplan_moves(p);
    //return energy_squiggle(p);
    //return energy_straight(p);
    //return energy_numConsecutiveASTARMoves(g, p);
    //return energy_timetofood(g, p) + 20 * energy_numConsecutiveASTARMoves(g, p);
  }
  float energy_timetofood(Game g, FastHPath p) {
    return p.timingGrid[g.food.x][g.food.y]-abs(g.food.x-p.start.x)-abs(g.food.y-p.start.y);
  }
  float energy_expectation_nplusone(Game g, FastHPath p) {
    float sum = 0;
    int count = 0;
    int[][] fgrid = new int[GRID_SIZE][GRID_SIZE];
    int timeToFood = p.timingGrid[g.food.x][g.food.y];
    // make time pass
    for (int i = 0; i < GRID_SIZE; i++) for (int j = 0; j < GRID_SIZE-1; j++) fgrid[i][j] = max(0, g.grid[i][j] - timeToFood);
    Pos currentPos = p.start.copy();
    for (int i = 0; i < p.size; i++) {
      int move = (int)p.tabs[(i+p.startPos)%p.size];
      movePosByDir(currentPos, move);
      fgrid[currentPos.x][currentPos.y] = g.snake_length - timeToFood + i+1;
      if (currentPos.equals(g.food)) break;
    }
    int[][] fastarplan = findastarplan(fgrid, g.food);
    for (int i = 0; i < GRID_SIZE; i++) for (int j = 0; j < GRID_SIZE-1; j++) if (fgrid[i][j] == 0) {
      sum += fastarplan[i][j];
      count++;
    }
    return sum / count;
  }
  float energy_astarplan_moves(FastHPath p) {
    int count = 0;
    Pos currentPos = p.start.copy();
    Pos pastPos = p.start.copy();
    movePosByDir(currentPos, p.tabs[p.startPos]);
    for (int i = 1; i < p.size; i++) {
      int move = (int)p.tabs[(i+p.startPos)%p.size];
      movePosByDir(currentPos, move);
      if (currentPos.equals(g.food)) return count;
      if (astarplan[pastPos.x][pastPos.y] < astarplan[currentPos.x][currentPos.y]) count++;
      pastPos.x = currentPos.x;
      pastPos.y = currentPos.y;
    }
    return count;
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
  float energy_straight(FastHPath p) {
    Pos pos = p.start.copy();
    int count = 0;
    int pmove = (int)p.tabs[p.startPos];
    for (int i = 1; i < p.size; i++) {
      int move = (int)p.tabs[(i+p.startPos)%p.size];
      if (move != pmove) count++;
      movePosByDir(pos, move);
      pmove = move;
    }
    return count;
  }
  float energy_squiggle(FastHPath p) {
    Pos pos = p.start.copy();
    int count = 0;
    int pmove = (int)p.tabs[p.startPos];
    for (int i = 1; i < p.size; i++) {
      int move = (int)p.tabs[(i+p.startPos)%p.size];
      if (move == pmove) count++;
      movePosByDir(pos, move);
      pmove = move;
    }
    return count;
  }

  float temperature(float time, float max_temp, float alpha) {
    // https://www.desmos.com/calculator/i3ai4oncvw
    return max_temp*(1-time)/(1+alpha*time);
  }


  void anneal(Game g, int STEPS_ANNEAL) {
    if (STEPS_ANNEAL == 0) return;
    int disrespect_count = 0;
    int restarts_count = 0;

    FastHPath recordPlan = plan.copy();
    float recordEnergy = energy(g, plan);
    //if (DO_DEBUG) println("recordEnergy : ", recordEnergy);
    for (int i = 0; i < STEPS_ANNEAL; i++) {
      float time = map(i, 0, STEPS_ANNEAL-1, 0, 1);
      float temperature = temperature(time, MAX_TEMPERATURE, 9);
      FastHPath newPlan = generateCandidate(g, float(i)/STEPS_ANNEAL);
      if (newPlan.isDirespectful(g.grid, g.snake_length, g.food)) {
        //println("REJECTING CANDIDATE");
        debug_disrespectful.add(newPlan.copy());
        disrespect_count++;
        newPlan = plan.copy();
        newPlan.computeTimingGrid();
      }
      float currentEnergy = energy(g, plan);
      float newEnergy = energy(g, newPlan);
      //println("newEnergy : ", newEnergy);
      boolean accepted = newEnergy < currentEnergy || random(1) < exp((currentEnergy - newEnergy) / temperature);
      if (accepted) {
        setPlan(newPlan);
        if (newEnergy <= recordEnergy) {
          recordEnergy = newEnergy;
          recordPlan = newPlan.copy();
          recordPlan.computeTimingGrid();
        }
      }
      float planEnergy = energy(g, plan);

      float restartProb = (1+4*time)*(planEnergy-recordEnergy)/1000.0;
      if (restartProb <= 0) restartProb = 0;
      else restartProb /= restartProb+1;
      boolean restart = random(1) < restartProb;
      if (restart) {
        recordPlan.computeTimingGrid();
        setPlan(recordPlan);
        restarts_count++;
      }
      debug_annealing_plans.add(newPlan);
      debug_annealing_energy.add(newEnergy);
      debug_annealing_accepted.add(accepted);
      debug_annealing_restart.add(restart);
    }
    setPlan(recordPlan);
    if (DO_DEBUG)
      if (disrespect_count>0) {
        println(round(float(100)*disrespect_count/STEPS_ANNEAL)+"% disrespectful, "+restarts_count+" restarts, energy : ", recordEnergy);
        PAUSED = true;
      }
    plan = plan.copy();
    plan.computeTimingGrid();
    //println("final energy : ", recordEnergy);
  }
  FastHPath generateCandidate(Game g, float time) { // should never return null
    //return generateAStarPlan(g, plan);
    float temperature = 0; //temperature(time, 1000, 3);
    FastHPath newPlan = generateShortcutPlan(g, plan, temperature, true);
    if (newPlan != null) return newPlan;
    return generateShortcutPlanSafe(g, generateShortcutPlanSafe(g, plan, 1000000000, false), 0, true);
    //return generateRandomCutJoin(g, generateRandomCutJoin(g, generateRandomCutJoin(g, plan)));
  }

  FastHPath generateAStarPlan(Game g, FastHPath pln) {
    OutputPlanProducer producer = new OutputPlanProducer();
    // To implement
    exploreAStarPlan(g, pln);
    return producer.output_plan;
  }

  boolean exploreAStarPlan(Game g, FastHPath pln) {
    // To implement
    return false;
  }

  FastHPath generateShortcutPlan(Game g, FastHPath pln, float temperature, boolean mustBeShortcut) {
    OutputPlanProducer producer = new OutputPlanProducer();
    if (exploreShortcutPlan(g, pln, producer, temperature, mustBeShortcut)) return producer.output_plan;
    return null;
  }
  FastHPath generateShortcutPlanSafe(Game g, FastHPath pln, float temperature, boolean mustBeShortcut) {
    FastHPath improved = generateShortcutPlan(g, pln, temperature, mustBeShortcut);
    if (improved == null) return pln;
    return improved;
  }

  boolean exploreShortcutPlan(Game g, FastHPath pln, CutJoinConsumer consumer, float temperature, boolean mustBeShortcut) {
    PriorityQueue<Pos> q_cuts = new PriorityQueue<Pos>(new Comparator<Pos>() {
      int compare(Pos cutPos1, Pos cutPos2) {
        int[] cutQuadrantValues1 = getSortedPlanValues(pln.timingGrid, cutPos1);
        int[] cutQuadrantValues2 = getSortedPlanValues(pln.timingGrid, cutPos2);
        int r = round(random(-temperature, temperature));
        return r + (cutQuadrantValues2[2]-cutQuadrantValues2[1]) - (cutQuadrantValues1[2]-cutQuadrantValues1[1]);
      }
    }
    );
    int food_time = pln.timingGrid[g.food.x][g.food.y];
    exploreCutsAlongPlanToGoal(pln, g.food, new CutConsumer() {
      void consume(Pos cutPos) {
        int[] cutQuadrantValues = getSortedPlanValues(pln.timingGrid, cutPos);
        if (cutQuadrantValues[0]+1 != cutQuadrantValues[1] || cutQuadrantValues[2]+1 != cutQuadrantValues[3]) return; // must be cutable
        if (mustBeShortcut && cutQuadrantValues[3] > food_time) return; // must be a shortcut
        q_cuts.add(cutPos.copy());
      }
    }
    );
    while (!q_cuts.isEmpty()) {
      Pos cutPos = q_cuts.poll();
      CutJoinConsumer wrapper_consumer = new CutJoinConsumer() {
        boolean consume(FastHPath pln, Pos cutPos, int[] cutQuadrantValues, int[] cutQuadrantPositions, Pos joinPos, int[] joinQuadrantValues, int[] joinQuadrantPositions) {
          if (food_time >= joinQuadrantValues[3]) return false;
          return consumer.consume(pln, cutPos, cutQuadrantValues, cutQuadrantPositions, joinPos, joinQuadrantValues, joinQuadrantPositions);
        }
      };
      if (exploreCut(g, pln, cutPos, wrapper_consumer, false, true, true)) return true;
    }
    return false;
  }

  boolean exploreRandomCutJoin(Game g, FastHPath pln, CutJoinConsumer consumer) {
    for (int i = 0; i < 1000; i++) {
      Pos cutPos = new Pos(floor(random(GRID_SIZE-1)), floor(random(GRID_SIZE-1)));
      if (exploreCut(g, pln, cutPos, consumer, false, true, true)) return true;
    }
    println("Damn! exploreRandomCutJoin timed out");
    return false;
  }
  FastHPath generateRandomCutJoin(Game g, FastHPath pln) {
    OutputPlanProducer producer = new OutputPlanProducer();
    exploreRandomCutJoin(g, pln, producer);
    return producer.output_plan;
  }

  void exploreCutsAlongPlanToGoal(FastHPath pln, Pos goal, CutConsumer consumer) {
    Pos pos = pln.start.copy();
    Pos cutPos = new Pos(0, 0);
    for (int i = 0; i < pln.size; i++) {
      int move = (int)pln.tabs[(i+pln.startPos)%pln.size];
      for (int flip = 0; flip < 2; flip++) {
        cutPos.x = pos.x - int(((flip==1)&&(move==UP||move==DOWN))||(move==LEFT));
        cutPos.y = pos.y - int(((flip==1)&&(move==LEFT||move==RIGHT))||(move==UP));
        if (boxInBounds(cutPos))consumer.consume(cutPos);
      }
      movePosByDir(pos, move);
      if (pos.equals(goal)) break;
    }
  }

  boolean exploreCut(Game g, FastHPath pln, Pos cutPos, CutJoinConsumer consumer, boolean skipIfNotShortcut, boolean forbidCuttingTail, boolean refuseReversals) {
    if (!boxInBounds(cutPos)) return false;
    if (pln.timingGrid == null) println("exploreCut - plan.timingGrid is null");
    int[] cutQuadrantValues = getSortedPlanValues(pln.timingGrid, cutPos);
    if (cutQuadrantValues[0]+1 != cutQuadrantValues[1] || cutQuadrantValues[2]+1 != cutQuadrantValues[3]) return false;
    int[] cutQuadrantPositions = getSortedPlanPositions(pln.timingGrid, cutQuadrantValues, cutPos);
    if (skipIfNotShortcut && cutQuadrantValues[3] > pln.timingGrid[g.food.x][g.food.y]) println(cutQuadrantValues[3], pln.timingGrid[g.food.x][g.food.y]);
    if (skipIfNotShortcut && cutQuadrantValues[3] > pln.timingGrid[g.food.x][g.food.y]) return false;
    Pos pos = getQuadrantPos(cutPos, cutQuadrantPositions[1]);
    Pos joinPos = new Pos(0, 0);
    int loopMove_n = cutQuadrantValues[2] - cutQuadrantValues[1];
    for (int i = 0; i < loopMove_n; i++) {
      int move = (int)pln.tabs[(i+pln.startPos+cutQuadrantValues[1])%pln.size];
      for (int flip = 0; flip < 2; flip++) {
        joinPos.x = pos.x - int(((flip==1)&&(move==UP||move==DOWN))||(move==LEFT));
        joinPos.y = pos.y - int(((flip==1)&&(move==LEFT||move==RIGHT))||(move==UP));
        if (!boxInBounds(joinPos)) continue;
        if (joinPos.equals(cutPos)) continue;
        int[] joinQuadrantValues = getSortedPlanValues(pln.timingGrid, joinPos);
        if (joinQuadrantValues[0]+1 != joinQuadrantValues[1] || joinQuadrantValues[2]+1 != joinQuadrantValues[3]) continue; // needs to be cutable
        if (cutQuadrantValues[1] <= joinQuadrantValues[0] && joinQuadrantValues[3] <= cutQuadrantValues[2]) continue; // This would lead to two loops
        // basically the main hamiltonian path would no longer go through every tile in the grid
        int[] joinQuadrantPositions = getSortedPlanPositions(pln.timingGrid, joinQuadrantValues, joinPos);
        if (forbidCuttingTail) {
          Pos cq0pos = getQuadrantPos(cutPos, cutQuadrantPositions[0]);
          Pos cq1pos = getQuadrantPos(cutPos, cutQuadrantPositions[1]);
          Pos cq2pos = getQuadrantPos(cutPos, cutQuadrantPositions[2]);
          Pos cq3pos = getQuadrantPos(cutPos, cutQuadrantPositions[3]);
          Pos jq0pos = getQuadrantPos(joinPos, joinQuadrantPositions[0]);
          Pos jq1pos = getQuadrantPos(joinPos, joinQuadrantPositions[1]);
          Pos jq2pos = getQuadrantPos(joinPos, joinQuadrantPositions[2]);
          Pos jq3pos = getQuadrantPos(joinPos, joinQuadrantPositions[3]);
          int minTimeToFood = astarplan[g.food.x][g.food.y];
          int stepsFromHeadToCut = cutQuadrantValues[0];
          int stepsFromCutToJoin = joinQuadrantValues[2] - cutQuadrantValues[3];
          int loopStepsFromJoinToCut = cutQuadrantValues[2] - joinQuadrantValues[1];
          int loopStepsFromCutToJoin = joinQuadrantValues[0] - cutQuadrantValues[1];
          //int stepsFromJoinToHead = GRID_SIZE*GRID_SIZE - joinQuadrantValues[3];
          if (gridAtPos(g.grid, cq0pos) > min(stepsFromHeadToCut, minTimeToFood, gridAtPos(astarplan, cq0pos))) continue;
          if (gridAtPos(g.grid, cq3pos) > min(stepsFromHeadToCut+1, minTimeToFood, gridAtPos(astarplan, cq3pos))) continue;
          if (gridAtPos(g.grid, jq0pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin, minTimeToFood, gridAtPos(astarplan, jq0pos))) continue;
          if (gridAtPos(g.grid, jq1pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin+1, minTimeToFood, gridAtPos(astarplan, jq1pos))) continue;
          if (gridAtPos(g.grid, cq2pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut, minTimeToFood, gridAtPos(astarplan, cq2pos))) continue;
          if (gridAtPos(g.grid, cq1pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1, minTimeToFood, gridAtPos(astarplan, cq1pos))) continue;
          if (gridAtPos(g.grid, jq2pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin, minTimeToFood, gridAtPos(astarplan, jq2pos))) continue;
          if (gridAtPos(g.grid, jq3pos) > min(stepsFromHeadToCut+1+stepsFromCutToJoin+1+loopStepsFromJoinToCut+1+loopStepsFromCutToJoin+1, minTimeToFood, gridAtPos(astarplan, jq3pos))) continue;
        }

        boolean REVERSED = cutQuadrantValues[0] > joinQuadrantValues[0];
        if (REVERSED && refuseReversals) continue;
        if (!REVERSED) {
          if (joinQuadrantValues[2] < cutQuadrantValues[3]) continue;
          if (consumer.consume(pln, cutPos, cutQuadrantValues, cutQuadrantPositions, joinPos, joinQuadrantValues, joinQuadrantPositions)) return true;
        } else {
          if (joinQuadrantValues[2] > cutQuadrantValues[3]) continue;
          if (consumer.consume(pln, joinPos, joinQuadrantValues, joinQuadrantPositions, cutPos, cutQuadrantValues, cutQuadrantPositions)) return true;
        }
      }
      movePosByDir(pos, move);
    }
    return false;
  }

  FastHPath introducePerturbation(FastHPath plan, int encodedPerturbation) {
    Pos joinPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    encodedPerturbation /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encodedPerturbation % GRID_SIZE, (encodedPerturbation/GRID_SIZE) % GRID_SIZE);
    int[] cutQuadrantValues = getSortedPlanValues(plan.timingGrid, cutPos);
    int[] cutQuadrantPositions = getSortedPlanPositions(plan.timingGrid, cutQuadrantValues, cutPos);
    int[] joinQuadrantValues = getSortedPlanValues(plan.timingGrid, joinPos);
    int[] joinQuadrantPositions = getSortedPlanPositions(plan.timingGrid, joinQuadrantValues, joinPos);
    return introducePerturbation(plan, cutPos, cutQuadrantValues, cutQuadrantPositions, joinPos, joinQuadrantValues, joinQuadrantPositions);
  }

  FastHPath introducePerturbation(FastHPath plan, Pos cutPos, int[] cutQuadrantValues, int[] cutQuadrantPositions, Pos joinPos, int[] joinQuadrantValues, int[] joinQuadrantPositions) {
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
    FastHPath newPlan = new FastHPath(plan.start);
    newPlan.cutPos = cutPos;
    newPlan.joinPos = joinPos;
    int moveId = 0;
    newPlan.moveCopy(plan, 0, moveId, stepsFromHeadToCut);
    moveId += stepsFromHeadToCut;
    newPlan.setTab(moveId++, (byte)(dirAtoB(cutQuadrantPositions[0], cutQuadrantPositions[3])));
    newPlan.moveCopy(plan, cutQuadrantValues[3], moveId, stepsFromCutToJoin);
    moveId += stepsFromCutToJoin;
    newPlan.setTab(moveId++, (byte)(dirAtoB(joinQuadrantPositions[2], joinQuadrantPositions[1])));
    newPlan.moveCopy(plan, joinQuadrantValues[1], moveId, loopStepsFromJoinToCut);
    moveId += loopStepsFromJoinToCut;
    newPlan.setTab(moveId++, (byte)(dirAtoB(cutQuadrantPositions[2], cutQuadrantPositions[1])));
    newPlan.moveCopy(plan, cutQuadrantValues[1], moveId, loopStepsFromCutToJoin);
    moveId += loopStepsFromCutToJoin;
    newPlan.setTab(moveId++, (byte)(dirAtoB(joinQuadrantPositions[0], joinQuadrantPositions[3])));
    newPlan.moveCopy(plan, joinQuadrantValues[3], moveId, stepsFromJoinToHead);
    newPlan.computeTimingGrid();
    return newPlan;
  }
  class OutputPlanProducer extends CutJoinConsumer {
    boolean consume(FastHPath plan, Pos cutPos, int[] cutQuadrantValues, int[] cutQuadrantPositions, Pos joinPos, int[] joinQuadrantValues, int[] joinQuadrantPositions) {
      output_plan = introducePerturbation(plan, cutPos, cutQuadrantValues, cutQuadrantPositions, joinPos, joinQuadrantValues, joinQuadrantPositions);
      return !output_plan.isDirespectful(g.grid, g.snake_length, g.food);
      //return true;
    }
  }

  void show(Game g) {
    plan.computeTimingGrid();
    //showDebugPossibilitiesAlongPlan(g);

    noFill();
    stroke(255);
    strokeWeight(5);
    //plan.show(g.food, color(255), color(128), false);

    //if (!DO_DEBUG) return;
    //if (mouseX < 600 || !DO_SIDE_DEBUG) plan.show(g.food, color(255), color(64), false);
    //else showSideDebug(g);
    showSideDebug(g);
    //showDebugBlueBoxesAtPoses(g);
    //showDebugRedGreen(g);
    //showDisrespectful(g);//showMousePlan(g);
    //showScores();
    //showMousePeturbations();
  }

  void showSideDebug(Game g) {
    showSideDebugAnnealing(g);
  }

  void showSideDebugAnnealing(Game g) {
    if (debug_annealing_plans == null || debug_annealing_plans.size() == 0) return;
    int id = floor(map(mouseX, 600, 1200, 0, debug_annealing_plans.size()));
    id = constrain(id, 0, debug_annealing_plans.size()-1);
    FastHPath pln;
    if (mouseX > 600) pln = debug_annealing_plans.get(id);
    else pln = plan;
    pln.show(g.food, color(255), color(64), false);
    pushMatrix();
    translate(-10, -10);
    translate(600, 0);
    noStroke();
    fill(0);
    rectMode(CORNER);
    rect(0, 0, 600, height);
    fill(60);
    strokeWeight(1);
    float xscale = 600.0 / (debug_annealing_plans.size());
    float yscale = 170.0/log(10);
    //for (int i = 0; i <= 1000; i += 100) line(0, 600-yscale*log(i), 600, 600-yscale*log(i));
    for (int i = 0; i <= 3; i ++) {
      float y = pow(10, i);
      stroke(60);
      line(0, 600-yscale*log(y), 600, 600-yscale*log(y));
      text(int(y), 0, -13+600-yscale*log(y));
      stroke(20);
      for (int j = 2; j < 10; j++) {
        float y_ = j*y;
        line(0, 600-yscale*log(y_), 600, 600-yscale*log(y_));
      }
    }
    float pe = 0;
    float re = 0;
    for (int i = 0; i < debug_annealing_plans.size(); i++) {
      FastHPath p = debug_annealing_plans.get(i);
      float e = debug_annealing_energy.get(i);
      boolean acc = debug_annealing_accepted.get(i);
      boolean res = debug_annealing_restart.get(i);
      if (i == 0 || acc) pe = e;
      if (i == 0 || e <= re) re = e;
      noStroke();
      if (acc && i == id) fill(0, 255, 0);
      if (acc && i != id) fill(0, 64, 0);
      if (!acc && i == id) fill(255, 0, 0);
      if (!acc && i != id) fill(64, 0, 0);
      rect(i*xscale, 600, xscale, 10);
      if (res) {
        if (i == id) fill(0, 0, 255);
        if (i != id) fill(0, 0, 128);
        rect(i*xscale, 600, xscale, -30);
      }
      stroke(255);
      line(i*xscale, -1+600-yscale*log(e), (i+1)*xscale, -1+600-yscale*log(e));
      stroke(255, 0, 0);
      line(i*xscale, 600-yscale*log(pe), (i+1)*xscale, 600-yscale*log(pe));
      stroke(0, 0, 255);
      line(i*xscale, 600-yscale*log(re), (i+1)*xscale, 600-yscale*log(re));
    };
    popMatrix();
  }

  void showDebugRedGreen(Game g) {
    CutJoinConsumer consumer = new CutJoinConsumer() {
      boolean consume(FastHPath plan, Pos cutPos, int[] cutQuadrantValues, int[] cutQuadrantPositions, Pos joinPos, int[] joinQuadrantValues, int[] joinQuadrantPositions) {
        noStroke();
        fill(255, 0, 0, 64);
        ellipse(20*cutPos.x+10, 20*cutPos.y+10, 40, 40);
        fill(0, 255, 0, 64);
        ellipse(20*joinPos.x+10, 20*joinPos.y+10, 40, 40);
        return true;
      }
    };
    exploreShortcutPlan(g, plan, consumer, 0, true);
  }
  void showDebugBlueBoxesAtPoses(Game g) {
    exploreCutsAlongPlanToGoal(plan, g.food, new CutConsumer() {
      void consume(Pos cutPos) {
        int food_time = plan.timingGrid[g.food.x][g.food.y];
        int[] cutQuadrantValues = getSortedPlanValues(plan.timingGrid, cutPos);
        if (cutQuadrantValues[0]+1 != cutQuadrantValues[1] || cutQuadrantValues[2]+1 != cutQuadrantValues[3]) return;
        if (cutQuadrantValues[3] > food_time) return;
        noStroke();
        fill(0, 0, 255, 64);
        rect(cutPos.x*20+10, cutPos.y*20+10, 30, 30, 5);
      }
    }
    );
  }

  void showDisrespectful(Game g) {
    if (debug_disrespectful.size() == 0) return;
    int id = floor(map(mouseX, 0, width+1, 0, debug_disrespectful.size()));
    FastHPath newPlan = debug_disrespectful.get(id);
    newPlan.show(g.food, color(255), color(64), false);
  }
}

int[][] findastarplan(Game g) {
  return findastarplan(g.grid, g.head);
}
int[][] findastarplan(int[][] grid, Pos head) {
  int[][] astarplan = new int[GRID_SIZE][GRID_SIZE];
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      astarplan[i][j] = -1;
    }
  }
  PriorityQueue<WaitingPos> q = new PriorityQueue<WaitingPos>();
  q.add(new WaitingPos(head.x, head.y, 0));
  astarplan[head.x][head.y] = 0;
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
      if (grid[np.x][np.y] > np.waited) {
        if (astarplan[p.x][p.y] == 0) continue;
        else np.waited += 2*((1+grid[np.x][np.y]-np.waited)/2);
      }
      if (astarplan[np.x][np.y] != -1 && np.waited >= astarplan[np.x][np.y]) continue;
      astarplan[np.x][np.y] = np.waited;
      q.add(np);
    }
  }
  return astarplan;
}
