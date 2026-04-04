#!/usr/bin/env python3
"""
Nia Vision API — Backend for Nia Glasses app.
Receives photos from Meta Ray-Ban glasses, sends to Claude vision, returns analysis.
"""

import base64
import os

import anthropic
from flask import Flask, jsonify, request

app = Flask(__name__)

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

SYSTEM_PROMPT = """You are Nia, an AI assistant looking through smart glasses worn by Jeremy,
a startup CEO. When he asks you to identify or describe something, be concise and direct.
Lead with what matters most. If you see text, read it. If you see a person, describe context
clues (not appearance). If you see a product, document, or screen, extract the key information.
Keep responses under 3 sentences unless asked for detail — these get spoken aloud."""


@app.route("/api/vision", methods=["POST"])
def analyze_image():
    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400

    image_file = request.files["image"]
    image_data = image_file.read()
    prompt = request.form.get("prompt", "What am I looking at? Describe it concisely.")

    image_b64 = base64.standard_b64encode(image_data).decode("utf-8")

    # Detect media type
    media_type = "image/jpeg"
    if image_file.filename and image_file.filename.lower().endswith(".png"):
        media_type = "image/png"
    elif image_file.filename and image_file.filename.lower().endswith(".heic"):
        media_type = "image/webp"  # Claude doesn't support HEIC directly

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=300,
        system=SYSTEM_PROMPT,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": image_b64,
                        },
                    },
                    {
                        "type": "text",
                        "text": prompt,
                    },
                ],
            }
        ],
    )

    response_text = message.content[0].text
    return jsonify({"response": response_text})


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "nia-vision"})


if __name__ == "__main__":
    port = int(os.environ.get("VISION_API_PORT", 5100))
    app.run(host="0.0.0.0", port=port)
