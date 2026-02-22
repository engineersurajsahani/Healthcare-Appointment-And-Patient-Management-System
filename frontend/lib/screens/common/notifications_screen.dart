import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _apiService.getNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
      // Mark all as read conceptually or handle individually
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (_notifications[index]['isRead']) return;
    
    await _apiService.markNotificationRead(id);
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'critical':
        return Colors.red[50]!;
      case 'warning':
        return Colors.orange[50]!;
      case 'info':
      default:
        return Colors.blue[50]!;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'critical':
        return Icons.emergency;
      case 'warning':
        return Icons.warning_amber;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No new notifications'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final String type = note['type'] ?? 'info';
                    final bool isRead = note['isRead'] ?? false;

                    return Card(
                      color: isRead ? Colors.white : _getNotificationColor(type),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isRead ? 1 : 3,
                      child: ListTile(
                        leading: Icon(
                          _getIcon(type),
                          color: _getIconColor(type),
                          size: 32,
                        ),
                        title: Text(
                          note['message'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          // Simple date formatting
                          note['createdAt'].toString().split('T')[0],
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        onTap: () => _markAsRead(note['_id'], index),
                        trailing: !isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
