package googledocsclone.example.googledocsclone.models;
import java.util.List;
import java.util.Map;


import org.springframework.data.util.Pair;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Documents {

    @Id
    private String id;
    @Indexed(unique = true)
    private String name;
    private List<List<Character>> content;
    private String ownerId;
    private String sharedWith;
    private Integer version=null;
    private Map<String, Integer> editUserLatestVersion;
    private int bufferStartVersion;
    private List<Pair<String, Integer>> changesBuffer;
    

    
    public Documents(String name, List<List<Character>> content, String ownerId, String sharedWith, int version) {
        this.name = name;
        this.content = content;
        this.ownerId = ownerId;
        this.sharedWith = sharedWith;
        this.version = version;
    }

    public Documents(String name, List<List<Character>> content, String ownerId,int version) {
        this.name = name;
        this.content = content;
        this.ownerId = ownerId;
        this.version = version;
    }

    public Documents(String name, List<List<Character>> content,int version) {
        this.name = name;
        this.content = content;
        this.version = version;
    }

    public Documents(String name,int version) {
        this.name = name;
        this.version = version;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<List<Character>> getContent() {
        return content;
    }

    public void setContent(List<List<Character>> content) {
        this.content = content;
    }

    public String getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }

    public String getSharedWith() {
        return sharedWith;
    }

    public void setSharedWith(String sharedWith) {
        this.sharedWith = sharedWith;
    }

    public int getVersion() {
        return version;
    }

    public void setVersion(int version) {
        this.version = version;
    }

}
