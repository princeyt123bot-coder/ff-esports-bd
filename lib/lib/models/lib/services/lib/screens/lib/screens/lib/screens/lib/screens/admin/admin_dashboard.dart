import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _titleController = TextEditingController();
  final _feeController = TextEditingController();
  final _prizeController = TextEditingController();
  final _timeController = TextEditingController();
  
  String _selectedType = 'Solo';
  String _selectedCategory = 'Solo';
  final DatabaseService _dbService = DatabaseService();

  void _addTournament() async {
    if (_titleController.text.isEmpty || _feeController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('tournaments').add({
      'title': _titleController.text.trim(),
      'type': _selectedType,
      'category': _selectedCategory,
      'entry_fee': double.parse(_feeController.text),
      'prize_pool': double.parse(_prizeController.text),
      'date_time': _timeController.text.trim(),
      'map_name': 'Bermuda',
      'total_slots': 48,
      'joined_slots': 0,
      'room_id': '',
      'room_pass': '',
      'status': 'Upcoming',
      'thumbnail': '',
      'joined_users': [],
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament Added Successfully!')),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Tournament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _feeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Entry Fee')),
              TextField(controller: _prizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prize Pool')),
              TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'Time (e.g. 8:00 PM)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addTournament, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: const Color(0xFF1E1E2C),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Deposit Requests'),
              Tab(text: 'Manage Tournaments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Deposit Requests Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return const Center(child: Text('No Pending Deposits'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text('৳${data['amount']} via ${data['method']}'),
                        subtitle: Text('TrxID: ${data['trx_id']}\nUser: ${data['user_id']}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            _dbService.approveDeposit(
                              docs[index].id,
                              data['user_id'],
                              (data['amount'] as num).toDouble(),
                            );
                          },
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Tournaments Tab
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create New Tournament'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
