package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import googledocsclone.example.googledocsclone.repositories.DocumentRepository;
import googledocsclone.example.googledocsclone.models.Documents;


@RestController
@RequestMapping("/document")
public class DocumentController {

    @Autowired
    DocumentRepository DocumentRepository;
    @PostMapping("/add")
    public String addDocument(@RequestBody Map<String, String> body) {
        Documents document = new Documents();
        document.setName(body.get("documentName"));
        DocumentRepository.save(document);
        return "Document added successfully";
    }
    @DeleteMapping("/delete")
    public String deleteDocument(@RequestParam String documentName) {
        DocumentRepository.deleteByName(documentName);
        return "Document deleted successfully";
    }


}
