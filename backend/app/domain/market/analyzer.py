# Archivo: backend/app/domain/market/analyzer.py
import math


class MarketAnalyzer:
    @staticmethod
    def calcular_estadisticas_zona(prices: list[float]) -> dict:
        """Calcula medidas estadísticas de precios comparables."""

        if not prices:
            return {}

        sorted_prices = sorted(float(price) for price in prices)
        total = len(sorted_prices)

        mean = sum(sorted_prices) / total
        variance = sum((price - mean) ** 2 for price in sorted_prices) / total
        standard_deviation = math.sqrt(variance)
        coefficient_of_variation = (
            (standard_deviation / mean) * 100 if mean > 0 else 0
        )

        def percentile(position: float) -> float:
            index = (total - 1) * position
            floor_index = math.floor(index)
            ceil_index = math.ceil(index)

            if floor_index == ceil_index:
                return sorted_prices[int(index)]

            return (
                sorted_prices[floor_index] * (ceil_index - index)
                + sorted_prices[ceil_index] * (index - floor_index)
            )

        q1 = percentile(0.25)
        median = percentile(0.50)
        q3 = percentile(0.75)

        if mean > median:
            skewness = "positive"
        elif mean < median:
            skewness = "negative"
        else:
            skewness = "symmetric"

        return {
            "mean": round(mean, 2),
            "standard_deviation": round(standard_deviation, 2),
            "coefficient_of_variation": round(coefficient_of_variation, 2),
            "quartiles": {
                "q1": round(q1, 2),
                "q2": round(median, 2),
                "q3": round(q3, 2),
            },
            "skewness": skewness,
        }

    @staticmethod
    def evaluar_precio(price_to_evaluate: float, stats: dict) -> str:
        """Clasifica un precio usando media, desviación estándar y cuartiles."""

        mean = float(stats["mean"])
        standard_deviation = float(stats["standard_deviation"])
        quartiles = stats["quartiles"]

        lower_limit = mean - standard_deviation
        upper_limit = mean + standard_deviation

        if price_to_evaluate <= quartiles["q1"] and price_to_evaluate < lower_limit:
            return "possible_bargain"

        if price_to_evaluate >= quartiles["q3"] and price_to_evaluate > upper_limit:
            return "high_price"

        return "fair_price"

