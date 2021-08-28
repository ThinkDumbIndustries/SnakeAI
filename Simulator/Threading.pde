import java.util.PriorityQueue;
import java.util.Comparator;

class MyThread implements Runnable {
  Thread thread;
  String threadName;

  Game game;

  void start(int i) {
    if (thread == null) {
      threadName = "Thread "+i;
      thread = new Thread(this, threadName);
      thread.start();
    }
  }

  MyThread() {
    //game = new Game(new ZigZag());
    //game = new Game(new SmartZigZag());
    //game = new Game(new AStar());
    //game = new Game(new ZStar());
    //game = new Game(new ZStarPlus());
    //game = new Game(new LazySpiral());
    game = new Game(new LazySpiralModed());
  }
  void run() {
    while (true) {
      if (game.step()) {
        outputRsult(game.output);
        game.output = "";
        game.resetGame();
      }
    }
  }
}
