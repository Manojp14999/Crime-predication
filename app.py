import os
import sys
import logging
import pandas as pd
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash

sys.path.insert(0, os.path.dirname(__file__))

AREAS = {
    "Mysuru City": {}, "Bannur": {}, "Nanjangud": {}, "Hunsur": {},
    "T Narasipura": {}, "KRS": {}, "Periyapatna": {}, "HD Kote": {}, "Saragur": {}
}
from src.model_training   import train_models
from src.prediction       import predict
from src.analytics_module import get_analytics
from src.db_handler       import insert_dataframe, fetch_all, count_records, delete_record

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler("app.log")]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = "mysuru_crime_secret_2024"

MONGO_URI = os.environ.get("MONGO_URI", "mongodb+srv://manojp14999_db_user:kBPH0aeHduHxyN2z@cluster0.gughvlp.mongodb.net/mysuru_crime_db?retryWrites=true&w=majority")
MODELS_READY = os.path.exists("models/random_forest_crime.pkl")
MODEL_ACCURACIES = {}

DAYS   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
MONTHS = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"]
WEATHERS = ["Clear", "Cloudy", "Rainy", "Foggy", "Stormy"]

def _load_df():
    try:
        return fetch_all(MONGO_URI)
    except Exception as e:
        logger.warning(f"DB fetch failed: {e}")
        return pd.DataFrame()

@app.route("/")
def index():
    df = _load_df()
    analytics = get_analytics(df) if not df.empty else {}
    return render_template("index.html", analytics=analytics, models_ready=MODELS_READY)

@app.route("/predict", methods=["GET"])
def predict_page():
    return render_template("predict.html",
                           areas=list(AREAS.keys()),
                           days=DAYS, months=MONTHS, weathers=WEATHERS,
                           models_ready=MODELS_READY)

@app.route("/api/predict", methods=["POST"])
def api_predict():
    global MODELS_READY
    if not MODELS_READY:
        return jsonify({"error": "Models not trained yet. Please train first."}), 503
    try:
        data = request.get_json() or request.form
        result = predict(
            area               = str(data.get("area", "Mysuru City")),
            hour               = int(data.get("hour", 12)),
            day                = str(data.get("day", "Monday")),
            month              = str(data.get("month", "January")),
            weather            = str(data.get("weather", "Clear")),
            population_density = int(data.get("population_density", 5000)),
            is_weekend         = int(data.get("is_weekend", 0)),
            is_festival        = int(data.get("is_festival", 0)),
        )
        logger.info(f"Prediction: {result}")
        return jsonify(result)
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        file = request.files.get("file")
        if not file or not file.filename.endswith(".csv"):
            flash("Please upload a valid CSV file.", "danger")
            return redirect(url_for("upload"))
        try:
            df = pd.read_csv(file)
            required = {"Crime_ID", "Area", "Hour", "Day", "Month", "Crime_Type", "Risk_Level"}
            if not required.issubset(df.columns):
                flash(f"Missing columns: {required - set(df.columns)}", "danger")
                return redirect(url_for("upload"))
            total = len(df)
            inserted = insert_dataframe(df, MONGO_URI)
            duplicates = total - inserted
            msg = f"Inserted {inserted} new records into MongoDB."
            if duplicates:
                msg += f" ({duplicates} duplicates skipped — Crime_IDs already exist)"
            flash(msg, "success" if inserted > 0 else "warning")
            if inserted > 0:
                _retrain_on_upload()
        except Exception as e:
            logger.error(f"Upload error: {e}")
            flash(f"Error: {e}", "danger")
        return redirect(url_for("upload"))
    return render_template("upload.html")

@app.route("/train", methods=["POST"])
def train():
    global MODELS_READY
    try:
        df = _load_df()
        if df.empty:
            return jsonify({"status": "error", "message": "No data in database. Please upload a CSV file first."}), 400
        results = train_models(df)
        MODELS_READY = True
        MODEL_ACCURACIES.update(results)
        _send_high_risk_alerts(df)
        return jsonify({"status": "success", "accuracies": results})
    except Exception as e:
        logger.error(f"Training error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/api/analytics")
def api_analytics():
    df = _load_df()
    return jsonify(get_analytics(df))

@app.route("/api/status")
def api_status():
    try:
        count = count_records(MONGO_URI)
        db_status = "connected"
    except Exception:
        count = 0
        db_status = "disconnected"
    return jsonify({
        "models_ready": MODELS_READY,
        "db_status":    db_status,
        "record_count": count,
    })

@app.route("/api/compare")
def api_compare():
    return jsonify(MODEL_ACCURACIES)

@app.route("/records")
def records_page():
    page     = int(request.args.get("page", 1))
    search   = request.args.get("search", "").strip()
    per_page = 20
    return render_template("records.html", page=page, search=search, per_page=per_page)

@app.route("/api/records")
def api_records():
    page     = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 20))
    search   = request.args.get("search", "").strip()
    try:
        from src.db_handler import get_collection
        col = get_collection(MONGO_URI)
        query = {"$or": [
            {"Crime_ID":   {"$regex": search, "$options": "i"}},
            {"Area":       {"$regex": search, "$options": "i"}},
            {"Crime_Type": {"$regex": search, "$options": "i"}},
            {"Risk_Level": {"$regex": search, "$options": "i"}},
        ]} if search else {}
        total = col.count_documents(query)
        docs  = list(col.find(query, {"_id": 0})
                        .skip((page - 1) * per_page)
                        .limit(per_page))
        return jsonify({"records": docs, "total": total, "page": page, "per_page": per_page})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/records/delete/<crime_id>", methods=["DELETE"])
def api_delete_record(crime_id):
    try:
        deleted = delete_record(crime_id, MONGO_URI)
        if deleted:
            return jsonify({"status": "deleted"})
        return jsonify({"error": "Record not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/add_record", methods=["POST"])
def api_add_record():
    try:
        data = request.get_json()
        import uuid
        from datetime import datetime
        date_obj = datetime.strptime(data["date"], "%Y-%m-%d")
        record = {
            "Crime_ID":           data.get("crime_id") or f"MYS-{uuid.uuid4().hex[:8].upper()}",
            "Date":               data["date"],
            "Time":               data["time"],
            "Day":                date_obj.strftime("%A"),
            "Month":              date_obj.strftime("%B"),
            "Year":               date_obj.year,
            "Area":               data["area"],
            "Latitude":           float(data["latitude"]),
            "Longitude":          float(data["longitude"]),
            "Crime_Type":         data["crime_type"],
            "Risk_Level":         data["risk_level"],
            "Population_Density": int(data["population_density"]),
            "Weather":            data["weather"],
            "Is_Weekend":         1 if date_obj.weekday() >= 5 else 0,
            "Is_Festival":        int(data.get("is_festival", 0)),
            "Hour":               int(data["time"].split(":")[0]),
        }
        df = pd.DataFrame([record])
        inserted = insert_dataframe(df, MONGO_URI)
        if inserted == 0:
            return jsonify({"status": "error", "message": "Record already exists (duplicate Crime_ID)."}), 409
        _retrain_on_upload()
        return jsonify({"status": "success", "crime_id": record["Crime_ID"]})
    except Exception as e:
        logger.error(f"Add record error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/api/alert", methods=["POST"])
def api_alert():
    try:
        import json, urllib.request, urllib.parse
        data     = request.get_json()
        area     = data.get("area", "All Areas")
        message  = data.get("message", "")
        severity = data.get("severity", "High")
        topic = "crime_alerts" if area == "All Areas" else area.lower().replace(" ", "_")

        sa_path = os.path.join(os.path.dirname(__file__), "firebase_service_account.json")
        if os.path.exists(sa_path):
            import google.oauth2.service_account as sa
            import google.auth.transport.requests as ga_requests
            credentials = sa.Credentials.from_service_account_file(
                sa_path,
                scopes=["https://www.googleapis.com/auth/firebase.messaging"]
            )
            credentials.refresh(ga_requests.Request())
            token = credentials.token

            with open(sa_path) as f:
                project_id = json.load(f)["project_id"]

            payload = json.dumps({
                "message": {
                    "topic": topic,
                    "notification": {
                        "title": f"\U0001f6a8 {severity} Alert \u2014 {area}",
                        "body": message
                    },
                    "data": {"area": area, "severity": severity}
                }
            }).encode()
            req = urllib.request.Request(
                f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
                data=payload,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
            )
            urllib.request.urlopen(req)
            logger.info(f"FCM alert sent via service account: [{severity}] {area}")
        else:
            logger.warning("firebase_service_account.json not found — alert not sent via FCM")

        return jsonify({"status": "sent", "area": area, "severity": severity})
    except Exception as e:
        logger.error(f"Alert error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/clear", methods=["POST"])
def api_clear():
    global MODELS_READY
    try:
        from src.db_handler import get_collection
        get_collection(MONGO_URI).drop()
        MODELS_READY = False
        MODEL_ACCURACIES.clear()
        logger.info("All records cleared from MongoDB.")
        return jsonify({"status": "cleared"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/export")
def api_export():
    from flask import Response
    df = _load_df()
    if df.empty:
        return jsonify({"error": "No data"}), 404
    return Response(
        df.to_csv(index=False),
        mimetype="text/csv",
        headers={"Content-Disposition": "attachment; filename=mysuru_crime_export.csv"}
    )

def _send_fcm_alert(title: str, body: str, topic: str = "crime_alerts"):
    """Send FCM push notification to all subscribers of a topic."""
    import json, urllib.request
    sa_path = os.path.join(os.path.dirname(__file__), "firebase_service_account.json")
    if not os.path.exists(sa_path):
        logger.warning("firebase_service_account.json not found — FCM alert skipped")
        return
    try:
        import google.oauth2.service_account as sa
        import google.auth.transport.requests as ga_requests
        credentials = sa.Credentials.from_service_account_file(
            sa_path, scopes=["https://www.googleapis.com/auth/firebase.messaging"]
        )
        credentials.refresh(ga_requests.Request())
        with open(sa_path) as f:
            project_id = json.load(f)["project_id"]
        payload = json.dumps({
            "message": {
                "topic": topic,
                "notification": {"title": title, "body": body},
                "data": {"type": "high_risk_alert"}
            }
        }).encode()
        req = urllib.request.Request(
            f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
            data=payload,
            headers={"Authorization": f"Bearer {credentials.token}", "Content-Type": "application/json"}
        )
        urllib.request.urlopen(req)
        logger.info(f"FCM alert sent → topic={topic}: {title}")
    except Exception as e:
        logger.error(f"FCM send failed: {e}")


def _send_high_risk_alerts(df):
    """After training, find high-risk areas and push alerts to mobile."""
    import threading
    def _run():
        try:
            if df.empty or "Risk_Level" not in df.columns:
                return
            high_risk = df[df["Risk_Level"] == "High"]
            if high_risk.empty:
                return
            area_counts = high_risk.groupby("Area").size().sort_values(ascending=False)
            top_areas = area_counts.head(3)
            summary = ", ".join([f"{area} ({count} cases)" for area, count in top_areas.items()])
            _send_fcm_alert(
                title="🚨 High Risk Alert — Mysuru District",
                body=f"High crime activity detected in: {summary}. Stay alert!",
                topic="crime_alerts"
            )
            # Also send per-area alerts
            for area, count in top_areas.items():
                topic = area.lower().replace(" ", "_")
                _send_fcm_alert(
                    title=f"⚠️ High Risk — {area}",
                    body=f"{count} high-risk crimes recorded. Exercise caution.",
                    topic=topic
                )
        except Exception as e:
            logger.error(f"High risk alert error: {e}")
    threading.Thread(target=_run, daemon=True).start()


def _retrain_on_upload():
    global MODELS_READY
    import threading
    def _run():
        try:
            df = _load_df()
            results = train_models(df)
            MODELS_READY = True
            MODEL_ACCURACIES.update(results)
            _send_high_risk_alerts(df)
            logger.info(f"Retrain complete on {len(df)} records. Accuracies: {results}")
        except Exception as e:
            logger.error(f"Retrain failed: {e}")
    threading.Thread(target=_run, daemon=True).start()

def _startup_init():
    global MODELS_READY
    if MODELS_READY:
        logger.info("Models already exist — ready.")
        return
    logger.info("No trained models found. Upload a CSV to get started.")

if __name__ == "__main__":
    os.makedirs("models", exist_ok=True)
    os.makedirs("data", exist_ok=True)

    import threading
    t = threading.Thread(target=_startup_init, daemon=True)
    t.start()

    app.run(debug=False, host="0.0.0.0", port=5000)
