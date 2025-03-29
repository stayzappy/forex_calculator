import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forex_calculator/models/news_item.dart';

class NewsService {
  static const String baseUrl = 'https://www.jblanked.com/news/api/forex-factory/calendar/today/';
  static const String apiKey = 'BCobJHxg.Y0NnKSDGY564Oj0YqNPKzUKCjFwXP0gP';
  static const String _newsCacheKey = 'cached_news_items';

  Future<List<NewsItem>> fetchNews() async {
    try {
      final url = Uri.parse(baseUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Api-Key $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final newsItems = jsonData.map((json) => NewsItem.fromJson(json)).toList();
        
        // Cache the successful news fetch
        await _cacheNewsItems(newsItems);
        
        return newsItems;
      } else {
        // If network request fails, try to fetch cached data
        return await _getCachedNewsItems();
      }
    } catch (e) {
      // On any error, attempt to retrieve cached data
      return await _getCachedNewsItems();
    }
  }

  // Cache news items to SharedPreferences
  Future<void> _cacheNewsItems(List<NewsItem> newsItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert NewsItems to JSON strings
      final jsonList = newsItems.map((item) => jsonEncode({
        'name': item.name,
        'currency': item.currency,
        'category': item.category,
        'date': item.date,
        'actual': item.actual,
        'forecast': item.forecast,
        'previous': item.previous,
        'outcome': item.outcome,
        'projection': item.projection,
        'strength': item.strength,
        'quality': item.quality,
      })).toList();

      await prefs.setStringList(_newsCacheKey, jsonList);
    } catch (e) {
      print('Error caching news items: $e');
    }
  }

  // Retrieve cached news items
  Future<List<NewsItem>> _getCachedNewsItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedItems = prefs.getStringList(_newsCacheKey);

      if (cachedItems != null && cachedItems.isNotEmpty) {
        return cachedItems.map((jsonString) {
          final Map<String, dynamic> json = jsonDecode(jsonString);
          return NewsItem(
            name: json['name'],
            currency: json['currency'],
            category: json['category'],
            date: json['date'],
            actual: json['actual'],
            forecast: json['forecast'],
            previous: json['previous'],
            outcome: json['outcome'],
            projection: json['projection'],
            strength: json['strength'],
            quality: json['quality'],
          );
        }).toList();
      }

      // Return empty list if no cached items
      return [];
    } catch (e) {
      print('Error retrieving cached news items: $e');
      return [];
    }
  }

  // Optional method to clear cache
  Future<void> clearNewsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_newsCacheKey);
  }
}