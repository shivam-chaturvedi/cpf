🧾 Certificate Generation API

A simple FastAPI service that dynamically generates Word (.docx) certificates for:

Compliance

Due Diligence

Letterhead

The templates use docxtpl
 for placeholder rendering.

⚙️ Overview

Each endpoint accepts a POST request with JSON data containing the required attributes.
It then fills the respective .docx template (c.docx, d.docx, or l.docx) and returns the generated file directly as a downloadable .docx response.

All processing is done in memory — no file writes.

CORS is disabled (open for any frontend).

Fully deployable on Vercel, Windows, Linux, and macOS.

📡 API Endpoints
API Endpoint	Method	Required Fields	Optional Fields	Output
/generate/compliance	POST	ngo_name, issue_date, exp_date	logo_url (embed image in {{ logo }})	Returns certificate_compliance.docx
/generate/due_diligence	POST	ngo_name, issue_date, exp_date	logo_url (embed image in {{ logo }})	Returns certificate_due_diligence.docx
/generate/letterhead	POST	cfo_name, ngo_name, ngo_address, check_type, issue_date, exp_date	(none)	Returns certificate_letterhead.docx (auto adds {{current_date}})
🧩 Example Requests
1️⃣ Compliance Certificate

Endpoint:

POST /generate/compliance


Body:

{
  "ngo_name": "Helping Hands Foundation",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026",
  "logo_url": "https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg"
}


Response:
Downloads certificate_compliance.docx with the logo embedded at {{ logo }}.

2️⃣ Due Diligence Certificate

Endpoint:

POST /generate/due_diligence


Body:

{
  "ngo_name": "Bright Future Trust",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026",
  "logo_url": "https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg"
}


Response:
Downloads certificate_due_diligence.docx with the logo embedded at {{ logo }}.

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
Downloads certificate_letterhead.docx with {{current_date}} auto-filled by the server.

🖼️ Template Setup

In your Word templates:

Compliance & Due Diligence:
Add this where you want the logo:

{{ logo }}


Letterhead:
Add this to include today’s date:

{{ current_date }}

⚠️ Error Handling

If any required field is missing, the API returns a 400 Bad Request with a clear message:

{
  "error": "Field 'cfo_name' is required"
}


If a template file (c.docx, d.docx, or l.docx) is missing:

{
  "error": "Template not found: c.docx"
}


If an invalid image URL is provided:

{
  "error": "Failed to load image from URL: ..."
}

🧰 Installation

Clone the repository:

git clone <repo-url>
cd certificate-api


Install dependencies:

pip install -r requirements.txt


Ensure templates exist:

c.docx
d.docx
l.docx
main.py
requirements.txt
vercel.json

🚀 Run Locally

Start your FastAPI app:

uvicorn main:app --reload --host 0.0.0.0 --port 8000


Then open:

http://127.0.0.1:8000/docs


You can test all APIs interactively from Swagger UI.

🌐 Deploying to Vercel

Create a vercel.json:

{
  "builds": [
    { "src": "main.py", "use": "@vercel/python" }
  ],
  "routes": [
    { "src": "/(.*)", "dest": "main.py" }
  ]
}


Deploy:

vercel deploy --prod


Access APIs at:

https://your-app-name.vercel.app/generate/compliance
https://your-app-name.vercel.app/generate/due_diligence
https://your-app-name.vercel.app/generate/letterhead

🧠 Summary
API	Supports Logo	Auto Current Date	Output
/generate/compliance	✅ Yes (logo_url)	❌ No	certificate_compliance.docx
/generate/due_diligence	✅ Yes (logo_url)	❌ No	certificate_due_diligence.docx
/generate/letterhead	❌ No	✅ Yes ({{current_date}})	certificate_letterhead.docx