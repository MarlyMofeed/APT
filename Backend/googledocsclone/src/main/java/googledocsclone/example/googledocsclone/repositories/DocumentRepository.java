package googledocsclone.example.googledocsclone.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import googledocsclone.example.googledocsclone.models.Documents;

public interface DocumentRepository extends MongoRepository<Documents, String> {
    @Query(value = "{'name' : ?0}")
    void deleteByName(String name);
}