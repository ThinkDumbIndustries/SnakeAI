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
  Path plan;
  HamiltonianPathSA() {
  }
  ArrayList<Pos> join_candidates;
  void reset(Game g) {
    plan = aHamiltonianPath(g.head);
    for (int i = 0; i < 100; i++) {
      updatePlanPerturbations(g);
      DEBUG_ID = floor(random(debug_allpossibilities.length));
      int encoded = debug_allpossibilities[DEBUG_ID];
      plan = introducePerturbation(plan, encoded);
    }
  }
  int[] debug_allpossibilities = new int[0];
  float[] debug_scores = new float[0];
  void updateFood(Game g) {
    doAThing(g);
  }
  void updatePlanPerturbations(Game g) {
    debug_allpossibilities = getAllPossibleChanges(g);
    //println("There are ", debug_allpossibilities.length, " elements in debug_allpossibilities");
    Arrays.sort(debug_allpossibilities);
    //debug_allpossibilities = (int[])subset(debug_allpossibilities, floor(random(2000)), width);
  }
  int getDir(Game g) {
    if (plan == null) return -1;
    if (plan.size() == 0) return -1;
    int move = plan.pop();
    plan.add(move);
    return move;
  }

  void doAThing(Game g) {
    updatePlanPerturbations(g);
    if (debug_allpossibilities.length == 0) return;
    int[][] planTimingGrid = plan.timingGrid();
    int STEPS = 100;
    for (int i = 0; i < STEPS; i++) {
      float temperature = 0; //map(i, 0, STEPS, 1.0, -1.0);
      DEBUG_ID = floor(random(debug_allpossibilities.length));
      int encoded = debug_allpossibilities[DEBUG_ID];
      //println("[", DEBUG_ID, "] with encoding "+encoded);
      Path newPlan = introducePerturbation(plan, encoded);
      if (newPlan == null) continue;
      int[][] newPlanTimingGrid = newPlan.timingGrid();
      if (planTimingGrid[g.food.x][g.food.y] > newPlanTimingGrid[g.food.x][g.food.y] || random(1) < temperature) {
        plan = newPlan;
        planTimingGrid = newPlanTimingGrid;
        updatePlanPerturbations(g);
        if (debug_allpossibilities.length == 0) break;
      }
    }
  }

  int[] getAllPossibleChanges(Game g) {
    HashSet<Integer> encodedPossibilities = new HashSet<Integer>();
    int[][] planTimingGrid = plan.timingGrid();
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
    int[][] planTimingGrid = plan.timingGrid();
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
    if (!newPlan.start.equals(newPlan.end)) return null;
    if (newPlan.size() != GRID_SIZE*GRID_SIZE) return null;
    return newPlan;
  }
  Pos getQuadrantPos(Pos box, int p) {
    if (p == 0) return box;
    if (p == 1) return new Pos(box.x+1, box.y);
    if (p == 2) return new Pos(box.x, box.y+1);
    if (p == 3) return new Pos(box.x+1, box.y+1);
    return null;
  }
  /*void makeOneChange(Game g) {
   if (!plan.isInBounds()) println("OUT OF BOUNDS STARTTT");
   int[][] plan_grid = plan.timingGrid();
   Path newPlan = plan.copy();
   
   
   Pos cutBox = getRandomValidCut(g, plan_grid);
   join_candidates = new ArrayList<Pos>(0);
   if (plan_grid == null) println("makeOneChange : plan_grid = null");
   int[] sorted_plan_values = getSortedPlanValues(plan_grid, cutBox);
   if (sorted_plan_values[0]+1 != sorted_plan_values[1] || sorted_plan_values[2]+1 != sorted_plan_values[3]) println("THIS IS NOT GOOD");
   if (sorted_plan_values[0] < 1) println("THIS IS NOT GOOD");
   int[] sorted_positions = getSortedPlanPositions(plan_grid, sorted_plan_values, cutBox);
   if (gridAtThing(g.grid, cutBox, sorted_positions[0]) != 0 || gridAtThing(g.grid, cutBox, sorted_positions[1]) != 0) println("THIS IS NOT GOOD");
   if (gridAtThing(g.grid, cutBox, sorted_positions[2]) != 0 || gridAtThing(g.grid, cutBox, sorted_positions[3]) != 0) println("THIS IS NOT GOOD");
   int dir0to3 = dirAtoB(sorted_positions[0], sorted_positions[3]);
   //int dir0to1 = dirAtoB(sorted_positions[0], sorted_positions[1]);
   
   Integer[] oldmoves = newPlan.moves.toArray(new Integer[0]);
   Integer[] newmoves = new Integer[oldmoves.length - sorted_plan_values[3] + sorted_plan_values[0] + 1];
   Integer[] cutmoves = new Integer[sorted_plan_values[2] - sorted_plan_values[1] + 1];
   // new
   System.arraycopy(oldmoves, 0, newmoves, 0, sorted_plan_values[0]);
   if (dir0to3 == -1) println("HFKJLMJDFKLMJ");
   newmoves[sorted_plan_values[0]] = dir0to3;
   System.arraycopy(oldmoves, sorted_plan_values[3], newmoves, sorted_plan_values[0]+1, newmoves.length-sorted_plan_values[0]-1);
   newPlan.moves = new ArrayDeque<Integer>(Arrays.asList(newmoves));
   if (!newPlan.isInBounds()) println("OUT OF BOUNDS 1");
   int[][] new_plan_grid = newPlan.timingGrid(); // update, as plan has been changed
   // cut
   System.arraycopy(oldmoves, sorted_plan_values[1], cutmoves, 0, cutmoves.length-1);
   cutmoves[cutmoves.length-1] = rotateDir180(dir0to3);
   cut_loop = new Path(new Pos(cutBox.x+sorted_positions[1]%2, cutBox.y+sorted_positions[1]/2));
   cut_loop.moves = new ArrayDeque<Integer>(Arrays.asList(cutmoves));
   if (!cut_loop.isInBounds()) println("OUT OF BOUNDS 2 (loop)");
   int[][] cut_grid = cut_loop.planGrid();
   if (cut_grid == null) println("STRAIGHT : cut_loop.planGrid() == null");
   
   
   join_candidates = new ArrayList<Pos>(0);
   Pos posAlongCut = cut_loop.start;
   for (int move : cut_loop.moves.toArray(new Integer[0])) {
   Pos nposAlongCut = movePosByDir(posAlongCut, move);
   Pos candidatePos = new Pos(min(posAlongCut.x, nposAlongCut.x), min(posAlongCut.y, nposAlongCut.y));
   posAlongCut = nposAlongCut;
   for (int flip = 0; flip < 2; flip++) {
   if (flip == 1) {
   if (move == LEFT || move == RIGHT) candidatePos.y--;
   else candidatePos.x--;
   }
   if (candidatePos.x < 0 || candidatePos.y < 0 || candidatePos.x >= GRID_SIZE-1 || candidatePos.y >= GRID_SIZE-1) continue;
   if (candidatePos.equals(cutBox)) continue;
   if (cut_grid == null) println("XXXYYYZZZ : cut_grid =  null");
   int[] sorted_plan_values2 = getSortedPlanValues2(new_plan_grid, cut_grid, candidatePos);
   if (sorted_plan_values2.length == 0) continue;
   if (sorted_plan_values2[0]+1 != sorted_plan_values2[1]) continue;
   if (sorted_plan_values2[2]+1 != sorted_plan_values2[3]) continue;
   if (gridAtThing(g.grid, candidatePos, sorted_positions[0]) != 0 || gridAtThing(g.grid, candidatePos, sorted_positions[1]) != 0) continue;
   if (gridAtThing(g.grid, candidatePos, sorted_positions[2]) != 0 || gridAtThing(g.grid, candidatePos, sorted_positions[3]) != 0) continue;
   join_candidates.add(candidatePos.copy());
   }
   }
   //println("THERE ARE ", join_candidates.size(), " CANDIDATES");
   if (join_candidates.size() == 0) {
   println("THIS SHOULD NOT HAVE HAPPENED");
   cut_loop = null;
   return;
   }
   debugCutPos = cutBox;
   
   
   //if (join_candidates.size() == 0) println("STILL NO CANDIDATES...");
   if (join_candidates.size() != 0) {
   int join_id = floor(random(join_candidates.size()));
   Pos candidatePos = join_candidates.get(join_id);
   if (candidatePos == null) {
   println("WTF - NULL Candidate");
   return;
   }
   if (cut_loop == null) println("AAABBBCCC !!!!! : cut_loop =  null");
   cut_grid = cut_loop.planGrid();
   if (cut_grid == null) println("AAABBBCCC : cut_grid =  null");
   int[] sorted_plan_values2 = getSortedPlanValues2(new_plan_grid, cut_grid, candidatePos);
   int[] sorted_positions2 = getSortedPlanPositions2(new_plan_grid, cut_grid, sorted_plan_values2, candidatePos);
   //println("Chose candidate pos ", join_id);
   //println("sorted_plan_values2");
   //printArray(sorted_plan_values2);
   //println("sorted_positions2");
   //printArray(sorted_positions2);
   
   Integer[] newoldmoves = newPlan.moves.toArray(new Integer[0]);
   Integer[] newcutmoves = cut_loop.moves.toArray(new Integer[0]);
   Integer[] newnewmoves = new Integer[GRID_SIZE*GRID_SIZE];
   System.arraycopy(newoldmoves, 0, newnewmoves, 0, sorted_plan_values2[0]);
   int id = sorted_plan_values2[0];
   newnewmoves[id] = dirAtoB(sorted_positions2[0], sorted_positions2[3]);
   if (dirAtoB(sorted_positions2[0], sorted_positions2[3]) == -1) {
   println("GUESS 2");
   println(debugCutPos.x, debugCutPos.y);
   println(candidatePos.x, candidatePos.y);
   println("Chose candidate pos ", join_id);
   println("sorted_plan_values2");
   printArray(sorted_plan_values2);
   println("sorted_positions2");
   printArray(sorted_positions2);
   println("-------------------   plan_grid    -------------------");
   for (int j = 0; j < GRID_SIZE; j++) {
   for (int i = 0; i < GRID_SIZE; i++) {
   if (new_plan_grid[i][j] == -9999)print(" x  ");
   else print(nf(new_plan_grid[i][j], 3)+" ");
   }
   println();
   }
   println("-------------------   cut_grid    -------------------");
   for (int j = 0; j < GRID_SIZE; j++) {
   for (int i = 0; i < GRID_SIZE; i++) {
   if (cut_grid[i][j] == -9999)print(" x  ");
   else print(nf(cut_grid[i][j], 3)+" ");
   }
   println();
   }
   }
   id ++;
   System.arraycopy(newcutmoves, sorted_plan_values2[3], newnewmoves, id, newcutmoves.length - sorted_plan_values2[3]);
   id += newcutmoves.length - sorted_plan_values2[3];
   System.arraycopy(newcutmoves, 0, newnewmoves, id, sorted_plan_values2[2]);
   id += sorted_plan_values2[2];
   newnewmoves[id] = dirAtoB(sorted_positions2[2], sorted_positions2[1]);
   if (dirAtoB(sorted_positions2[2], sorted_positions2[1]) == -1) {
   println("GUESS 3");
   println(debugCutPos.x, debugCutPos.y);
   println(candidatePos.x, candidatePos.y);
   println("Chose candidate pos ", join_id);
   println("sorted_plan_values2");
   printArray(sorted_plan_values2);
   println("sorted_positions2");
   printArray(sorted_positions2);
   println("-------------------   plan_grid    -------------------");
   for (int j = 0; j < GRID_SIZE; j++) {
   for (int i = 0; i < GRID_SIZE; i++) {
   if (new_plan_grid[i][j] == -9999)print(" x  ");
   else print(nf(new_plan_grid[i][j], 3)+" ");
   }
   println();
   }
   println("-------------------   cut_grid    -------------------");
   for (int j = 0; j < GRID_SIZE; j++) {
   for (int i = 0; i < GRID_SIZE; i++) {
   if (cut_grid[i][j] == -9999)print(" x  ");
   else print(nf(cut_grid[i][j], 3)+" ");
   }
   println();
   }
   }
   id ++;
   System.arraycopy(newoldmoves, sorted_plan_values2[1], newnewmoves, id, newnewmoves.length - id);
   newPlan.moves = new ArrayDeque<Integer>(Arrays.asList(newnewmoves));
   
   if (!newPlan.isInBounds()) println("OUT OF BOUNDS -- ROUTINE CHECK AT END");
   new_plan_grid = plan.timingGrid();
   
   debugJoinPos = candidatePos;
   }
   plan = newPlan;
   }*/
  //Pos getRandomValidCut(Game g, int[][] plan_grid) {
  //  for (int count = 0; count < 20; count++) {
  //    Pos cutBox = new Pos(floor(random(GRID_SIZE-1)), floor(random(GRID_SIZE-1)));
  //    if (isValidCut(g, plan_grid, cutBox)) return cutBox;
  //  }
  //  ArrayList<Pos> validCuts = new ArrayList<Pos>();
  //  for (int i = 0; i < GRID_SIZE; i++) {
  //    for (int j = 0; j < GRID_SIZE; j++) {
  //      Pos cutCandidate = new Pos(i, j);
  //      if (isValidCut(g, plan_grid, cutCandidate)) validCuts.add(cutCandidate);
  //    }
  //  }
  //  if (validCuts.size() == 0) return null;
  //  int id = floor(random(validCuts.size()));
  //  return validCuts.get(id);
  //}
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
    //stroke(255);
    strokeWeight(5);
    plan.show(g.food, color(255), color(128, 200));

    //int id = frameCount % debug_allpossibilities.length;
    int id = floor(map(mouseX, 0, width+1, 0, debug_allpossibilities.length));
    //if (frameCount % 2 == 0) DEBUG_ID = floor(random(debug_allpossibilities.length));
    int encoded = debug_allpossibilities[id];
    Pos joinPos = new Pos(encoded % GRID_SIZE, (encoded/GRID_SIZE) % GRID_SIZE);
    encoded /= GRID_SIZE*GRID_SIZE;
    Pos cutPos = new Pos(encoded % GRID_SIZE, (encoded/GRID_SIZE) % GRID_SIZE);
    strokeWeight(2);
    stroke(255, 0, 0);
    rect(20*cutPos.x+10, 20*cutPos.y+10, 40, 40);
    stroke(0, 255, 0);
    rect(20*joinPos.x+10, 20*joinPos.y+10, 40, 40);

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
    void show(Pos goal, color c1, color c2) {
      if (moves == null) return;
      stroke(c1);
      Pos currentPos = start;
      for (int move : moves.toArray(new Integer[0])) {
        Pos newPos = movePosByDir(currentPos, move);
        line(20*currentPos.x, 20*currentPos.y, 20*newPos.x, 20*newPos.y);
        if (newPos.equals(goal)) stroke(c2);
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
