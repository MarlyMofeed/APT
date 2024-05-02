package googledocsclone.example.googledocsclone.CRDT;

import java.util.List;
import java.util.ArrayList;

public class TextDocumentCRDT {

    private List<List<Character>> document;

    public TextDocumentCRDT(List<Character> characters) {
        this.document = new ArrayList<>();
        this.document.add(new ArrayList<>());
    }

    public void insertCharacter(Character character, int row, int col) {
        if (row >= document.size()) {
            document.add(new ArrayList<>());
        }
        document.get(row).add(col, character);
    }


    public void deleteCharacter(int row, int col) {
        if (row < 0 || row >= document.size() || col < 0 || col >= document.get(row).size()) {
            return;
        }
        document.get(row).remove(col);
    }
}
