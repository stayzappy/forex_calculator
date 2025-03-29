import 'package:flutter/material.dart';
import '../services/news_service.dart';
import 'package:intl/intl.dart';
import '../models/news_item.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsItem>> _newsFuture;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews();
  }

   void _loadNews() {
    setState(() {
      _newsFuture = _newsService.fetchNews().then((newsItems) {
        // Check if we got any items
        if (newsItems.isEmpty) {
          setState(() {
            _isOfflineMode = true;
          });
        } else {
          setState(() {
            _isOfflineMode = false;
          });
        }
        return newsItems;
      }).catchError((error) {
        setState(() {
          _isOfflineMode = true;
        });
        return <NewsItem>[]; // Return empty list to prevent crash
      });
    });
  }

  Future<void> _refreshNews() async {
    _loadNews();
  }

  String _formatDateTime(String dateString) {
    try {
      // Parse the date string in the format "yyyy.MM.dd HH:mm:ss"
      final dateTime = DateTime.parse(dateString.replaceAll('.', '-'));
      return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economic Calendar'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        child: FutureBuilder<List<NewsItem>>(
          future: _newsFuture,
          builder: (context, snapshot) {
             if (_isOfflineMode) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Offline Mode - Showing Cached Data'),
                    ElevatedButton(
                      onPressed: _loadNews,
                      child: Text('Retry Connection'),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshNews,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No economic events available'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.currency,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(item.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Category: ${item.category}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _impactIndicator(item.strength),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _valueColumn('Actual', item.actual.toString(),
                                      Colors.blue),
                                  _valueColumn('Forecast',
                                      item.forecast.toString(), Colors.orange),
                                  _valueColumn('Previous',
                                      item.previous.toString(), Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        //const SizedBox(height: 8),
                        if (item.outcome != "Data Not Loaded") ...[
                        Text(
                          'Outcome: ${item.outcome}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Upcoming Event',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                        if (item.projection > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Projection: ${item.projection}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _valueColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _impactIndicator(String strength) {
    int bars = 1;
    Color color = Colors.green;

    switch (strength.toLowerCase()) {
      case 'strong data':
        bars = 3;
        color = Colors.red;
        break;
      case 'neutral data':
        bars = 2;
        color = Colors.amber;
        break;
      case 'weak data':
        bars = 1;
        color = Colors.blue;
        break;
    }

    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 4,
          height: 16 + (index * 4), // Progressively taller bars
          decoration: BoxDecoration(
            color: index < bars ? color : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _indicatorChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStrengthColor(String strength) {
    switch (strength.toLowerCase()) {
      case 'strong data':
        return Colors.green;
      case 'weak data':
        return Colors.red;
      case 'neutral data':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good data':
        return Colors.green;
      case 'bad data':
        return Colors.red;
      case 'neutral data':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
