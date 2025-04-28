import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dns_config.dart';
import '../services/dns_config_provider.dart';
import '../services/admin_service.dart';
import 'add_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;
  bool _isAdminChecked = false;

  @override
  void initState() {
    super.initState();
    // Initialize provider after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus();
      _initProvider();
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isRunningAsAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isAdminChecked = true;
    });
  }

  Future<void> _initProvider() async {
    final provider = Provider.of<DnsConfigProvider>(context, listen: false);
    await provider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNS Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAdminStatus();
              _initProvider();
            },
          ),
        ],
      ),
      body: _isAdminChecked && !_isAdmin
          ? _buildAdminRequiredScreen()
          : Consumer<DnsConfigProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => provider.clearError(),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdminWarningBanner(),
                      const SizedBox(height: 16),
                      _buildInterfaceSelector(provider),
                      Expanded(
                        child: _buildConfigList(provider),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const AddConfigScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildAdminRequiredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Administrator Privileges Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This application requires administrator privileges to modify Windows DNS settings.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _adminService.restartAsAdmin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings),
                  const SizedBox(width: 8),
                  const Text('Restart with Admin Privileges', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Or manually:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Close this application'),
                  Text('2. Right-click on the application icon'),
                  Text('3. Select "Run as administrator"'),
                  Text('4. Confirm the UAC prompt'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _checkAdminStatus(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Check Admin Status Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdminWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade800),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This application requires administrator privileges to modify DNS settings.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceSelector(DnsConfigProvider provider) {
    return FutureBuilder<List<String>>(
      future: provider.getNetworkInterfaces(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Failed to load network interfaces: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final interfaces = snapshot.data!;
        if (interfaces.isEmpty) {
          return const Center(
            child: Text(
              'No network interfaces found',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Network Interface:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              value: provider.selectedInterface,
              hint: const Text('Select Interface'),
              items: interfaces.map((interface) {
                return DropdownMenuItem<String>(
                  value: interface,
                  child: Text(interface),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setSelectedInterface(value);
                }
              },
            ),
            const SizedBox(height: 8),
            if (provider.selectedInterface != null)
              ElevatedButton(
                onPressed: () => provider.deactivateAllConfigs(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Use Automatic DNS (DHCP)'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConfigList(DnsConfigProvider provider) {
    final configs = provider.configs;
    
    if (configs.isEmpty) {
      return const Center(
        child: Text(
          'No DNS configurations found.\nTap + to add a new configuration.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (ctx, index) {
        final config = configs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(config.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primary DNS: ${config.primaryDns}'),
                if (config.alternateDns != null && config.alternateDns!.isNotEmpty)
                  Text('Alternate DNS: ${config.alternateDns}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config.isActive)
                  const Icon(Icons.check_circle, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: provider.selectedInterface == null
                      ? null
                      : () => provider.activateConfig(config),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, provider, config),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DnsConfigProvider provider, DnsConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteConfig(config.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 