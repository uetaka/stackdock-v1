
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

import 'package:read_it_later/services/auth_service.dart';

class ApiService {
  static const String _urlKey = 'gas_web_app_url';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> getGasUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  Future<Map<String, String>> get _headers async {
    final token = await AuthService().getAccessToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> setGasUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }

  Future<http.Response> _authenticatedRequest(String method, String url, {Map<String, dynamic>? body}) async {
    final headers = await _headers;
    final uri = Uri.parse(url);
    
    final request = http.Request(method, uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = json.encode(body);
      request.headers['Content-Type'] = 'application/json'; // Ensure content type for JSON body
    }
    request.followRedirects = false; // Disable auto-redirects

    print('Request URL: $url');
    // print('Request Headers: ...'); // Removed debug log

    // Use _client.send if possible, but http.Client doesn't have send() for Request object directly in the same way as generic send.
    // Actually http.Client.send(BaseRequest) exists.
    final streamedResponse = await _client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    // Handle 302 Redirect manually to keep Authorization header
    if (response.statusCode == 302) {
      final location = response.headers['location'];
      if (location != null) {
        print('Redirecting to: $location');
        if (location.contains('accounts.google.com')) {
          throw Exception('Authentication failed: Redirected to login page. Please check OAuth scopes and GAS deployment.');
        }
        final newUri = Uri.parse(location);
        // GAS redirects (302) should be followed with GET to retrieve the output.
        // The original POST action has already been executed by the time we get the redirect.
        final newRequest = http.Request('GET', newUri);
        
        // Do NOT re-attach Authorization header for script.googleusercontent.com
        // The user_content_key in the URL is sufficient and sending Auth header might cause issues.
        if (!location.contains('script.googleusercontent.com')) {
           newRequest.headers.addAll(headers);
        }
        
        // Body is not needed for the redirect GET
        // if (body != null) { ... }
        final newStreamedResponse = await _client.send(newRequest);
        response = await http.Response.fromStream(newStreamedResponse);
      }
    }
    return response;
  }

  Future<List<Article>> fetchArticles() async {
    final baseUrl = await getGasUrl();
    if (baseUrl == 'demo') {
      return [
        Article(
          id: '1',
          url: 'https://flutter.dev',
          title: 'Flutter - Build apps for any screen',
          addedDate: DateTime.now().subtract(const Duration(days: 1)),
          isRead: false,
        ),
        Article(
          id: '2',
          url: 'https://google.com',
          title: 'Google',
          addedDate: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: false,
        ),
      ];
    }
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('GAS URL not set');
    }

    // Append ?format=json to get JSON response
    final url = '$baseUrl?format=json';
    print('Fetching articles from: $url');
    final response = await _authenticatedRequest('GET', url);

    print('Fetch Articles Status: ${response.statusCode}');
    print('Fetch Articles Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Article.fromJson(json)).toList();
      } catch (e) {
        final errorBody = response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body;
        throw Exception('Failed to parse response: $errorBody');
      }
    } else {
      throw Exception('Failed to load articles: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> addArticle(String url, {String? title}) async {
    final baseUrl = await getGasUrl();
    if (baseUrl == 'demo') {
      // Mock success
      return;
    }
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('GAS URL not set');
    }

    final response = await _authenticatedRequest('POST', baseUrl, body: {
      'action': 'add',
      'url': url,
      'title': title,
    });

    print('Add Article Response Status: ${response.statusCode}');
    print('Add Article Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return;
        }
      } catch (e) {
        // If body is not JSON, it will fail here
      }
    }
    final errorBody = response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body;
    throw Exception('Failed to add article: $errorBody');
  }

  Future<void> markAsRead(String id) async {
    final baseUrl = await getGasUrl();
    if (baseUrl == 'demo') {
      return;
    }
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('GAS URL not set');
    }

    final response = await _authenticatedRequest('POST', baseUrl, body: {
      'action': 'markRead',
      'id': id,
    });

    if (response.statusCode != 200) {
      final errorBody = response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body;
      throw Exception('Failed to mark as read: $errorBody');
    }
  }
  
  Future<void> deleteArticle(String id) async {
    final baseUrl = await getGasUrl();
    if (baseUrl == 'demo') {
      return;
    }
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('GAS URL not set');
    }

    final response = await _authenticatedRequest('POST', baseUrl, body: {
      'action': 'delete',
      'id': id,
    });

    if (response.statusCode != 200) {
      final errorBody = response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body;
      throw Exception('Failed to delete article: $errorBody');
    }
  }
}
