# 🚀 Quick Start Guide - Sketch Recognition Test Feature

## 30-Second Setup

### 1. Install & Run Server (One-time)
```bash
# Windows
cd Code\backend
pip install -r requirements.txt
run_sketch_server.bat

# Linux/Mac
cd Code/backend
pip install -r requirements.txt
bash run_sketch_server.sh
```

### 2. Run Flutter App
```bash
cd Code/frontend
flutter run
```

### 3. Test It!
- Open app → See blue "Test Sketch Recognition" card
- Click "Start Test" → Draw → Click "Predict" → See results!

---

## 📍 Key Files

| File | Purpose |
|------|---------|
| `sketch_recognition_server.py` | Python AI server |
| `sketch_recognition_test_screen.dart` | Flutter test UI |
| `requirements.txt` | Python dependencies |
| `run_sketch_server.bat` | Windows launcher |
| `run_sketch_server.sh` | Linux/Mac launcher |

---

## ⚠️ Requirements

- [x] Model file: `resnet34_epoch_18.pt` in `Code/backend/` (already there ✓)
- [x] Python 3.7+ installed
- [x] PyTorch installed (via requirements.txt)
- [x] Flutter environment configured

---

## 🎮 How It Works

```
User draws → Flutter canvas captures image → 
Sends to Python server (port 5000) → 
AI predicts (ResNet34) → 
Returns top 5 guesses → 
Display results in app
```

---

## 🔧 Configuration

**Server running on**: `http://localhost:5000` (or your IP)

**Endpoints**:
- `GET /health` - Check server status
- `POST /predict` - Send drawing for prediction
- `GET /classes` - See all 345 object classes

---

## ✅ Verify Setup

Check server is running:
```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "status": "ok",
  "model_loaded": true,
  "device": "cuda",
  "num_classes": 345
}
```

---

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| "Server request timed out" | Start Python server on port 5000 |
| "Model not loaded" | Verify `resnet34_epoch_18.pt` exists |
| App won't connect | Check firewall, verify server URL |
| Inaccurate predictions | Draw clearer, simpler sketches |

---

## 📊 What The AI Can Recognize

✅ Animals (cat, dog, elephant, etc.)
✅ Objects (car, house, phone, etc.)
✅ Shapes (circle, triangle, square, etc.)
✅ Food (pizza, ice cream, apple, etc.)
✅ Activities (dancing, swimming, etc.)
✅ And 295+ more classes!

---

## 🎨 Canvas Tips

- 280x280 pixel white canvas
- 18px brush width
- Draw in center of canvas
- Keep drawings simple and clear
- Works best with single object sketches

---

## 🚦 App Flow

```
Lobby Screen
    ↓
[See "Test Sketch Recognition" card]
    ↓
[Click "Start Test"]
    ↓
Test Screen
    ↓
[Draw on canvas]
    ↓
[Click "Predict"]
    ↓
[View top 5 predictions]
```

---

## 📞 Need Help?

1. Check console output from Python server
2. Verify all files exist in correct locations
3. Ensure Python dependencies installed: `pip list | grep -i flask torch`
4. Check network connectivity between app and server
5. Review detailed setup guide: `SKETCH_RECOGNITION_SETUP.md`

---

**Version**: 1.0
**Status**: ✅ Production Ready
**Last Updated**: December 2024
