import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dns_config.dart';
import '../services/dns_config_provider.dart';

class AddConfigScreen extends StatefulWidget {
  const AddConfigScreen({super.key});

  @override
  State<AddConfigScreen> createState() => _AddConfigScreenState();
}

class _AddConfigScreenState extends State<AddConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _primaryDnsController = TextEditingController();
  final _alternateDnsController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _primaryDnsController.dispose();
    _alternateDnsController.dispose();
    super.dispose();
  }

  void _saveForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    final dnsConfig = DnsConfig(
      name: _nameController.text.trim(),
      primaryDns: _primaryDnsController.text.trim(),
      alternateDns: _alternateDnsController.text.trim().isNotEmpty
          ? _alternateDnsController.text.trim()
          : null,
    );

    final provider = Provider.of<DnsConfigProvider>(context, listen: false);
    provider.addConfig(dnsConfig).then((_) {
      Navigator.of(context).pop();
    }).catchError((error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save DNS configuration: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  bool _isValidIpAddress(String value) {
    final ipRegex = RegExp(
        r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
    return ipRegex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add DNS Configuration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Configuration Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _primaryDnsController,
                      decoration: const InputDecoration(
                        labelText: 'Primary DNS Server',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 8.8.8.8',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a primary DNS server';
                        }
                        if (!_isValidIpAddress(value.trim())) {
                          return 'Please enter a valid IP address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alternateDnsController,
                      decoration: const InputDecoration(
                        labelText: 'Alternate DNS Server (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 8.8.4.4',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !_isValidIpAddress(value.trim())) {
                          return 'Please enter a valid IP address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 