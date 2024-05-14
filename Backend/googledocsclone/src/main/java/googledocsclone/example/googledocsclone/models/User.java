package googledocsclone.example.googledocsclone.models;

import java.util.List;
import java.util.ArrayList;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    private String id;
    private String username;
    private String password;
    private String email;
    private List<String> documentIds= new ArrayList<>();
    private List<String> editorDocumentIds=new ArrayList<>();
    private List<String> viewerDocumentIds=new ArrayList<>();
    private String role;

    

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
    public List<String> getDocumentIds() {
        return documentIds;
    }

    public void setDocumentIds(List<String> documentIds) {
        this.documentIds = documentIds;
    }
    public List<String> getEditorDocumentIds() {
        return editorDocumentIds;
    }
    public void setEditorDocumentIds(List<String> editorDocumentIds) {
        this.editorDocumentIds = editorDocumentIds;
    }
    public List<String> getViewerDocumentIds() {
        return viewerDocumentIds;
    }
    public void setViewerDocumentIds(List<String> viewerDocumentIds) {
        this.viewerDocumentIds = viewerDocumentIds;
    }
    public String getRole() {
        return role;
    }
    public void setRole(String role) {
        this.role = role;
    }
}
