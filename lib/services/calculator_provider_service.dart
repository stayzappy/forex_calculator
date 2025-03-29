import 'package:flutter/material.dart';
import '../models/forex_price_data.dart';

class CalculatorProvider extends ChangeNotifier {
  String _selectedPair = 'EURUSD';

  // Calculator fields
  double _riskAmount = 0.0;
  double _pipToRisk = 0.0;
  double _lotSize = 0.0;

  // Getters
  String get selectedPair => _selectedPair;
  double get riskAmount => _riskAmount;
  double get pipToRisk => _pipToRisk;
  double get lotSize => _lotSize;

  // Keep track of which fields were most recently edited
List<String> _editOrder = ['risk', 'pip', 'lot']; // Default order

void _updateEditOrder(String fieldName) {
  _editOrder.remove(fieldName);
  _editOrder.add(fieldName); // Move to end (most recent)
}

// Returns the name of the least recently edited field
String get _fieldToCalculate {
  return _editOrder[0]; // First item is least recently edited
}

String getFieldToCalculate() {
  return _editOrder[0]; // First item is least recently edited
}
  // Setters with calculations
  void setSelectedPair(String pair) {
    _selectedPair = pair;
    notifyListeners();
  }

void setRiskAmount(double value) {
  _riskAmount = value;
  _updateEditOrder('risk');
  
  // Determine which field to calculate
  String fieldToCalculate = _fieldToCalculate;
  if (fieldToCalculate == 'pip' && _lotSize > 0 && _riskAmount > 0) {
    _pipToRisk = _calculatePipToRisk(_riskAmount, _lotSize);
  } else if (fieldToCalculate == 'lot' && _pipToRisk > 0 && _riskAmount > 0) {
    _lotSize = _calculateLotSize(_riskAmount, _pipToRisk);
  }
  
  notifyListeners();
}

void setPipToRisk(double value) {
  _pipToRisk = value;
  _updateEditOrder('pip');
  
  // Determine which field to calculate
  String fieldToCalculate = _fieldToCalculate;
  if (fieldToCalculate == 'risk' && _pipToRisk > 0 && _lotSize > 0) {
    _riskAmount = _calculateRiskAmount(_pipToRisk, _lotSize);
  } else if (fieldToCalculate == 'lot' && _pipToRisk > 0 && _riskAmount > 0) {
    _lotSize = _calculateLotSize(_riskAmount, _pipToRisk);
  }
  
  notifyListeners();
}

void setLotSize(double value) {
  _lotSize = value;
  _updateEditOrder('lot');
  
  // Determine which field to calculate
  String fieldToCalculate = _fieldToCalculate;
  if (fieldToCalculate == 'risk' && _pipToRisk > 0 && _lotSize > 0) {
    _riskAmount = _calculateRiskAmount(_pipToRisk, _lotSize);
  } else if (fieldToCalculate == 'pip' && _riskAmount > 0 && _lotSize > 0) {
    _pipToRisk = _calculatePipToRisk(_riskAmount, _lotSize);
  }
  
  notifyListeners();
}
  // Formula to calculate lot size
 double _calculateLotSize(double riskAmount, double pipToRisk) {
  if (pipToRisk <= 0) return 0;
  double pipValue = _getPipValue(_selectedPair);
  return (riskAmount / (pipToRisk * pipValue)).abs();  // Use abs to ensure positive value
}

double _calculatePipToRisk(double riskAmount, double lotSize) {
  if (lotSize <= 0) return 0;
  double pipValue = _getPipValue(_selectedPair);
  return (riskAmount / (lotSize * pipValue)).abs();  // Use abs to ensure positive value
}

double _calculateRiskAmount(double pipToRisk, double lotSize) {
  if (pipToRisk <= 0 || lotSize <= 0) return 0;
  double pipValue = _getPipValue(_selectedPair);
  return (pipToRisk * lotSize * pipValue).abs();  // Use abs to ensure positive value
}

  double _getPipValue(String pair) {
    // USD pairs
    if (['XAUUSD', 'EURUSD', 'GBPUSD', 'BTCUSD', 'AUDUSD', 'NZDUSD']
        .contains(pair)) {
      return 10.0;
    }
    // JPY pairs
    else if ([
      'EURJPY',
      'GBPJPY',
      'USDJPY',
      'NZDJPY',
      'AUDJPY',
      'CHFJPY',
      'CADJPY'
    ].contains(pair)) {
      return 6.7;
    }
    // AUD pairs
    else if (['EURAUD', 'GBPAUD'].contains(pair)) {
      return 6.36;
    }
    // CAD pairs
    else if (['USDCAD', 'AUDCAD', 'NZDCAD', 'EURCAD', 'GBPCAD']
        .contains(pair)) {
      return 6.99;
    }
    // CHF pairs
    else if (['USDCHF', 'AUDCHF', 'NZDCHF', 'EURCHF', 'GBPCHF']
        .contains(pair)) {
      return 11.4;
    }
    // NZD pairs
    else if (['GBPNZD', 'EURNZD',]
        .contains(pair)) {
      return 5.72;
    }
    // AUDNZD specific
    else if (pair == 'AUDNZD') {
      return 5.82;
    }
    // EURGBP specific
    else if (pair == 'EURGBP') {
      return 13.0;
    }
    // Default fallback
    return 10.0;
  }

  

  // Reset all fields
  void resetCalculator() {
  _riskAmount = 0.0;
  _pipToRisk = 0.0;
  _lotSize = 0.0;
  _editOrder = ['risk', 'pip', 'lot']; // Reset edit order
  notifyListeners();
}
}
class ForexServiceProvider with ChangeNotifier {
  static final ForexServiceProvider _instance = ForexServiceProvider._internal();
  factory ForexServiceProvider() => _instance;
  
  ForexServiceProvider._internal() {
    _forexService.init();
  }

  final CurrencyLayerService _forexService = CurrencyLayerService();
  
  CurrencyLayerService get forexService => _forexService;
  
  Stream<Map<String, ForexPrice>> get priceStream => _forexService.priceStream;
}
