import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _initNotifications();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alerts = await ApiService.getAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Dështoi ngarkimi i alerteve. Sigurohuni që serveri është ndezur.';
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initialize(context);
    });
  }

  Future<void> _toggleAlert(AlertModel alert, bool value) async {
    try {
      final updated = await ApiService.toggleAlertActive(alert.id, value);
      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = updated;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dështoi ndryshimi i gjendjes.')),
      );
    }
  }

  Future<void> _deleteAlert(String id) async {
    try {
      final success = await ApiService.deleteAlert(id);
      if (success) {
        setState(() {
          _alerts.removeWhere((a) => a.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerti u fshi me sukses.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dështoi fshirja e alertit.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kap Oferten',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            tooltip: 'Njoftimet',
            onPressed: () {
              Navigator.pushNamed(context, '/notifications').then((_) => _fetchAlerts());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Cilësimet',
            onPressed: () {
              Navigator.pushNamed(context, '/settings').then((_) => _fetchAlerts());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlerts,
        color: secondaryColor,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: secondaryColor),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white60, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAlerts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            child: const Text('Riprovo'),
                          )
                        ],
                      ),
                    ),
                  )
                : _alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 72,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nuk keni asnjë alert të krijuar.',
                              style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kliko butonin + poshtë për të shtuar filtra.',
                              style: TextStyle(color: Colors.white30, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Dismissible(
                            key: Key(alert.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text('Fshi Alertin', style: TextStyle(color: Colors.white)),
                                  content: Text('A jeni të sigurt për fshirjen e alertit "${alert.title}"?', style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Anulo', style: TextStyle(color: Colors.white60)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Fshi', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              _deleteAlert(alert.id);
                            },
                            child: Card(
                              color: const Color(0xFF1E293B),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            alert.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: alert.isActive,
                                          activeColor: secondaryColor,
                                          activeTrackColor: secondaryColor.withOpacity(0.3),
                                          inactiveThumbColor: Colors.white60,
                                          inactiveTrackColor: Colors.white10,
                                          onChanged: (val) => _toggleAlert(alert, val),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (alert.keyword != null && alert.keyword!.isNotEmpty)
                                          _buildTag(Icons.search, 'Fjala: ${alert.keyword}', secondaryColor),
                                        if (alert.minPrice != null || alert.maxPrice != null)
                                          _buildTag(
                                            Icons.monetization_on_outlined,
                                            'Çmimi: ${_formatPriceRange(alert.minPrice, alert.maxPrice)}',
                                            secondaryColor,
                                          ),
                                        if (alert.city != null && alert.city!.isNotEmpty)
                                          _buildTag(Icons.location_on_outlined, alert.city!, secondaryColor),
                                        if (alert.category != null && alert.category!.isNotEmpty)
                                          _buildTag(Icons.category_outlined, alert.category!, secondaryColor),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.pushNamed(context, '/create-alert').then((_) => _fetchAlerts());
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _formatPriceRange(double? min, double? max) {
    if (min != null && max != null) return '${min.toInt()} - ${max.toInt()} EUR';
    if (min != null) return '>= ${min.toInt()} EUR';
    if (max != null) return '<= ${max.toInt()} EUR';
    return 'Çdo çmim';
  }
}
