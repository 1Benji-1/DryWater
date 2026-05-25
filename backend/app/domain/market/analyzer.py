# Archivo: backend/app/domain/market/analyzer.py
import math

class MarketAnalyzer:
    @staticmethod
    def calcular_estadisticas_zona(precios: list) -> dict:
        """Calcula medidas de tendencia central, dispersión y posición."""
        if not precios:
            return None
            
        n = len(precios)
        precios.sort()
        
        # Media (Promedio)
        media = sum(precios) / n
        
        # Varianza y Desviación Estándar (Dispersión)
        varianza = sum((x - media) ** 2 for x in precios) / n
        desviacion_std = math.sqrt(varianza)
        
        # Coeficiente de Variación (Homogeneidad de la zona)
        cv = (desviacion_std / media) * 100 if media > 0 else 0
        
        # Cuartiles (Posición)
        def obtener_percentil(p):
            k = (n - 1) * p
            f = math.floor(k)
            c = math.ceil(k)
            if f == c:
                return precios[int(k)]
            return precios[int(f)] * (c - k) + precios[int(c)] * (k - f)

        q1 = obtener_percentil(0.25)
        mediana = obtener_percentil(0.50)
        q3 = obtener_percentil(0.75)
        
        # Asimetría Simple
        sesgo = "Simétrica"
        if media > mediana:
            sesgo = "Asimetría Positiva (Inclinación a precios caros)"
        elif media < mediana:
            sesgo = "Asimetría Negativa (Inclinación a precios baratos)"
            
        return {
            "media": round(media, 2),
            "desviacion_std": round(desviacion_std, 2),
            "cv": round(cv, 2),
            "cuartiles": {"Q1": q1, "Q2": mediana, "Q3": q3},
            "sesgo": sesgo
        }
        
    @staticmethod
    def evaluar_precio(precio_evaluar: float, stats: dict) -> str:
        """Cruza los Cuartiles con la Desviación Estándar para clasificar el precio."""
        limite_inferior = stats["media"] - stats["desviacion_std"]
        limite_superior = stats["media"] + stats["desviacion_std"]
        
        if precio_evaluar <= stats["cuartiles"]["Q1"] and precio_evaluar < limite_inferior:
            return "¡Posible Ganga!"
        elif precio_evaluar >= stats["cuartiles"]["Q3"] and precio_evaluar > limite_superior:
            return "Precio Elevado"
        else:
            return "Precio Justo"