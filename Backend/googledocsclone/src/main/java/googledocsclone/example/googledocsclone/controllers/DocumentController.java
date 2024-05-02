package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;

import googledocsclone.example.googledocsclone.repositories.DocumentRepository;
import googledocsclone.example.googledocsclone.repositories.UserRepository;
import googledocsclone.example.googledocsclone.models.Documents;
import googledocsclone.example.googledocsclone.models.User;


@RestController
@RequestMapping("/document")
public class DocumentController {


    private final DocumentRepository documentRepository;
    private final UserRepository userRepository;

    public DocumentController(DocumentRepository documentRepository, UserRepository userRepository) {
        this.documentRepository = documentRepository;
        this.userRepository = userRepository;
    }

    @PostMapping("/add")
    public ResponseEntity<Map<String, Object>> addDocument(@RequestHeader("Id") String userId, @RequestBody Map<String, String> body) {
        Documents document = new Documents();
        document.setName(body.get("documentName"));
        documentRepository.save(document);
        
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = optionalUser.get();
        document.setOwnerId(user.getId());
        documentRepository.save(document);
    
        List<String> documentIds = user.getDocumentIds();
        if (documentIds == null) {
            documentIds = (List<String>) new ArrayList();
        }
        
        documentIds.add(document.getId());
        userRepository.save(user);
    
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Document added successfully");
        response.put("document", document);
    
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/delete")
    public ResponseEntity<Map<String, Object>> deleteDocument(@RequestHeader("Id") String userId, @RequestBody Map<String, String> body) {
        String documentName = body.get("documentName");
        Map<String, Object> response = new HashMap<>();
        
        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        User user = optionalUser.get();
    
        // Find the document by name and user ID
        Documents document = documentRepository.findByNameAndOwnerId(documentName, userId);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    
        // Remove the document's ID from the user's documentIds list
        user.getDocumentIds().remove(document.getId());
    
        // Save the updated user
        userRepository.save(user);
    
        try {
            // Delete the document
            documentRepository.delete(document);
            response.put("message", "Document deleted successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error deleting document: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }


}
