import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/app_models.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FFEsportsApp());
}

class FFEsportsApp extends StatelessWidget {
  const FFEsportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FF ESPORTS BD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFFFF5722),
        cardColor: const Color(0xFF1E1E2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          secondary: Color(0xFFFFC107),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String selectedCategory = 'All';

  final List<String> categories = ['All', 'Solo', 'Duo', 'Squad', '1v1', 'Clash Squad'];

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          height: 120,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF8F00)],
            ),
          ),
          child: const Center(
            child: Text(
              '🔥 DAILY FF TOURNAMENTS BD 🔥\nJOIN & WIN BIG PRIZES!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              bool isSelected = selectedCategory == categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(categories[index]),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5722),
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                  },
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TournamentModel>>(
            stream: _dbService.streamTournaments(selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No Tournaments Available'));
              }

              final tournaments = snapshot.data!;
              return ListView.builder(
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final item = tournaments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(item.type, style: const TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Entry: ৳${item.entryFee.toInt()}', style: const TextStyle(color: Colors.redAccent)),
                              Text('Prize: ৳${item.prizePool.toInt()}', style: const TextStyle(color: Colors.green)),
                              Text('Map: ${item.mapName}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.totalSlots > 0 ? item.joinedSlots / item.totalSlots : 0,
                            backgroundColor: Colors.grey[800],
                            color: const Color(0xFFFF5722),
                          ),
                          const SizedBox(height: 4),
                          Text('Slots: ${item.joinedSlots}/${item.totalSlots}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                              backgroundColor: const Color(0xFFFF5722),
                            ),
                            onPressed: () async {
                              String res = await _dbService.joinTournament(
                                item.id,
                                currentUid,
                                item.entryFee,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res)),
                              );
                            },
                            child: const Text('JOIN NOW', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FF ESPORTS BD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2C),
        actions: [
          StreamBuilder<UserModel>(
            stream: _dbService.streamUser(currentUid),
            builder: (context, snapshot) {
              double balance = snapshot.data?.walletBalance ?? 0.0;
              bool isAdmin = snapshot.data?.role == 'admin';

              return Row(
                children: [
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboard()),
                      ),
                    ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text('৳${balance.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF5722),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
