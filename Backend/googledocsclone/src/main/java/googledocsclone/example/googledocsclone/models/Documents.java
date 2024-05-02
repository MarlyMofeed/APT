package googledocsclone.example.googledocsclone.models;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Document
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Documents {

    @Id
    private String id;
    @Indexed(unique = true)
    private String name;
    private String[][]content;
    private String ownerId;
    private String sharedWith;

    
}
