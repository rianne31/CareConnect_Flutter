import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class BlockchainService {
  static const String rpcUrl = 'https://rpc-mumbai.maticvigil.com/'; // Polygon Mumbai testnet
  final Web3Client _web3client;

  BlockchainService()
      : _web3client = Web3Client(
          rpcUrl,
          Client(),
        );

  // Contract addresses (to be loaded from .env)
  String get _donationContractAddress =>
      dotenv.env['DONATION_CONTRACT_ADDRESS'] ?? '';
  String get _auctionContractAddress =>
      dotenv.env['AUCTION_CONTRACT_ADDRESS'] ?? '';
  String get _nftContractAddress =>
      dotenv.env['NFT_CONTRACT_ADDRESS'] ?? '';

  // Contract ABIs
  Future<String> get _donationContractABI async =>
      '{"abi": [...]}'; // Load from assets

  Future<String> get _auctionContractABI async =>
      '{"abi": [...]}'; // Load from assets

  Future<String> get _nftContractABI async =>
      '{"abi": [...]}'; // Load from assets

  // Create donation transaction
  Future<String> createDonation({
    required String donor,
    required String patient,
    required BigInt amount,
  }) async {
    try {
      final credentials = await _getCredentials();
      final contract = await _getDonationContract();

      final result = await _web3client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: contract.function('donate'),
          parameters: [donor, patient, amount],
        ),
        chainId: 80001, // Mumbai testnet
      );

      return result;
    } catch (e) {
      print('Error creating donation: $e');
      rethrow;
    }
  }

  // Create auction
  Future<String> createAuction({
    required String seller,
    required BigInt startingPrice,
    required BigInt duration,
  }) async {
    try {
      final credentials = await _getCredentials();
      final contract = await _getAuctionContract();

      final result = await _web3client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: contract.function('createAuction'),
          parameters: [seller, startingPrice, duration],
        ),
        chainId: 80001,
      );

      return result;
    } catch (e) {
      print('Error creating auction: $e');
      rethrow;
    }
  }

  // Place bid
  Future<String> placeBid({
    required int auctionId,
    required BigInt bidAmount,
  }) async {
    try {
      final credentials = await _getCredentials();
      final contract = await _getAuctionContract();

      final result = await _web3client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: contract.function('placeBid'),
          parameters: [BigInt.from(auctionId)],
          value: EtherAmount.fromBigInt(EtherUnit.wei, bidAmount),
        ),
        chainId: 80001,
      );

      return result;
    } catch (e) {
      print('Error placing bid: $e');
      rethrow;
    }
  }

  // Internal helpers
  Future<Credentials> _getCredentials() async {
    final privateKey = dotenv.env['POLYGON_PRIVATE_KEY'];
    if (privateKey == null) {
      throw Exception('No private key found in environment');
    }
    return EthPrivateKey.fromHex(privateKey);
  }

  Future<DeployedContract> _getDonationContract() async {
    return DeployedContract(
      ContractAbi.fromJson(await _donationContractABI, 'DonationContract'),
      EthereumAddress.fromHex(_donationContractAddress),
    );
  }

  Future<DeployedContract> _getAuctionContract() async {
    return DeployedContract(
      ContractAbi.fromJson(await _auctionContractABI, 'AuctionContract'),
      EthereumAddress.fromHex(_auctionContractAddress),
    );
  }

  Future<DeployedContract> _getNFTContract() async {
    return DeployedContract(
      ContractAbi.fromJson(await _nftContractABI, 'AchievementNFT'),
      EthereumAddress.fromHex(_nftContractAddress),
    );
  }
}