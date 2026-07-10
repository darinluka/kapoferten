import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gabim në ngarkimin e historikut të njoftimeve.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Nuk mund të hapej lidhja.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuk mund të hapej faqja e njoftimit.')),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel item) async {
    _launchUrl(item.url);

    if (!item.isRead) {
      try {
        await ApiService.markAsRead(item.id);
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = NotificationModel(
              id: item.id,
              userId: item.userId,
              alertId: item.alertId,
              title: item.title,
              price: item.price,
              city: item.city,
              category: item.category,
              url: item.url,
              imageUrl: item.imageUrl,
              isRead: true,
              createdAt: item.createdAt,
            );
          }
        });
      } catch (e) {
        // Ignore silent api error
      }
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    try {
      await ApiService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            alertId: n.alertId,
            title: n.title,
            price: n.price,
            city: n.city,
            category: n.category,
            url: n.url,
            imageUrl: n.imageUrl,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Të gjitha njoftimet u shënuan si të lexuara.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dështoi përditësimi i njoftimeve.')),
      );
    }
  }

  Widget _buildPlatformBadge(String url) {
    final isFb = url.contains('facebook.com');
    final isMj = url.contains('merrjep');
    
    String label = 'Platformë';
    Color color = Colors.blueGrey;
    if (isFb) {
      label = 'Facebook';
      color = const Color(0xFF1877F2);
    } else if (isMj) {
      label = 'MerrJep';
      color = const Color(0xFFF97316);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Historiku i Njoftimeve',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: Icon(Icons.done_all, color: secondaryColor),
              tooltip: 'Shëno të gjitha si të lexuara',
              onPressed: _handleMarkAllAsRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: secondaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: secondaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.white60, fontSize: 16), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchNotifications,
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                            child: const Text('Riprovo'),
                          )
                        ],
                      ),
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 72, color: Colors.white.withOpacity(0.15)),
                            const SizedBox(height: 16),
                            const Text('Nuk keni marrë asnjë njoftim ende.', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            const Text('Njoftimet do të shfaqen sapo të ketë përputhje.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final formattedTime = DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt.toLocal());

                          return Card(
                            color: item.isRead ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: item.isRead 
                                    ? Colors.white.withOpacity(0.03)
                                    : secondaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _handleNotificationTap(item),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                                          ? Image.network(
                                              item.imageUrl!,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                            )
                                          : _buildPlaceholderImage(),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: item.isRead ? Colors.white70 : Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (!item.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: secondaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              if (item.price != null)
                                                Text(
                                                  '${item.price!.toInt()} EUR',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: secondaryColor,
                                                  ),
                                                ),
                                              if (item.price != null && item.city != null)
                                                const Text('  •  ', style: TextStyle(color: Colors.white24)),
                                              if (item.city != null)
                                                Text(
                                                  item.city!,
                                                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                                                ),
                                              const Spacer(),
                                              _buildPlatformBadge(item.url),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.white.withOpacity(0.04),
      child: const Icon(Icons.image, color: Colors.white24),
    );
  }
}
