package model;

public class Result {

    public volatile long result;

    public Result() {
        this.result = 0;
    }

    public void setResult(long result) {
        this.result = result;
    }

    public long getResult() {
        return result;
    }
    
}
