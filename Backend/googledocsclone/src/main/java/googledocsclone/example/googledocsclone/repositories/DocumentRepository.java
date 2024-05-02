package googledocsclone.example.googledocsclone.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;

import googledocsclone.example.googledocsclone.models.Documents;

public interface DocumentRepository extends MongoRepository<Documents, String> {
    Documents findByName(String name);

    Documents findByNameAndOwnerId(String documentName, String userId);

    Documents findByIdAndOwnerId(String documentId, String userId);
}