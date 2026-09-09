import io
import time
import threading
from typing import List, Dict, Any, Optional
import cv2
import numpy as np
from PIL import Image
from fastapi import FastAPI, Request, Response, Query
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO

app = FastAPI(title="SAFAR Real-Time AI Computer Vision Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load lightweight YOLOv8 nano model for ultra-low latency inference
print("Loading YOLOv8 model for real-time vision...")
model = YOLO("yolov8n.pt")
print("YOLOv8 Ready!")

# Global stream tracker state
stream_lock = threading.Lock()
active_stream_url: Optional[str] = None
stream_running = False
latest_detections: List[Dict[str, Any]] = []
latest_fps: float = 0.0
latest_inference_ms: float = 0.0

CATEGORY_MAPPING = {
    "person": "person",
    "bicycle": "vehicle",
    "car": "vehicle",
    "motorcycle": "vehicle",
    "airplane": "drone",
    "bus": "vehicle",
    "train": "vehicle",
    "truck": "vehicle",
    "boat": "vehicle",
    "traffic light": "obstacle",
    "fire hydrant": "obstacle",
    "stop sign": "obstacle",
    "dog": "obstacle",
    "cat": "obstacle",
    "chair": "obstacle",
    "couch": "obstacle",
    "laptop": "obstacle",
    "cell phone": "obstacle",
    "bottle": "obstacle",
}

def parse_yolo_results(results, orig_w: int, orig_h: int) -> List[Dict[str, Any]]:
    detections = []
    if not results or len(results) == 0:
        return detections
    
    r = results[0]
    boxes = r.boxes
    if boxes is None:
        return detections

    for i, box in enumerate(boxes):
        coords = box.xyxy[0].tolist() # [x1, y1, x2, y2]
        conf = float(box.conf[0])
        cls_id = int(box.cls[0])
        cls_name = r.names[cls_id] if hasattr(r, 'names') and cls_id in r.names else "object"
        
        # Track ID from ByteTrack if active
        track_id = int(box.id[0]) if box.id is not None else (i + 1)
        
        x1, y1, x2, y2 = coords
        left = max(0.0, min(1.0, x1 / orig_w))
        top = max(0.0, min(1.0, y1 / orig_h))
        width = max(0.01, min(1.0, (x2 - x1) / orig_w))
        height = max(0.01, min(1.0, (y2 - y1) / orig_h))
        
        category = CATEGORY_MAPPING.get(cls_name.lower(), "obstacle")
        
        detections.append({
            "id": f"TRK-{track_id:02d}",
            "track_id": track_id,
            "label": cls_name.upper(),
            "confidence": round(conf, 3),
            "category": category,
            "normalized_rect": {
                "left": left,
                "top": top,
                "width": width,
                "height": height,
            },
            "distance_meters": round(15.0 + (1.0 - height) * 45.0, 1),
            "speed_kmh": round(0.0, 1),
        })
    return detections

@app.get("/health")
def health_check():
    return {
        "status": "online",
        "engine": "Ultralytics YOLOv8",
        "model": "yolov8n.pt",
    }

@app.post("/detect_frame")
async def detect_frame(request: Request):
    """
    Direct frame detection endpoint: Accepts JPEG/PNG raw bytes from Flutter
    and returns real detected targets with real bounding boxes and classes.
    """
    global latest_detections, latest_fps, latest_inference_ms
    start_time = time.time()
    
    body = await request.body()
    if not body:
        return {"status": "error", "message": "Empty frame body", "detections": []}

    try:
        # Decode image from bytes
        np_arr = np.frombuffer(body, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if img is None:
            return {"status": "error", "message": "Failed to decode image", "detections": []}

        h, w = img.shape[:2]
        
        # Run real-time YOLO tracking
        results = model.track(img, persist=True, tracker="bytetrack.yaml", verbose=False, conf=0.35, imgsz=480)
        
        inference_time_ms = round((time.time() - start_time) * 1000.0, 1)
        fps = round(1000.0 / max(1.0, inference_time_ms), 1)
        
        detections = parse_yolo_results(results, w, h)
        
        latest_detections = detections
        latest_fps = fps
        latest_inference_ms = inference_time_ms

        return {
            "status": "success",
            "model": "YOLOv8n",
            "inference_ms": inference_time_ms,
            "fps": fps,
            "target_count": len(detections),
            "detections": detections,
        }
    except Exception as e:
        return {"status": "error", "message": str(e), "detections": []}

@app.get("/latest_detections")
def get_latest_detections():
    return {
        "status": "success",
        "inference_ms": latest_inference_ms,
        "fps": latest_fps,
        "target_count": len(latest_detections),
        "detections": latest_detections,
    }

if __name__ == "__main__":
    import uvicorn
    print("Starting SAFAR AI Detection Server on http://127.0.0.1:5055 ...")
    uvicorn.run(app, host="127.0.0.1", port=5055, log_level="warning")
