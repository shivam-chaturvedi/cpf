🧾 Certificate Generation API

A simple FastAPI service that dynamically generates Word (.docx) certificates for:

Compliance

Due Diligence

Letterhead

The templates use docxtpl
 for placeholder rendering.

⚙️ Overview

Each endpoint accepts a POST request with JSON data containing the required attributes.
It then fills the respective .docx template (c.docx, d.docx, or l.docx) and returns the generated file directly as a downloadable response.

📡 API Endpoints
API Endpoint	Method	Required Fields	Output
/generate/compliance	POST	ngo_name, issue_date, exp_date	Returns certificate_compliance.docx
/generate/due_diligence	POST	ngo_name, issue_date, exp_date	Returns certificate_due_diligence.docx
/generate/letterhead	POST	cfo_name, ngo_name, ngo_address, check_type, issue_date, exp_date	Returns certificate_letterhead.docx
🧩 Example Requests
1️⃣ Compliance Certificate

Endpoint:

POST /generate/compliance


Body:

{
  "ngo_name": "Helping Hands Foundation",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026"
}


Response:
Downloads certificate_compliance.docx.

2️⃣ Due Diligence Certificate

Endpoint:

POST /generate/due_diligence


Body:

{
  "ngo_name": "Bright Future Trust",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026"
}


Response:
Downloads certificate_due_diligence.docx.

3️⃣ Letterhead Certificate

Endpoint:

POST /generate/letterhead


Body:

{
  "cfo_name": "Ravi Sharma",
  "ngo_name": "Helping Hands Foundation",
  "ngo_address": "12 Green Avenue, Delhi",
  "check_type": "Financial Audit",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026"
}


Response:
Downloads certificate_letterhead.docx.

⚠️ Error Handling

If any required field is missing, the API returns a 400 Bad Request with a clear error message.

Example:

{
  "error": "Field 'cfo_name' is required"
}


If a template file (c.docx, d.docx, l.docx) is missing, the API will also respond with:

{
  "error": "Template not found: c.docx"
}
