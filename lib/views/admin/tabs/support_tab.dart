import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/support_ticket.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  List<SupportTicketModel> _tickets = [];
  List<SupportTicketModel> _filteredTickets = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Open', 'In Progress', 'Waiting for Customer', 'Resolved', 'Closed'
  String _typeFilter = 'All'; // 'All', 'Contact Request', 'Complaint', 'Return Request', 'Refund Request'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      await _prepopulateMockTickets();
      final list = await DatabaseService.getSupportTickets();
      setState(() {
        _tickets = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load support tickets: $e');
    }
  }

  Future<void> _prepopulateMockTickets() async {
    final list = await DatabaseService.getSupportTickets();
    if (list.isNotEmpty) return;

    final mockTicket1 = SupportTicketModel(
      id: 'TCK-84392',
      customerId: 'cust_01',
      customerName: 'Bharath Vemavarapu',
      customerEmail: 'bharath@example.com',
      customerPhone: '+91 98765 43210',
      type: 'Refund Request',
      subject: 'Double payment charged during checkout',
      message: 'I placed an order for Cast Iron Skillet but the payment was charged twice from my account.',
      status: 'Open',
      replies: [],
      createdDate: DateTime.now().subtract(const Duration(hours: 5)),
      updatedDate: DateTime.now().subtract(const Duration(hours: 5)),
    );

    final mockTicket2 = SupportTicketModel(
      id: 'TCK-29481',
      customerId: 'cust_03',
      customerName: 'Karthik Raja',
      customerEmail: 'karthik@example.com',
      customerPhone: '+91 76543 21098',
      type: 'Return Request',
      subject: 'Incorrect cookware size delivered',
      message: 'I ordered the 28cm frying pan but received the 24cm model instead. Requesting a return.',
      status: 'In Progress',
      replies: [
        SupportReplyModel(sender: 'Customer', message: 'Hello, please review this issue quickly.', timestamp: DateTime.now().subtract(const Duration(days: 1))),
        SupportReplyModel(sender: 'Admin', message: 'We have initiated the review with our courier service.', timestamp: DateTime.now().subtract(const Duration(hours: 18))),
      ],
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
      updatedDate: DateTime.now().subtract(const Duration(hours: 18)),
    );

    await DatabaseService.createSupportTicket(mockTicket1);
    await DatabaseService.createSupportTicket(mockTicket2);
  }

  void _applyFilters() {
    setState(() {
      _filteredTickets = _tickets.where((ticket) {
        final matchesQuery = ticket.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            ticket.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            ticket.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'All' || ticket.status == _statusFilter;
        final matchesType = _typeFilter == 'All' || ticket.type == _typeFilter;
        return matchesQuery && matchesStatus && matchesType;
      }).toList();
    });
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showTicketDetails(SupportTicketModel ticket) {
    final replyController = TextEditingController();
    String updatedStatus = ticket.status;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: const Color(0xFF150A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 720,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(ticket.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Ticket ID: ${ticket.id} • Type: ${ticket.type}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  const Divider(color: Colors.white10, height: 28),
                  
                  // Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 8),
                            Text('Name: ${ticket.customerName}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Email: ${ticket.customerEmail}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Phone: ${ticket.customerPhone}', style: const TextStyle(fontSize: 13)),
                            const Divider(color: Colors.white10, height: 24),
                            
                            const Text('Customer Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                              child: Text(ticket.message, style: const TextStyle(fontSize: 13, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Replies log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 12),
                            if (ticket.replies.isEmpty)
                              const Text('No replies yet.', style: TextStyle(color: Colors.white24, fontSize: 12))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ticket.replies.length,
                                itemBuilder: (context, index) {
                                  final r = ticket.replies[index];
                                  final isAdmin = r.sender == 'Admin';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? const Color(0xFFFF8A00).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isAdmin ? const Color(0xFFFF8A00).withValues(alpha: 0.2) : Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(r.sender, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isAdmin ? const Color(0xFFFF8A00) : Colors.white60)),
                                            Text(DateFormat('MMM d, h:mm a').format(r.timestamp), style: const TextStyle(color: Colors.white24, fontSize: 8)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(r.message, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 28),
                  
                  Row(
                    children: [
                      const Text('Change Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: updatedStatus,
                        dropdownColor: const Color(0xFF150A2E),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'Open', child: Text('Open')),
                          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'Waiting for Customer', child: Text('Waiting for Customer')),
                          DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() => updatedStatus = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: replyController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Reply Message',
                      hintText: 'Type reply here to send to customer...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final msg = replyController.text.trim();
                          if (msg.isEmpty && updatedStatus == ticket.status) {
                            _showErrorSnackBar('Provide a reply or update status.');
                            return;
                          }
                          
                          try {
                            if (msg.isNotEmpty) {
                              final reply = SupportReplyModel(sender: 'Admin', message: msg, timestamp: DateTime.now());
                              await DatabaseService.addReplyToTicket(ticket.id, reply, updatedStatus);
                            } else {
                              await DatabaseService.updateTicketStatus(ticket.id, updatedStatus);
                            }
                            _showSuccessSnackBar('Support ticket updated successfully.');
                            if (mounted) Navigator.pop(context);
                            _loadTickets();
                          } catch (e) {
                            _showErrorSnackBar('Failed to update ticket: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00), foregroundColor: Colors.white),
                        child: const Text('SUBMIT UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Support Tickets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Manage customer support requests, post administrative replies, and resolve ticket disputes', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          const SizedBox(height: 28),
          
          // Filters
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by Ticket ID, Customer, or Subject...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8A00)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF150A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ticket Status',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Waiting for Customer', child: Text('Waiting for Customer')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _statusFilter = val;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _typeFilter,
                  dropdownColor: const Color(0xFF150A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ticket Type',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                    DropdownMenuItem(value: 'Contact Request', child: Text('Contact Request')),
                    DropdownMenuItem(value: 'Complaint', child: Text('Complaint')),
                    DropdownMenuItem(value: 'Return Request', child: Text('Return Request')),
                    DropdownMenuItem(value: 'Refund Request', child: Text('Refund Request')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _typeFilter = val;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : _filteredTickets.isEmpty
                    ? const Center(child: Text('No support tickets open.', style: TextStyle(color: Colors.white38)))
                    : GlassCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(cardColor: Colors.transparent, dividerColor: Colors.white10),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Last Updated', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredTickets.map((ticket) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(ticket.id)),
                                      DataCell(Text(ticket.customerName)),
                                      DataCell(Text(ticket.type)),
                                      DataCell(Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ticket.status == 'Resolved' || ticket.status == 'Closed'
                                                ? Colors.green.withValues(alpha: 0.15)
                                                : Colors.red.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ticket.status,
                                            style: TextStyle(
                                              color: ticket.status == 'Resolved' || ticket.status == 'Closed' ? Colors.greenAccent : Colors.redAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(DateFormat('yMMMd').format(ticket.updatedDate))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.reply_rounded, color: Colors.blueAccent, size: 18),
                                          onPressed: () => _showTicketDetails(ticket),
                                          tooltip: 'View & Reply',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
