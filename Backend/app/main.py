from fastapi import FastAPI, File, UploadFile
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from app.routes import user, media
from app.database import Base, engine
from .ml_model import *
import json
from io import StringIO


Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(user.router)
app.include_router(media.router)

app.mount("/static", StaticFiles(directory="static"), name="static")

# Basic root
@app.get("/")
def read_root():
    return {"message": "Welcome to FastAPI"}

# Prediction
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    contents = await file.read()
    df = pd.read_csv(StringIO(contents.decode()))

    df, day_enc, area_enc, product_enc = load_and_preprocess_data(df)

    # Extract features and targets
    X = df[['hour', 'day_of_week', 'area_encoded']]
    y_product = df['product_label']
    y_quantity = df['quantity_class']
    y_area = df['area_encoded']

    # Train/test split (for training only)
    X_train, _, y_product_train, _, y_quantity_train, _, y_area_train, _ = train_test_split(
        X, y_product, y_quantity, y_area, test_size=0.2
    )
    X_keras = X_train[['hour', 'day_of_week']].values
    weights = compute_sample_weight(class_weight='balanced', y=y_quantity_train)

    # Train models
    lgbm_model = train_lightgbm(df)
    quantity_model = train_quantity_model(X_keras, y_quantity_train, weights)
    multi_model = train_multi_output_model(
        X_keras, y_product_train, y_area_train,
        len(product_enc.classes_), len(area_enc.classes_)
    )

    # Create a DataFrame with hours as index and days as columns
    hours = list(range(6, 24))  # 6:00 to 23:00
    days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
    resultDF = pd.DataFrame(index=hours, columns=days)

    # Fill the DataFrame with JSON strings of predictions
    for day in days:
        for hour in hours:
            prediction = predict_top5(
                hour=hour,
                day_name=day,
                day_encoder=day_enc,
                product_encoder=product_enc,
                area_encoder=area_enc,
                lgbm=lgbm_model,
                quantity_model=quantity_model,
                multi_model=multi_model
            )
            resultDF.at[hour, day] = json.dumps([
                {
                    'product_id': str(item['product_id']),
                    'confidence': float(item['confidence']),
                    'predicted_quantity': int(item['predicted_quantity']),
                    'predicted_area': str(item['predicted_area'])
                }
                for item in prediction
            ])

    # Save to CSV
    resultDF.to_csv("result.csv")
    return {"message": "Prediction completed. Visit /download to download result.csv"}

@app.get("/download")
def download_file():
    return FileResponse(
        path="result.csv",              # Path to file
        media_type="text/csv",          # MIME type
        filename="result.csv"           # Suggested filename on download
    )