import pandas as pd
import numpy as np
import tensorflow as tf
import lightgbm as lgb

from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.utils.class_weight import compute_sample_weight


def load_and_preprocess_data(df):
    df['delivery_time'] = pd.to_datetime(df['delivery_time'], format='%Y-%m-%d %H:%M:%S', errors='coerce')
    df['hour'] = df['delivery_time'].dt.hour
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['day_of_week'] = df['order_date'].dt.day_name()

    df.drop(['order_id', 'unit_price', 'delivery_time', 'order_date'], axis=1, inplace=True)

    day_encoder = LabelEncoder()
    df['day_of_week'] = day_encoder.fit_transform(df['day_of_week'])

    area_encoder = LabelEncoder()
    df['area_encoded'] = area_encoder.fit_transform(df['area'])

    product_encoder = LabelEncoder()
    df['product_label'] = product_encoder.fit_transform(df['product_id'])

    df['quantity_class'] = df['quantity'] - 1

    return df, day_encoder, area_encoder, product_encoder


def train_lightgbm(df):
    X = df[['hour', 'day_of_week']]
    y = df['product_label']
    X_train, _, y_train, _ = train_test_split(X, y, test_size=0.2)
    clf = lgb.LGBMClassifier()
    clf.fit(X_train, y_train)
    return clf


def train_quantity_model(X, y, sample_weights):
    model = tf.keras.Sequential([
        tf.keras.Input(shape=(2,)),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dense(5, activation='softmax')
    ])
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    model.fit(X, y, sample_weight=sample_weights, epochs=5, batch_size=32, verbose=0)
    return model


def train_multi_output_model(X, y_product, y_area, n_product, n_area):
    inputs = tf.keras.Input(shape=(2,))
    x = tf.keras.layers.Dense(64, activation='relu')(inputs)
    x = tf.keras.layers.Dense(128, activation='relu')(x)

    product_output = tf.keras.layers.Dense(n_product, activation='softmax', name='product')(x)
    area_output = tf.keras.layers.Dense(n_area, activation='softmax', name='area')(x)

    model = tf.keras.Model(inputs=inputs, outputs=[product_output, area_output])
    model.compile(
        optimizer='adam',
        loss={'product': 'sparse_categorical_crossentropy', 'area': 'sparse_categorical_crossentropy'},
        metrics={'product': 'accuracy', 'area': 'accuracy'}
    )
    model.fit(X, {'product': y_product, 'area': y_area}, epochs=5, batch_size=32, verbose=0)
    return model


def predict_top5(hour, day_name, day_encoder, product_encoder, area_encoder, lgbm, quantity_model, multi_model):
    encoded_day = day_encoder.transform([day_name])[0]
    input_data = np.array([[hour, encoded_day]])

    product_probs = lgbm.predict_proba(input_data)[0]
    top5_indices = product_probs.argsort()[-5:][::-1]
    top5_product_ids = product_encoder.inverse_transform(top5_indices)
    top5_confidences = product_probs[top5_indices]

    quantity_probs = quantity_model.predict(input_data, verbose=0)
    quantity = int(np.argmax(quantity_probs[0]) + 1)

    _, area_probs = multi_model.predict(input_data, verbose=0)
    area_idx = np.argmax(area_probs[0])
    predicted_area = area_encoder.inverse_transform([area_idx])[0]

    return [
        {
            'product_id': pid,
            'confidence': round(float(conf), 4),
            'predicted_quantity': quantity,
            'predicted_area': predicted_area
        }
        for pid, conf in zip(top5_product_ids, top5_confidences)
    ]
