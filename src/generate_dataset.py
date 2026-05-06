import pandas as pd
import numpy as np
import uuid
from datetime import datetime, timedelta

AREAS = {
    "Mysuru City":  (12.2958, 76.6394),
    "Bannur":       (12.0833, 76.8167),
    "Nanjangud":    (12.1167, 76.6833),
    "Hunsur":       (12.3000, 76.2833),
    "T Narasipura": (12.2167, 76.9167),
    "KRS":          (12.4167, 76.5667),
    "Periyapatna":  (12.3333, 76.1000),
    "HD Kote":      (12.0500, 76.2667),
    "Saragur":      (11.9833, 76.3833),
}

CRIME_TYPES  = ["Theft", "Assault", "Robbery", "Burglary", "Fraud", "Vandalism", "Drug Offense", "Eve Teasing"]
RISK_LEVELS  = ["High", "Medium", "Low"]
WEATHERS     = ["Clear", "Cloudy", "Rainy", "Foggy", "Stormy"]
DAYS         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
MONTHS       = ["January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"]

FESTIVALS = {
    (10, 1): 1, (10, 2): 1, (10, 3): 1,   # Dasara
    (8, 15): 1,                              # Independence Day
    (1, 26): 1,                              # Republic Day
    (11, 1): 1, (11, 2): 1,                 # Diwali
}

def _risk(crime, hour, is_weekend, is_festival):
    score = 0
    if crime in ["Robbery", "Assault"]:       score += 3
    elif crime in ["Theft", "Burglary"]:      score += 2
    else:                                      score += 1
    if hour >= 21 or hour <= 5:               score += 2
    elif hour >= 18:                           score += 1
    if is_weekend:                             score += 1
    if is_festival:                            score += 1
    if score >= 5:   return "High"
    elif score >= 3: return "Medium"
    return "Low"

def generate_dataset(n: int = 10000) -> pd.DataFrame:
    np.random.seed(42)
    start = datetime(2022, 1, 1)
    records = []

    area_names = list(AREAS.keys())
    area_weights = [0.35, 0.08, 0.10, 0.08, 0.08, 0.07, 0.08, 0.08, 0.08]

    for _ in range(n):
        area = np.random.choice(area_names, p=area_weights)
        lat, lon = AREAS[area]
        lat += np.random.uniform(-0.05, 0.05)
        lon += np.random.uniform(-0.05, 0.05)

        dt = start + timedelta(
            days=np.random.randint(0, 730),
            hours=np.random.randint(0, 24),
            minutes=np.random.randint(0, 60),
        )
        hour       = dt.hour
        day        = DAYS[dt.weekday()]
        month      = MONTHS[dt.month - 1]
        is_weekend = 1 if dt.weekday() >= 5 else 0
        is_festival = FESTIVALS.get((dt.month, dt.day), 0)

        # Night hours have more serious crimes
        if hour >= 21 or hour <= 5:
            crime = np.random.choice(CRIME_TYPES, p=[0.20, 0.20, 0.20, 0.15, 0.08, 0.07, 0.05, 0.05])
        else:
            crime = np.random.choice(CRIME_TYPES, p=[0.25, 0.10, 0.10, 0.10, 0.15, 0.10, 0.10, 0.10])

        risk = _risk(crime, hour, is_weekend, is_festival)
        pop_density = int(np.random.normal(5000, 2000))
        pop_density = max(500, min(pop_density, 12000))

        records.append({
            "Crime_ID":           f"MYS-{uuid.uuid4().hex[:8].upper()}",
            "Date":               dt.strftime("%Y-%m-%d"),
            "Time":               dt.strftime("%H:%M"),
            "Hour":               hour,
            "Day":                day,
            "Month":              month,
            "Year":               dt.year,
            "Area":               area,
            "Latitude":           round(lat, 4),
            "Longitude":          round(lon, 4),
            "Crime_Type":         crime,
            "Risk_Level":         risk,
            "Population_Density": pop_density,
            "Weather":            np.random.choice(WEATHERS, p=[0.40, 0.25, 0.20, 0.10, 0.05]),
            "Is_Weekend":         is_weekend,
            "Is_Festival":        is_festival,
        })

    return pd.DataFrame(records)
