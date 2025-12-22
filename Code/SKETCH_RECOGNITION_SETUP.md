# Sketch Recognition Test Feature - Setup & Implementation Guide

## Overview
The sketch recognition test feature has been successfully implemented! It allows users to:
- Draw sketches on a canvas in the app
- Send the drawing to a Python Flask server for AI recognition
- See the top 5 predictions with confidence scores

## Components Added

### 1. **Backend - Python Flask Server** (`sketch_recognition_server.py`)
- **Location**: `Code/backend/sketch_recognition_server.py`
- **Port**: 5000
- **Model**: ResNet34 with 345 QuickDraw classes
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /predict` - Predict sketch class from image
  - `GET /classes` - Get list of all 345 classes
  - `CORS` enabled for cross-origin requests

### 2. **Frontend - Flutter Test Screen** (`sketch_recognition_test_screen.dart`)
- **Location**: `Code/frontend/lib/screens/pages/sketch_recognition_test_screen.dart`
- **Features**:
  - Interactive canvas for drawing (280x280 pixels)
  - Clear and Predict buttons
  - Real-time prediction results display
  - Top 5 predictions with confidence scores
  - Animated loading state
  - Error handling and server connection feedback

### 3. **Modified Files**
- **scribble_lobby_screen.dart**:
  - Added import for `sketch_recognition_test_screen.dart`
  - Added new `_buildTestCard()` widget
  - Test card appears on the lobby screen with a "Start Test" button

## Installation & Setup

### Step 1: Install Python Dependencies
```bash
cd Code/backend
pip install -r requirements.txt
```

**Required packages** (already in `requirements.txt`):
- torch
- torchvision
- flask
- flask-cors
- opencv-python (cv2)
- numpy
- pillow

### Step 2: Start the Python Server
```bash
cd Code/backend
python sketch_recognition_server.py
```

**Expected output**:
```
✅ Model loaded from resnet34_epoch_18.pt
🚀 Starting Flask sketch recognition server...
📊 Using device: cuda  # or cpu
 * Running on http://0.0.0.0:5000
```

**Important Notes**:
- The server loads the `resnet34_epoch_18.pt` model file from the backend folder
- Ensure GPU drivers are installed if you want to use CUDA acceleration
- If no GPU available, it will automatically use CPU (slower but works)

### Step 3: Configure Flutter Frontend
The Flutter frontend is automatically configured. The test screen uses the WebSocket URL to connect to the Python server.

**Server URL Configuration**:
- The test screen receives the server URL from the lobby screen
- It automatically converts `ws://` to `http://` for HTTP requests to the Python server
- Default: `http://192.168.200.163:5000`

### Step 4: Run the Application
```bash
cd Code/frontend
flutter run
```

## Usage

### From the Lobby Screen:
1. User sees a new blue "Test Sketch Recognition" card on the lobby
2. Click "Start Test" button to navigate to the test screen

### On the Test Screen:
1. **Draw**: Touch and drag on the canvas to draw your sketch
2. **Clear**: Click "Clear" to erase the canvas
3. **Predict**: Click "Predict" to send to the AI
4. **Results**: View the top 5 predictions with confidence percentages

## API Reference

### POST /predict
**Request**:
```json
{
  "image": "data:image/png;base64,<base64_encoded_image>"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "predictions": [
    {"rank": 1, "class": "cat", "confidence": 0.9523},
    {"rank": 2, "class": "dog", "confidence": 0.0234},
    ...
  ],
  "top_prediction": "cat"
}
```

**Response (Error)**:
```json
{
  "success": false,
  "error": "Error message"
}
```

## Troubleshooting

### Issue: "Server request timed out"
- **Solution**: Ensure the Python Flask server is running on port 5000
- Check firewall settings if server is on a different machine
- Verify network connectivity between mobile device and server

### Issue: "Model not loaded. Server may still be initializing"
- **Solution**: Check that `resnet34_epoch_18.pt` exists in the backend folder
- Restart the Python server
- Check console for model loading errors

### Issue: Predictions are inaccurate
- The model was trained on QuickDraw dataset
- Draw simple, clear sketches in the center of the canvas
- Similar objects may have overlapping predictions (e.g., cat/dog)

### Issue: Server returns 503 (Service Unavailable)
- **Solution**: Model failed to load - check `sketch_recognition_server.py` output
- Verify PyTorch and model file are properly installed

## File Structure

```
Code/
├── backend/
│   ├── sketch_recognition_server.py    ← New Flask server
│   ├── requirements.txt                ← New dependencies file
│   ├── resnet34_epoch_18.pt            ← Model file (must exist)
│   └── ... (other backend files)
│
└── frontend/
    └── lib/
        └── screens/
            └── pages/
                ├── sketch_recognition_test_screen.dart  ← New test screen
                ├── scribble_lobby_screen.dart          ← Modified (added test button)
                └── ... (other pages)
```

## Performance Notes

- **Model Loading**: ~5-10 seconds (one-time on server startup)
- **Image Processing**: ~100-200ms per prediction
- **Canvas Rendering**: 280x280 pixels at 18px brush width
- **Supported Image Formats**: PNG, JPG (auto-converted to grayscale)

## Classes Recognized (345 Total)

The model can recognize 345 different objects from the QuickDraw dataset including:
- Animals: cat, dog, bird, elephant, giraffe, etc.
- Objects: apple, car, house, phone, computer, etc.
- Shapes: circle, triangle, square, star, etc.
- Activities: dancing, swimming, running, etc.
- And many more!

See `/classes` endpoint for complete list.

## Future Enhancements

Possible improvements:
1. Add gesture recognition (swipe to clear, etc.)
2. Save drawing history to local storage
3. Share predictions on social media
4. Leaderboard for quick predictions
5. Real-time confidence score display while drawing
6. Multiple sketch support (drawing 5 objects and guessing all)

## Support

For issues or feature requests:
1. Check the troubleshooting section
2. Review server logs in console
3. Verify all dependencies are installed
4. Ensure model file exists and is accessible
