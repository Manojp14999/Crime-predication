import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder, StandardScaler
import joblib
import os

FEATURE_COLS = ["Area", "Hour", "Day", "Month", "Weather", "Population_Density", "Is_Weekend", "Is_Festival"]
TARGET_CRIME = "Crime_Type"
TARGET_RISK  = "Risk_Level"

DAYS_ORDER   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
MONTHS_ORDER = ["January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"]

def preprocess(df: pd.DataFrame):
    df = df.copy()
    df["Day_Num"]   = df["Day"].apply(lambda d: DAYS_ORDER.index(d) if d in DAYS_ORDER else 0)
    df["Month_Num"] = df["Month"].apply(lambda m: MONTHS_ORDER.index(m) if m in MONTHS_ORDER else 0)

    encoders = {}
    for col in ["Area", "Weather"]:
        le = LabelEncoder()
        df[col + "_enc"] = le.fit_transform(df[col].astype(str))
        encoders[col] = le

    num_features = ["Area_enc", "Hour", "Day_Num", "Month_Num", "Weather_enc",
                    "Population_Density", "Is_Weekend", "Is_Festival"]

    scaler = StandardScaler()
    df[num_features] = scaler.fit_transform(df[num_features])

    le_crime = LabelEncoder()
    le_risk  = LabelEncoder()
    df["Crime_Type_enc"] = le_crime.fit_transform(df[TARGET_CRIME])
    df["Risk_Level_enc"] = le_risk.fit_transform(df[TARGET_RISK])

    os.makedirs("models", exist_ok=True)
    joblib.dump(encoders, "models/label_encoders.pkl")
    joblib.dump(scaler,   "models/scaler.pkl")
    joblib.dump(le_crime, "models/le_crime.pkl")
    joblib.dump(le_risk,  "models/le_risk.pkl")

    return df, num_features, encoders, scaler, le_crime, le_risk

def transform_input(area, hour, day, month, weather, population_density, is_weekend, is_festival):
    encoders = joblib.load("models/label_encoders.pkl")
    scaler   = joblib.load("models/scaler.pkl")

    day_num   = DAYS_ORDER.index(day)   if day   in DAYS_ORDER   else 0
    month_num = MONTHS_ORDER.index(month) if month in MONTHS_ORDER else 0

    def safe_encode(le, val):
        if val in le.classes_:
            return le.transform([val])[0]
        return 0

    area_enc    = safe_encode(encoders["Area"],    area)
    weather_enc = safe_encode(encoders["Weather"], weather)

    raw = np.array([[area_enc, hour, day_num, month_num, weather_enc,
                     population_density, is_weekend, is_festival]], dtype=float)
    return scaler.transform(raw)
