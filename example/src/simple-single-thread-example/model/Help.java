package model;

import java.util.Random;

public class Help {
    private final Random rand;

    public Help() {
        this.rand = new Random();
    }

    public int slowAdd() {
        int a = (new Random()).nextInt(100);
        int b = (new Random()).nextInt(150) +100;

        for (int i = 0; i < a; i++) {
            b++;
        }

        return b;
    }

    public int fastAdd() {
        int a = (new Random()).nextInt(100);
        int b = (new Random()).nextInt(150) + 100;

        return a + b;
    }
}
