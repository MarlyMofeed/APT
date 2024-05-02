package googledocsclone.example.googledocsclone.OT;

public class InsertOperation {

    private int row, col;
    private char character;

    public InsertOperation(int row, int col, char character) {
        this.row = row;
        this.col = col;
        this.character = character;
    }

    public int getRow() {
        return row;
    }

    public void setRow(int row) {
        this.row = row;
    }

    public int getCol() {
        return col;
    }

    public void setCol(int col) {
        this.col = col;
    }

    public char getCharacter() {
        return character;
    }

    public void setCharacter(char character) {
        this.character = character;
    }

    @Override
    public String toString() {
        return "InsertOperation{" +
                "row=" + row +
                ", col=" + col +
                ", character=" + character +
                '}';
    }
}
