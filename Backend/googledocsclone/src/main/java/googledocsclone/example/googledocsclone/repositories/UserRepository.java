package googledocsclone.example.googledocsclone.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

import googledocsclone.example.googledocsclone.models.User;

public interface UserRepository extends MongoRepository<User, String> {

    User findByUsername(String username);
    Optional<User> findById(String id);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);


}
