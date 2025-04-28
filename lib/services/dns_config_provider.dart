import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dns_config.dart';
import 'database_service.dart';
import 'dns_service.dart';

class DnsConfigProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final DnsService _dnsService = DnsService();
  List<DnsConfig> _configs = [];
  String? _selectedInterface;
  bool _isLoading = false;
  String? _error;

  List<DnsConfig> get configs => _configs;
  String? get selectedInterface => _selectedInterface;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize the provider
  Future<void> init() async {
    _setLoading(true);
    try {
      // Load saved interface from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _selectedInterface = prefs.getString('selectedInterface');
      
      // Load configs from database
      await _loadConfigs();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Load configurations from database
  Future<void> _loadConfigs() async {
    try {
      _configs = await _databaseService.getDnsConfigs();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load configurations: $e');
    }
  }
  
  // Add a new DNS configuration
  Future<void> addConfig(DnsConfig config) async {
    _setLoading(true);
    try {
      final id = await _databaseService.insertDnsConfig(config);
      final newConfig = config.copyWith(id: id);
      _configs.add(newConfig);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add configuration: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Update an existing DNS configuration
  Future<void> updateConfig(DnsConfig config) async {
    _setLoading(true);
    try {
      await _databaseService.updateDnsConfig(config);
      final index = _configs.indexWhere((c) => c.id == config.id);
      if (index != -1) {
        _configs[index] = config;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update configuration: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a DNS configuration
  Future<void> deleteConfig(int id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteDnsConfig(id);
      _configs.removeWhere((config) => config.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete configuration: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Activate a DNS configuration
  Future<void> activateConfig(DnsConfig config) async {
    if (_selectedInterface == null) {
      _setError('No network interface selected');
      return;
    }
    
    _setLoading(true);
    try {
      // First deactivate all configs
      await _databaseService.deactivateAllConfigs();
      
      // Update the configs in memory
      for (var i = 0; i < _configs.length; i++) {
        _configs[i] = _configs[i].copyWith(isActive: false);
      }
      
      // Activate the selected config
      final updatedConfig = config.copyWith(isActive: true);
      await _databaseService.updateDnsConfig(updatedConfig);
      
      // Apply DNS settings
      await _dnsService.setDnsServers(_selectedInterface!, updatedConfig);
      
      // Update the config in memory
      final index = _configs.indexWhere((c) => c.id == config.id);
      if (index != -1) {
        _configs[index] = updatedConfig;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to activate configuration: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Deactivate all DNS configurations and set to automatic
  Future<void> deactivateAllConfigs() async {
    if (_selectedInterface == null) {
      _setError('No network interface selected');
      return;
    }
    
    _setLoading(true);
    try {
      // Deactivate all configs in database
      await _databaseService.deactivateAllConfigs();
      
      // Update the configs in memory
      for (var i = 0; i < _configs.length; i++) {
        _configs[i] = _configs[i].copyWith(isActive: false);
      }
      
      // Reset DNS settings to automatic
      await _dnsService.setAutomaticDns(_selectedInterface!);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to deactivate configurations: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Set selected network interface
  Future<void> setSelectedInterface(String interfaceName) async {
    _selectedInterface = interfaceName;
    
    // Save selected interface
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedInterface', interfaceName);
    
    notifyListeners();
  }
  
  // Get available network interfaces
  Future<List<String>> getNetworkInterfaces() async {
    try {
      return await _dnsService.getNetworkInterfaces();
    } catch (e) {
      _setError('Failed to get network interfaces: $e');
      return [];
    }
  }
  
  // Get current DNS settings
  Future<Map<String, dynamic>> getCurrentDnsSettings() async {
    if (_selectedInterface == null) {
      _setError('No network interface selected');
      return {'primaryDns': null, 'alternateDns': null};
    }
    
    try {
      return await _dnsService.getCurrentDnsSettings(_selectedInterface!);
    } catch (e) {
      _setError('Failed to get current DNS settings: $e');
      return {'primaryDns': null, 'alternateDns': null};
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 