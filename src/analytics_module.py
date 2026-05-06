import pandas as pd
from collections import Counter

def get_analytics(df: pd.DataFrame) -> dict:
    if df.empty:
        return {}

    crime_by_area = df.groupby("Area")["Crime_Type"].count().to_dict()
    crime_by_type = df["Crime_Type"].value_counts().to_dict()
    risk_dist     = df["Risk_Level"].value_counts().to_dict()
    hourly_trend  = df.groupby("Hour")["Crime_Type"].count().to_dict()
    monthly_trend = df.groupby("Month")["Crime_Type"].count().to_dict()

    top_area = max(crime_by_area, key=crime_by_area.get) if crime_by_area else "N/A"
    top_crime = max(crime_by_type, key=crime_by_type.get) if crime_by_type else "N/A"

    hotspots = (
        df.groupby("Area")[["Latitude", "Longitude"]]
        .mean()
        .reset_index()
        .rename(columns={"Latitude": "lat", "Longitude": "lon"})
        .assign(count=df.groupby("Area").size().values)
        .to_dict(orient="records")
    )

    weekend_vs_weekday = {
        "Weekend": int(df[df["Is_Weekend"] == 1].shape[0]),
        "Weekday": int(df[df["Is_Weekend"] == 0].shape[0]),
    }

    return {
        "total_records":     len(df),
        "top_area":          top_area,
        "top_crime":         top_crime,
        "crime_by_area":     crime_by_area,
        "crime_by_type":     crime_by_type,
        "risk_distribution": risk_dist,
        "hourly_trend":      {str(k): int(v) for k, v in hourly_trend.items()},
        "monthly_trend":     monthly_trend,
        "hotspots":          hotspots,
        "weekend_vs_weekday": weekend_vs_weekday,
    }
