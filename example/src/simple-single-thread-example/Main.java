import model.Help;

public class Main {
    public static void main(String[] args) {
        Help help = new Help();
        long iteration = 0;
        while (true) {
            int slow = help.slowAdd();
            int fast = help.fastAdd();
            String format = String.format("Progress point - slow add result = %d, fast add result = %d", slow, fast);
            System.out.println("Iteration: " + iteration++ + "  -  (" + format + ")");
        }
    }
}
