# Backend Deployment Instructions

1. **Create a Google Spreadsheet**
   - Create a new Google Spreadsheet at https://sheets.google.com/create
   - Rename the default sheet to `Articles`.
   - Create a new sheet named `RSS`.

2. **Open Apps Script**
   - In the Spreadsheet, go to **Extensions** > **Apps Script**.

3. **Paste Code**
   - Copy the content of `Code.js` and paste it into the script editor (replace existing code).
   - Save the project (Ctrl+S).

4. **Deploy as Web App**
   - Click **Deploy** > **New deployment**.
   - Select type: **Web app**.
   - Description: `Stackdock Backend`.
   - Execute as: **Me** (your email).
   - Who has access: **Anyone**. (This is important for the app to access it without complex OAuth for now. Since the URL is secret, it's relatively safe for personal use, but be careful not to share the URL).
   - Click **Deploy**.
   - Authorize the script when prompted.

5. **Get URL**
   - Copy the **Web App URL** (ends with `/exec`).
   - You will need this URL for the Flutter app.
