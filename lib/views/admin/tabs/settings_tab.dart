import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/app_settings.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _logoUrl;
  XFile? _pickedLogo;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final s = await DatabaseService.getAppSettings();
      setState(() {
        _nameController.text = s.name;
        _descController.text = s.description;
        _phoneController.text = s.contactNumber;
        _emailController.text = s.email;
        _whatsappController.text = s.whatsapp;
        _logoUrl = s.logoUrl.isEmpty ? null : s.logoUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load settings: $e');
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _pickedLogo = img;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLogo == null && _logoUrl == null) {
      _showErrorSnackBar('Please pick a store logo.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      String finalLogo = _logoUrl ?? '';
      
      if (_pickedLogo != null) {
        final bytes = await _pickedLogo!.readAsBytes();
        finalLogo = await CloudinaryService.uploadImage(bytes, _pickedLogo!.name);
      }

      final payload = AppSettingsModel(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        logoUrl: finalLogo,
      );

      await DatabaseService.saveAppSettings(payload);
      _showSuccessSnackBar('Store settings saved successfully!');
      _loadSettings();
    } catch (e) {
      _showErrorSnackBar('Failed to save settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Configure global branding and contact parameters for customers', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 28),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Text('Store Brand Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                            ),
                            child: _pickedLogo != null
                                ? ClipOval(child: Image.network(_pickedLogo!.path, fit: BoxFit.cover))
                                : _logoUrl != null
                                    ? ClipOval(child: Image.network(_logoUrl!, fit: BoxFit.cover))
                                    : const Center(child: Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF8A00), size: 36)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to choose store emblem artwork',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                Expanded(
                  flex: 7,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Store Name', prefixIcon: Icon(Icons.storefront_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter store name' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _descController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Store Description', prefixIcon: Icon(Icons.description_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Contact Phone Number', prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Support Email Address', prefixIcon: Icon(Icons.email_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter email address' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _whatsappController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'WhatsApp Business Number', prefixIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter WhatsApp contact' : null,
                        ),
                        const SizedBox(height: 32),
                        
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                              : const Text('SAVE APP SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
