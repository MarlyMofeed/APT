package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;

import googledocsclone.example.googledocsclone.models.User;
import googledocsclone.example.googledocsclone.repositories.UserRepository;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import services.AuthService;



@RestController
@ComponentScan({"googledocsclone.example.googledocsclone", "googledocsclone.configurations"})
@RequestMapping("/auth")
public class AuthController {

    
    private final String jwtSecret;
    private final UserRepository userRepository;
    private final AuthService authService;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public AuthController(
        @Value("${jwt.secret}") String jwtSecret,
        UserRepository userRepository,
        AuthService authService,
        PasswordEncoder passwordEncoder
    ) {
        this.jwtSecret = jwtSecret;
        this.userRepository = userRepository;
        this.authService = authService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/signup")
    public ResponseEntity<Map<String, Object>> signup(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");
        String email = body.get("email");
        String role = "owner"; 
        // Check if username or email already exists
        if (userRepository.existsByUsername(username)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Username already exists"));
        }
        if (userRepository.existsByEmail(email)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Email already exists"));
        }

        // Hash the password before saving
        String encodedPassword = passwordEncoder.encode(password);

        User newUser = new User();
        newUser.setUsername(username);
        newUser.setPassword(encodedPassword);
        newUser.setEmail(email);

        User savedUser = userRepository.save(newUser);

        String jwt = generateJwt(savedUser.getId());

        // Return the JWT token and a success message
        Map<String, Object> response = new HashMap<>();
        response.put("token", jwt);
        response.put("message", "User registered successfully");

        return ResponseEntity.ok(response);
    }
    

    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        String userId = authService.authenticateUser(username, password);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Invalid username or password"));
        }

        String jwt = generateJwt(userId);

        return ResponseEntity.ok(Map.of("token", jwt));
    }

    private String generateJwt(String userId) {
        return Jwts.builder()
                .setSubject(userId)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 3600000)) // 1 hour
                .signWith(SignatureAlgorithm.HS256, jwtSecret)
                .compact();
    }
}
