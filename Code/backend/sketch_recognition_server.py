"""
Flask server for sketch recognition using ResNet34 model.
Handles image predictions for the Doodle game test feature.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
import torch.nn as nn
from torchvision import models
import numpy as np
import cv2
import base64
from io import BytesIO
from PIL import Image
import os
import json
from pathlib import Path

# Configuration
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
NUM_CLASSES = 345
MODEL_PATH = os.path.join(os.path.dirname(__file__), "models/resnet34_epoch_13.pt")

# Classes list (345 classes from QuickDraw)
CLASSES = [
    "The Eiffel Tower", "The Great Wall of China", "The Mona Lisa",
    "aircraft carrier", "airplane", "alarm clock", "ambulance", "angel", 
    "animal migration", "ant", "anvil", "apple", "arm", "asparagus", "axe",
    "backpack", "banana", "bandage", "barn", "baseball bat", "baseball", 
    "basket", "basketball", "bat", "bathtub", "beach", "bear", "beard", 
    "bed", "bee", "belt", "bench", "bicycle", "binoculars", "bird", 
    "birthday cake", "blackberry", "blueberry", "book", "boomerang", 
    "bottlecap", "bowtie", "bracelet", "brain", "bread", "bridge", "broccoli",
    "broom", "bucket", "bulldozer", "bus", "bush", "butterfly", "cactus", 
    "cake", "calculator", "calendar", "camel", "camera", "camouflage", 
    "campfire", "candle", "cannon", "canoe", "car", "carrot", "castle", 
    "cat", "ceiling fan", "cell phone", "cello", "chair", "chandelier", 
    "church", "circle", "clarinet", "clock", "cloud", "coffee cup", "compass",
    "computer", "cookie", "cooler", "couch", "cow", "crab", "crayon", 
    "crocodile", "crown", "cruise ship", "cup", "diamond", "dishwasher", 
    "diving board", "dog", "dolphin", "donut", "door", "dragon", "dresser",
    "drill", "drums", "duck", "dumbbell", "ear", "elbow", "elephant", 
    "envelope", "eraser", "eye", "eyeglasses", "face", "fan", "feather", 
    "fence", "finger", "fire hydrant", "fireplace", "firetruck", "fish", 
    "flamingo", "flashlight", "flip flops", "floor lamp", "flower", 
    "flying saucer", "foot", "fork", "frog", "frying pan", "garden hose", 
    "garden", "giraffe", "goatee", "golf club", "grapes", "grass", "guitar",
    "hamburger", "hammer", "hand", "harp", "hat", "headphones", "hedgehog",
    "helicopter", "helmet", "hexagon", "hockey puck", "hockey stick", "horse",
    "hospital", "hot air balloon", "hot dog", "hot tub", "hourglass", 
    "house plant", "house", "hurricane", "ice cream", "jacket", "jail", 
    "kangaroo", "key", "keyboard", "knee", "knife", "ladder", "lantern", 
    "laptop", "leaf", "leg", "light bulb", "lighter", "lighthouse", 
    "lightning", "line", "lion", "lipstick", "lobster", "lollipop", "mailbox",
    "map", "marker", "matches", "megaphone", "mermaid", "microphone", 
    "microwave", "monkey", "moon", "mosquito", "motorbike", "mountain", 
    "mouse", "moustache", "mouth", "mug", "mushroom", "nail", "necklace", 
    "nose", "ocean", "octagon", "octopus", "onion", "oven", "owl", 
    "paint can", "paintbrush", "palm tree", "panda", "pants", "paper clip", 
    "parachute", "parrot", "passport", "peanut", "pear", "peas", "pencil", 
    "penguin", "piano", "pickup truck", "picture frame", "pig", "pillow", 
    "pineapple", "pizza", "pliers", "police car", "pond", "pool", "popsicle",
    "postcard", "potato", "power outlet", "purse", "rabbit", "raccoon", 
    "radio", "rain", "rainbow", "rake", "remote control", "rhinoceros", 
    "rifle", "river", "roller coaster", "rollerskates", "sailboat", "sandwich",
    "saw", "saxophone", "school bus", "scissors", "scorpion", "screwdriver", 
    "sea turtle", "see saw", "shark", "sheep", "shoe", "shorts", "shovel", 
    "sink", "skateboard", "skull", "skyscraper", "sleeping bag", "smiley face",
    "snail", "snake", "snorkel", "snowflake", "snowman", "soccer ball", "sock",
    "speedboat", "spider", "spoon", "spreadsheet", "square", "squiggle", 
    "squirrel", "stairs", "star", "steak", "stereo", "stethoscope", "stitches",
    "stop sign", "stove", "strawberry", "streetlight", "string bean", 
    "submarine", "suitcase", "sun", "swan", "sweater", "swing set", "sword", 
    "syringe", "t-shirt", "table", "teapot", "teddy-bear", "telephone", 
    "television", "tennis racquet", "tent", "tiger", "toaster", "toe", 
    "toilet", "tooth", "toothbrush", "toothpaste", "tornado", "tractor", 
    "traffic light", "train", "tree", "triangle", "trombone", "truck", 
    "trumpet", "umbrella", "underwear", "van", "vase", "violin", 
    "washing machine", "watermelon", "waterslide", "whale", "wheel", 
    "windmill", "wine bottle", "wine glass", "wristwatch", "yoga", "zebra", 
    "zigzag"
]

app = Flask(__name__)
CORS(app)

# Global model variable
model = None

def load_model():
    """Load the ResNet34 model from checkpoint."""
    global model
    try:
        model = models.resnet34(weights=None)
        model.conv1 = nn.Conv2d(1, 64, kernel_size=7, stride=2, padding=3, bias=False)
        model.fc = nn.Linear(model.fc.in_features, NUM_CLASSES)
        
        model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
        model.to(DEVICE)
        model.eval()
        print(f"✅ Model loaded from {MODEL_PATH}")
        return True
    except Exception as e:
        print(f"❌ Failed to load model: {str(e)}")
        return False

def process_image(image_data):
    """
    Process image from base64 or file format to tensor.
    Expected format: base64 encoded PNG/JPG or raw image data
    """
    try:
        # If it's base64 encoded
        if isinstance(image_data, str):
            # Remove data URL prefix if present
            if image_data.startswith('data:image'):
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes)).convert('L')  # Convert to grayscale
            img_array = np.array(image)
        else:
            # Direct numpy array
            img_array = image_data
        
        # Resize to 112x112 (model expects this)
        img_resized = cv2.resize(img_array, (112, 112))
        
        # Normalize
        img_normalized = img_resized.astype(np.float32) / 255.0
        
        # Convert to tensor
        tensor = torch.tensor(img_normalized).unsqueeze(0).unsqueeze(0).float().to(DEVICE)
        return tensor
    except Exception as e:
        print(f"❌ Error processing image: {str(e)}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'device': str(DEVICE),
        'num_classes': NUM_CLASSES
    }), 200

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict sketch class from image.
    
    Expected POST body:
    {
        "image": "<base64_encoded_image_or_url_data>"
    }
    
    Returns:
    {
        "success": true,
        "predictions": [
            {"rank": 1, "class": "class_name", "confidence": 0.95},
            ...
        ],
        "top_prediction": "class_name"
    }
    """
    if model is None:
        return jsonify({
            'success': False,
            'error': 'Model not loaded. Server may still be initializing.'
        }), 503
    
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing image data in request'
            }), 400
        
        # Process the image
        image_tensor = process_image(data['image'])
        if image_tensor is None:
            return jsonify({
                'success': False,
                'error': 'Failed to process image'
            }), 400
        
        # Run prediction
        with torch.no_grad():
            logits = model(image_tensor)
            probs = torch.softmax(logits, dim=1)[0]
        
        # Get top 5 predictions
        top5_probs, top5_indices = torch.topk(probs, 5)
        
        predictions = []
        for rank, (prob, idx) in enumerate(zip(top5_probs, top5_indices)):
            class_idx = idx.item()
            confidence = prob.item()
            class_name = CLASSES[class_idx] if class_idx < len(CLASSES) else f"Unknown_{class_idx}"
            
            predictions.append({
                'rank': rank + 1,
                'class': class_name,
                'confidence': round(confidence, 4)
            })
        
        return jsonify({
            'success': True,
            'predictions': predictions,
            'top_prediction': predictions[0]['class']
        }), 200
    
    except Exception as e:
        print(f"❌ Prediction error: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/classes', methods=['GET'])
def get_classes():
    """Get list of all possible classes."""
    return jsonify({
        'success': True,
        'num_classes': len(CLASSES),
        'classes': CLASSES
    }), 200

if __name__ == '__main__':
    # Load model before starting server
    if not load_model():
        print("⚠️ Warning: Could not load model. Server will still run but predictions will fail.")
    
    print(f"🚀 Starting Flask sketch recognition server...")
    print(f"📊 Using device: {DEVICE}")
    app.run(host='0.0.0.0', port=5000, debug=False)
