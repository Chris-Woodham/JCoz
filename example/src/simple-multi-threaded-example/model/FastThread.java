package model;

public class FastThread extends Thread {

    private int numberIterations;
    private Result result;

    public FastThread(int numberIterations, Result result) {
        this.numberIterations = numberIterations;
        this.result = result;
    }

    @Override
    public void run() {
        while (this.numberIterations > 0) {
            long currentValue = result.getResult();
            result.setResult(currentValue += ((7 * this.numberIterations) % 13));
            this.numberIterations--;
        }
        System.out.println("Fast Thread returning - current fastResult is: " + result.getResult());
    }

}