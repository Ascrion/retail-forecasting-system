from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.routes import user, media
from app.database import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(user.router)
app.include_router(media.router)

app.mount("/static", StaticFiles(directory="static"), name="static")

# Basic root
@app.get("/")
def read_root():
    return {"message": "Welcome to FastAPI"}