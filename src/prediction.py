import joblib
import numpy as np
from src.preprocessing import transform_input

def predict(area, hour, day, month, weather, population_density, is_weekend, is_festival):
    rf_crime = joblib.load("models/random_forest_crime.pkl")
    rf_risk  = joblib.load("models/random_forest_risk.pkl")
    le_crime = joblib.load("models/le_crime.pkl")
    le_risk  = joblib.load("models/le_risk.pkl")

    X = transform_input(area, hour, day, month, weather, population_density, is_weekend, is_festival)

    crime_idx  = rf_crime.predict(X)[0]
    crime_prob = rf_crime.predict_proba(X)[0]
    risk_idx   = rf_risk.predict(X)[0]
    risk_prob  = rf_risk.predict_proba(X)[0]

    crime_type  = le_crime.inverse_transform([crime_idx])[0]
    risk_level  = le_risk.inverse_transform([risk_idx])[0]
    crime_conf  = round(float(np.max(crime_prob)) * 100, 2)
    risk_conf   = round(float(np.max(risk_prob))  * 100, 2)

    return {
        "crime_type":   crime_type,
        "risk_level":   risk_level,
        "crime_confidence": crime_conf,
        "risk_confidence":  risk_conf,
    }

def get_hotspot_cluster(lat, lon):
    kmeans = joblib.load("models/kmeans_hotspot.pkl")
    cluster = int(kmeans.predict([[lat, lon]])[0])
    return cluster
