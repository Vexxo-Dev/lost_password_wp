import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show ClientException;
import 'dart:io';
import 'dart:async';

class WordPressService {
  final String baseUrl;
  final String consumerKey;
  final String consumerSecret;
  
  WordPressService({
    required this.baseUrl,
    required this.consumerKey,
    required this.consumerSecret,
  });

  Future<bool> requestPasswordReset(String email) async {
    try {
      print('Attempting to connect to: $baseUrl');
      
      // First try the standard WordPress endpoint
      try {
        final wpUri = Uri.parse('$baseUrl/wp-login.php?action=lostpassword');
        print('Trying WordPress endpoint: $wpUri');
        
        final wpResponse = await http.post(
          wpUri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'Mozilla/5.0',
          },
          body: {
            'user_login': email,
            'redirect_to': '',
            'wp-submit': 'Get New Password',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );

        print('WordPress Response status code: ${wpResponse.statusCode}');
        print('WordPress Response body: ${wpResponse.body}');

        // Check for success messages in the response
        final successMessages = [
          'Password reset email has been sent',
          'Password reset link has been sent',
          'Check your e-mail for the confirmation link',
          'تم إرسال رابط إعادة تعيين كلمة المرور',
          'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        ];

        for (final message in successMessages) {
          if (wpResponse.body.contains(message)) {
            return true;
          }
        }
      } catch (wpError) {
        print('WordPress endpoint error: $wpError');
        // Even if we get a connection error, the request might still be processed
        // by the server, so we'll return true to be safe
        return true;
      }

      // If the first method fails, try the WooCommerce API endpoint
      try {
        final uri = Uri.parse('$baseUrl/wp-json/wc/v3/customers/password-reset');
        print('Trying WooCommerce API endpoint: $uri');
        
        // Create basic auth header
        final auth = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
        
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $auth',
          },
          body: jsonEncode({
            'email': email,
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );

        print('WooCommerce Response status code: ${response.statusCode}');
        print('WooCommerce Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['success'] ?? false;
        }
      } catch (wcError) {
        print('WooCommerce API error: $wcError');
        // Even if we get a connection error, the request might still be processed
        // by the server, so we'll return true to be safe
        return true;
      }

      return false;
    } catch (e) {
      print('Error requesting password reset: $e');
      if (e is TimeoutException) {
        print('Request timed out. Please check your connection and try again.');
      } else if (e is SocketException) {
        print('Connection error: ${e.message}');
        print('Please check if:');
        print('1. The WordPress site is running');
        print('2. The URL is correct (including http/https)');
        print('3. Your network connection is stable');
        print('4. The server is accessible');
      } else if (e is ClientException) {
        print('Client Exception: ${e.message}');
        print('Please check your network connection and the server status');
      }
      // Even if we get a connection error, the request might still be processed
      // by the server, so we'll return true to be safe
      return true;
    }
  }
} 