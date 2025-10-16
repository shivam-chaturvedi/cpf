from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse, JSONResponse, PlainTextResponse
from fastapi.middleware.cors import CORSMiddleware
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from datetime import datetime
import requests
import io
import os

app = FastAPI()

# === Fully disable CORS ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# === Handle browser preflight (OPTIONS) safely ===
@app.options("/{rest_of_path:path}")
async def preflight_handler(rest_of_path: str):
    return PlainTextResponse(
        "OK",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        },
    )


# === Helper: download image safely ===
def fetch_image_bytes(url: str):
    if not url.lower().startswith("https://"):
        raise ValueError("Only HTTPS URLs are supported for logo_url.")
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return io.BytesIO(response.content)
    except Exception as e:
        raise ValueError(f"Failed to fetch image: {str(e)}")


# === Utility: render a DOCX in-memory ===
def render_docx(template_name: str, context: dict, logo_bytes: io.BytesIO = None):
    template_path = os.path.join(os.getcwd(), template_name)
    if not os.path.exists(template_path):
        return None, f"Template not found: {template_name}"

    doc = DocxTemplate(template_path)

    # ✅ attach InlineImage using the SAME template object
    if logo_bytes:
        context["logo"] = InlineImage(doc, logo_bytes, width=Mm(25))

    doc.render(context)
    file_stream = io.BytesIO()
    doc.save(file_stream)
    file_stream.seek(0)
    return file_stream, None


# === Helper: validate fields ===
def validate_fields(data: dict, required_fields: list):
    for field in required_fields:
        if not data.get(field):
            return f"Field '{field}' is required"
    return None


# === API 1: Compliance Certificate ===
@app.post("/generate/compliance")
async def generate_compliance(request: Request):
    try:
        data = await request.json()
        required = ["ngo_name", "issue_date", "exp_date"]
        missing = validate_fields(data, required)
        if missing:
            return JSONResponse({"error": missing}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        logo_bytes = None
        if data.get("logo_url"):
            try:
                logo_bytes = fetch_image_bytes(data["logo_url"])
            except Exception as e:
                return JSONResponse({"error": str(e)}, status_code=400,
                                    headers={"Access-Control-Allow-Origin": "*"})

        context = {
            "ngo_name": data["ngo_name"],
            "issue_date": data["issue_date"],
            "exp_date": data["exp_date"],
        }

        file_stream, err = render_docx("c.docx", context, logo_bytes)
        if err:
            return JSONResponse({"error": err}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        return StreamingResponse(
            file_stream,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers={
                "Content-Disposition": 'attachment; filename="certificate_compliance.docx"',
                "Access-Control-Allow-Origin": "*",
            },
        )
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500,
                            headers={"Access-Control-Allow-Origin": "*"})



# === API 2: Due Diligence Certificate ===
@app.post("/generate/due_diligence")
async def generate_due_diligence(request: Request):
    try:
        data = await request.json()
        required = ["ngo_name", "issue_date", "exp_date"]
        missing = validate_fields(data, required)
        if missing:
            return JSONResponse({"error": missing}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        logo_bytes = None
        if data.get("logo_url"):
            try:
                logo_bytes = fetch_image_bytes(data["logo_url"])
            except Exception as e:
                return JSONResponse({"error": str(e)}, status_code=400,
                                    headers={"Access-Control-Allow-Origin": "*"})

        context = {
            "ngo_name": data["ngo_name"],
            "issue_date": data["issue_date"],
            "exp_date": data["exp_date"],
        }

        file_stream, err = render_docx("d.docx", context, logo_bytes)
        if err:
            return JSONResponse({"error": err}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        return StreamingResponse(
            file_stream,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers={
                "Content-Disposition": 'attachment; filename="certificate_due_diligence.docx"',
                "Access-Control-Allow-Origin": "*",
            },
        )
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500,
                            headers={"Access-Control-Allow-Origin": "*"})



# === API 3: Letterhead Certificate ===
@app.post("/generate/letterhead")
async def generate_letterhead(request: Request):
    try:
        data = await request.json()
        required = ["cfo_name", "ngo_name", "ngo_address", "check_type", "issue_date", "exp_date"]
        missing = validate_fields(data, required)
        if missing:
            return JSONResponse({"error": missing}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        current_date = datetime.now().strftime("%d %b %Y")

        context = {
            "cfo_name": data["cfo_name"],
            "ngo_name": data["ngo_name"],
            "ngo_address": data["ngo_address"],
            "check_type": data["check_type"],
            "issue_date": data["issue_date"],
            "exp_date": data["exp_date"],
            "current_date": current_date,
        }

        file_stream, err = render_docx("l.docx", context)
        if err:
            return JSONResponse({"error": err}, status_code=400,
                                headers={"Access-Control-Allow-Origin": "*"})

        return StreamingResponse(
            file_stream,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers={
                "Content-Disposition": 'attachment; filename="certificate_letterhead.docx"',
                "Access-Control-Allow-Origin": "*",
            },
        )
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500,
                            headers={"Access-Control-Allow-Origin": "*"})



# === Health Check ===
@app.get("/ping")
async def ping():
    return JSONResponse({"status": "ok", "message": "API running"}, headers={"Access-Control-Allow-Origin": "*"})
