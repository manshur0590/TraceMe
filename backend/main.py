from fastapi import FastAPI, UploadFile, HTTPException
import numpy as np
from insightface.app import FaceAnalysis
import requests
import json

SUPABASE_URL = "https://lijmcwxxlnvqynpwefyb.supabase.co"
SUPABASE_KEY = "your-service-role-key"

app = FastAPI()

# Load face model (ArcFace)
face_app = FaceAnalysis(name='buffalo_l')
face_app.prepare(ctx_id=-1, det_size=(640, 640))  # CPU mode

def cosine_distance(a, b):
    return 1 - np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

@app.post("/search-face")
async def search_face(file: UploadFile):
    img_bytes = await file.read()

    faces = face_app.get(img_bytes)
    if not faces:
        raise HTTPException(status_code=400, detail="No face detected")

    query_emb = faces[0].embedding  # 512-dim vector

    # Fetch all embeddings from Supabase
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    resp = requests.get(f"{SUPABASE_URL}/rest/v1/missing_persons?select=id,name,photo_url,face_embedding",
                        headers=headers)

    if resp.status_code != 200:
        raise HTTPException(status_code=500, detail="Failed to fetch data")

    persons = resp.json()
    best_match = None
    min_dist = 1.0

    for person in persons:
        emb = np.array(person['face_embedding'], dtype=np.float32)
        dist = cosine_distance(query_emb, emb)
        if dist < min_dist:
            min_dist = dist
            best_match = person

    if min_dist < 0.35:
        return {
            "id": best_match['id'],
            "name": best_match['name'],
            "photo_url": best_match['photo_url'],
            "distance": float(min_dist)
        }
    else:
        return {"message": "No match found"}
