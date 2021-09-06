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
  }
  void run() {
    Policy p = makePolicy();
    game = new Game(p);
    while (true) {
      if (game.step()) {
        outputRsult(game.output);
        game.output = "";
        game.resetGame();
      }
    }
  }
}
