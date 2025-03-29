import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firebase_remote_config.dart';

class ForexPrice {
  final String symbol;
  final double price;
  final double previousPrice;
  final DateTime timestamp;
  final List<PricePoint> priceHistory;

  ForexPrice({
    required this.symbol,
    required this.price,
    required this.previousPrice,
    required this.timestamp,
    List<PricePoint>? priceHistory,
  }) : this.priceHistory = priceHistory ?? [];

  bool get isIncreasing => price > previousPrice;
  bool get isDecreasing => price < previousPrice;
  bool get unchanged => price == previousPrice;

  ForexPrice copyWithNewPrice(double newPrice, DateTime newTimestamp) {
    final updatedHistory = List<PricePoint>.from(priceHistory);
    updatedHistory.add(PricePoint(timestamp: timestamp, price: price));
    if (updatedHistory.length > 30) {
      updatedHistory.removeAt(0);
    }
    return ForexPrice(
      symbol: symbol,
      price: newPrice,
      previousPrice: price,
      timestamp: newTimestamp,
      priceHistory: updatedHistory,
    );
  }
}

class PricePoint {
  final DateTime timestamp;
  final double price;

  PricePoint({required this.timestamp, required this.price});
}

class CurrencyLayerService {
  Timer? _simulationTimer;
  final Random _random = Random();

  final RemoteConfigService _remoteConfig;

  CurrencyLayerService({RemoteConfigService? remoteConfig})
    : _remoteConfig = remoteConfig ?? RemoteConfigService.instance;

  // Updated API details
  static const String _baseUrl =
      'https://openexchangerates.org/api/latest.json';

  // Map to store latest prices for each symbol
  final Map<String, ForexPrice> _latestPrices = {};

  // Stream controller to broadcast price updates
  final _priceController =
      StreamController<Map<String, ForexPrice>>.broadcast();

  // Getter for the stream
  Stream<Map<String, ForexPrice>> get priceStream => _priceController.stream;

  // Loading status controller
  StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  // Getter for loading status stream
  Stream<bool> get loadingStream => _loadingController.stream;

  // Last fetch timestamp
  DateTime? _lastFetchTime;

  // Currency pairs we're interested in
  final List<String> supportedPairs = [
    // Original pairs
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'XAUUSD',
    'BTCUSD',
    // Additional USD-related pairs
    'AUDUSD',
    'NZDUSD',
    // Cross pairs with JPY
    'EURJPY',
    'GBPJPY',
    'NZDJPY',
    'AUDJPY',
    'CHFJPY',
    'CADJPY',
    // AUD-related pairs
    'EURAUD',
    'GBPAUD',
    // CAD-related pairs
    'USDCAD',
    'AUDCAD',
    'NZDCAD',
    'EURCAD',
    'GBPCAD',
    // CHF-related pairs
    'USDCHF',
    'AUDCHF',
    'NZDCHF',
    'EURCHF',
    'GBPCHF',
    // Other cross pairs
    'AUDNZD',
    'EURGBP',
    'EURNZD',
    'GBPNZD'
  ];

  // Initial fetch for first load
  void init() {
    // Check if we already have prices to prevent re-initialization
    if (_latestPrices.isNotEmpty && !_isDataStale()) {
      // If prices exist and are not stale, start simulation immediately
      _startSimulation();
      return;
    }

    getCachedForexData().then((cachedPrices) {
      if (cachedPrices.isNotEmpty) {
        _latestPrices.addAll(cachedPrices);
        _priceController.add(Map.from(_latestPrices));

        // If cached prices exist and are not stale, start simulation
        if (!_isDataStale()) {
          _startSimulation();
          return;
        }
      }
      fetchLatestRates().then((_) {
        _startSimulation();
      });
    });
  }

// Add a method to check if cached data is stale
  bool _isDataStale() {
    if (_lastFetchTime == null) return true;
    // Consider data stale if it's older than 1 hour
    return DateTime.now().difference(_lastFetchTime!).inMinutes > 60;
  }

  void dispose() {
    _simulationTimer?.cancel();
    _priceController.close();
    disposeLoadingController();
  }

  void initLoadingController() {
    // Only create if not already created
    if (!_loadingController.isClosed) {
      _loadingController.close();
    }
    // Create a new broadcast controller
    _loadingController = StreamController<bool>.broadcast();
  }

  void disposeLoadingController() {
    _loadingController.close();
  }

  void setLoading(bool isLoading) {
    // Only add if controller exists and is not closed
    if (!_loadingController.isClosed) {
      _loadingController.add(isLoading);
    }
  }

  // Get last fetch time
  DateTime? get lastFetchTime => _lastFetchTime;

  Future<void> cacheForexData(Map<String, ForexPrice> prices) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prices.map((key, value) => MapEntry(
        key,
        jsonEncode({
          'symbol': value.symbol,
          'price': value.price,
          'previousPrice': value.previousPrice,
          'timestamp': value.timestamp.toIso8601String(),
          'priceHistory': value.priceHistory
              .map((point) => {
                    'timestamp': point.timestamp.toIso8601String(),
                    'price': point.price
                  })
              .toList()
        })));

    await prefs.setString('forexPricesCache', jsonEncode(cachedData));
  }

  Future<Map<String, ForexPrice>> getCachedForexData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString('forexPricesCache');

    if (cachedDataString == null) return {};

    try {
      final cachedData = jsonDecode(cachedDataString);

      // The cached data is a Map of JSON-encoded strings
      if (cachedData is Map) {
        return cachedData.map<String, ForexPrice>((key, value) {
          // Parse the JSON-encoded string
          final parsedValue = jsonDecode(value);

          return MapEntry(
              key,
              ForexPrice(
                  symbol: parsedValue['symbol'],
                  price: _parseDouble(parsedValue['price']),
                  previousPrice: _parseDouble(parsedValue['previousPrice']),
                  timestamp: DateTime.tryParse(parsedValue['timestamp']) ??
                      DateTime.now(),
                  priceHistory:
                      _parsePriceHistory(parsedValue['priceHistory'])));
        });
      }

      return {};
    } catch (e) {
      print('Error parsing cached forex data: $e');
      return {};
    }
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

// Helper method to parse price history
  List<PricePoint> _parsePriceHistory(dynamic historyData) {
    if (historyData == null) return [];

    try {
      return (historyData as List).map((point) {
        return PricePoint(
            timestamp: DateTime.tryParse(point['timestamp']) ?? DateTime.now(),
            price: _parseDouble(point['price']));
      }).toList();
    } catch (e) {
      print('Error parsing price history: $e');
      return [];
    }
  }

  // Method to fetch latest rates on demand
  Future<bool> fetchLatestRates({bool forceRefresh = false}) async {
    initLoadingController();
    try {
      setLoading(true);
      if (!forceRefresh) {
        final cachedPrices = await getCachedForexData();
        if (cachedPrices.isNotEmpty) {
          // Populate _latestPrices with cached data
          _latestPrices.addAll(cachedPrices);
          _priceController.add(Map.from(_latestPrices));
          return true;
        }
      }

      // Fetch the latest rates from the API
      final apiKey = _remoteConfig.apiKey;
      
      // Construct API URL with app_id
      final url = '$_baseUrl?app_id=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // OpenExchangeRates provides a timestamp (in seconds)
        final timestamp =
            DateTime.fromMillisecondsSinceEpoch(data['timestamp'] * 1000);

        // Extract rates from the JSON response
        final rates = data['rates'] as Map<String, dynamic>;

        // Process the rates and update our price maps
        _updatePrices(rates, timestamp);

        // Update last fetch time
        _lastFetchTime = DateTime.now();
        setLoading(false);
        await cacheForexData(_latestPrices);
        return true;
      } else {
        print('HTTP Error: ${response.statusCode}');
        setLoading(false);
        return false;
      }
    } catch (e) {
      print('Exception during API call: $e');
      setLoading(false);
      return false;
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    if (_latestPrices.isEmpty) return;

    _simulationTimer = Timer.periodic(Duration(seconds: 2), (_) {
      // Make copy of current prices
      final currentPrices = Map<String, ForexPrice>.from(_latestPrices);

      // Update 1-3 random pairs
      final pairsToUpdate = _random.nextInt(3) + 1;
      final allPairs = currentPrices.keys.toList();

      if (allPairs.isNotEmpty) {
        allPairs.shuffle(_random);

        for (final pair in allPairs.take(pairsToUpdate)) {
          final priceData = currentPrices[pair]!;

          // Tiny random change (-0.005% to +0.005%)
          final changePercent = (_random.nextDouble() - 0.5) * 0.0001;
          final newPrice = priceData.price * (1 + changePercent);

          // Update price
          currentPrices[pair] =
              priceData.copyWithNewPrice(newPrice, DateTime.now());
        }

        // Broadcast the updated prices
        _latestPrices.addAll(currentPrices);
        _priceController.add(Map.from(_latestPrices));
      }
    });
  }

  void _updatePrices(Map<String, dynamic> rates, DateTime timestamp) {
    _processUsdPairs(rates, timestamp);

    // Calculate cross rates
    _calculateCrossRates();

    // Add special pairs (XAUUSD, BTCUSD)
    _addSpecialPairs(rates, timestamp);

    // Broadcast the updated prices
    _priceController.add(Map.from(_latestPrices));
  }

  void _processUsdPairs(Map<String, dynamic> rates, DateTime timestamp) {
    // Process EUR/USD (USD is the quote currency)
    if (rates.containsKey('EUR')) {
      final eurUsdRate = 1 / rates['EUR'];
      _updatePriceForSymbol('EURUSD', eurUsdRate, timestamp);
    }

    // Process GBP/USD (USD is the quote currency)
    if (rates.containsKey('GBP')) {
      final gbpUsdRate = 1 / rates['GBP'];
      _updatePriceForSymbol('GBPUSD', gbpUsdRate, timestamp);
    }

    // Process USD/JPY (USD is the base currency)
    if (rates.containsKey('JPY')) {
      final usdJpyRate = rates['JPY'];
      _updatePriceForSymbol('USDJPY', usdJpyRate, timestamp);
    }

    // Process USD/CAD (USD is the base currency)
    if (rates.containsKey('CAD')) {
      final usdCadRate = rates['CAD'];
      _updatePriceForSymbol('USDCAD', usdCadRate, timestamp);
    }

    // Process AUD/USD (USD is the quote currency)
    if (rates.containsKey('AUD')) {
      final audUsdRate = 1 / rates['AUD'];
      _updatePriceForSymbol('AUDUSD', audUsdRate, timestamp);
    }

    // Process USD/CHF (USD is the base currency)
    if (rates.containsKey('CHF')) {
      final usdChfRate = rates['CHF'];
      _updatePriceForSymbol('USDCHF', usdChfRate, timestamp);
    }

    // Process NZD/USD (USD is the quote currency)
    if (rates.containsKey('NZD')) {
      final nzdUsdRate = 1 / rates['NZD'];
      _updatePriceForSymbol('NZDUSD', nzdUsdRate, timestamp);
    }

    // Process USD/MXN (USD is the base currency)
    if (rates.containsKey('MXN')) {
      final usdMxnRate = rates['MXN'];
      _updatePriceForSymbol('USDMXN', usdMxnRate, timestamp);
    }

    // Process USD/SGD (USD is the base currency)
    if (rates.containsKey('SGD')) {
      final usdSgdRate = rates['SGD'];
      _updatePriceForSymbol('USDSGD', usdSgdRate, timestamp);
    }
  }

  void _updatePriceForSymbol(String symbol, double price, DateTime timestamp) {
    if (_latestPrices.containsKey(symbol)) {
      _latestPrices[symbol] =
          _latestPrices[symbol]!.copyWithNewPrice(price, timestamp);
    } else {
      _latestPrices[symbol] = ForexPrice(
          symbol: symbol,
          price: price,
          previousPrice: price,
          timestamp: timestamp);
    }
  }

  void _calculateCrossRates() {
    // Existing cross rate calculations
    // EURJPY from EURUSD and USDJPY
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('USDJPY')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final eurJpy = eurUsd * usdJpy;
      _updatePriceForSymbol('EURJPY', eurJpy, DateTime.now());
    }

    // GBPJPY from GBPUSD and USDJPY
    if (_latestPrices.containsKey('GBPUSD') &&
        _latestPrices.containsKey('USDJPY')) {
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final gbpJpy = gbpUsd * usdJpy;
      _updatePriceForSymbol('GBPJPY', gbpJpy, DateTime.now());
    }

    // EURGBP from EURUSD and GBPUSD
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('GBPUSD')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final eurGbp = eurUsd / gbpUsd;
      _updatePriceForSymbol('EURGBP', eurGbp, DateTime.now());
    }

    // EURAUD from EURUSD and AUDUSD
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('AUDUSD')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final audUsd = _latestPrices['AUDUSD']!.price;
      final eurAud = eurUsd / audUsd;
      _updatePriceForSymbol('EURAUD', eurAud, DateTime.now());
    }

    // EURCHF from EURUSD and USDCHF
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('USDCHF')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final usdChf = _latestPrices['USDCHF']!.price;
      final eurChf = eurUsd * usdChf;
      _updatePriceForSymbol('EURCHF', eurChf, DateTime.now());
    }

    // EURSGD from EURUSD and USDSGD
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('USDSGD')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final usdSgd = _latestPrices['USDSGD']!.price;
      final eurSgd = eurUsd * usdSgd;
      _updatePriceForSymbol('EURSGD', eurSgd, DateTime.now());
    }

    // New cross-rate calculations

    // NZDJPY from NZDUSD and USDJPY
    if (_latestPrices.containsKey('NZDUSD') &&
        _latestPrices.containsKey('USDJPY')) {
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final nzdJpy = nzdUsd * usdJpy;
      _updatePriceForSymbol('NZDJPY', nzdJpy, DateTime.now());
    }

    // AUDJPY from AUDUSD and USDJPY
    if (_latestPrices.containsKey('AUDUSD') &&
        _latestPrices.containsKey('USDJPY')) {
      final audUsd = _latestPrices['AUDUSD']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final audJpy = audUsd * usdJpy;
      _updatePriceForSymbol('AUDJPY', audJpy, DateTime.now());
    }

    // CHFJPY from USDCHF and USDJPY
    if (_latestPrices.containsKey('USDCHF') &&
        _latestPrices.containsKey('USDJPY')) {
      final usdChf = _latestPrices['USDCHF']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final chfJpy = 1 / usdChf * usdJpy;
      _updatePriceForSymbol('CHFJPY', chfJpy, DateTime.now());
    }

    // CADJPY from USDCAD and USDJPY
    if (_latestPrices.containsKey('USDCAD') &&
        _latestPrices.containsKey('USDJPY')) {
      final usdCad = _latestPrices['USDCAD']!.price;
      final usdJpy = _latestPrices['USDJPY']!.price;
      final cadJpy = 1 / usdCad * usdJpy;
      _updatePriceForSymbol('CADJPY', cadJpy, DateTime.now());
    }

    // GBPAUD from GBPUSD and AUDUSD
    if (_latestPrices.containsKey('GBPUSD') &&
        _latestPrices.containsKey('AUDUSD')) {
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final audUsd = _latestPrices['AUDUSD']!.price;
      final gbpAud = gbpUsd / audUsd;
      _updatePriceForSymbol('GBPAUD', gbpAud, DateTime.now());
    }

    // AUDCAD from AUDUSD and USDCAD
    if (_latestPrices.containsKey('AUDUSD') &&
        _latestPrices.containsKey('USDCAD')) {
      final audUsd = _latestPrices['AUDUSD']!.price;
      final usdCad = _latestPrices['USDCAD']!.price;
      final audCad = audUsd / usdCad;
      _updatePriceForSymbol('AUDCAD', audCad, DateTime.now());
    }

    // NZDCAD from NZDUSD and USDCAD
    if (_latestPrices.containsKey('NZDUSD') &&
        _latestPrices.containsKey('USDCAD')) {
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final usdCad = _latestPrices['USDCAD']!.price;
      final nzdCad = nzdUsd / usdCad;
      _updatePriceForSymbol('NZDCAD', nzdCad, DateTime.now());
    }

    // EURCAD from EURUSD and USDCAD
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('USDCAD')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final usdCad = _latestPrices['USDCAD']!.price;
      final eurCad = eurUsd / usdCad;
      _updatePriceForSymbol('EURCAD', eurCad, DateTime.now());
    }

    // GBPCAD from GBPUSD and USDCAD
    if (_latestPrices.containsKey('GBPUSD') &&
        _latestPrices.containsKey('USDCAD')) {
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final usdCad = _latestPrices['USDCAD']!.price;
      final gbpCad = gbpUsd / usdCad;
      _updatePriceForSymbol('GBPCAD', gbpCad, DateTime.now());
    }

    // AUDCHF from AUDUSD and USDCHF
    if (_latestPrices.containsKey('AUDUSD') &&
        _latestPrices.containsKey('USDCHF')) {
      final audUsd = _latestPrices['AUDUSD']!.price;
      final usdChf = _latestPrices['USDCHF']!.price;
      final audChf = audUsd / usdChf;
      _updatePriceForSymbol('AUDCHF', audChf, DateTime.now());
    }

    // NZDCHF from NZDUSD and USDCHF
    if (_latestPrices.containsKey('NZDUSD') &&
        _latestPrices.containsKey('USDCHF')) {
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final usdChf = _latestPrices['USDCHF']!.price;
      final nzdChf = nzdUsd / usdChf;
      _updatePriceForSymbol('NZDCHF', nzdChf, DateTime.now());
    }

    // GBPCHF from GBPUSD and USDCHF
    if (_latestPrices.containsKey('GBPUSD') &&
        _latestPrices.containsKey('USDCHF')) {
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final usdChf = _latestPrices['USDCHF']!.price;
      final gbpChf = gbpUsd / usdChf;
      _updatePriceForSymbol('GBPCHF', gbpChf, DateTime.now());
    }

    // EURNZD from EURUSD and NZDUSD
    if (_latestPrices.containsKey('EURUSD') &&
        _latestPrices.containsKey('NZDUSD')) {
      final eurUsd = _latestPrices['EURUSD']!.price;
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final eurNzd = eurUsd / nzdUsd;
      _updatePriceForSymbol('EURNZD', eurNzd, DateTime.now());
    }

    // GBPNZD from GBPUSD and NZDUSD
    if (_latestPrices.containsKey('GBPUSD') &&
        _latestPrices.containsKey('NZDUSD')) {
      final gbpUsd = _latestPrices['GBPUSD']!.price;
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final gbpNzd = gbpUsd / nzdUsd;
      _updatePriceForSymbol('GBPNZD', gbpNzd, DateTime.now());
    }

    // AUDNZD from AUDUSD and NZDUSD
    if (_latestPrices.containsKey('AUDUSD') &&
        _latestPrices.containsKey('NZDUSD')) {
      final audUsd = _latestPrices['AUDUSD']!.price;
      final nzdUsd = _latestPrices['NZDUSD']!.price;
      final audNzd = audUsd / nzdUsd;
      _updatePriceForSymbol('AUDNZD', audNzd, DateTime.now());
    }
  }

  void _addSpecialPairs(Map<String, dynamic> rates, DateTime timestamp) {
    // Check if OpenExchangeRates provides XAU rate
    if (rates.containsKey('XAU')) {
      // XAU is quoted in USD per ounce, so we need to take the inverse
      final xauUsdRate = 1 / rates['XAU'];
      _updatePriceForSymbol('XAUUSD', xauUsdRate, timestamp);
    } else {
      // If not provided, use a placeholder value
      if (!_latestPrices.containsKey('XAUUSD')) {
        _latestPrices['XAUUSD'] = ForexPrice(
            symbol: 'XAUUSD',
            price: 2150.43,
            previousPrice: 2150.43,
            timestamp: timestamp);
      }
    }

    // Check if OpenExchangeRates provides BTC rate
    if (rates.containsKey('BTC')) {
      // BTC is quoted in USD per BTC, so we need to take the inverse
      final btcUsdRate = 1 / rates['BTC'];
      _updatePriceForSymbol('BTCUSD', btcUsdRate, timestamp);
    } else {
      // If not provided, use a placeholder value
      if (!_latestPrices.containsKey('BTCUSD')) {
        _latestPrices['BTCUSD'] = ForexPrice(
            symbol: 'BTCUSD',
            price: 67432.18,
            previousPrice: 67432.18,
            timestamp: timestamp);
      }
    }
  }
}
