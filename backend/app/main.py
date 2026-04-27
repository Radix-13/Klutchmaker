from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Klutchmaker backend is running"}