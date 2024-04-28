package googledocsclone.example.googledocsclone.controllers;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
public class DocumentController {
    @PostMapping("/document")
    public String postMethodName(@RequestBody String entity) {

        return entity;
    }

}
