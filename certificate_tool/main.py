from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from docxtpl import DocxTemplate
from datetime import datetime
import io
import os

app = FastAPI()

# === Disable CORS (allow all origins) ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# === Utility: render a docx file and return as BytesIO ===
def render_docx(template_name: str, context: dict):
    template_path = os.path.join(os.getcwd(), template_name)
    if not os.path.exists(template_path):
        return None, f"Template not found: {template_name}"

    doc = DocxTemplate(template_path)
    doc.render(context)

    file_stream = io.BytesIO()
    doc.save(file_stream)
    file_stream.seek(0)
    return file_stream, None


# === Helper: validate required fields ===
def validate_fields(data: dict, required_fields: list):
    for field in required_fields:
        if not data.get(field):
            return f"Field '{field}' is required"
    return None


# === API 1: Compliance Certificate ===
@app.post("/generate/compliance")
async def generate_compliance(request: Request):
    data = await request.json()
    required = ["ngo_name", "issue_date", "exp_date"]

    missing = validate_fields(data, required)
    if missing:
        return JSONResponse({"error": missing}, status_code=400)

    context = {
        "ngo_name": data["ngo_name"],
        "issue_date": data["issue_date"],
        "exp_date": data["exp_date"],
    }

    file_stream, err = render_docx("c.docx", context)
    if err:
        return JSONResponse({"error": err}, status_code=400)

    return StreamingResponse(
        file_stream,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": 'attachment; filename="certificate_compliance.docx"'},
    )


# === API 2: Due Diligence Certificate ===
@app.post("/generate/due_diligence")
async def generate_due_diligence(request: Request):
    data = await request.json()
    required = ["ngo_name", "issue_date", "exp_date"]

    missing = validate_fields(data, required)
    if missing:
        return JSONResponse({"error": missing}, status_code=400)

    context = {
        "ngo_name": data["ngo_name"],
        "issue_date": data["issue_date"],
        "exp_date": data["exp_date"],
    }

    file_stream, err = render_docx("d.docx", context)
    if err:
        return JSONResponse({"error": err}, status_code=400)

    return StreamingResponse(
        file_stream,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": 'attachment; filename="certificate_due_diligence.docx"'},
    )


# === API 3: Letterhead Certificate ===
@app.post("/generate/letterhead")
async def generate_letterhead(request: Request):
    data = await request.json()
    required = ["cfo_name", "ngo_name", "ngo_address", "check_type", "issue_date", "exp_date"]

    missing = validate_fields(data, required)
    if missing:
        return JSONResponse({"error": missing}, status_code=400)

    # Automatically add current date
    current_date = datetime.now().strftime("%d %b %Y")

    context = {
        "cfo_name": data["cfo_name"],
        "ngo_name": data["ngo_name"],
        "ngo_address": data["ngo_address"],
        "check_type": data["check_type"],
        "issue_date": data["issue_date"],
        "exp_date": data["exp_date"],
        "current_date": current_date,  # Auto field for template
    }

    file_stream, err = render_docx("l.docx", context)
    if err:
        return JSONResponse({"error": err}, status_code=400)

    return StreamingResponse(
        file_stream,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": 'attachment; filename="certificate_letterhead.docx"'},
    )
