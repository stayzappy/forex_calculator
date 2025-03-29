// calculator_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/calculator_provider_service.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({Key? key}) : super(key: key);

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  late TextEditingController _riskController;
  late TextEditingController _pipController;
  late TextEditingController _lotController;
  bool _isUpdating = false;
  /////////////////////////////////////////

  double _currentRisk = 0.0;
  double _currentPip = 0.0;
  double _currentLot = 0.0;

  @override
  void initState() {
    super.initState();
    _riskController = TextEditingController();
    _pipController = TextEditingController();
    _lotController = TextEditingController();
    // Initialize with values from provider
    final calculator = Provider.of<CalculatorProvider>(context, listen: false);
    if (calculator.riskAmount > 0) {
      _riskController.text = calculator.riskAmount.toStringAsFixed(2);
    }
    if (calculator.pipToRisk > 0) {
      _pipController.text = calculator.pipToRisk.toStringAsFixed(2);
    }
    if (calculator.lotSize > 0) {
      _lotController.text = calculator.lotSize.toStringAsFixed(2);
    }
    // Add listeners
    _riskController.addListener(_updateFromRiskChange);
    _pipController.addListener(_updateFromPipChange);
    _lotController.addListener(_updateFromLotChange);
  }

  void _updateFromRiskChange() {
    if (_isUpdating || _riskController.text.isEmpty) return;
    _isUpdating = true;

    final calculator = Provider.of<CalculatorProvider>(context, listen: false);
    double value = double.tryParse(_riskController.text) ?? 0;
    calculator.setRiskAmount(value);

    // Update the field that was calculated
    String fieldToUpdate = calculator.getFieldToCalculate();
    if (fieldToUpdate == 'pip' && calculator.pipToRisk > 0) {
      _pipController.text = calculator.pipToRisk.toStringAsFixed(2);
    } else if (fieldToUpdate == 'lot' && calculator.lotSize > 0) {
      _lotController.text = calculator.lotSize.toStringAsFixed(2);
    }

    _isUpdating = false;
  }

  void _updateFromPipChange() {
    if (_isUpdating || _pipController.text.isEmpty) return;
    _isUpdating = true;

    final calculator = Provider.of<CalculatorProvider>(context, listen: false);
    double value = double.tryParse(_pipController.text) ?? 0;
    calculator.setPipToRisk(value);

    // Update the field that was calculated
    String fieldToUpdate = calculator.getFieldToCalculate();
    if (fieldToUpdate == 'risk' && calculator.riskAmount > 0) {
      _riskController.text = calculator.riskAmount.toStringAsFixed(2);
    } else if (fieldToUpdate == 'lot' && calculator.lotSize > 0) {
      _lotController.text = calculator.lotSize.toStringAsFixed(2);
    }

    _isUpdating = false;
  }

  void _updateFromLotChange() {
    if (_isUpdating || _lotController.text.isEmpty) return;
    _isUpdating = true;

    final calculator = Provider.of<CalculatorProvider>(context, listen: false);
    double value = double.tryParse(_lotController.text) ?? 0;
    calculator.setLotSize(value);

    // Update the field that was calculated
    String fieldToUpdate = calculator.getFieldToCalculate();
    if (fieldToUpdate == 'risk' && calculator.riskAmount > 0) {
      _riskController.text = calculator.riskAmount.toStringAsFixed(2);
    } else if (fieldToUpdate == 'pip' && calculator.pipToRisk > 0) {
      _pipController.text = calculator.pipToRisk.toStringAsFixed(2);
    }

    _isUpdating = false;
  }

  void _resetAllFields() {
    final calculator = Provider.of<CalculatorProvider>(context, listen: false);
    calculator.resetCalculator();
    setState(() {
      _isUpdating = true;
      _riskController.text = '';
      _pipController.text = '';
      _lotController.text = '';
      _isUpdating = false;
    });
  }

  @override
  void dispose() {
    _riskController.removeListener(_updateFromRiskChange);
    _pipController.removeListener(_updateFromPipChange);
    _lotController.removeListener(_updateFromLotChange);
    _riskController.dispose();
    _pipController.dispose();
    _lotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculator = Provider.of<CalculatorProvider>(context);
    final ThemeData theme = Theme.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isUpdating) {
        _isUpdating = true;

        // Only update if text doesn't match
        if (_riskController.text !=
                (calculator.riskAmount > 0
                    ? calculator.riskAmount.toStringAsFixed(2)
                    : '') &&
            _riskController.text.isEmpty) {
          _riskController.text = calculator.riskAmount > 0
              ? calculator.riskAmount.toStringAsFixed(2)
              : '';
        }

        if (_pipController.text !=
                (calculator.pipToRisk > 0
                    ? calculator.pipToRisk.toStringAsFixed(2)
                    : '') &&
            _pipController.text.isEmpty) {
          _pipController.text = calculator.pipToRisk > 0
              ? calculator.pipToRisk.toStringAsFixed(2)
              : '';
        }

        if (_lotController.text !=
                (calculator.lotSize > 0
                    ? calculator.lotSize.toStringAsFixed(2)
                    : '') &&
            _lotController.text.isEmpty) {
          _lotController.text = calculator.lotSize > 0
              ? calculator.lotSize.toStringAsFixed(2)
              : '';
        }

        _isUpdating = false;
      }
    });
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surface
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Forex Calculator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey),
                    onPressed: () {
                      _resetAllFields();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              // Selected pair display
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    calculator.selectedPair,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),

              // In _CalculatorDialogState class:

// Replace the onChanged handlers in the build method:

// Risk Amount Input
              _buildInputField(context, 'Risk Amount', 'USD', _riskController),
                (SizedBox(height: 16)),
// Pip to Risk Input
              _buildInputField(
                  context, 'Pips to Risk (SL)', 'pips', _pipController),
                (SizedBox(height:16)),
// Lot Size Input
              _buildInputField(context, 'Lot Size', 'lots', _lotController),

              SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _resetAllFields(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Reset',
                        style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87)),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      _resetAllFields();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Done', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // In calculator_dialog.dart, modify the _buildInputField method:
    Widget _buildInputField(
    BuildContext context,
    String label,
    String unit,
    TextEditingController controller,
  ) {
    final ThemeData theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.brightness == Brightness.dark 
              ? Colors.white70 
              : Colors.grey[700],
          ),
        ),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
              ? Colors.grey[800] 
              : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.brightness == Brightness.dark 
                ? Colors.grey[700]! 
                : Colors.grey[300]!
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87
                  ),
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: theme.brightness == Brightness.dark 
                        ? Colors.white54 
                        : Colors.grey
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
