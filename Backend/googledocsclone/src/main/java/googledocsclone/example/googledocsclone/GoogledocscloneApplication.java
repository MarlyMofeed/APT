package googledocsclone.example.googledocsclone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan({"googledocsclone.example.googledocsclone", "services"})
public class GoogledocscloneApplication {

	public static void main(String[] args) {
		SpringApplication.run(GoogledocscloneApplication.class, args);
	}

}
