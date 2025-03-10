import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/farm.dart';
import '../models/product.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({Key? key}) : super(key: key);

  @override
  _BackendTestScreenState createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _testResults = 'Press "Run Tests" button to start testing backend connection';
  
  // Test email and password
  final String _testEmail = 'admin@freshfarmily.com';
  final String _testPassword = 'admin123';
  
  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running tests...\n';
    });
    
    try {
      // Step 1: Test authentication
      _appendResult('🔒 Testing Authentication...');
      final authResult = await _testAuthentication();
      
      if (authResult) {
        // Step 2: Test farms endpoint
        _appendResult('\n🏡 Testing Farms Endpoint...');
        await _testFarmsEndpoint();
        
        // Step 3: Test products endpoint
        _appendResult('\n🛒 Testing Products Endpoint...');
        await _testProductsEndpoint();
      }
      
      _appendResult('\n✅ All tests completed!');
    } catch (e) {
      _appendResult('\n❌ Error during tests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<bool> _testAuthentication() async {
    try {
      _appendResult('📝 Attempting login with test credentials');
      
      final result = await _authService.login(_testEmail, _testPassword);
      
      if (result.containsKey('access_token')) {
        final token = result['access_token'];
        final role = result['role'] ?? result['user_role'] ?? 'Not specified';
        
        _appendResult('✅ Authentication successful!');
        _appendResult('🔑 Token received: ${token.substring(0, 20)}...');
        _appendResult('👤 User role: $role');
        return true;
      } else {
        _appendResult('❌ Authentication failed: No token received');
        return false;
      }
    } catch (e) {
      _appendResult('❌ Authentication error: $e');
      return false;
    }
  }
  
  Future<void> _testFarmsEndpoint() async {
    try {
      _appendResult('🔍 Fetching farms from backend...');
      
      final farms = await _apiService.getFarms();
      
      _appendResult('✅ Successfully connected to farms endpoint!');
      _appendResult('📊 Retrieved ${farms.items.length} farms');
      
      if (farms.items.isNotEmpty) {
        final firstFarm = farms.items.first;
        _appendResult('🏡 First farm: ${firstFarm.name}');
        _appendResult('📍 Location: ${firstFarm.location}');
      } else {
        _appendResult('ℹ️ No farms found in the response');
      }
    } catch (e) {
      _appendResult('❌ Farms endpoint error: $e');
    }
  }
  
  Future<void> _testProductsEndpoint() async {
    try {
      _appendResult('🔍 Fetching products from backend...');
      
      final products = await _apiService.getProducts();
      
      _appendResult('✅ Successfully connected to products endpoint!');
      _appendResult('📊 Retrieved ${products.items.length} products');
      
      if (products.items.isNotEmpty) {
        final firstProduct = products.items.first;
        _appendResult('🥕 First product: ${firstProduct.name}');
        _appendResult('💰 Price: \$${firstProduct.price} per ${firstProduct.unit}');
      } else {
        _appendResult('ℹ️ No products found in the response');
      }
    } catch (e) {
      _appendResult('❌ Products endpoint error: $e');
    }
  }
  
  void _appendResult(String text) {
    setState(() {
      _testResults += '$text\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Integration Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Run Tests'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Results:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
