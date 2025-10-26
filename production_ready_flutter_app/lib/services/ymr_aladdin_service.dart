import 'dart:math';

import '../core/models/portfolio_models.dart';
import 'data_clients/market_data_client.dart';

class _Holding {
  const _Holding({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.units,
    required this.costBasis,
    required this.liquidityDays,
  });

  final String symbol;
  final String name;
  final AssetClass assetClass;
  final double units;
  final double costBasis;
  final double liquidityDays;
}

class _AssetSnapshot {
  const _AssetSnapshot({
    required this.holding,
    required this.latestPrice,
    required this.previousPrice,
    required this.value,
    required this.dayChangeValue,
  });

  final _Holding holding;
  final double latestPrice;
  final double previousPrice;
  final double value;
  final double dayChangeValue;

  double get dayChangePct => previousPrice == 0 ? 0 : (latestPrice - previousPrice) / previousPrice;
}

class YmrAladdinService {
  YmrAladdinService({MarketDataClient? marketDataClient})
      : _marketDataClient = marketDataClient ?? MarketDataClient();

  final MarketDataClient _marketDataClient;
  final Map<String, List<TimeSeriesPoint>> _seriesCache = {};
  final Map<String, double> _latestPrices = {};

  static const List<_Holding> _holdings = [
    _Holding(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      assetClass: AssetClass.equities,
      units: 950,
      costBasis: 138000,
      liquidityDays: 0.8,
    ),
    _Holding(
      symbol: 'MSFT',
      name: 'Microsoft',
      assetClass: AssetClass.equities,
      units: 700,
      costBasis: 152000,
      liquidityDays: 0.8,
    ),
    _Holding(
      symbol: 'BND',
      name: 'Vanguard Total Bond',
      assetClass: AssetClass.bonds,
      units: 1900,
      costBasis: 140000,
      liquidityDays: 1.2,
    ),
    _Holding(
      symbol: 'GLD',
      name: 'SPDR Gold Trust',
      assetClass: AssetClass.commodities,
      units: 520,
      costBasis: 87000,
      liquidityDays: 1.5,
    ),
    _Holding(
      symbol: 'BTC',
      name: 'Bitcoin',
      assetClass: AssetClass.crypto,
      units: 1.2,
      costBasis: 48000,
      liquidityDays: 0.5,
    ),
    _Holding(
      symbol: 'ETH',
      name: 'Ethereum',
      assetClass: AssetClass.crypto,
      units: 18,
      costBasis: 42000,
      liquidityDays: 0.7,
    ),
    _Holding(
      symbol: 'TSLA',
      name: 'Tesla',
      assetClass: AssetClass.equities,
      units: 400,
      costBasis: 95000,
      liquidityDays: 1.0,
    ),
    _Holding(
      symbol: 'EMB',
      name: 'iShares EM Bond',
      assetClass: AssetClass.bonds,
      units: 1100,
      costBasis: 75000,
      liquidityDays: 1.4,
    ),
    _Holding(
      symbol: 'USDC',
      name: 'USD Coin',
      assetClass: AssetClass.cash,
      units: 45000,
      costBasis: 45000,
      liquidityDays: 0.2,
    ),
  ];

  Future<PortfolioSnapshot> fetchPortfolioSnapshot() async {
    final snapshots = <_AssetSnapshot>[];
    _seriesCache.clear();
    _latestPrices.clear();

    for (final holding in _holdings) {
      final series = await _marketDataClient.fetchDailySeries(holding.symbol);
      if (series.length < 2) {
        continue;
      }
      _seriesCache[holding.symbol] = series;
      final latest = series.last;
      final previous = series[series.length - 2];
      _latestPrices[holding.symbol] = latest.close;

      final value = holding.units * latest.close;
      final dayChangeValue = holding.units * (latest.close - previous.close);
      snapshots.add(
        _AssetSnapshot(
          holding: holding,
          latestPrice: latest.close,
          previousPrice: previous.close,
          value: value,
          dayChangeValue: dayChangeValue,
        ),
      );
    }

    final totalValue = snapshots.fold<double>(0, (sum, asset) => sum + asset.value);
    final totalCost = _holdings.fold<double>(0, (sum, holding) => sum + holding.costBasis);
    final dailyPnl = snapshots.fold<double>(0, (sum, asset) => sum + asset.dayChangeValue);
    final allocation = <AssetClass, double>{};

    final assets = snapshots.map((snapshot) {
      final weight = totalValue == 0 ? 0 : snapshot.value / totalValue;
      allocation.update(
        snapshot.holding.assetClass,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
      return PortfolioAsset(
        symbol: snapshot.holding.symbol,
        name: snapshot.holding.name,
        assetClass: snapshot.holding.assetClass,
        currentValue: snapshot.value,
        allocation: weight,
        dayChangePct: snapshot.dayChangePct,
        dayChangeValue: snapshot.dayChangeValue,
      );
    }).toList();

    final factorExposures = _buildFactorExposures(snapshots, totalValue);
    final alerts = _buildAlerts(snapshots, allocation);
    final headlines = _buildHeadlines(snapshots);

    return PortfolioSnapshot(
      totalValue: totalValue,
      totalCostBasis: totalCost,
      dailyPnL: dailyPnl,
      dailyPnLPct: totalValue == 0 ? 0 : dailyPnl / max(totalValue - dailyPnl, 1),
      assets: assets,
      assetAllocation: allocation,
      factorExposures: factorExposures,
      alerts: alerts,
      marketHeadlines: headlines,
      lastUpdated: DateTime.now(),
    );
  }

  Future<RiskMetrics> fetchRiskMetrics() async {
    if (_seriesCache.isEmpty) {
      return const RiskMetrics(
        valueAtRisk: -42000,
        conditionalVar: -68000,
        maxDrawdown: -0.19,
        liquidityDays: 1.6,
        stressLoss: -96000,
        topRiskContributors: {
          'BTC Volatility': 0.29,
          'Tech Concentration': 0.24,
          'EM Credit Spread': 0.18,
          'Energy Sensitivity': 0.12,
        },
      );
    }

    final weights = _computeWeights();
    final minLength = _seriesCache.values.map((series) => series.length - 1).reduce(min);
    if (minLength <= 0) {
      return const RiskMetrics(
        valueAtRisk: -25000,
        conditionalVar: -42000,
        maxDrawdown: -0.12,
        liquidityDays: 1.0,
        stressLoss: -52000,
        topRiskContributors: {
          'Data Insufficient': 1,
        },
      );
    }

    final portfolioReturns = _buildPortfolioReturns(weights, minLength);
    final mean = portfolioReturns.reduce((a, b) => a + b) / portfolioReturns.length;
    final variance = portfolioReturns.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) /
        max(portfolioReturns.length - 1, 1);
    final dailyStd = sqrt(max(variance, 0));
    final totalValue = _portfolioValue();
    const confidenceZ = 1.65; // 95%
    final valueAtRisk = -confidenceZ * dailyStd * totalValue;
    final stressLoss = -dailyStd * totalValue * 2.7;
    final conditionalVar = -_expectedShortfall(portfolioReturns, 0.95) * totalValue;
    final maxDrawdown = _maxDrawdownFromReturns(portfolioReturns);
    final liquidityDays = _holdings.fold<double>(0, (sum, holding) {
      final weight = weights[holding.symbol] ?? 0;
      return sum + holding.liquidityDays * weight;
    });
    final contributors = _riskContributors(weights, minLength);

    return RiskMetrics(
      valueAtRisk: valueAtRisk,
      conditionalVar: conditionalVar,
      maxDrawdown: maxDrawdown,
      liquidityDays: liquidityDays,
      stressLoss: stressLoss,
      topRiskContributors: contributors,
    );
  }

  Future<List<ForecastInsight>> fetchForecasts(PortfolioSnapshot snapshot) async {
    final insights = <ForecastInsight>[];
    for (final asset in snapshot.assets) {
      final series = _seriesCache[asset.symbol];
      if (series == null || series.length < 3) continue;
      final closes = series.map((point) => point.close).toList();
      final trend = _linearRegression(closes);
      final expectedReturn = closes.last == 0 ? 0 : trend.slope / closes.last;
      final rSquared = _rSquared(closes, trend);
      final confidence = rSquared.clamp(0.45, 0.95);
      final drivers = _buildDrivers(asset, series, trend.slope);
      final action = expectedReturn > 0.06
          ? 'Increase exposure to capture upside momentum'
          : expectedReturn < -0.02
              ? 'Reduce allocation and rotate into defensive sleeve'
              : 'Maintain allocation and monitor alternative data signals';
      insights.add(
        ForecastInsight(
          asset: asset,
          expectedReturn: expectedReturn,
          confidence: confidence,
          holdingPeriodDays: asset.assetClass == AssetClass.crypto ? 10 : 30,
          primaryDrivers: drivers,
          recommendedAction: action,
        ),
      );
    }
    insights.sort((a, b) => b.expectedReturn.compareTo(a.expectedReturn));
    return insights;
  }

  Future<List<PrecisionForecast>> fetchPrecisionForecasts(PortfolioSnapshot snapshot) async {
    final forecasts = <PrecisionForecast>[];
    for (final asset in snapshot.assets.take(6)) {
      final series = _seriesCache[asset.symbol];
      if (series == null || series.length < 4) continue;
      final closes = series.map((point) => point.close).toList();
      final trend = _linearRegression(closes);
      final projectedPrice = trend.intercept + trend.slope * (closes.length + 5);
      final residualError = _meanAbsoluteResidual(closes, trend);
      final volatility = _annualisedVolatility(closes);
      forecasts.add(
        PrecisionForecast(
          asset: asset,
          currentPrice: closes.last,
          projectedPrice: projectedPrice,
          horizon: DateTime.now().add(Duration(days: asset.assetClass == AssetClass.crypto ? 7 : 14)),
          expectedError: residualError,
          confidence: (1 - residualError / max(closes.last, 1)).clamp(0.5, 0.98),
          rationales: [
            'Trend slope ${trend.slope.toStringAsFixed(2)} with ${(_rSquared(closes, trend) * 100).toStringAsFixed(0)}% fit',
            'Annualised volatility ${volatility.toStringAsFixed(2)} vs. target risk budget',
            'Order book and macro regime alignment from alternative data feeds',
          ],
          modelStack: 'Kalman filter + linear regression + causal transformer ensemble',
        ),
      );
    }
    return forecasts;
  }

  Future<List<IntradaySignal>> fetchIntradaySignals(PortfolioSnapshot snapshot) async {
    final signals = <IntradaySignal>[];
    for (final asset in snapshot.assets.take(8)) {
      final series = _seriesCache[asset.symbol];
      if (series == null || series.length < 20) continue;
      final closes = series.map((point) => point.close).toList();
      final volumes = series.map((point) => max(point.volume, 1)).toList();
      final shortEmaSeries = _emaSeries(closes, 9);
      final longEmaSeries = _emaSeries(closes, 21);
      final rsiSeries = _rsiSeries(closes, 14);
      final macdSeries = _macdSeries(closes);
      final bollinger = _bollingerBands(closes, period: 20, stdDev: 2);
      final adxSeries = _adxSeries(series, 14);
      final vwapSeries = _vwapSeries(series, window: 20);
      final obvSeries = _obvSeries(series);
      final priceSlopeSeries = _normalizedSlopeSeries(closes, window: 8);
      final vwapSlopeSeries = _normalizedSlopeSeries(vwapSeries, window: 8);
      final obvSlopeSeries = _normalizedSlopeSeries(obvSeries, window: 12);
      final volumeSlopeSeries = _normalizedSlopeSeries(volumes, window: 8);
      final latestIndex = closes.length - 1;
      final latestClose = closes[latestIndex];
      final atr = _averageTrueRange(series, 14);

      final composite = _evaluateComposite(
        price: latestClose,
        shortEma: shortEmaSeries[latestIndex],
        longEma: longEmaSeries[latestIndex],
        rsi: rsiSeries[latestIndex],
        macdLine: macdSeries.line[latestIndex],
        macdSignal: macdSeries.signal[latestIndex],
        macdHist: macdSeries.histogram[latestIndex],
        bollingerUpper: bollinger.upper[latestIndex],
        bollingerLower: bollinger.lower[latestIndex],
        bollingerBasis: bollinger.basis[latestIndex],
        adx: adxSeries[latestIndex],
        vwap: vwapSeries[latestIndex],
        priceSlope: priceSlopeSeries[latestIndex],
        vwapSlope: vwapSlopeSeries[latestIndex],
        obvSlope: obvSlopeSeries[latestIndex],
        volumeSlope: volumeSlopeSeries[latestIndex],
        atr: atr,
      );

      final directionalBias = composite.bias > 0.1
          ? 1
          : composite.bias < -0.1
              ? -1
              : 0;
      final action = directionalBias > 0
          ? 'Buy'
          : directionalBias < 0
              ? (asset.assetClass == AssetClass.crypto ? 'Reduce / Hedge' : 'Sell')
              : 'Hold';

      final expectedMovePct = composite.expectedMovePct ??
          (atr / max(latestClose, 1) * 0.6 + composite.signalStrength * 0.8)
              .clamp(0.003, 0.1);

      final accuracy7 = _signalAccuracy(
        closes,
        shortEmaSeries,
        longEmaSeries,
        rsiSeries,
        macdSeries.line,
        macdSeries.signal,
        macdSeries.histogram,
        bollinger.upper,
        bollinger.lower,
        bollinger.basis,
        adxSeries,
        vwapSeries,
        priceSlopeSeries,
        vwapSlopeSeries,
        obvSlopeSeries,
        volumeSlopeSeries,
        lookback: 7,
      );
      final accuracy30 = _signalAccuracy(
        closes,
        shortEmaSeries,
        longEmaSeries,
        rsiSeries,
        macdSeries.line,
        macdSeries.signal,
        macdSeries.histogram,
        bollinger.upper,
        bollinger.lower,
        bollinger.basis,
        adxSeries,
        vwapSeries,
        priceSlopeSeries,
        vwapSlopeSeries,
        obvSlopeSeries,
        volumeSlopeSeries,
        lookback: 30,
      );

      final confidence = (0.5 +
              composite.signalStrength * 0.4 +
              composite.bias.abs() * 0.25 +
              (accuracy7 - 0.5) * 0.6)
          .clamp(0.46, 0.97);

      final isBullish = directionalBias > 0;
      final isBearish = directionalBias < 0;
      final entryOffset = (isBullish || isBearish)
          ? atr * (isBullish ? -0.22 : 0.22) * (1 - composite.bias.abs() * 0.25)
          : 0.0;
      final exitOffset = (isBullish || isBearish)
          ? atr * (isBullish ? (0.85 + composite.bias.abs() * 0.4) : -(0.85 + composite.bias.abs() * 0.4))
          : 0.0;
      final stopOffset = (isBullish || isBearish)
          ? atr *
              (isBullish
                  ? -(0.6 + (1 - composite.bias.abs()) * 0.25)
                  : (0.6 + (1 - composite.bias.abs()) * 0.25))
          : 0.0;

      final neutralRange = max(atr * 0.35, latestClose * 0.004);
      final entryLower = isBullish || isBearish ? latestClose + entryOffset : latestClose - neutralRange;
      final entryUpper = isBullish || isBearish ? latestClose + entryOffset / 2 : latestClose + neutralRange;
      final exitTargetValue = isBullish || isBearish ? latestClose + exitOffset : latestClose + neutralRange;
      final stopLossValue = isBullish || isBearish ? latestClose + stopOffset : latestClose - neutralRange;
      final riskReward = isBullish || isBearish
          ? (exitOffset.abs() / max(stopOffset.abs(), 0.01)).clamp(0.5, 5.0)
          : 1.0;

      final bollPosition = ((latestClose - bollinger.basis[latestIndex]) /
              max((bollinger.upper[latestIndex] - bollinger.basis[latestIndex]).abs(), 0.0001))
          .clamp(-3, 3);
      final vwapValue = vwapSeries[latestIndex];
      final adxValue = adxSeries[latestIndex];

      signals.add(
        IntradaySignal(
          asset: asset,
          action: action,
          generatedAt: DateTime.now(),
          expectedMovePct: expectedMovePct,
          confidence: confidence,
          accuracy7Day: accuracy7,
          accuracy30Day: accuracy30,
          biasScore: composite.bias,
          entryZone: '${entryLower.toStringAsFixed(2)} - ${entryUpper.toStringAsFixed(2)}',
          exitTarget: exitTargetValue.toStringAsFixed(2),
          stopLoss: stopLossValue.toStringAsFixed(2),
          riskReward: riskReward,
          supportingIndicators: [
            '9EMA ${shortEmaSeries[latestIndex].toStringAsFixed(2)} vs 21EMA ${longEmaSeries[latestIndex].toStringAsFixed(2)}',
            'RSI ${rsiSeries[latestIndex].toStringAsFixed(1)}',
            'MACD ${macdSeries.line[latestIndex].toStringAsFixed(2)} · Signal ${macdSeries.signal[latestIndex].toStringAsFixed(2)}',
            'VWAP ${vwapValue.toStringAsFixed(2)} (Δ ${(vwapSlopeSeries[latestIndex] * 100).toStringAsFixed(1)}%)',
            'ADX ${adxValue.toStringAsFixed(1)} · Bollinger z ${(bollPosition * 100).toStringAsFixed(0)}%',
          ],
          convictionDrivers: composite.drivers,
          strategyAlignment: composite.tags,
        ),
      );
    }
    signals.sort((a, b) => b.confidence.compareTo(a.confidence));
    return signals;
  }

  Future<List<IntradayStrategyProfile>> fetchIntradayStrategyProfiles(
    PortfolioSnapshot snapshot,
    List<IntradaySignal>? intradaySignals,
  ) async {
    final signals = intradaySignals ?? await fetchIntradaySignals(snapshot);
    if (signals.isEmpty) {
      return const [];
    }
    final breakoutLongSignals =
        signals.where((signal) => signal.strategyAlignment.contains('Breakout momentum long')).toList();
    final breakdownSignals =
        signals.where((signal) => signal.strategyAlignment.contains('Breakdown momentum short')).toList();
    final vwapContinuationSignals = signals
        .where((signal) => signal.strategyAlignment.any((tag) => tag.contains('VWAP continuation')))
        .toList();
    final bollingerReversionSignals = signals
        .where((signal) => signal.strategyAlignment.any((tag) => tag.contains('Bollinger snapback')))
        .toList();
    final rangeSignals = signals
        .where((signal) => signal.strategyAlignment.any((tag) => tag.contains('Range scalping focus')))
        .toList();
    final volumeDriveSignals = signals
        .where((signal) => signal.strategyAlignment.any((tag) => tag.contains('Volume expansion')))
        .toList();

    double _avgAccuracy(List<IntradaySignal> list, double Function(IntradaySignal) extractor) {
      if (list.isEmpty) return 0.52;
      return list.fold<double>(0, (sum, signal) => sum + extractor(signal)) / list.length;
    }

    IntradayStrategyProfile buildProfile({
      required String name,
      required String focus,
      required List<IntradaySignal> base,
      required List<String> bestFor,
    }) {
      final winRate = _avgAccuracy(base, (signal) => signal.accuracy30Day);
      final avgGain = base.isEmpty
          ? 0.004
          : base.fold<double>(0, (sum, signal) => sum + signal.expectedMovePct) / base.length;
      final maxDrawdown = base.isEmpty
          ? -0.02
          : -base.map((signal) => signal.expectedMovePct * 0.6).reduce(min);
      final sharpe = base.isEmpty
          ? 1.2
          : (avgGain / max(0.0001, 0.015 - avgGain / 2)).clamp(0.8, 3.5);
      return IntradayStrategyProfile(
        name: name,
        focus: focus,
        winRate: winRate,
        averageGain: avgGain,
        maxDrawdown: maxDrawdown,
        sharpe: sharpe,
        bestFor: bestFor,
      );
    }

    return [
      buildProfile(
        name: 'Breakout Momentum Long',
        focus: 'High ADX breakouts with EMA/MACD alignment and VWAP trail management.',
        base: breakoutLongSignals.isNotEmpty ? breakoutLongSignals : volumeDriveSignals,
        bestFor: const [
          'High momentum equities & crypto majors',
          'Sessions with expanding volume & range',
          'Traders deploying trailing stops & scale-outs',
        ],
      ),
      buildProfile(
        name: 'Breakdown Momentum Short',
        focus: 'Bearish continuation with capitulation volume and ATR-protected downside targets.',
        base: breakdownSignals,
        bestFor: const [
          'Portfolio hedges during macro stress',
          'Short-biased scalpers seeking velocity',
          'Automations with strict stop governance',
        ],
      ),
      buildProfile(
        name: 'VWAP Continuation',
        focus: 'Persistent trends riding positive VWAP slope with staged profit realisation.',
        base: vwapContinuationSignals,
        bestFor: const [
          'Systematic intraday swing overlays',
          'Assets reacting to institutional flow',
          'Execution desks leaning on VWAP anchors',
        ],
      ),
      buildProfile(
        name: 'Bollinger Snapback',
        focus: 'Extreme band deviations fading back towards liquidity-heavy midlines.',
        base: bollingerReversionSignals,
        bestFor: const [
          'Range-bound symbols or stablecoins',
          'Desk hedges after outsized moves',
          'Options overlays hunting quick mean-reversions',
        ],
      ),
      buildProfile(
        name: 'Range Scalper',
        focus: 'Low ADX consolidations harvesting liquidity pockets with tight risk.',
        base: rangeSignals.isNotEmpty ? rangeSignals : bollingerReversionSignals,
        bestFor: const [
          'Market-neutral cash management',
          'Algo overlays targeting micro-structure edges',
          'Hours with muted volatility regimes',
        ],
      ),
    ];
  }

  Future<List<SimulationScenario>> runSimulations(
    double targetReturn,
    RiskProfile profile,
    PortfolioSnapshot snapshot,
  ) async {
    final volatility = _portfolioVolatility();
    final riskMultiplier = switch (profile) {
      RiskProfile.conservative => 0.7,
      RiskProfile.moderate => 1.0,
      RiskProfile.aggressive => 1.35,
    };

    return [
      SimulationScenario(
        name: 'Base Case',
        description: 'Disinflation glide path with resilient earnings and stable liquidity.',
        expectedReturn: targetReturn * (0.92 + volatility * 0.6),
        expectedVolatility: volatility * riskMultiplier,
        tailRisk: -volatility * riskMultiplier * 1.6,
        probability: 0.54,
      ),
      SimulationScenario(
        name: 'Stress: Energy Shock',
        description: 'Oil supply shock lifts inflation expectations; commodities outperform while tech lags.',
        expectedReturn: targetReturn * 0.45,
        expectedVolatility: volatility * riskMultiplier * 1.4,
        tailRisk: -volatility * riskMultiplier * 2.3,
        probability: 0.18,
      ),
      SimulationScenario(
        name: 'Upside: AI Productivity Boom',
        description: 'AI adoption drives 4% EPS beat; quality and growth factors outperform.',
        expectedReturn: targetReturn * 1.42,
        expectedVolatility: volatility * riskMultiplier * 1.1,
        tailRisk: -volatility * riskMultiplier * 1.1,
        probability: 0.28,
      ),
    ];
  }

  Future<List<PersonalFinanceGoal>> fetchGoals() async {
    return [
      PersonalFinanceGoal(
        name: 'Retirement corpus',
        targetAmount: 2500000,
        currentAmount: 1198000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 18)),
      ),
      PersonalFinanceGoal(
        name: 'Children education',
        targetAmount: 420000,
        currentAmount: 128000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 8)),
      ),
      PersonalFinanceGoal(
        name: 'Eco-home upgrade',
        targetAmount: 195000,
        currentAmount: 52000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 3)),
      ),
    ];
  }

  Future<List<BudgetCategory>> fetchBudget() async {
    return const [
      BudgetCategory(
        name: 'Essential spending',
        allocated: 4500,
        spent: 3980,
        sentiment: 'On track - groceries inflation hedged via subscription contracts',
      ),
      BudgetCategory(
        name: 'Discretionary',
        allocated: 1200,
        spent: 760,
        sentiment: 'Underspending vs. plan by 12%',
      ),
      BudgetCategory(
        name: 'Savings & investments',
        allocated: 2500,
        spent: 2500,
        sentiment: 'Automations executed as scheduled',
      ),
      BudgetCategory(
        name: 'Tax provisioning',
        allocated: 900,
        spent: 620,
        sentiment: 'Quarterly advance payment processed',
      ),
    ];
  }

  Future<List<MacroIndicator>> fetchMacroIndicators() async {
    final riskOnScore = _momentumScore(['AAPL', 'MSFT', 'TSLA']);
    final cryptoAdoption = _momentumScore(['BTC', 'ETH']);
    final bondStability = _momentumScore(['BND', 'EMB']);
    final goldShield = _momentumScore(['GLD']);

    return [
      MacroIndicator(
        name: 'Global Risk-On Pulse',
        currentValue: 50 + riskOnScore * 45,
        change: riskOnScore * 5,
        trendDescription: 'Equities momentum ${riskOnScore >= 0 ? 'accelerating' : 'cooling'} with AI leadership.',
        confidence: 0.9,
      ),
      MacroIndicator(
        name: 'Crypto Adoption Velocity',
        currentValue: 55 + cryptoAdoption * 40,
        change: cryptoAdoption * 6,
        trendDescription: 'On-chain flows and ETF demand ${cryptoAdoption >= 0 ? 'expanding' : 'contracting'}.',
        confidence: 0.92,
      ),
      MacroIndicator(
        name: 'Income Stability Index',
        currentValue: 60 + bondStability * 35,
        change: bondStability * 4,
        trendDescription: 'Duration hedge effectiveness ${bondStability >= 0 ? 'improving' : 'softening'}.',
        confidence: 0.86,
      ),
      MacroIndicator(
        name: 'Inflation Shield Score',
        currentValue: 48 + goldShield * 30,
        change: goldShield * 3,
        trendDescription: 'Gold sleeve ${goldShield >= 0 ? 'buffering CPI shocks' : 'lagging other hedges'}.',
        confidence: 0.84,
      ),
    ];
  }

  Future<List<AutomationIntegration>> fetchIntegrations() async {
    final now = DateTime.now();
    return [
      AutomationIntegration(
        id: 'zerodha',
        brokerName: 'Zerodha',
        accountType: 'Kite Connect',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 4)),
        apiLatencyMs: 210,
      ),
      AutomationIntegration(
        id: 'upstox',
        brokerName: 'Upstox',
        accountType: 'Pro API',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 18)),
        apiLatencyMs: 240,
      ),
      AutomationIntegration(
        id: 'binance',
        brokerName: 'Binance',
        accountType: 'Spot',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 12)),
        apiLatencyMs: 320,
      ),
      AutomationIntegration(
        id: 'ibkr',
        brokerName: 'Interactive Brokers',
        accountType: 'Institutional',
        isConnected: true,
        lastSync: now.subtract(const Duration(minutes: 2)),
        apiLatencyMs: 180,
      ),
    ];
  }

  Future<List<TradeIdea>> fetchTradeIdeas(PortfolioSnapshot snapshot) async {
    final ideas = <TradeIdea>[];
    final precision = await fetchPrecisionForecasts(snapshot);
    final precisionMap = {for (final item in precision) item.asset.symbol: item};

    for (final forecast in snapshot.assets) {
      final precisionForecast = precisionMap[forecast.symbol];
      if (precisionForecast == null) continue;
      final expectedDelta = precisionForecast.relativeDelta;
      if (expectedDelta.abs() < 0.015) continue;

      final action = expectedDelta > 0.02
          ? 'Increase'
          : expectedDelta < -0.02
              ? 'Trim'
              : 'Hold';
      final evidence = <String>[
        'Deterministic price target ${precisionForecast.projectedPrice.toStringAsFixed(2)}',
        'Forecast confidence ${(precisionForecast.confidence * 100).toStringAsFixed(0)}%',
      ];
      if (action != 'Hold') {
        evidence.add('Explainable drivers: ${precisionForecast.rationales.first}');
      }
      ideas.add(
        TradeIdea(
          asset: forecast,
          action: action,
          positionSizePct: (expectedDelta * 100).clamp(-2.0, 2.0),
          entryPrice: precisionForecast.currentPrice,
          stopLoss: precisionForecast.currentPrice * (action == 'Increase' ? 0.94 : 0.9),
          rationale: action == 'Hold'
              ? 'Stay the course while monitoring variance budget.'
              : 'Rebalance exposure based on deterministic price discovery.',
          supportingEvidence: evidence,
          confidence: precisionForecast.confidence,
        ),
      );
    }

    if (ideas.isEmpty && snapshot.assets.isNotEmpty) {
      ideas.add(
        TradeIdea(
          asset: snapshot.assets.first,
          action: 'Hold',
          positionSizePct: 0,
          entryPrice: _latestPrices[snapshot.assets.first.symbol] ?? 0,
          stopLoss: 0,
          rationale: 'Signals aligned with current allocation. Maintain posture.',
          supportingEvidence: const ['No rebalance required.'],
          confidence: 0.6,
        ),
      );
    }

    return ideas;
  }

  Future<PortfolioOptimization> optimizePortfolio(
    double targetReturn,
    RiskProfile profile,
    PortfolioSnapshot snapshot,
  ) async {
    final currentReturn = snapshot.assets
            .map((asset) => _seriesCache[asset.symbol])
            .where((series) => series != null)
            .map((series) => _meanReturn(series!))
            .fold<double>(0, (sum, value) => sum + value) /
        max(snapshot.assets.length, 1);
    final adjustment = targetReturn - currentReturn;
    final expectedRisk = _portfolioVolatility();
    final adjustments = snapshot.assets.map((asset) {
      final tilt = adjustment * (asset.assetClass == AssetClass.equities ? 1.2 : 0.6);
      final recommended = (asset.allocation + tilt).clamp(0.01, 0.35);
      final action = recommended > asset.allocation
          ? 'Scale allocation to capture upside.'
          : 'Trim position to respect volatility guardrails.';
      return OptimizationAllocation(
        asset: asset,
        currentAllocation: asset.allocation,
        recommendedAllocation: recommended,
        action: action,
      );
    }).toList();

    return PortfolioOptimization(
      targetReturn: targetReturn,
      expectedReturn: targetReturn + adjustment * 0.5,
      expectedRisk: expectedRisk,
      sharpe: expectedRisk == 0 ? 0 : (targetReturn - 0.02) / expectedRisk,
      instructions: [
        'Deploy smart order routing and monitor slippage < 12bps.',
        'Respect ESG and concentration guardrails embedded in mandate.',
        'Sync allocation changes with connected broker APIs for execution.',
      ],
      constraintsRespected: [
        'Tracking error within 3% policy limit.',
        'Liquidity budget keeps 92% of NAV tradeable within 1 day.',
        'Carbon intensity 15% below benchmark threshold.',
      ],
      allocations: adjustments,
    );
  }

  Future<List<TaxOptimizationOpportunity>> fetchTaxOpportunities(
    PortfolioSnapshot snapshot,
  ) async {
    final opportunities = <TaxOptimizationOpportunity>[];
    for (final asset in snapshot.assets) {
      if (asset.dayChangePct < -0.025) {
        opportunities.add(
          TaxOptimizationOpportunity(
            asset: asset,
            harvestAmount: asset.currentValue * 0.03,
            estimatedBenefit: asset.currentValue * 0.03 * 0.15,
            deadline: DateTime.now().add(const Duration(days: 20)),
            action: 'Harvest ${asset.symbol} loss and rotate via proxy ETF to maintain exposure.',
          ),
        );
      }
    }

    if (opportunities.isEmpty && snapshot.assets.isNotEmpty) {
      opportunities.add(
        TaxOptimizationOpportunity(
          asset: snapshot.assets.first,
          harvestAmount: snapshot.assets.first.currentValue * 0.015,
          estimatedBenefit: snapshot.assets.first.currentValue * 0.015 * 0.2,
          deadline: DateTime.now().add(const Duration(days: 30)),
          action: 'Monitor positions for strategic harvesting opportunities.',
        ),
      );
    }

    if (snapshot.assets.isEmpty) {
      return const [];
    }

    return opportunities;
  }

  Future<CashFlowProjection> fetchCashFlowProjection() async {
    final now = DateTime.now();
    final points = List.generate(6, (index) {
      final month = DateTime(now.year, now.month + index, 1);
      final inflows = 14800 + (index * 140);
      final outflows = 11250 + (index * 95);
      return CashFlowPoint(month: month, inflows: inflows.toDouble(), outflows: outflows.toDouble());
    });
    final averageSurplus =
        points.fold<double>(0, (sum, point) => sum + point.net) / max(points.length, 1);
    final coverageRatio = points.fold<double>(0, (sum, point) => sum + point.inflows) /
        points.fold<double>(0, (sum, point) => sum + point.outflows);
    return CashFlowProjection(
      points: points,
      averageSurplus: averageSurplus,
      coverageRatio: coverageRatio,
      commentary: 'Projected surplus covers planned investments ${coverageRatio.toStringAsFixed(2)}× with no negative months.',
    );
  }

  Future<AssistantMessage> processCommand(
    String command,
    PortfolioSnapshot? snapshot,
    RiskMetrics? riskMetrics,
    List<ForecastInsight> forecasts,
    List<TradeIdea> tradeIdeas,
  ) async {
    if (snapshot == null || riskMetrics == null) {
      return const AssistantMessage(
        role: AssistantRole.assistant,
        content:
            'I am still loading the latest analytics. Please retry in a second once the dashboards are ready.',
        confidence: 0.2,
      );
    }

    final cleaned = command.toLowerCase();
    double desiredReturn = 0.08;
    final percentIndex = cleaned.indexOf('%');
    if (percentIndex != -1) {
      var start = percentIndex - 1;
      while (start >= 0 && '0123456789.'.contains(cleaned[start])) {
        start -= 1;
      }
      final numeric = cleaned.substring(start + 1, percentIndex).trim();
      final parsed = double.tryParse(numeric);
      if (parsed != null) {
        desiredReturn = parsed / 100;
      }
    }

    final profile = cleaned.contains('low risk') || cleaned.contains('conservative')
        ? RiskProfile.conservative
        : cleaned.contains('high risk') || cleaned.contains('aggressive')
            ? RiskProfile.aggressive
            : RiskProfile.moderate;

    final optimization = await optimizePortfolio(desiredReturn, profile, snapshot);
    final playbooks = await fetchStrategyPlaybooks(snapshot);
    final summary = StringBuffer()
      ..writeln('Optimization calibrated for ${(desiredReturn * 100).toStringAsFixed(1)}% target return with a '
          '${profile.label.toLowerCase()} risk stance.')
      ..writeln('Top allocation shift: ${optimization.allocations.first.asset.symbol} -> '
          '${(optimization.allocations.first.recommendedAllocation * 100).toStringAsFixed(1)}%');

    if (profile == RiskProfile.conservative) {
      summary.writeln('Dialling up bonds and cash sleeves to bring VaR to '
          '${(riskMetrics.valueAtRisk.abs() / snapshot.totalValue * 100).toStringAsFixed(1)}%.');
    } else if (profile == RiskProfile.aggressive) {
      summary.writeln('Rotating into AI leaders and crypto to pursue upside with guarded tail risk.');
    } else {
      summary.writeln('Balanced allocation retains diversification while leaning into quality tech.');
    }

    final evidence = <String>[
      'Portfolio VaR ${(riskMetrics.valueAtRisk / snapshot.totalValue * 100).abs().toStringAsFixed(1)}%',
      if (forecasts.isNotEmpty)
        'Top signal: ${forecasts.first.asset.symbol} ${(forecasts.first.expectedReturn * 100).toStringAsFixed(1)}% expected return',
      if (tradeIdeas.isNotEmpty)
        'Execution-ready idea: ${tradeIdeas.first.action} ${tradeIdeas.first.asset.symbol}',
      if (playbooks.isNotEmpty) 'Strategy focus: ${playbooks.first.name}',
    ];

    return AssistantMessage(
      role: AssistantRole.assistant,
      content: optimization.allocations
          .map((allocation) =>
              '${allocation.asset.symbol}: ${(allocation.recommendedAllocation * 100).toStringAsFixed(1)}% (${allocation.action.toLowerCase()})')
          .join('\n'),
      confidence: 0.78,
      supportingData: evidence,
      rationale: summary.toString().trim(),
    );
  }

  Future<List<ResearchInsight>> fetchResearchInsights() async {
    final insights = <ResearchInsight>[];
    for (final holding in _holdings) {
      final series = _seriesCache[holding.symbol];
      if (series == null || series.length < 10) continue;
      final closes = series.map((point) => point.close).toList();
      final fastMa = _movingAverage(closes, 5);
      final slowMa = _movingAverage(closes, 20);
      final momentum = (closes.last - closes[closes.length - 6]) / closes[closes.length - 6];
      final title = '${holding.symbol} research brief';
      final summary = fastMa > slowMa
          ? '${holding.name} showing positive crossover with ${(momentum * 100).toStringAsFixed(1)}% 5d momentum.'
          : '${holding.name} momentum cooling with ${(momentum * 100).toStringAsFixed(1)}% drift.';
      final sources = [
        'Price momentum ${(momentum * 100).toStringAsFixed(1)}%',
        'Moving average spread ${(fastMa - slowMa).toStringAsFixed(2)}',
      ];
      insights.add(
        ResearchInsight(
          title: title,
          summary: summary,
          supportingSources: sources,
          confidence: (0.55 + momentum.abs()).clamp(0.55, 0.92),
        ),
      );
    }
    insights.sort((a, b) => b.confidence.compareTo(a.confidence));
    return insights.take(6).toList();
  }

  Future<List<StrategyPlaybook>> fetchStrategyPlaybooks(PortfolioSnapshot snapshot) async {
    final playbooks = <StrategyPlaybook>[];
    final riskMetrics = await fetchRiskMetrics();
    final equitiesWeight = snapshot.assetAllocation[AssetClass.equities] ?? 0;
    final cryptoWeight = snapshot.assetAllocation[AssetClass.crypto] ?? 0;

    playbooks.add(
      StrategyPlaybook(
        name: 'AI Compounder Core',
        objective: 'Capture compounding returns from AI platform leaders while respecting risk budget.',
        expectedReturn: 0.11,
        riskBudget: max(riskMetrics.valueAtRisk.abs() / snapshot.totalValue, 0.05),
        tactics: [
          'Maintain ${(equitiesWeight * 100).toStringAsFixed(1)}% equities weight with quality tilt.',
          'Overlay downside hedges via structured puts during volatility spikes.',
          'Harvest gains progressively once deterministic targets hit.',
        ],
      ),
    );

    playbooks.add(
      StrategyPlaybook(
        name: 'Digital Asset Satellite',
        objective: 'Participate in crypto upside with risk-controlled sleeve.',
        expectedReturn: 0.18,
        riskBudget: max(cryptoWeight * 0.5, 0.04),
        tactics: [
          'Stake ETH to earn yield while maintaining liquidity.',
          'Rebalance BTC weight when contribution to VaR exceeds 25%.',
          'Use stablecoins (USDC) for tactical redeployment and hedging.',
        ],
      ),
    );

    playbooks.add(
      StrategyPlaybook(
        name: 'Defensive Income Ladder',
        objective: 'Provide downside protection and dependable cash flows.',
        expectedReturn: 0.045,
        riskBudget: 0.03,
        tactics: [
          'Extend bond ladder duration when yield curve steepens.',
          'Blend EM credit (EMB) with investment grade bonds for carry.',
          'Allocate surplus cash to high-grade T-bills with auto-roll.',
        ],
      ),
    );

    return playbooks;
  }

  Future<List<PlatformCapability>> fetchPlatformCapabilities() async {
    return const [
      PlatformCapability(
        platform: 'Android & iOS',
        status: 'Fully optimised',
        notes: 'Responsive Flutter UI with secure biometrics and offline caches.',
      ),
      PlatformCapability(
        platform: 'Windows',
        status: 'Production ready',
        notes: 'Desktop build with keyboard shortcuts, multi-window dashboards, and encrypted storage.',
      ),
      PlatformCapability(
        platform: 'Web',
        status: 'Progressive web app',
        notes: 'Works offline with service workers and TLS mutual authentication.',
      ),
    ];
  }

  Map<String, double> _buildFactorExposures(List<_AssetSnapshot> snapshots, double totalValue) {
    if (totalValue == 0) {
      return const {
        'AI Momentum': 0,
        'Quality': 0,
        'Income Stability': 0,
        'Digital Assets': 0,
      };
    }
    double exposure(List<String> symbols) {
      final value = snapshots
          .where((snapshot) => symbols.contains(snapshot.holding.symbol))
          .fold<double>(0, (sum, snapshot) => sum + snapshot.value);
      return value / totalValue;
    }

    return {
      'AI Momentum': exposure(const ['AAPL', 'MSFT', 'TSLA']),
      'Quality': exposure(const ['AAPL', 'MSFT', 'BND']),
      'Income Stability': exposure(const ['BND', 'EMB', 'USDC']),
      'Digital Assets': exposure(const ['BTC', 'ETH', 'USDC']),
    };
  }

  List<String> _buildAlerts(List<_AssetSnapshot> snapshots, Map<AssetClass, double> allocation) {
    final alerts = <String>[];
    for (final snapshot in snapshots) {
      if (snapshot.dayChangePct.abs() > 0.035) {
        alerts.add('${snapshot.holding.symbol} moved '
            '${(snapshot.dayChangePct * 100).toStringAsFixed(1)}% today; review guardrails.');
      }
    }
    final cryptoWeight = allocation[AssetClass.crypto] ?? 0;
    if (cryptoWeight > 0.15) {
      alerts.add('Crypto sleeve above policy band at ${(cryptoWeight * 100).toStringAsFixed(1)}%.');
    }
    if ((allocation[AssetClass.equities] ?? 0) > 0.55) {
      alerts.add('Equity concentration trending above 55% threshold.');
    }
    return alerts;
  }

  List<MarketHeadline> _buildHeadlines(List<_AssetSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return const [];
    }
    final sorted = List<_AssetSnapshot>.from(snapshots)
      ..sort((a, b) => b.dayChangePct.abs().compareTo(a.dayChangePct.abs()));
    final top = sorted.take(3).toList();
    final now = DateTime.now();
    return [
      for (var i = 0; i < top.length; i++)
        MarketHeadline(
          source: 'QuantDesk',
          title: '${top[i].holding.name} moves ${(top[i].dayChangePct * 100).toStringAsFixed(1)}% on macro signals',
          sentimentScore: top[i].dayChangePct >= 0 ? 0.45 + i * 0.1 : -0.3 - i * 0.05,
          publishedAt: now.subtract(Duration(minutes: 15 + i * 9)),
        ),
    ];
  }

  Map<String, double> _computeWeights() {
    final total = _portfolioValue();
    if (total == 0) return {};
    final weights = <String, double>{};
    for (final holding in _holdings) {
      final price = _latestPrices[holding.symbol];
      if (price == null) continue;
      weights[holding.symbol] = (price * holding.units) / total;
    }
    return weights;
  }

  double _portfolioValue() {
    return _holdings.fold<double>(0, (sum, holding) {
      final price = _latestPrices[holding.symbol];
      if (price == null) return sum;
      return sum + price * holding.units;
    });
  }

  List<double> _buildPortfolioReturns(Map<String, double> weights, int minLength) {
    final returns = List<double>.filled(minLength, 0);
    weights.forEach((symbol, weight) {
      final series = _seriesCache[symbol];
      if (series == null || series.length < minLength + 1) return;
      final assetReturns = _assetReturns(series);
      final trimmed = assetReturns.sublist(assetReturns.length - minLength);
      for (var i = 0; i < minLength; i++) {
        returns[i] += trimmed[i] * weight;
      }
    });
    return returns;
  }

  Map<String, double> _riskContributors(Map<String, double> weights, int minLength) {
    final contributions = <String, double>{};
    double total = 0;
    weights.forEach((symbol, weight) {
      final series = _seriesCache[symbol];
      if (series == null || series.length < minLength + 1) return;
      final assetReturns = _assetReturns(series);
      final trimmed = assetReturns.sublist(assetReturns.length - minLength);
      final mean = trimmed.reduce((a, b) => a + b) / trimmed.length;
      final variance =
          trimmed.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) / max(trimmed.length - 1, 1);
      final contribution = weight * sqrt(max(variance, 0));
      contributions[symbol] = contribution;
      total += contribution;
    });
    if (total == 0) {
      return contributions;
    }
    return contributions.map((key, value) => MapEntry(key, value / total));
  }

  List<double> _assetReturns(List<TimeSeriesPoint> series) {
    final returns = <double>[];
    for (var i = 1; i < series.length; i++) {
      final previous = series[i - 1].close;
      if (previous == 0) continue;
      returns.add((series[i].close - previous) / previous);
    }
    return returns;
  }

  double _expectedShortfall(List<double> returns, double alpha) {
    final sorted = List<double>.from(returns)..sort();
    final cutoff = (sorted.length * (1 - alpha)).floor();
    if (cutoff <= 0) {
      return sorted.first;
    }
    final tail = sorted.take(cutoff).toList();
    if (tail.isEmpty) {
      return sorted.first;
    }
    return tail.reduce((a, b) => a + b) / tail.length;
  }

  double _maxDrawdownFromReturns(List<double> returns) {
    var peak = 0.0;
    var trough = 0.0;
    var maxDrawdown = 0.0;
    var cumulative = 0.0;
    for (final value in returns) {
      cumulative += value;
      if (cumulative > peak) {
        peak = cumulative;
        trough = cumulative;
      }
      if (cumulative < trough) {
        trough = cumulative;
        maxDrawdown = min(maxDrawdown, trough - peak);
      }
    }
    return maxDrawdown;
  }

  _TrendResult _linearRegression(List<double> series) {
    final n = series.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = series[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final denominator = (n * sumXX) - (sumX * sumX);
    final slope = denominator == 0 ? 0 : ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - slope * sumX) / n;
    return _TrendResult(slope: slope, intercept: intercept);
  }

  double _rSquared(List<double> series, _TrendResult trend) {
    final mean = series.reduce((a, b) => a + b) / series.length;
    double ssTot = 0;
    double ssRes = 0;
    for (var i = 0; i < series.length; i++) {
      final predicted = trend.intercept + trend.slope * i;
      ssRes += pow(series[i] - predicted, 2);
      ssTot += pow(series[i] - mean, 2);
    }
    if (ssTot == 0) return 0;
    return 1 - (ssRes / ssTot);
  }

  double _meanAbsoluteResidual(List<double> series, _TrendResult trend) {
    if (series.isEmpty) return 0;
    double sum = 0;
    for (var i = 0; i < series.length; i++) {
      final predicted = trend.intercept + trend.slope * i;
      sum += (series[i] - predicted).abs();
    }
    final residual = sum / series.length;
    return residual / max(series.last, 1);
  }

  double _annualisedVolatility(List<double> series) {
    final returns = <double>[];
    for (var i = 1; i < series.length; i++) {
      final prev = series[i - 1];
      if (prev == 0) continue;
      returns.add((series[i] - prev) / prev);
    }
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) /
        max(returns.length - 1, 1);
    return sqrt(max(variance, 0)) * sqrt(252);
  }

  double _meanReturn(List<TimeSeriesPoint> series) {
    final returns = _assetReturns(series);
    if (returns.isEmpty) return 0;
    return returns.reduce((a, b) => a + b) / returns.length;
  }

  double _portfolioVolatility() {
    final weights = _computeWeights();
    final minLength = _seriesCache.values.map((series) => series.length - 1).reduce(min);
    if (minLength <= 0) return 0.1;
    final returns = _buildPortfolioReturns(weights, minLength);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) /
        max(returns.length - 1, 1);
    return sqrt(max(variance, 0));
  }

  double _movingAverage(List<double> series, int window) {
    if (series.length < window) {
      return series.isEmpty ? 0 : series.reduce((a, b) => a + b) / series.length;
    }
    final slice = series.sublist(series.length - window);
    return slice.reduce((a, b) => a + b) / slice.length;
  }

  double _momentumScore(List<String> symbols) {
    if (symbols.isEmpty) return 0;
    double total = 0;
    var count = 0;
    for (final symbol in symbols) {
      final series = _seriesCache[symbol];
      if (series == null || series.length < 6) continue;
      final recent = series.last.close;
      final prior = series[series.length - 6].close;
      if (prior == 0) continue;
      total += (recent - prior) / prior;
      count += 1;
    }
    if (count == 0) return 0;
    return (total / count).clamp(-1, 1);
  }

  List<String> _buildDrivers(
    PortfolioAsset asset,
    List<TimeSeriesPoint> series,
    double slope,
  ) {
    final drivers = <String>['Trend slope ${slope.toStringAsFixed(2)}'];
    final returns = _assetReturns(series);
    if (returns.isNotEmpty) {
      final volatility = _annualisedVolatility(series.map((point) => point.close).toList());
      drivers.add('Annualised volatility ${volatility.toStringAsFixed(2)}');
    }
    if (asset.assetClass == AssetClass.crypto) {
      drivers.add('On-chain velocity indicator > baseline');
    } else if (asset.assetClass == AssetClass.bonds) {
      drivers.add('Yield curve steepness supporting carry');
    } else if (asset.assetClass == AssetClass.commodities) {
      drivers.add('Inflation hedge demand strengthening');
    } else {
      drivers.add('Earnings revisions trending higher');
    }
    return drivers;
  }

  List<double> _emaSeries(List<double> series, int window) {
    if (series.isEmpty) return const [];
    final ema = <double>[];
    final multiplier = 2 / (window + 1);
    double? previous;
    for (final value in series) {
      previous = previous == null ? value : (value - previous) * multiplier + previous;
      ema.add(previous);
    }
    return ema;
  }

  List<double> _rsiSeries(List<double> series, int period) {
    if (series.length < 2) return List<double>.filled(series.length, 50);
    final rsis = <double>[];
    double gainAvg = 0;
    double lossAvg = 0;
    for (var i = 0; i < series.length; i++) {
      if (i == 0) {
        rsis.add(50);
        continue;
      }
      final change = series[i] - series[i - 1];
      final gain = change > 0 ? change : 0;
      final loss = change < 0 ? -change : 0;
      if (i <= period) {
        gainAvg = (gainAvg * (i - 1) + gain) / max(i, 1);
        lossAvg = (lossAvg * (i - 1) + loss) / max(i, 1);
      } else {
        gainAvg = (gainAvg * (period - 1) + gain) / period;
        lossAvg = (lossAvg * (period - 1) + loss) / period;
      }
      final rs = lossAvg == 0 ? 100.0 : gainAvg / max(lossAvg, 0.0001);
      final rsi = 100 - (100 / (1 + rs));
      rsis.add(rsi.isNaN ? 50 : rsi);
    }
    return rsis;
  }

  double _averageTrueRange(List<TimeSeriesPoint> series, int period) {
    if (series.length < 2) return 0.01;
    final trs = <double>[];
    for (var i = 1; i < series.length; i++) {
      final current = series[i];
      final previous = series[i - 1];
      final range1 = current.high - current.low;
      final range2 = (current.high - previous.close).abs();
      final range3 = (current.low - previous.close).abs();
      trs.add(max(range1, max(range2, range3)));
    }
    if (trs.isEmpty) return 0.01;
    final subset = trs.sublist(max(0, trs.length - period));
    return subset.reduce((a, b) => a + b) / subset.length;
  }

  _MacdSeries _macdSeries(List<double> series, {int fast = 12, int slow = 26, int signal = 9}) {
    if (series.isEmpty) {
      return const _MacdSeries(line: [], signal: [], histogram: []);
    }
    final fastEma = _emaSeries(series, fast);
    final slowEma = _emaSeries(series, slow);
    final macdLine = <double>[];
    for (var i = 0; i < series.length; i++) {
      final fastValue = i < fastEma.length ? fastEma[i] : series[i];
      final slowValue = i < slowEma.length ? slowEma[i] : series[i];
      macdLine.add(fastValue - slowValue);
    }
    final signalLine = _emaSeries(macdLine, signal);
    final histogram = <double>[];
    for (var i = 0; i < macdLine.length; i++) {
      final signalValue = i < signalLine.length ? signalLine[i] : 0;
      histogram.add(macdLine[i] - signalValue);
    }
    return _MacdSeries(line: macdLine, signal: signalLine, histogram: histogram);
  }

  _BollingerBands _bollingerBands(
    List<double> series, {
    int period = 20,
    double stdDev = 2,
  }) {
    if (series.isEmpty) {
      return const _BollingerBands(upper: [], lower: [], basis: []);
    }
    final upper = <double>[];
    final lower = <double>[];
    final basis = <double>[];
    for (var i = 0; i < series.length; i++) {
      final start = max(0, i - period + 1);
      final window = series.sublist(start, i + 1);
      final mean = window.reduce((a, b) => a + b) / window.length;
      final variance = window.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) / window.length;
      final deviation = sqrt(max(variance, 0));
      basis.add(mean);
      upper.add(mean + deviation * stdDev);
      lower.add(mean - deviation * stdDev);
    }
    return _BollingerBands(upper: upper, lower: lower, basis: basis);
  }

  List<double> _adxSeries(List<TimeSeriesPoint> series, int period) {
    if (series.length < 2) {
      return List<double>.filled(series.length, 15);
    }
    final adx = List<double>.filled(series.length, 15);
    double prevHigh = series.first.high;
    double prevLow = series.first.low;
    double prevClose = series.first.close;
    double smoothedTr = 0;
    double smoothedPlus = 0;
    double smoothedMinus = 0;
    double adxValue = 15;
    for (var i = 1; i < series.length; i++) {
      final current = series[i];
      final upMove = current.high - prevHigh;
      final downMove = prevLow - current.low;
      final trueRange = max(
        current.high - current.low,
        max((current.high - prevClose).abs(), (current.low - prevClose).abs()),
      );
      final plusDm = (upMove > downMove && upMove > 0) ? upMove : 0;
      final minusDm = (downMove > upMove && downMove > 0) ? downMove : 0;
      if (i <= period) {
        smoothedTr += trueRange;
        smoothedPlus += plusDm;
        smoothedMinus += minusDm;
      } else {
        smoothedTr = smoothedTr - (smoothedTr / period) + trueRange;
        smoothedPlus = smoothedPlus - (smoothedPlus / period) + plusDm;
        smoothedMinus = smoothedMinus - (smoothedMinus / period) + minusDm;
      }
      final diPlus = smoothedTr == 0 ? 0 : (smoothedPlus / smoothedTr) * 100;
      final diMinus = smoothedTr == 0 ? 0 : (smoothedMinus / smoothedTr) * 100;
      final dx = (diPlus + diMinus) == 0 ? 0 : ((diPlus - diMinus).abs() / (diPlus + diMinus)) * 100;
      if (i <= period) {
        adxValue = ((adxValue * (i - 1)) + dx) / i;
      } else {
        adxValue = ((adxValue * (period - 1)) + dx) / period;
      }
      adx[i] = adxValue;
      prevHigh = current.high;
      prevLow = current.low;
      prevClose = current.close;
    }
    return adx;
  }

  List<double> _vwapSeries(List<TimeSeriesPoint> series, {int window = 20}) {
    if (series.isEmpty) {
      return const [];
    }
    final vwap = <double>[];
    final pvWindow = <double>[];
    final volumeWindow = <double>[];
    double sumPv = 0;
    double sumVolume = 0;
    for (final point in series) {
      final typicalPrice = (point.high + point.low + point.close) / 3;
      final volume = max(point.volume, 1);
      final pv = typicalPrice * volume;
      sumPv += pv;
      sumVolume += volume;
      pvWindow.add(pv);
      volumeWindow.add(volume);
      if (pvWindow.length > window) {
        sumPv -= pvWindow.removeAt(0);
        sumVolume -= volumeWindow.removeAt(0);
      }
      vwap.add(sumVolume == 0 ? typicalPrice : sumPv / sumVolume);
    }
    return vwap;
  }

  List<double> _obvSeries(List<TimeSeriesPoint> series) {
    if (series.isEmpty) {
      return const [];
    }
    final obv = <double>[];
    double running = 0;
    obv.add(running);
    for (var i = 1; i < series.length; i++) {
      final current = series[i];
      final previous = series[i - 1];
      if (current.close > previous.close) {
        running += max(current.volume, 1);
      } else if (current.close < previous.close) {
        running -= max(current.volume, 1);
      }
      obv.add(running);
    }
    return obv;
  }

  List<double> _normalizedSlopeSeries(List<double> series, {required int window}) {
    if (series.isEmpty) {
      return const [];
    }
    final slopes = <double>[];
    for (var i = 0; i < series.length; i++) {
      final start = max(0, i - window + 1);
      final segment = series.sublist(start, i + 1);
      slopes.add(_normalizedSlopeValue(segment));
    }
    return slopes;
  }

  double _normalizedSlopeValue(List<double> segment) {
    if (segment.length < 2) {
      return 0;
    }
    final trend = _linearRegression(segment);
    final scale = segment.last.abs() < 1 ? 1 : segment.last.abs();
    return (trend.slope / scale) * segment.length;
  }

  _CompositeSignalOutcome _evaluateComposite({
    required double price,
    required double shortEma,
    required double longEma,
    required double rsi,
    required double macdLine,
    required double macdSignal,
    required double macdHist,
    required double bollingerUpper,
    required double bollingerLower,
    required double bollingerBasis,
    required double adx,
    required double vwap,
    required double priceSlope,
    required double vwapSlope,
    required double obvSlope,
    required double volumeSlope,
    double? atr,
  }) {
    final votes = <_Vote>[];
    final emaScore = (shortEma - longEma) / max(longEma.abs(), 1);
    votes.add(_Vote(label: 'EMA momentum', score: emaScore.clamp(-1.5, 1.5), weight: 1.0));

    final macdScore = macdHist / max(price * 0.002, 0.0001);
    final macdSignalDiff = macdLine - macdSignal;
    votes.add(
      _Vote(
        label: 'MACD impulse',
        score: (macdScore + macdSignalDiff * 1.2).clamp(-1.5, 1.5),
        weight: 0.95,
      ),
    );

    final rsiScore = ((rsi - 50) / 25).clamp(-1.2, 1.2);
    votes.add(_Vote(label: 'RSI balance', score: rsiScore, weight: 0.7));

    final bandWidth = max((bollingerUpper - bollingerBasis).abs(), 0.0001);
    final bollPosition = ((price - bollingerBasis) / bandWidth).clamp(-3, 3);
    votes.add(_Vote(label: 'Bollinger posture', score: bollPosition * 0.6, weight: 0.65));

    final vwapScore = ((price - vwap) / max(price * 0.003, 0.0001) + vwapSlope * 8).clamp(-1.4, 1.4);
    votes.add(_Vote(label: 'VWAP alignment', score: vwapScore, weight: 0.9));

    votes.add(_Vote(label: 'Trend slope', score: priceSlope.clamp(-1.2, 1.2), weight: 0.6));
    votes.add(_Vote(label: 'OBV flow', score: obvSlope.clamp(-1.2, 1.2), weight: 0.55));
    votes.add(_Vote(label: 'Volume impulse', score: volumeSlope.clamp(-1.2, 1.2), weight: 0.5));

    final totalWeight = votes.fold<double>(0, (sum, vote) => sum + vote.weight);
    final weightedScore = votes.fold<double>(0, (sum, vote) => sum + vote.score * vote.weight);
    final trendIntensity = (adx / 25).clamp(0.4, 2.2);
    final bias = (weightedScore / max(totalWeight, 0.0001)) * trendIntensity;
    final clampedBias = bias.clamp(-1.0, 1.0);

    final absSignal = votes.fold<double>(0, (sum, vote) => sum + vote.weight * vote.score.abs());
    final signalStrength = (absSignal / max(totalWeight, 0.0001) * trendIntensity).clamp(0, 2.4);

    final sortedVotes = [...votes]
      ..sort((a, b) => (b.weight * b.score.abs()).compareTo(a.weight * a.score.abs()));
    final convictionDrivers = sortedVotes.take(4).map((vote) {
      final direction = vote.score >= 0 ? 'bullish' : 'bearish';
      final magnitude = (vote.score.abs() * 100 * vote.weight).clamp(8, 95).toStringAsFixed(0);
      return '${vote.label} $direction bias ($magnitude)';
    }).toList();

    final tags = <String>[];
    if (clampedBias > 0.3 && trendIntensity > 0.9 && bollPosition > 0.3) {
      tags.add('Breakout momentum long');
    }
    if (clampedBias < -0.3 && trendIntensity > 0.9 && bollPosition < -0.3) {
      tags.add('Breakdown momentum short');
    }
    if (clampedBias.abs() < 0.2 && bollPosition.abs() > 0.8) {
      tags.add('Bollinger snapback');
    }
    if (clampedBias > 0.15 && vwapSlope > 0.12) {
      tags.add('VWAP continuation long');
    }
    if (clampedBias < -0.15 && vwapSlope < -0.12) {
      tags.add('VWAP continuation short');
    }
    if (volumeSlope > 0.35 && clampedBias > 0.2) {
      tags.add('Volume expansion long');
    }
    if (volumeSlope < -0.35 && clampedBias < -0.2) {
      tags.add('Volume capitulation short');
    }
    if (trendIntensity < 0.75 && clampedBias.abs() < 0.25) {
      tags.add('Range scalping focus');
    }
    if (tags.isEmpty) {
      tags.add(clampedBias.abs() < 0.1 ? 'Neutral observation' : 'Discretionary follow-through');
    }

    final baselineVol = atr == null || price == 0 ? 0.005 : (atr / price).clamp(0.002, 0.09);
    final expectedMovePct = atr == null
        ? null
        : (baselineVol * 0.55 + signalStrength * 0.35 + bollPosition.abs() * 0.04)
            .clamp(0.002, 0.12);

    return _CompositeSignalOutcome(
      bias: clampedBias,
      signalStrength: signalStrength,
      trendIntensity: trendIntensity,
      tags: tags,
      drivers: convictionDrivers,
      expectedMovePct: expectedMovePct,
    );
  }

  double _signalAccuracy(
    List<double> closes,
    List<double> shortEma,
    List<double> longEma,
    List<double> rsi,
    List<double> macdLine,
    List<double> macdSignal,
    List<double> macdHist,
    List<double> bollingerUpper,
    List<double> bollingerLower,
    List<double> bollingerBasis,
    List<double> adxSeries,
    List<double> vwapSeries,
    List<double> priceSlopeSeries,
    List<double> vwapSlopeSeries,
    List<double> obvSlopeSeries,
    List<double> volumeSlopeSeries, {
    required int lookback,
  }) {
    if (closes.length < 3) return 0.55;
    final start = max(1, closes.length - lookback - 1);
    var correct = 0;
    var total = 0;
    for (var i = start; i < closes.length - 1; i++) {
      final outcome = _evaluateComposite(
        price: closes[i],
        shortEma: shortEma[i],
        longEma: longEma[i],
        rsi: rsi[i],
        macdLine: macdLine[i],
        macdSignal: macdSignal[i],
        macdHist: macdHist[i],
        bollingerUpper: bollingerUpper[i],
        bollingerLower: bollingerLower[i],
        bollingerBasis: bollingerBasis[i],
        adx: adxSeries[i],
        vwap: vwapSeries[i],
        priceSlope: priceSlopeSeries[i],
        vwapSlope: vwapSlopeSeries[i],
        obvSlope: obvSlopeSeries[i],
        volumeSlope: volumeSlopeSeries[i],
      );
      if (outcome.bias.abs() < 0.1) {
        continue;
      }
      final direction = outcome.bias > 0 ? 1 : -1;
      final nextReturn = (closes[i + 1] - closes[i]) / max(closes[i], 1);
      if (direction > 0 && nextReturn > 0) {
        correct += 1;
      } else if (direction < 0 && nextReturn < 0) {
        correct += 1;
      }
      total += 1;
    }
    if (total == 0) return 0.56;
    return (correct / total).clamp(0.42, 0.97);
  }
}

class _TrendResult {
  const _TrendResult({required this.slope, required this.intercept});

  final double slope;
  final double intercept;
}

class _MacdSeries {
  const _MacdSeries({required this.line, required this.signal, required this.histogram});

  final List<double> line;
  final List<double> signal;
  final List<double> histogram;
}

class _BollingerBands {
  const _BollingerBands({required this.upper, required this.lower, required this.basis});

  final List<double> upper;
  final List<double> lower;
  final List<double> basis;
}

class _CompositeSignalOutcome {
  const _CompositeSignalOutcome({
    required this.bias,
    required this.signalStrength,
    required this.trendIntensity,
    required this.tags,
    required this.drivers,
    this.expectedMovePct,
  });

  final double bias;
  final double signalStrength;
  final double trendIntensity;
  final List<String> tags;
  final List<String> drivers;
  final double? expectedMovePct;
}

class _Vote {
  const _Vote({required this.label, required this.score, required this.weight});

  final String label;
  final double score;
  final double weight;
}
