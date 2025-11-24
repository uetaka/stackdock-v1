import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:read_it_later/services/api_service.dart';
import 'package:read_it_later/models/article.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('fetchArticles handles 302 redirect correctly', () async {
      final client = MockClient((request) async {
        if (request.url.toString().contains('exec?format=json')) {
          // Initial request returns 302
          return http.Response('', 302, headers: {
            'location': 'https://script.googleusercontent.com/macros/echo?user_content_key=xyz',
          });
        }
        if (request.url.toString().contains('echo?user_content_key=xyz')) {
          // Redirected request checks for Authorization header
          // Note: In this test environment, AuthService().getAccessToken() returns null, so no Auth header is sent.
          // We simulate success anyway to verify the redirect logic follows the URL.
          
          // Returns JSON
          return http.Response(json.encode([
            {
              'id': '1',
              'title': 'Test Article',
              'url': 'https://example.com',
              'addedDate': DateTime.now().toIso8601String(),
              'isRead': false
            }
          ]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: client);
      
      final articles = await apiService.fetchArticles();
      expect(articles.length, 1);
      expect(articles.first.title, 'Test Article');
    });

    test('fetchArticles throws exception on HTML response (404)', () async {
      final client = MockClient((request) async {
        return http.Response('<!DOCTYPE html><html>...Page not found...</html>', 200);
      });

      final apiService = ApiService(client: client);

      expect(
        () async => await apiService.fetchArticles(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to parse response'))),
      );
    });
    
    test('fetchArticles throws exception on Login Redirect', () async {
      final client = MockClient((request) async {
         return http.Response('', 302, headers: {
            'location': 'https://accounts.google.com/ServiceLogin?...',
          });
      });

      final apiService = ApiService(client: client);

      expect(
        () async => await apiService.fetchArticles(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Authentication failed'))),
      );
    });
  });
}
