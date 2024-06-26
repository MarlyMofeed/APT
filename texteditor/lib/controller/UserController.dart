import 'dart:convert';
import 'package:http/http.dart' as http;

class UserController {
  static const String baseUrl = 'http://localhost:8080/auth';

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    print("hamdella 3al salama");
    print(response.body);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      return {"message": "Invalid credentials"};
    } else {
      throw Exception('Failed to login');
    }
  }

  static Future<Map<String, dynamic>> signup(
      String username, String password, String email) async {
    print("hamdella 3al salama");
    print(username);
    print(password);
    print(email);
    print("$baseUrl/signup");
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      final responseBody = json.decode(response.body);
      if (responseBody["message"] == "Username already exists") {
        return responseBody;
      } else if (responseBody["message"] == "Email already exists") {
        return responseBody;
      } else {
        throw Exception('Failed to signup');
      }
    } else {
      throw Exception('Failed to signup');
    }
  }
}
