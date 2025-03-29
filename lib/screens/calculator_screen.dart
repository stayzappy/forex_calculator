import 'package:flutter/material.dart';
import 'package:forex_calculator/models/forex_price_data.dart';
import 'package:provider/provider.dart';
import '../models/graph_chart.dart';
import '../services/calculator_provider_service.dart';
import '../screens/calculator_dialog.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  final List<String> forexPairs = [
    'XAU/USD',
    'GBP/USD',
    'USD/JPY',
    'EUR/AUD',
    'USD/CAD',
    'EUR/JPY',
    'GBP/JPY',
    'BTC/USD',
    'EUR/USD',
    'USD/CHF',
    'AUD/USD',
    'EUR/GBP',
    'NZD/USD',
    'USD/MXN',
    'EUR/SGD',
    'EUR/CHF',
    'EUR/NZD',
    'NZD/JPY',
    'AUD/JPY',
    'CHF/JPY',
    'CAD/JPY',
    'GBP/AUD',
    'AUD/CAD',
    'NZD/CAD',
    'EUR/CAD',
    'GBP/CAD',
    'AUD/CHF',
    'NZD/CHF',
    'GBP/CHF',
    'AUD/NZD',
    'GBP/NZD'
  ];

  String _selectedPair = 'EURUSD';
  String _searchQuery = '';
  List<String> _filteredPairs = [];
  bool _isRefreshing = false;
  Map<String, ForexPrice> _currentPrices = {};
  late ForexServiceProvider _forexServiceProvider;
  

  
  final Map<String, AnimationController> _colorControllers = {};
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _filteredPairs = forexPairs;

    _forexServiceProvider =
        Provider.of<ForexServiceProvider>(context, listen: false);

    // Use the forexService from the provider
    final forexService = _forexServiceProvider.forexService;
    forexService.init();

    for (var pair in forexPairs) {
      final normalizedPair = pair.replaceAll('/', '');
      _colorControllers[normalizedPair] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
    }

    // Listen to price updates and trigger animations
    forexService.priceStream.listen((priceMap) {
      if (!mounted) return;
      setState(() {
        _currentPrices = Map.from(priceMap);
      });

      for (var pair in priceMap.keys) {
        final priceData = priceMap[pair];
        if (priceData != null) {
          if (priceData.isIncreasing) {
            _triggerAnimation(pair, Colors.green);
          } else if (priceData.isDecreasing) {
            _triggerAnimation(pair, Colors.red);
          }
        }
      }
    });

    // Listen to loading status
    forexService.loadingStream.listen((isLoading) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = isLoading;
      });
    });
  }

  // Method to handle refresh
  Future<void> _refreshData() async {
    await _forexServiceProvider.forexService
        .fetchLatestRates(forceRefresh: true);
    //return Future.value();
  }

  void _triggerAnimation(String pair, Color targetColor) {
    if (_colorControllers.containsKey(pair)) {
      final controller = _colorControllers[pair]!;
      controller.reset();
      controller.forward();
    }
  }

  void _filterPairs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPairs = forexPairs;
      } else {
        _filteredPairs = forexPairs
            .where((pair) => pair.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    // Clean up resources
    for (var controller in _colorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex Calculator'),
        centerTitle: true,
        actions: [
          // Last updated indicator in app bar
          StreamBuilder<Map<String, ForexPrice>>(
              stream: _forexServiceProvider.forexService.priceStream,
              builder: (context, snapshot) {
                final lastFetch = _forexServiceProvider.forexService.lastFetchTime;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      lastFetch != null
                          ? 'Updated: ${_formatTimestamp(lastFetch)}'
                          : 'Loading...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
        ],
      ),
      body: Column(
        children: [
          // Selected Pair Display
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selected Pair: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _selectedPair,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: _filterPairs,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search currency pairs...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Currency Pairs List with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredPairs.length,
                  itemBuilder: (context, index) {
                    final pair = _filteredPairs[index];
                    final normalizedPair = pair.replaceAll('/', '');
                    final isSelected = normalizedPair == _selectedPair;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPair = normalizedPair;
                        });
                        Provider.of<CalculatorProvider>(context, listen: false)
                            .setSelectedPair(normalizedPair);
                        showDialog(
                          context: context,
                          builder: (context) => CalculatorDialog(),
                        );
                      },
                      child: Card(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pair,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  if (_currentPrices
                                      .containsKey(normalizedPair)) {
                                    final priceData =
                                        _currentPrices[normalizedPair]!;
                                    Color priceColor;
                                    if (priceData.isIncreasing) {
                                      priceColor = Colors.green;
                                    } else if (priceData.isDecreasing) {
                                      priceColor = Colors.red;
                                    } else {
                                      priceColor = isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.grey;
                                    }
                                    return Column(
                                      children: [
                                        Text(
                                          priceData.price.toStringAsFixed(5),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : priceColor,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: MiniSparklineChart(
                                            priceHistory:
                                                priceData.priceHistory,
                                            isSelected: isSelected,
                                            color: isSelected
                                                ? Colors.white
                                                : priceColor,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              priceData.isIncreasing
                                                  ? Icons.arrow_upward
                                                  : priceData.isDecreasing
                                                      ? Icons.arrow_downward
                                                      : Icons.remove,
                                              color: isSelected
                                                  ? Colors.white
                                                  : priceColor,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${(((priceData.price / priceData.previousPrice) - 1) * 100).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected
                                                    ? Colors.white
                                                    : priceColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Show placeholder if no data is available yet
                                    return Text(
                                      "Loading...",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
