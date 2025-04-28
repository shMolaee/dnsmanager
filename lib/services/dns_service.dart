import 'package:process_run/process_run.dart';
import '../models/dns_config.dart';

class DnsService {
  static final DnsService _instance = DnsService._internal();
  
  factory DnsService() => _instance;
  
  DnsService._internal();
  
  Future<List<String>> getNetworkInterfaces() async {
    try {
      final result = await runExecutableArguments(
        'powershell',
        ['-Command', 'Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -ExpandProperty Name'],
      );
      
      if (result.exitCode != 0) {
        throw Exception('Failed to get network interfaces: ${result.stderr}');
      }
      
      return result.stdout.toString().trim().split('\r\n');
    } catch (e) {
      if (e.toString().contains('Access') || e.toString().contains('Permission')) {
        throw Exception('Administrator privileges required to access network interfaces.');
      }
      rethrow;
    }
  }
  
  Future<void> setDnsServers(String interfaceName, DnsConfig config) async {
    try {
      // First, get the network adapters to check if the interface exists
      final interfaces = await getNetworkInterfaces();
      if (!interfaces.contains(interfaceName)) {
        throw Exception('Network interface $interfaceName not found');
      }
      
      // Set the DNS servers using PowerShell
      String commandString;
      
      // If alternate DNS is provided, include it
      if (config.alternateDns != null && config.alternateDns!.isNotEmpty) {
        commandString = 'Set-DnsClientServerAddress -InterfaceAlias "$interfaceName" -ServerAddresses "${config.primaryDns}","${config.alternateDns}"';
      } else {
        commandString = 'Set-DnsClientServerAddress -InterfaceAlias "$interfaceName" -ServerAddresses "${config.primaryDns}"';
      }
      
      // Execute PowerShell command
      final result = await runExecutableArguments(
        'powershell',
        ['-Command', commandString],
      );
      
      if (result.exitCode != 0) {
        if (result.stderr.toString().contains('Access') || 
            result.stderr.toString().contains('Permission') ||
            result.stderr.toString().contains('CIM resource')) {
          throw Exception('Administrator privileges required to change DNS settings.');
        }
        throw Exception('Failed to set DNS servers: ${result.stderr}');
      }
    } catch (e) {
      if (e.toString().contains('Access') || 
          e.toString().contains('Permission') || 
          e.toString().contains('CIM resource')) {
        throw Exception('Administrator privileges required to change DNS settings.');
      }
      rethrow;
    }
  }
  
  Future<void> setAutomaticDns(String interfaceName) async {
    try {
      final result = await runExecutableArguments(
        'powershell',
        ['-Command', 'Set-DnsClientServerAddress -InterfaceAlias "$interfaceName" -ResetServerAddresses'],
      );
      
      if (result.exitCode != 0) {
        if (result.stderr.toString().contains('Access') || 
            result.stderr.toString().contains('Permission') ||
            result.stderr.toString().contains('CIM resource')) {
          throw Exception('Administrator privileges required to reset DNS settings.');
        }
        throw Exception('Failed to reset DNS settings: ${result.stderr}');
      }
    } catch (e) {
      if (e.toString().contains('Access') || 
          e.toString().contains('Permission') || 
          e.toString().contains('CIM resource')) {
        throw Exception('Administrator privileges required to reset DNS settings.');
      }
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getCurrentDnsSettings(String interfaceName) async {
    try {
      final result = await runExecutableArguments(
        'powershell',
        ['-Command', 'Get-DnsClientServerAddress -InterfaceAlias "$interfaceName" -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses'],
      );
      
      if (result.exitCode != 0) {
        if (result.stderr.toString().contains('Access') || 
            result.stderr.toString().contains('Permission') ||
            result.stderr.toString().contains('CIM resource')) {
          throw Exception('Administrator privileges required to get DNS settings.');
        }
        throw Exception('Failed to get current DNS settings: ${result.stderr}');
      }
      
      final dnsServers = result.stdout.toString().trim().split('\r\n');
      
      return {
        'primaryDns': dnsServers.isNotEmpty ? dnsServers[0] : null,
        'alternateDns': dnsServers.length > 1 ? dnsServers[1] : null,
      };
    } catch (e) {
      if (e.toString().contains('Access') || 
          e.toString().contains('Permission') || 
          e.toString().contains('CIM resource')) {
        throw Exception('Administrator privileges required to get DNS settings.');
      }
      rethrow;
    }
  }
} 