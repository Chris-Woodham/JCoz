import model.*;

public class Main {
    
    public static void main(String[] args) {
        Result slowResult = new Result();
        Result fastResult = new Result();
        int iteration = 0;

        while (true) {
            Thread slowThread = new SlowThread(5, slowResult);
            Thread fastThread = new FastThread(5, fastResult);
            slowThread.start();
            fastThread.start();
            try {
                slowThread.join();
                fastThread.join();
            } catch(InterruptedException exception) {
                System.out.println("Thread interrupted");
            }
            System.out.println("End of loop " + iteration++ + "\n");
        }
    }

}
