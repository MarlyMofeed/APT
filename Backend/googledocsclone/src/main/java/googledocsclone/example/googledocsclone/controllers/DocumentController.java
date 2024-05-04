package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;

import org.springframework.data.util.Pair;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.ArrayList;
import java.net.Socket;
import java.net.ServerSocket;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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
    private Integer currentVersion;
    List<Pair<String, Integer>> changesBuffer = new ArrayList<>();
    
    List<Map<String, Integer>> editUserLatestVersion = new ArrayList<>();
    

    public DocumentController(DocumentRepository documentRepository, UserRepository userRepository) {
        this.documentRepository = documentRepository;
        this.userRepository = userRepository;
    }

    @PostMapping("/add")
    public ResponseEntity<Map<String, Object>> addDocument(@RequestHeader("userId") String userId, @RequestBody Map<String, String> body) {
        Documents document = new Documents();
        document.setName(body.get("documentName"));
        documentRepository.save(document);

        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "User not found"));
        }
        User user = optionalUser.get();
        document.setOwnerId(user.getId());
        document.setVersion(0);
        documentRepository.save(document);

        List<String> documentIds = user.getDocumentIds();
        if (documentIds == null) {
            documentIds = new ArrayList<>();
        }

        documentIds.add(document.getId());
        userRepository.save(user);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Document added successfully");
        response.put("document", document);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/delete")
    public ResponseEntity<Map<String, Object>> deleteDocument(@RequestHeader("userId") String userId, @RequestBody Map<String, String> body) {
        String documentId = body.get("id");
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
        Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
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

    @PutMapping("/update")
    public ResponseEntity<Map<String, Object>> updateDocument(@RequestHeader("userId") String userId, @RequestBody Map<String, String> body) {
        String documentId = body.get("id");
        Map<String, Object> response = new HashMap<>();

        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        User user = optionalUser.get();

        // Find the document by ID and user ID
        Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            // Update the document's name
            String newName = body.get("documentName");
            document.setName(newName);
            documentRepository.save(document);

            response.put("message", "Document updated successfully");
            response.put("document", document);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error updating document: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @GetMapping("/get")
    public ResponseEntity<Map<String, Object>> getDocument(@RequestHeader("userId") String userId, @RequestBody Map<String, String> body) {
        String documentId = body.get("id");
        Map<String, Object> response = new HashMap<>();

        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        User user = optionalUser.get();

        // Find the document by ID and user ID
        Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            // Return the document details
            response.put("message", "Document retrieved successfully");
            response.put("document", document);
          
            if(currentVersion==null || currentVersion < document.getVersion()){
                currentVersion = document.getVersion();
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error retrieving document: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveDocument(@RequestHeader("userId") String userId, @RequestBody Map<String, Object> body) {
        // String documentId = body.get("id").toString();
        // Map<String, Object> response = new HashMap<>();

        // // Find the user
        // Optional<User> optionalUser = userRepository.findById(userId);
        // if (optionalUser.isEmpty()) {
        //     response.put("message", "User not found");
        //     return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        // }
        // User user = optionalUser.get();

        // // Find the document by ID and user ID
        // Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
        // if (document == null) {
        //     response.put("message", "Document not found");
        //     return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        // }

        // try {
        //     // Save the document
        //     documentRepository.save(document);

        //     response.put("message", "Document saved successfully");
        //     response.put("document", document);

        //     return ResponseEntity.ok(response);
        // } catch (Exception e) {
        //     response.put("message", "Error saving document: " + e.getMessage());
        //     return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        // }

        String documentId = body.get("id").toString();
        Map<String, Object> response = new HashMap<>();

        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        User user = optionalUser.get();

        // Find the document by ID and user ID
        Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            // Update the document's content
            List<List<Character>> newContent = (List<List<Character>>) body.get("documentContent");
            document.setContent(newContent);
            documentRepository.save(document);

            response.put("message", "Document content updated successfully");
            response.put("document", document);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error updating document content: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    





}
