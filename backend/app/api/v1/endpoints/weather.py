import httpx
from fastapi import APIRouter, Query, HTTPException
from typing import Dict, Any

router = APIRouter(prefix="/weather", tags=["weather"])

ZONES_COORDINATES = {
    "Santa Cruz": {"lat": -17.7833, "lon": -63.1821},
    "La Paz": {"lat": -16.5, "lon": -68.15},
    "Cochabamba": {"lat": -17.3895, "lon": -66.1568},
    "Tarija": {"lat": -21.5355, "lon": -64.7296},
    "Pando": {"lat": -11.0267, "lon": -68.7692},
}

@router.get("/forecast", response_model=Dict[str, Any])
async def get_forecast(
    zone: str = Query(default="Santa Cruz"),
    lat: float = Query(default=None),
    lon: float = Query(default=None),
    simulate: str = Query(default=None)
):
    if lat is not None and lon is not None:
        coords = {"lat": lat, "lon": lon}
        zone = "Tu Ubicación Actual"
    else:
        coords = ZONES_COORDINATES.get(zone)
        if not coords:
            # Fallback a Santa Cruz si la zona no existe
            coords = ZONES_COORDINATES["Santa Cruz"]
            zone = "Santa Cruz"
        
    url = f"https://api.open-meteo.com/v1/forecast?latitude={coords['lat']}&longitude={coords['lon']}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max&timezone=auto&forecast_days=5"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()
        except httpx.RequestError:
            raise HTTPException(status_code=503, detail="Error al obtener datos meteorológicos de Open-Meteo")
            
    daily = data.get("daily", {})
    times = daily.get("time", [])
    temp_max = daily.get("temperature_2m_max", [])
    temp_min = daily.get("temperature_2m_min", [])
    precip = daily.get("precipitation_sum", [])
    wind = daily.get("windspeed_10m_max", [])
    
    forecast_list = []
    
    alert_status = "Normal"
    alert_message = "Las condiciones climáticas son estables."
    alert_type = "normal"
    
    # Calcular promedios y extremos para generar alertas
    total_precip = sum(precip) if precip else 0
    max_t = max(temp_max) if temp_max else 25
    min_t = min(temp_min) if temp_min else 15
    
    # MODO SIMULADOR
    if simulate == "flood":
        total_precip = 100
    elif simulate == "heatwave":
        max_t = 42
    elif simulate == "frost":
        min_t = -5
    elif simulate == "drought":
        total_precip = 0
        max_t = 37
    
    if total_precip > 50:
        alert_status = "Alerta de Inundación"
        alert_message = f"Se esperan fuertes lluvias acumuladas ({total_precip:.1f}mm) en los próximos 5 días."
        alert_type = "flood"
    elif max_t >= 38:
        alert_status = "Ola de Calor"
        alert_message = f"Temperaturas extremas de hasta {max_t}°C detectadas. Protégete del sol."
        alert_type = "heatwave"
    elif min_t <= 2:
        alert_status = "Alerta de Heladas"
        alert_message = f"Descenso crítico de temperatura. Las mínimas caerán hasta {min_t}°C."
        alert_type = "frost"
    elif total_precip == 0 and max_t > 35:
        alert_status = "Alerta de Sequía"
        alert_message = "Peligro de sequía e incendios. No se registran lluvias y hay altas temperaturas."
        alert_type = "drought"
        
    for i in range(len(times)):
        condition = "Soleado"
        if precip[i] > 10:
            condition = "Lluvioso"
        elif precip[i] > 0:
            condition = "Nublado"
        elif temp_max[i] > 34:
            condition = "Muy Caluroso"
        elif temp_max[i] < 15:
            condition = "Frío"
            
        forecast_list.append({
            "date": times[i],
            "day_index": i,
            "condition": condition,
            "temp_max": temp_max[i],
            "temp_min": temp_min[i],
            "precipitation": precip[i],
            "wind": wind[i]
        })
        
    return {
        "status": alert_status,
        "message": alert_message,
        "type": alert_type,
        "zone": zone,
        "forecast": forecast_list
    }
