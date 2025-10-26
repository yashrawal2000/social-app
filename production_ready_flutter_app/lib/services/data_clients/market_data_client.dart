import 'dart:convert';

import 'package:http/http.dart' as http;

class TimeSeriesPoint {
  const TimeSeriesPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class MarketDataClient {
  MarketDataClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static final Map<String, String> _symbolOverrides = {
    'BTC': 'btc.usd',
    'ETH': 'eth.usd',
    'USDC': 'usdc.usd',
    'GLD': 'gld.us',
    'BND': 'bnd.us',
    'EMB': 'emb.us',
    'TSLA': 'tsla.us',
  };

  static final Map<String, List<TimeSeriesPoint>> _fallbackSeries = {
    'AAPL': _buildFallback(
      symbol: 'AAPL',
      baseDate: DateTime(2024, 6, 10),
      closes: [173.2, 175.8, 179.4, 181.1, 184.6, 186.3, 188.1, 189.4, 191.2, 193.0],
    ),
    'MSFT': _buildFallback(
      symbol: 'MSFT',
      baseDate: DateTime(2024, 6, 10),
      closes: [312.1, 315.5, 318.9, 322.6, 324.2, 327.8, 329.5, 331.2, 333.8, 336.1],
    ),
    'BND': _buildFallback(
      symbol: 'BND',
      baseDate: DateTime(2024, 6, 10),
      closes: [74.2, 74.6, 75.1, 75.4, 75.9, 76.3, 76.5, 76.8, 77.1, 77.4],
    ),
    'GLD': _buildFallback(
      symbol: 'GLD',
      baseDate: DateTime(2024, 6, 10),
      closes: [181.0, 182.6, 183.9, 185.5, 187.4, 188.2, 189.1, 190.3, 191.8, 193.4],
    ),
    'BTC': _buildFallback(
      symbol: 'BTC',
      baseDate: DateTime(2024, 6, 10),
      closes: [61200, 62450, 63580, 64720, 65310, 66440, 67210, 68350, 69200, 70510],
    ),
    'ETH': _buildFallback(
      symbol: 'ETH',
      baseDate: DateTime(2024, 6, 10),
      closes: [2980, 3025, 3090, 3160, 3225, 3295, 3340, 3395, 3440, 3515],
    ),
    'TSLA': _buildFallback(
      symbol: 'TSLA',
      baseDate: DateTime(2024, 6, 10),
      closes: [245, 248.6, 252.4, 255.5, 259.1, 262.8, 265.9, 268.4, 271.0, 273.6],
    ),
    'EMB': _buildFallback(
      symbol: 'EMB',
      baseDate: DateTime(2024, 6, 10),
      closes: [88.2, 88.6, 89.0, 89.5, 89.8, 90.3, 90.8, 91.1, 91.5, 91.9],
    ),
    'USDC': _buildFallback(
      symbol: 'USDC',
      baseDate: DateTime(2024, 6, 10),
      closes: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
    ),
  };

  Future<List<TimeSeriesPoint>> fetchDailySeries(String symbol) async {
    final override = _symbolOverrides[symbol.toUpperCase()];
    final querySymbol = override ?? '${symbol.toLowerCase()}.us';
    final uri = Uri.https('stooq.com', '/q/d/l/', {'s': querySymbol, 'i': 'd'});
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to download time series');
      }
      final series = _parseCsv(response.body);
      if (series.isEmpty) {
        throw Exception('Empty series');
      }
      return series;
    } catch (_) {
      final fallback = _fallbackSeries[symbol.toUpperCase()];
      if (fallback != null) {
        return fallback;
      }
      return const [];
    }
  }

  static List<TimeSeriesPoint> _parseCsv(String csv) {
    final lines = const LineSplitter().convert(csv.trim());
    if (lines.length <= 1) {
      return const [];
    }
    final points = <TimeSeriesPoint>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 6) continue;
      final date = DateTime.tryParse(parts[0]);
      if (date == null) continue;
      final open = double.tryParse(parts[1]) ?? 0;
      final high = double.tryParse(parts[2]) ?? open;
      final low = double.tryParse(parts[3]) ?? open;
      final close = double.tryParse(parts[4]) ?? open;
      final volume = double.tryParse(parts[5]) ?? 0;
      points.add(
        TimeSeriesPoint(
          date: date,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  static List<TimeSeriesPoint> _buildFallback({
    required String symbol,
    required DateTime baseDate,
    required List<double> closes,
  }) {
    return List<TimeSeriesPoint>.generate(closes.length, (index) {
      final date = baseDate.add(Duration(days: index));
      final close = closes[index];
      return TimeSeriesPoint(
        date: date,
        open: close * 0.98,
        high: close * 1.01,
        low: close * 0.99,
        close: close,
        volume: 1,
      );
    });
  }
}
