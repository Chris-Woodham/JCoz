import model.Help;

public class Main {
    public static void main(String[] args) {
        Help help = new Help();
        while (true) {
            int slow = help.slowAdd();
            int fast = help.fastAdd();
            String format = String.format("Progress point - slow=%d, fast=%d", slow, fast);
        }
    }
}
