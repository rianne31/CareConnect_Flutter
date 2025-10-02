import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  ApiService([AuthService? authService]) : _authService = authService ?? AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Donations
  Future<Map<String, dynamic>> recordFiatDonation({
    required double amount,
    required String currency,
    required String paymentMethod,
    required String externalTxId,
    String? patientId,
    bool isAnonymous = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/donations/record-fiat'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'externalTxId': externalTxId,
        'patientId': patientId,
        'isAnonymous': isAnonymous,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to record donation: ${response.body}');
    }
  }
  
  // Chat with AI
  Future<Map<String, dynamic>> chatWithAI({
    required String message,
    String? conversationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'message': message,
        'conversationId': conversationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to chat with AI: ${response.body}');
    }
  }

  // Create donation
  Future<Map<String, dynamic>> createDonation({
    required double amount,
    required String currency,
    required String paymentMethod,
    String? patientId,
    bool isAnonymous = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/donations/create'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'patientId': patientId,
        'isAnonymous': isAnonymous,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create donation: ${response.body}');
    }
  }

  // Place bid on auction
  Future<Map<String, dynamic>> placeBid({
    required String auctionId,
    required double bidAmount,
    required String bidderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auctions/bid'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'auctionId': auctionId,
        'bidAmount': bidAmount,
        'bidderId': bidderId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to place bid: ${response.body}');
    }
  }
  
  Future<List<dynamic>> getDonationHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/donations/history'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['donations'];
    } else {
      throw Exception('Failed to fetch donation history');
    }
  }

  // Payments
  Future<Map<String, dynamic>> createPayMayaPayment({
    required double amount,
    required String description,
    String? patientId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/paymaya/create'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        'description': description,
        'patientId': patientId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  // AI Chat
  Future<String> sendChatMessage(String message, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'message': message,
        'conversationHistory': history,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to send chat message');
    }
  }

  // Donation recommendations
  Future<List<dynamic>> getDonationRecommendations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/donation-recommendations'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['recommendations'];
    } else {
      throw Exception('Failed to fetch recommendations');
    }
  }
}
