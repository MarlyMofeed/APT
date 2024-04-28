package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;
import googledocsclone.example.googledocsclone.models.User;
import googledocsclone.example.googledocsclone.repositories.UserRepository;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    UserRepository UserRepository;

    @PostMapping("/signup")
    public User signup(@RequestBody User newUser) {
        return UserRepository.save(newUser);
    }

    @GetMapping("/auth/login")
    public String login() {
        return "login";
    }
}