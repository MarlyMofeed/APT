package googledocsclone.example.googledocsclone.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;

import googledocsclone.example.googledocsclone.models.User;

public interface UserRepository extends MongoRepository<User, String> {

    User findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

}
