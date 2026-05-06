import pandas as pd
import joblib 
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from sklearn.cluster import KMeans

from src.preprocessing import preprocess

def train_models(df: pd.DataFrame):
    df_proc, features, encoders, scaler, le_crime, le_risk = preprocess(df)

    X = df_proc[features]
    y_crime = df_proc["Crime_Type_enc"]
    y_risk  = df_proc["Risk_Level_enc"]

    X_tr, X_te, yc_tr, yc_te, yr_tr, yr_te = train_test_split(
        X, y_crime, y_risk, test_size=0.2, random_state=42
    )

    results = {}

    # --- Crime Type Models ---
    models_crime = {
        "random_forest": RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
        "decision_tree": DecisionTreeClassifier(max_depth=10, random_state=42),
        "logistic_regression": LogisticRegression(max_iter=500, random_state=42),
    }
    for name, model in models_crime.items():
        model.fit(X_tr, yc_tr)
        acc = accuracy_score(yc_te, model.predict(X_te))
        results[f"{name}_crime"] = round(acc * 100, 2)
        joblib.dump(model, f"models/{name}_crime.pkl")

    # --- Risk Level Models ---
    models_risk = {
        "random_forest": RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
        "decision_tree": DecisionTreeClassifier(max_depth=10, random_state=42),
        "logistic_regression": LogisticRegression(max_iter=500, random_state=42),
    }
    for name, model in models_risk.items():
        model.fit(X_tr, yr_tr)
        acc = accuracy_score(yr_te, model.predict(X_te))
        results[f"{name}_risk"] = round(acc * 100, 2)
        joblib.dump(model, f"models/{name}_risk.pkl")

    # --- KMeans Hotspot Clustering ---
    coords = df[["Latitude", "Longitude"]].values
    kmeans = KMeans(n_clusters=5, random_state=42, n_init=10)
    kmeans.fit(coords)
    joblib.dump(kmeans, "models/kmeans_hotspot.pkl")

    print("Training complete. Accuracies:", results)
    return results

if __name__ == "__main__":
    from src.generate_dataset import generate_dataset
    df = generate_dataset(10000)
    train_models(df)
