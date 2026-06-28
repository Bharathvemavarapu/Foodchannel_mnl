import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/notification.dart';
import '../../../models/user.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<NotificationModel> _notifications = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String _notificationType = 'All Users'; // 'All Users', 'Selected Users', 'Promotional'
  List<String> _selectedUserIds = [];
  DateTime? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationData() async {
    setState(() => _isLoading = true);
    try {
      await _prepopulateMockNotifications();
      final results = await Future.wait([
        DatabaseService.getNotifications(),
        DatabaseService.getUsers(),
      ]);

      setState(() {
        _notifications = results[0] as List<NotificationModel>;
        _users = results[1] as List<UserModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load notification history: $e');
    }
  }

  Future<void> _prepopulateMockNotifications() async {
    final list = await DatabaseService.getNotifications();
    if (list.isNotEmpty) return;

    final mockNotif1 = NotificationModel(
      id: 'notif_01',
      title: 'Weekend Cooking Bonanza!',
      body: 'Get flat 20% discount on all premium cookware and utensils this Saturday. Shop now!',
      type: 'Promotional',
      targetUserIds: [],
      createdDate: DateTime.now().subtract(const Duration(days: 3)),
      isSent: true,
    );

    final mockNotif2 = NotificationModel(
      id: 'notif_02',
      title: 'Scheduled Maintenance Alert',
      body: 'FoodChannel MNL panel services will undergo a brief security patch update tonight at 11 PM.',
      type: 'All Users',
      targetUserIds: [],
      scheduledTime: DateTime.now().add(const Duration(hours: 12)),
      createdDate: DateTime.now().subtract(const Duration(hours: 4)),
      isSent: false,
    );

    await DatabaseService.addNotification(mockNotif1);
    await DatabaseService.addNotification(mockNotif2);
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _pickScheduleTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_notificationType == 'Selected Users' && _selectedUserIds.isEmpty) {
      _showErrorSnackBar('Please select at least one target user.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      final newNotif = NotificationModel(
        id: notifId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _notificationType,
        targetUserIds: _notificationType == 'Selected Users' ? _selectedUserIds : [],
        scheduledTime: _scheduledTime,
        createdDate: DateTime.now(),
        isSent: _scheduledTime == null,
      );

      await DatabaseService.addNotification(newNotif);
      _showSuccessSnackBar(_scheduledTime == null ? 'Notification broadcasted successfully!' : 'Notification scheduled.');
      
      // Reset form
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _notificationType = 'All Users';
        _selectedUserIds = [];
        _scheduledTime = null;
      });
      _loadNotificationData();
    } catch (e) {
      _showErrorSnackBar('Failed to send notification: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))));
    }

    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Composer
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Compose Notification Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Notification Title'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Provide a title' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _bodyController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Notification Body'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Provide a body' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        DropdownButtonFormField<String>(
                          value: _notificationType,
                          dropdownColor: const Color(0xFF150A2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Campaign Target Criteria'),
                          items: const [
                            DropdownMenuItem(value: 'All Users', child: Text('All Registered Users')),
                            DropdownMenuItem(value: 'Selected Users', child: Text('Target Selected Users')),
                            DropdownMenuItem(value: 'Promotional', child: Text('General Marketing Broadcast')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _notificationType = val;
                              });
                            }
                          },
                        ),
                        
                        // Render user list checkboxes if Selected Users is checked
                        if (_notificationType == 'Selected Users') ...[
                          const SizedBox(height: 16),
                          const Text('Select Target Users:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isChecked = _selectedUserIds.contains(user.uid);
                                return CheckboxListTile(
                                  title: Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  subtitle: Text(user.email, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                                  value: isChecked,
                                  activeColor: const Color(0xFFFF8A00),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedUserIds.add(user.uid);
                                      } else {
                                        _selectedUserIds.remove(user.uid);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Scheduling
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickScheduleTime,
                              icon: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: const Text('SCHEDULE SENDING'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF8A00),
                                side: const BorderSide(color: Color(0xFFFF8A00)),
                              ),
                            ),
                            if (_scheduledTime != null) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Sending at: ${DateFormat('yMMMd').add_jm().format(_scheduledTime!)}',
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 16),
                                      onPressed: () => setState(() => _scheduledTime = null),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        ElevatedButton(
                          onPressed: _isSaving ? null : _sendNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                              : Text(
                                  _scheduledTime == null ? 'BROADCAST NOW' : 'SCHEDULE CAMPAIGN',
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Log History
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Broadcasting History Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 20),
                      
                      _notifications.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('No historical notifications.', style: TextStyle(color: Colors.white24))))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFFF8A00).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                            child: Text(notif.type, style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                          Text(DateFormat('yMMMd').format(notif.createdDate), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 6),
                                      Text(notif.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            notif.isSent ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                            size: 14,
                                            color: notif.isSent ? Colors.greenAccent : Colors.orangeAccent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            notif.isSent 
                                                ? 'Broadcast Completed' 
                                                : 'Scheduled for ${DateFormat('yMMMd').add_jm().format(notif.scheduledTime!)}',
                                            style: TextStyle(
                                              color: notif.isSent ? Colors.greenAccent : Colors.orangeAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
