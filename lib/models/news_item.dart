class NewsItem {
  final String name;
  final String currency;
  final String category;
  final String date;
  final double actual;
  final double forecast;
  final double previous;
  final String outcome;
  final double projection;
  final String strength;
  final String quality;

  NewsItem({
    required this.name,
    required this.currency,
    required this.category,
    required this.date,
    required this.actual,
    required this.forecast,
    required this.previous,
    required this.outcome,
    required this.projection,
    required this.strength,
    required this.quality,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      name: json['Name'] ?? '',
      currency: json['Currency'] ?? '',
      category: json['Category'] ?? '',
      date: json['Date'] ?? '',
      actual: _parseDouble(json['Actual']),
      forecast: _parseDouble(json['Forecast']),
      previous: _parseDouble(json['Previous']),
      outcome: json['Outcome'] ?? '',
      projection: _parseDouble(json['Projection']),
      strength: json['Strength'] ?? '',
      quality: json['Quality'] ?? '',
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
}