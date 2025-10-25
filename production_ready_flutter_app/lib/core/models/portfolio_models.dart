import 'package:flutter/foundation.dart';

enum AssetClass {
  equities,
  crypto,
  bonds,
  commodities,
  cash,
}

extension AssetClassLabel on AssetClass {
  String get label {
    switch (this) {
      case AssetClass.equities:
        return 'Equities';
      case AssetClass.crypto:
        return 'Crypto';
      case AssetClass.bonds:
        return 'Bonds';
      case AssetClass.commodities:
        return 'Commodities';
      case AssetClass.cash:
        return 'Cash';
    }
  }
}

@immutable
class PortfolioAsset {
  const PortfolioAsset({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.currentValue,
    required this.allocation,
    required this.dayChangePct,
    required this.dayChangeValue,
  });

  final String symbol;
  final String name;
  final AssetClass assetClass;
  final double currentValue;
  final double allocation;
  final double dayChangePct;
  final double dayChangeValue;
}

@immutable
class MarketHeadline {
  const MarketHeadline({
    required this.source,
    required this.title,
    required this.sentimentScore,
    required this.publishedAt,
  });

  final String source;
  final String title;
  final double sentimentScore;
  final DateTime publishedAt;
}

@immutable
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.totalValue,
    required this.totalCostBasis,
    required this.dailyPnL,
    required this.dailyPnLPct,
    required this.assets,
    required this.assetAllocation,
    required this.factorExposures,
    required this.alerts,
    required this.marketHeadlines,
    required this.lastUpdated,
  });

  final double totalValue;
  final double totalCostBasis;
  final double dailyPnL;
  final double dailyPnLPct;
  final List<PortfolioAsset> assets;
  final Map<AssetClass, double> assetAllocation;
  final Map<String, double> factorExposures;
  final List<String> alerts;
  final List<MarketHeadline> marketHeadlines;
  final DateTime lastUpdated;

  double get netProfit => totalValue - totalCostBasis;

  double get netProfitPct => totalCostBasis == 0 ? 0 : netProfit / totalCostBasis;
}

@immutable
class ForecastInsight {
  const ForecastInsight({
    required this.asset,
    required this.expectedReturn,
    required this.confidence,
    required this.holdingPeriodDays,
    required this.primaryDrivers,
    required this.recommendedAction,
  });

  final PortfolioAsset asset;
  final double expectedReturn;
  final double confidence;
  final int holdingPeriodDays;
  final List<String> primaryDrivers;
  final String recommendedAction;
}

@immutable
class PrecisionForecast {
  const PrecisionForecast({
    required this.asset,
    required this.currentPrice,
    required this.projectedPrice,
    required this.horizon,
    required this.expectedError,
    required this.confidence,
    required this.rationales,
    required this.modelStack,
  });

  final PortfolioAsset asset;
  final double currentPrice;
  final double projectedPrice;
  final DateTime horizon;
  final double expectedError;
  final double confidence;
  final List<String> rationales;
  final String modelStack;

  double get absoluteDelta => projectedPrice - currentPrice;

  double get relativeDelta => currentPrice == 0 ? 0 : absoluteDelta / currentPrice;
}

@immutable
class RiskMetrics {
  const RiskMetrics({
    required this.valueAtRisk,
    required this.conditionalVar,
    required this.maxDrawdown,
    required this.liquidityDays,
    required this.stressLoss,
    required this.topRiskContributors,
  });

  final double valueAtRisk;
  final double conditionalVar;
  final double maxDrawdown;
  final double liquidityDays;
  final double stressLoss;
  final Map<String, double> topRiskContributors;
}

enum RiskProfile { conservative, moderate, aggressive }

extension RiskProfileLabel on RiskProfile {
  String get label {
    switch (this) {
      case RiskProfile.conservative:
        return 'Conservative';
      case RiskProfile.moderate:
        return 'Moderate';
      case RiskProfile.aggressive:
        return 'Aggressive';
    }
  }
}

@immutable
class SimulationScenario {
  const SimulationScenario({
    required this.name,
    required this.description,
    required this.expectedReturn,
    required this.expectedVolatility,
    required this.tailRisk,
    required this.probability,
  });

  final String name;
  final String description;
  final double expectedReturn;
  final double expectedVolatility;
  final double tailRisk;
  final double probability;
}

@immutable
class MacroIndicator {
  const MacroIndicator({
    required this.name,
    required this.currentValue,
    required this.change,
    required this.trendDescription,
    required this.confidence,
  });

  final String name;
  final double currentValue;
  final double change;
  final String trendDescription;
  final double confidence;
}

@immutable
class PersonalFinanceGoal {
  const PersonalFinanceGoal({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
}

@immutable
class BudgetCategory {
  const BudgetCategory({
    required this.name,
    required this.allocated,
    required this.spent,
    required this.sentiment,
  });

  final String name;
  final double allocated;
  final double spent;
  final String sentiment;

  double get utilization => allocated == 0 ? 0 : (spent / allocated).clamp(0.0, 1.5);
}

@immutable
class AutomationIntegration {
  const AutomationIntegration({
    required this.id,
    required this.brokerName,
    required this.accountType,
    required this.isConnected,
    required this.lastSync,
    required this.apiLatencyMs,
  });

  final String id;
  final String brokerName;
  final String accountType;
  final bool isConnected;
  final DateTime lastSync;
  final int apiLatencyMs;

  AutomationIntegration copyWith({bool? isConnected, DateTime? lastSync, int? apiLatencyMs}) {
    return AutomationIntegration(
      id: id,
      brokerName: brokerName,
      accountType: accountType,
      isConnected: isConnected ?? this.isConnected,
      lastSync: lastSync ?? this.lastSync,
      apiLatencyMs: apiLatencyMs ?? this.apiLatencyMs,
    );
  }
}

@immutable
class OptimizationAllocation {
  const OptimizationAllocation({
    required this.asset,
    required this.currentAllocation,
    required this.recommendedAllocation,
    required this.action,
  });

  final PortfolioAsset asset;
  final double currentAllocation;
  final double recommendedAllocation;
  final String action;

  double get delta => recommendedAllocation - currentAllocation;
}

@immutable
class PortfolioOptimization {
  const PortfolioOptimization({
    required this.targetReturn,
    required this.expectedReturn,
    required this.expectedRisk,
    required this.sharpe,
    required this.instructions,
    required this.constraintsRespected,
    required this.allocations,
  });

  final double targetReturn;
  final double expectedReturn;
  final double expectedRisk;
  final double sharpe;
  final List<String> instructions;
  final List<String> constraintsRespected;
  final List<OptimizationAllocation> allocations;
}

@immutable
class TaxOptimizationOpportunity {
  const TaxOptimizationOpportunity({
    required this.asset,
    required this.harvestAmount,
    required this.estimatedBenefit,
    required this.deadline,
    required this.action,
  });

  final PortfolioAsset asset;
  final double harvestAmount;
  final double estimatedBenefit;
  final DateTime deadline;
  final String action;
}

@immutable
class CashFlowPoint {
  const CashFlowPoint({
    required this.month,
    required this.inflows,
    required this.outflows,
  });

  final DateTime month;
  final double inflows;
  final double outflows;

  double get net => inflows - outflows;
}

@immutable
class CashFlowProjection {
  const CashFlowProjection({
    required this.points,
    required this.averageSurplus,
    required this.coverageRatio,
    required this.commentary,
  });

  final List<CashFlowPoint> points;
  final double averageSurplus;
  final double coverageRatio;
  final String commentary;
}

enum AssistantRole { user, assistant, system }

@immutable
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.confidence,
    this.supportingData = const [],
    this.rationale,
  });

  final AssistantRole role;
  final String content;
  final double? confidence;
  final List<String> supportingData;
  final String? rationale;
}

@immutable
class TradeIdea {
  const TradeIdea({
    required this.asset,
    required this.action,
    required this.positionSizePct,
    required this.entryPrice,
    required this.stopLoss,
    required this.rationale,
    required this.supportingEvidence,
    required this.confidence,
  });

  final PortfolioAsset asset;
  final String action;
  final double positionSizePct;
  final double entryPrice;
  final double stopLoss;
  final String rationale;
  final List<String> supportingEvidence;
  final double confidence;
}
