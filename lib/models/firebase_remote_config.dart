import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  // Static instance
  static RemoteConfigService? _instance;
  
  // Get the singleton instance
  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService._();
    return _instance!;
  }
  
  // Private constructor that initializes with default FirebaseRemoteConfig
  RemoteConfigService._() {
    // We'll initialize FirebaseRemoteConfig lazily when needed
  }
  
  // Keys for Remote Config values
  static const String openExchangeRatesApiKey = 'open_exchange_rates_api_key';
  
  // Default values (used if Remote Config fails)
  static final Map<String, dynamic> _defaults = {
    openExchangeRatesApiKey: '',
  };
  
  // Lazily initialized remote config
  FirebaseRemoteConfig? _remoteConfig;
  
  // Initialize the remote config
  Future<void> initialize() async {
    if (_remoteConfig != null) return; // Already initialized
    
    _remoteConfig = FirebaseRemoteConfig.instance;
    
    // Set default values
    await _remoteConfig!.setDefaults(_defaults);
    
    // Set cache expiration (for development, use a shorter duration)
    await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Fetch and activate
    await _remoteConfig!.fetchAndActivate();
  }
  
  // Method to get the API key
  String get apiKey {
    // Make sure it's initialized
    if (_remoteConfig == null) {
      print('Warning: RemoteConfig not initialized. Use default value.');
      return '';
    }
    return _remoteConfig!.getString(openExchangeRatesApiKey);
  }
  
  // Method to force refresh config
  Future<bool> refreshConfig() async {
    if (_remoteConfig == null) {
      await initialize();
      return true;
    }
    
    try {
      await _remoteConfig!.fetchAndActivate();
      return true;
    } catch (e) {
      print('Failed to refresh remote config: $e');
      return false;
    }
  }
}