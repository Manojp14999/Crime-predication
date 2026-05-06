import pandas as pd
from pymongo import MongoClient, errors
import logging

logger = logging.getLogger(__name__)

DB_NAME  = "mysuru_crime_db"
COL_NAME = "crimes"

def get_collection(uri="mongodb://localhost:27017/"):
    client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    return client[DB_NAME][COL_NAME]

def insert_dataframe(df: pd.DataFrame, uri="mongodb://localhost:27017/"):
    col = get_collection(uri)
    col.create_index("Crime_ID", unique=True)
    records = df.to_dict(orient="records")
    inserted = 0
    for rec in records:
        try:
            col.insert_one(rec)
            inserted += 1
        except errors.DuplicateKeyError:
            pass
    logger.info(f"Inserted {inserted}/{len(records)} records into MongoDB.")
    return inserted

def fetch_all(uri="mongodb://localhost:27017/") -> pd.DataFrame:
    col = get_collection(uri)
    docs = list(col.find({}, {"_id": 0}))
    return pd.DataFrame(docs) if docs else pd.DataFrame()

def count_records(uri="mongodb://localhost:27017/") -> int:
    return get_collection(uri).count_documents({})

def delete_record(crime_id: str, uri="mongodb://localhost:27017/") -> bool:
    result = get_collection(uri).delete_one({"Crime_ID": crime_id})
    return result.deleted_count > 0
