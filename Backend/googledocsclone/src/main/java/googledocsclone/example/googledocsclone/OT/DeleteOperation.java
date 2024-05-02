package googledocsclone.example.googledocsclone.OT;

public class DeleteOperation {

    private int row, col;

    public DeleteOperation(int row, int col) {
        this.row = row;
        this.col = col;
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

    @Override
    public String toString() {
        return "DeleteOperation{" +
                "row=" + row +
                ", col=" + col +
                '}';
    }
    
}
