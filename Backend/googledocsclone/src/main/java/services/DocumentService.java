package services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;


import googledocsclone.example.googledocsclone.models.Documents;
import googledocsclone.example.googledocsclone.repositories.DocumentRepository;

@Configuration
@ComponentScan({"googledocsclone.example.googledocsclone", "googledocsclone.configurations"})
@Service
public class DocumentService {

    private Map<String,Documents> documentMap = new HashMap<>();
    DocumentRepository documentRepository;
    public void getDocument(String documentId,String userId) {
       Documents document = documentMap.get(documentId);
       if(document == null){
           //get document from database
           document = documentRepository.findById(documentId).get();
           documentMap.put(documentId,document);
       }
       
    }
}
