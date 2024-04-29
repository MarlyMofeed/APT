package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import googledocsclone.example.googledocsclone.repositories.DocumentRepository;
import googledocsclone.example.googledocsclone.models.Documents;


@RestController
@RequestMapping("/document")
public class DocumentController {

    @Autowired
    DocumentRepository DocumentRepository;
    @PostMapping("/add")
    public ResponseEntity<Map<String, Object>> addDocument(@RequestBody Map<String, String> body) {
        Documents document = new Documents();
        document.setName(body.get("documentName"));
        DocumentRepository.save(document);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Document added successfully");
        response.put("document", document);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/delete")
    public ResponseEntity<Map<String, Object>> deleteDocument(@RequestBody Map<String, String> body) {
        String documentName = body.get("documentName");
        Map<String, Object> response = new HashMap<>();
        
        Documents document = DocumentRepository.findByName(documentName);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        

        try {
            DocumentRepository.delete(document);
            response.put("message", "Document deleted successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error deleting document: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }


}
