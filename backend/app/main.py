
from fastapi import FastAPI

app = FastAPI(title="Social Pub Hub API")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/integrations")
def integrations():
    return {
        "integrations": [
            {"platform": "x", "connected": False},
            {"platform": "linkedin", "connected": False},
            {"platform": "reddit", "connected": False},
            {"platform": "facebook", "connected": False},
            {"platform": "youtube", "connected": False},
        ]
    }
