/// DTO tipado para la respuesta de análisis de mercado.
class MarketEvaluationResult {
  final MarketStatistics statistics;
  final String priceVerdict;

  const MarketEvaluationResult({
    required this.statistics,
    required this.priceVerdict,
  });

  factory MarketEvaluationResult.fromJson(Map<String, dynamic> json) {
    final rawStats = json['statistical_analysis'];

    if (rawStats is! Map<String, dynamic>) {
      throw const FormatException(
          'Campo requerido inválido: statistical_analysis');
    }

    return MarketEvaluationResult(
      statistics: MarketStatistics.fromJson(rawStats),
      priceVerdict: _readRequiredString(json, 'price_verdict'),
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
    final rawQuartiles = json['quartiles'];

    if (rawQuartiles is! Map<String, dynamic>) {
      throw const FormatException('Campo requerido inválido: quartiles');
    }

    return MarketStatistics(
      mean: _readRequiredDouble(json, 'mean'),
      median: _readNullableDouble(json['median']),
      minPrice: _readNullableDouble(json['min_price']),
      maxPrice: _readNullableDouble(json['max_price']),
      standardDeviation: _readNullableDouble(json['standard_deviation']),
      coefficientOfVariation: _readNullableDouble(
        json['coefficient_of_variation'],
      ),
      quartiles: MarketQuartiles.fromJson(rawQuartiles),
      sampleSize: _readRequiredInt(json, 'sample_size'),
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
      q1: _readRequiredDouble(json, 'q1'),
      q2: _readRequiredDouble(json, 'q2'),
      q3: _readRequiredDouble(json, 'q3'),
    );
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';

  if (value.isEmpty) {
    throw FormatException('Campo requerido faltante o vacío: $key');
  }

  return value;
}

double _readRequiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is num) return value.toDouble();

  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Campo numérico inválido: $key');
  }

  return parsed;
}

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Campo entero inválido: $key');
  }

  return parsed;
}
