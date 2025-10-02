import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlockchainService {
  late Web3Client _client;
  late String _rpcUrl;
  late String _donationContractAddress;
  late String _auctionContractAddress;

  BlockchainService() {
    _rpcUrl = dotenv.env['POLYGON_RPC_URL'] ?? 'https://polygon-rpc.com';
    _donationContractAddress = dotenv.env['DONATION_CONTRACT_ADDRESS'] ?? '';
    _auctionContractAddress = dotenv.env['AUCTION_CONTRACT_ADDRESS'] ?? '';
    _client = Web3Client(_rpcUrl, Client());
  }

  // Get donation contract stats
  Future<Map<String, dynamic>> getDonationStats() async {
    try {
      // Load contract ABI and call getStats()
      // This is a simplified version - actual implementation needs ABI
      return {
        'totalDonations': 0,
        'totalAmount': 0,
        'contractBalance': 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch donation stats: $e');
    }
  }

  // Verify transaction on blockchain
  Future<bool> verifyTransaction(String txHash) async {
    try {
      final receipt = await _client.getTransactionReceipt(txHash);
      return receipt != null && receipt.status == true;
    } catch (e) {
      throw Exception('Failed to verify transaction: $e');
    }
  }

  // Get transaction details
  Future<Map<String, dynamic>> getTransactionDetails(String txHash) async {
    try {
      final transaction = await _client.getTransactionByHash(txHash);
      final receipt = await _client.getTransactionReceipt(txHash);

      return {
        'hash': txHash,
        'from': transaction?.from.hex,
        'to': transaction?.to?.hex,
        'value': transaction?.value.getInWei,
        'blockNumber': receipt?.blockNumber.blockNum,
        'status': receipt?.status,
        'gasUsed': receipt?.gasUsed,
      };
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  // Get current gas price
  Future<EtherAmount> getGasPrice() async {
    return await _client.getGasPrice();
  }

  // Dispose client
  void dispose() {
    _client.dispose();
  }
}
