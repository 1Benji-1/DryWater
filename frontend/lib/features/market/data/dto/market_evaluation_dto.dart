/// DTO tipado para la respuesta de análisis de mercado.
class MarketEvaluationResult {
  final MarketStatistics statistics;
  final String priceVerdict;

  const MarketEvaluationResult({
    required this.statistics,
    required this.priceVerdict,
  });

  factory MarketEvaluationResult.fromJson(Map<String, dynamic> json) {
    final rawStats = json['statistical_analysis'] ??
        json['analisis_estadistico'] ??
        const <String, dynamic>{};

    return MarketEvaluationResult(
      statistics: MarketStatistics.fromJson(
        rawStats is Map<String, dynamic> ? rawStats : const {},
      ),
      priceVerdict: (json['price_verdict'] ?? json['veredicto_precio'] ?? '')
          .toString(),
    );
  }
}

class MarketStatistics {
  final double mean;
  final double? median;
  final double? minPrice;
  final double? maxPrice;
  final double? standardDeviation;
  final double? coefficientOfVariation;
  final MarketQuartiles quartiles;
  final int sampleSize;

  const MarketStatistics({
    required this.mean,
    required this.median,
    required this.minPrice,
    required this.maxPrice,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.quartiles,
    required this.sampleSize,
  });

  factory MarketStatistics.fromJson(Map<String, dynamic> json) {
    final rawQuartiles = json['quartiles'] ??
        json['cuartiles'] ??
        const <String, dynamic>{};

    return MarketStatistics(
      mean: _readDouble(json['mean'] ?? json['media']),
      median: _readNullableDouble(json['median']),
      minPrice: _readNullableDouble(json['min_price']),
      maxPrice: _readNullableDouble(json['max_price']),
      standardDeviation: _readNullableDouble(
        json['standard_deviation'] ?? json['desviacion_std'],
      ),
      coefficientOfVariation: _readNullableDouble(
        json['coefficient_of_variation'] ?? json['cv'],
      ),
      quartiles: MarketQuartiles.fromJson(
        rawQuartiles is Map<String, dynamic> ? rawQuartiles : const {},
      ),
      sampleSize: _readInt(json['sample_size']),
    );
  }
}

class MarketQuartiles {
  final double q1;
  final double q2;
  final double q3;

  const MarketQuartiles({
    required this.q1,
    required this.q2,
    required this.q3,
  });

  factory MarketQuartiles.fromJson(Map<String, dynamic> json) {
    return MarketQuartiles(
      q1: _readDouble(json['q1'] ?? json['Q1']),
      q2: _readDouble(json['q2'] ?? json['Q2']),
      q3: _readDouble(json['q3'] ?? json['Q3']),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
