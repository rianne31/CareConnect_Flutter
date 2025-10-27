import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl;
  
  ApiService() : baseUrl = 'http://127.0.0.1:5019/${dotenv.env['FIREBASE_PROJECT_ID']}/us-central1/api';

  // Create a donation
  Future<Map<String, dynamic>> createDonation(Map<String, dynamic> donation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/donations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(donation),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create donation: ${response.statusCode}');
    }
  }

  // Place a bid on an auction
  Future<Map<String, dynamic>> placeBid(String auctionId, double amount, String bidderUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auctions/$auctionId/bids'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amount,
        'bidderUserId': bidderUserId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to place bid: ${response.statusCode}');
    }
  }

  // Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Chat with AI
  Future<String> chatWithAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? 'Sorry, I could not understand that.';
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      return 'Sorry, there was an error communicating with the AI service.';
    }
  }

  // Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/$paymentId/status'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get payment status: ${response.statusCode}');
    }
  }
}