package model;

public class SlowThread extends Thread {

    private int numberIterations;
    private Result result;

    public SlowThread(int numberIterations, Result result) {
        this.numberIterations = numberIterations;
        this.result = result;
    }

    @Override
    public void run() {
        while (this.numberIterations > 0) {
            try {
                Thread.sleep(1);
                long currentValue = result.getResult();
                result.setResult(currentValue += ((7 * this.numberIterations) % 13));
            } catch(InterruptedException exception) {
                System.out.println("Thread interrupted");
            }
            this.numberIterations--;
        }
        System.out.println("Slow Thread returning - current slowResult is: " + result.getResult());
    }
}