# Crime Prediction and Risk Analysis System
## Mysuru District Case Study — Karnataka, India

A full-stack machine learning web application + Android mobile app that predicts crime type and risk level for Mysuru district using Random Forest, Decision Tree, and Logistic Regression models. Includes real-time push notifications via Firebase Cloud Messaging.

---

## Project Structure

```
project-root/
├── app.py                    # Flask application (main entry point)
├── requirements.txt
├── README.md
├── firebase_service_account.json   # ⚠️ NOT included — generate your own (see setup)
├── data/
│   └── mysuru_crime_dataset.csv
├── models/
│   └── *.pkl                      # Auto-generated after training
├── src/
│   ├── generate_dataset.py        # Synthetic Mysuru crime data generator
│   ├── preprocessing.py           # Label encoding + feature scaling
│   ├── model_training.py          # Train RF, DT, LR + KMeans hotspot
│   ├── prediction.py              # Load models and predict
│   ├── analytics_module.py        # Dashboard analytics
│   └── db_handler.py              # MongoDB CRUD operations
├── templates/
│   ├── index.html                 # Dashboard
│   ├── predict.html               # Prediction form
│   ├── records.html               # Records viewer
│   └── upload.html                # CSV upload
├── static/
│   ├── css/style.css
│   └── js/main.js
└── crime_watch_mysuru/            # Flutter Android app
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   ├── services/
    │   └── models/
    └── android/
        └── app/
            └── google-services.json  # ⚠️ NOT included — add your own
```

---

## Setup Instructions

### 1. Clone / Download the project

```bash
cd "Crime Predication using ML - Case Study Mysore"
```

### 2. Create a virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. MongoDB Atlas Setup (Cloud)

1. Create a free cluster at https://cloud.mongodb.com
2. Create a database user and get your connection string
3. Go to **Network Access** → Add IP `0.0.0.0/0` (allow from anywhere)
4. Set the environment variable:

```bash
# Windows
set MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/mysuru_crime_db?retryWrites=true&w=majority

# macOS/Linux
export MONGO_URI="mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/mysuru_crime_db?retryWrites=true&w=majority"
```

### 5. Firebase Setup (for Push Notifications)

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with package name `com.mysuru.crimewatch`
3. Download `google-services.json` → place in `crime_watch_mysuru/android/app/`
4. Go to **Project Settings → Service Accounts** → Generate new private key
5. Rename downloaded file to `firebase_service_account.json` → place in project root
6. Enable **Cloud Messaging** in Firebase Console

---

## Running the Web App

```bash
python app.py
```

Open your browser at: **http://localhost:5000**

---

## Running the Mobile App

```bash
cd crime_watch_mysuru
flutter pub get
```

Update the backend URL in `lib/services/api_service.dart`:
- **Emulator:** `http://10.0.2.2:5000`
- **Real device:** `http://<your-pc-local-ip>:5000`

```bash
flutter run
```

---

## First-Time Usage

1. Open the Dashboard at `http://localhost:5000`
2. Upload a CSV file via **Upload Data** (see required columns below)
3. Click **🚀 Train / Retrain Model**
   - Trains Random Forest, Decision Tree, Logistic Regression
   - Runs KMeans hotspot clustering
   - Automatically sends push alerts to mobile if High risk crimes detected
4. Use **🔔 Send Alert** button to manually push notifications to all app users
5. Go to **Predict Crime** to make predictions

### Required CSV Columns
```
Crime_ID, Area, Hour, Day, Month, Crime_Type, Risk_Level,
Latitude, Longitude, Population_Density, Weather, Is_Weekend, Is_Festival
```

---

## API Reference

### POST `/api/predict`
```json
{
  "area": "Mysuru City", "hour": 22, "day": "Saturday",
  "month": "October", "weather": "Clear",
  "population_density": 9500, "is_weekend": 1, "is_festival": 1
}
```

### POST `/train` — Trigger model retraining
### GET `/api/analytics` — Full analytics JSON
### GET `/api/status` — Model and DB status
### POST `/api/alert` — Send push notification to mobile users
### POST `/upload` — Upload CSV (field name: `file`)

---

## Covered Areas in Mysuru District

| Area          | Latitude  | Longitude |
|---------------|-----------|-----------|
| Mysuru City   | 12.2958   | 76.6394   |
| Bannur        | 12.0833   | 76.8167   |
| Nanjangud     | 12.1167   | 76.6833   |
| Hunsur        | 12.3000   | 76.2833   |
| T Narasipura  | 12.2167   | 76.9167   |
| KRS           | 12.4167   | 76.5667   |
| Periyapatna   | 12.3333   | 76.1000   |
| HD Kote       | 12.0500   | 76.2667   |
| Saragur       | 11.9833   | 76.3833   |

---

## ML Models

| Model               | Target       |
|---------------------|--------------|
| Random Forest       | Crime Type + Risk Level (primary) |
| Decision Tree       | Crime Type + Risk Level |
| Logistic Regression | Crime Type + Risk Level |
| KMeans (k=5)        | Hotspot clustering |

---

## Tech Stack

- **Backend:** Python 3.10+, Flask 3.x
- **ML:** scikit-learn (Random Forest, Decision Tree, Logistic Regression, KMeans)
- **Database:** MongoDB Atlas (pymongo)
- **Frontend:** HTML5, CSS3, Vanilla JavaScript, Chart.js 4.x, Leaflet.js
- **Mobile:** Flutter (Android), Firebase Cloud Messaging, flutter_local_notifications
- **Data:** pandas, numpy
- **Model Persistence:** joblib
