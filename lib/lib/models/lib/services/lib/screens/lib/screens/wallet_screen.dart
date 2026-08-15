import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _trxController = TextEditingController();
  String _selectedMethod = 'bKash';
  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _submitDeposit() async {
    if (_amountController.text.isEmpty || _trxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    await _dbService.requestDeposit(
      uid,
      amount,
      _trxController.text.trim(),
      _selectedMethod,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposit Request Sent! Waiting for Admin Approval.')),
      );
      _amountController.clear();
      _trxController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money / Wallet'),
        backgroundColor: const Color(0xFF1E1E2C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send Money Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('bKash (Personal): 01700000000'),
                  Text('Nagad (Personal): 01700000000'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              items: ['bKash', 'Nagad'].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val!),
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (BDT)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trxController,
              decoration: const InputDecoration(labelText: 'Transaction ID (TrxID)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green,
              ),
              onPressed: _submitDeposit,
              child: const Text('SUBMIT DEPOSIT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
