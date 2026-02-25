---
name: Fake Store API Integration
description: How to integrate with the Fake Store API for products, categories, authentication (JWT), and user profiles in a Flutter app.
---

# Fake Store API Integration

This skill covers integrating the [Fake Store API](https://fakestoreapi.com/) into the Flutter app for product data, authentication, and user profile display.

---

## Base URL

```
https://fakestoreapi.com
```

---

## Endpoints

### Products

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/products` | All products (20 items) |
| `GET` | `/products/{id}` | Single product by ID |
| `GET` | `/products?limit=5` | Limit results |
| `GET` | `/products?sort=desc` | Sort order (`asc` / `desc`) |
| `GET` | `/products/categories` | All category names |
| `GET` | `/products/category/{categoryName}` | Products by category |

**Available Categories:**
- `electronics`
- `jewelery`
- `men's clothing`
- `women's clothing`

### Authentication

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| `POST` | `/auth/login` | `{"username":"mor_2314","password":"83r5^_"}` | `{"token":"eyJhbGci..."}` |

> **Note:** The token is a valid JWT but the API doesn't actually enforce it on other endpoints. Use it to simulate authenticated flows.

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/users` | All users (10 users) |
| `GET` | `/users/{id}` | Single user by ID |

### Test User Credentials

| Username | Password |
|----------|----------|
| `mor_2314` | `83r5^_` |
| `kevinryan` | `kev02937@` |
| `donero` | `ewedon` |
| `derek` | `jklg*_56` |
| `david_r` | `3478*#54` |
| `johnd` | `m38rmF$` |
| `jimmie_k` | `klein*#%*` |
| `kate_h` | `kfejk@*_` |

---

## Data Models

### Product Model

```dart
class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      category: json['category'],
      image: json['image'],
      rating: Rating.fromJson(json['rating']),
    );
  }
}

class Rating {
  final double rate;
  final int count;

  Rating({required this.rate, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: (json['rate'] as num).toDouble(),
      count: json['count'],
    );
  }
}
```

### User Model

```dart
class User {
  final int id;
  final String email;
  final String username;
  final String password;
  final Name name;
  final Address address;
  final String phone;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      password: json['password'],
      name: Name.fromJson(json['name']),
      address: Address.fromJson(json['address']),
      phone: json['phone'],
    );
  }
}

class Name {
  final String firstname;
  final String lastname;

  Name({required this.firstname, required this.lastname});

  factory Name.fromJson(Map<String, dynamic> json) {
    return Name(
      firstname: json['firstname'],
      lastname: json['lastname'],
    );
  }

  String get fullName => '$firstname $lastname';
}

class Address {
  final String city;
  final String street;
  final int number;
  final String zipcode;
  final Geolocation geolocation;

  Address({
    required this.city,
    required this.street,
    required this.number,
    required this.zipcode,
    required this.geolocation,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      city: json['city'],
      street: json['street'],
      number: json['number'],
      zipcode: json['zipcode'],
      geolocation: Geolocation.fromJson(json['geolocation']),
    );
  }
}

class Geolocation {
  final String lat;
  final String long;

  Geolocation({required this.lat, required this.long});

  factory Geolocation.fromJson(Map<String, dynamic> json) {
    return Geolocation(lat: json['lat'], long: json['long']);
  }
}
```

### Auth Response Model

```dart
class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(token: json['token']);
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}
```

---

## API Service Pattern

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'https://fakestoreapi.com';
  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to load products: ${response.statusCode}');
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/products/categories'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/category/$category'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to load category products: ${response.statusCode}');
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Login failed: ${response.statusCode}');
  }

  Future<User> getUser(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$id'));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load user: ${response.statusCode}');
  }
}
```

---

## Mapping Categories to Tabs

The task requires 2–3 tabs. A good mapping from the API categories:

| Tab Label      | API Category Filter          |
|---------------|------------------------------|
| All           | `/products` (no filter)       |
| Electronics   | `/products/category/electronics` |
| Fashion       | `/products/category/men's clothing` + `women's clothing` |

> **Tip:** You can merge "men's clothing" and "women's clothing" into a single "Fashion" tab by fetching both and concatenating.

---

## Important Notes

1. The API is **read-only** in practice — POST/PUT/DELETE endpoints accept requests but don't actually persist data.
2. The API has no rate limiting but can be slow — always show loading states.
3. Product images come as direct URLs — use `Image.network()` with error handling and `CachedNetworkImage` for better UX.
4. The JWT token from `/auth/login` is valid but **not required** for GET endpoints — the API doesn't enforce auth. Still implement the auth flow properly for the hiring task.
