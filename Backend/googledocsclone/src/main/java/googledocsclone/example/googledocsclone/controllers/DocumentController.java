package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
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
    WebSocketController webSocketController;
    List<Pair<String, Integer>> changesBuffer = new ArrayList<>();

    List<Map<String, Integer>> editUserLatestVersion = new ArrayList<>();

    public DocumentController(DocumentRepository documentRepository, UserRepository userRepository,
            WebSocketController webSocketController) {
        this.documentRepository = documentRepository;
        this.userRepository = userRepository;
        this.webSocketController = webSocketController;
    }

    @PostMapping("/add")
    public ResponseEntity<Map<String, Object>> addDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, String> body) {
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
    public ResponseEntity<Map<String, Object>> deleteDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, String> body) {
        String documentName = body.get("documentName");

        Map<String, Object> response = new HashMap<>();

        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        User user = optionalUser.get();
        String documentId = documentRepository.findByName(documentName).getId();

        // Find the document by name and user ID
        Documents document = documentRepository.findByIdAndOwnerId(documentId, userId);
        if (document == null) {
            response.put("message", "Document not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        // Remove the document's ID from the user's documentIds list
        user.getDocumentIds().remove(documentId);

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
    public ResponseEntity<Map<String, Object>> updateDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, String> body) {
        String documentName = body.get("documentName");
        Map<String, Object> response = new HashMap<>();

        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        User user = optionalUser.get();

        Documents document = documentRepository.findByName(documentName);
        if (document == null || !document.getOwnerId().equals(userId)) {
            response.put("message", "Document not found or you are not the owner");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            String newName = body.get("newDocumentName");
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
    public ResponseEntity<Map<String, Object>> getDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, String> body) {
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

            if (currentVersion == null || currentVersion < document.getVersion()) {
                currentVersion = document.getVersion();
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("message", "Error retrieving document: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PutMapping("/save")
    public ResponseEntity<Map<String, Object>> saveDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, Object> body) {
        // String documentId = body.get("id").toString();
        // Map<String, Object> response = new HashMap<>();

        // // Find the user
        // Optional<User> optionalUser = userRepository.findById(userId);
        // if (optionalUser.isEmpty()) {
        // response.put("message", "User not found");
        // return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        // }
        // User user = optionalUser.get();

        // // Find the document by ID and user ID
        // Documents document = documentRepository.findByIdAndOwnerId(documentId,
        // userId);
        // if (document == null) {
        // response.put("message", "Document not found");
        // return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        // }

        // try {
        // // Save the document
        // documentRepository.save(document);

        // response.put("message", "Document saved successfully");
        // response.put("document", document);

        // return ResponseEntity.ok(response);
        // } catch (Exception e) {
        // response.put("message", "Error saving document: " + e.getMessage());
        // return
        // ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
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
            // List<List<Character>> newContent = (List<List<Character>>)
            // body.get("documentContent");
            String documentContentString = (String) body.get("documentContent");
            System.out.println("Document content string: " + documentContentString);
            // print type of documentContentString
            System.out.println("Type of documentContentString: " + documentContentString.getClass().getName());
            List<List<Character>> newContent = new ArrayList<>();
            System.out.println("Type of new Content: " + newContent.getClass().getName());
            for (String word : documentContentString.split(" ")) {
                List<Character> wordChars = new ArrayList<>();
                for (char c : word.toCharArray()) {
                    wordChars.add(c);
                }
                newContent.add(wordChars);
                System.out.println("Word: " + word);
                System.out.println("newContent: " + newContent);
                // print type of newContent
                System.out.println("Type of newContent: " + newContent.getClass().getName());
            }

            System.out.println("newContenttttt: " + newContent);
            System.out.println("Type of newContenttttt: " + newContent.getClass().getName());

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

    @GetMapping("/user/owns")
    public ResponseEntity<Map<String, Object>> getUserDocuments(@RequestHeader("userId") String userId) {
        Map<String, Object> response = new HashMap<>();
        System.out.println("hgebbb documents: ");
        System.out.println("userId: " + userId);

        // Find the user
        Optional<User> optionalUser = userRepository.findById(userId);
        if (optionalUser.isEmpty()) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        User user = optionalUser.get();

        // Get the user's document IDs
        List<String> documentIds = user.getDocumentIds();
        if (documentIds == null || documentIds.isEmpty()) {
            response.put("message", "No documents found for this user");
            return ResponseEntity.ok(response);
        }

        // Retrieve the documents from the repository
        List<Documents> documents = documentRepository.findAllById(documentIds);

        // Prepare the response
        List<Map<String, String>> documentData = new ArrayList<>();
        for (Documents document : documents) {
            Map<String, String> data = new HashMap<>();
            data.put("id", document.getId());
            data.put("name", document.getName());
            documentData.add(data);
        }

        response.put("message", "Documents retrieved successfully");
        response.put("documents", documentData);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/share")
    public ResponseEntity<Map<String, Object>> shareDocument(@RequestHeader("userId") String userId,
            @RequestBody Map<String, String> body) {
        String documentName = body.get("documentName");
        String username = body.get("username");
        String role = body.get("role");
        Map<String, Object> response = new HashMap<>();

        User userToShareWith = userRepository.findByUsername(username);
        if (userToShareWith == null) {
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        Documents document = documentRepository.findByNameAndOwnerId(documentName, userId);
        if (document == null) {
            response.put("message", "Document not found or not owned by the current user");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        if (role.equals("editor")) {
            userToShareWith.getEditorDocumentIds().add(document.getId());
        } else if (role.equals("viewer")) {
            userToShareWith.getViewerDocumentIds().add(document.getId());
        } else {
            response.put("message", "Invalid role");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }

        userRepository.save(userToShareWith);

        response.put("message", "Document shared successfully");
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

}
