from __future__ import annotations

import os

from .base import DataStore
from .sql_store import SQLDataStore


def create_data_store() -> DataStore:
    backend = os.getenv("DB_BACKEND", "sql").strip().lower()
    if backend == "sql":
        return SQLDataStore()
    if backend in {"mongo", "mongodb"}:
        from .mongo_store import MongoDataStore

        return MongoDataStore()
    raise ValueError(f"Unsupported DB_BACKEND={backend!r}. Use 'sql' or 'mongo'.")
