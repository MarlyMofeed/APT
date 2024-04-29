package services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import googledocsclone.example.googledocsclone.models.User;
import googledocsclone.example.googledocsclone.repositories.UserRepository;

@Configuration
@ComponentScan({"googledocsclone.example.googledocsclone", "googledocsclone.configurations"})
@Service
public class AuthService {
   
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder; 
    
    public String authenticateUser(String username, String password) {
        User user = userRepository.findByUsername(username);
        if (user != null && passwordEncoder.matches(password, user.getPassword())) {
            return user.getId();
        }
        return null;
    }
}
