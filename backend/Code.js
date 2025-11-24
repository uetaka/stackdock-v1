/**
 * Google Apps Script for Stackdock
 * 
 * Setup:
 * 1. Create a new Google Sheet.
 * 2. Rename the first sheet to "Articles".
 *    Columns: A:ID, B:URL, C:Title, D:AddedDate, E:LastChecked, F:ContentHash, G:IsRead, H:Tags
 * 3. Create a second sheet named "RSS".
 *    Columns: A:FeedURL, B:LastChecked
 * 4. Open Extensions > Apps Script.
 * 5. Create 'index.html' and paste the content of backend/index.html.
 * 6. Paste this code into Code.gs.
 * 7. Deploy as Web App.
 */

const SHEET_ARTICLES = "Articles";
const SHEET_RSS = "RSS";

function doPost(e) {
    try {
        const data = JSON.parse(e.postData.contents);
        const action = data.action;

        if (action === "add") {
            return addItem(data.url, data.title);
        } else if (action === "markRead") {
            return markAsRead(data.id);
        } else if (action === "delete") {
            return deleteItem(data.id);
        }

        return ContentService.createTextOutput(JSON.stringify({ status: "error", message: "Invalid action" }))
            .setMimeType(ContentService.MimeType.JSON);

    } catch (err) {
        return ContentService.createTextOutput(JSON.stringify({ status: "error", message: err.toString() }))
            .setMimeType(ContentService.MimeType.JSON);
    }
}

function doGet(e) {
    const format = e.parameter.format;

    if (format === 'json') {
        return getJsonOutput();
    } else {
        return getHtmlOutput();
    }
}

function getJsonOutput() {
    const items = getArticles();
    return ContentService.createTextOutput(JSON.stringify(items))
        .setMimeType(ContentService.MimeType.JSON);
}

function getHtmlOutput() {
    const template = HtmlService.createTemplateFromFile('index');
    template.articles = getArticles();
    return template.evaluate()
        .setTitle('Stackdock')
        .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

function getArticles() {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const data = sheet.getDataRange().getValues();
    const headers = data.shift(); // Remove headers

    const items = data.map(row => ({
        id: row[0],
        url: row[1],
        title: row[2],
        addedDate: row[3],
        isRead: row[6]
    })).filter(item => item.url); // Filter empty rows

    // Reverse to show newest first
    items.reverse();
    return items;
}

function addItem(url, title) {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const id = Utilities.getUuid();
    const now = new Date();

    let contentHash = "";
    if (!title) {
        try {
            const response = UrlFetchApp.fetch(url);
            const content = response.getContentText();
            const match = content.match(/<title>(.*?)<\/title>/i);
            title = match ? match[1] : url;
            contentHash = Utilities.computeDigest(Utilities.DigestAlgorithm.MD5, content).toString();
        } catch (e) {
            title = url;
        }
    }

    sheet.appendRow([id, url, title, now, now, contentHash, false, ""]);

    return ContentService.createTextOutput(JSON.stringify({ status: "success", id: id, title: title }))
        .setMimeType(ContentService.MimeType.JSON);
}

function markAsRead(id) {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const data = sheet.getDataRange().getValues();

    for (let i = 1; i < data.length; i++) {
        if (data[i][0] == id) {
            sheet.getRange(i + 1, 7).setValue(true);
            return ContentService.createTextOutput(JSON.stringify({ status: "success" }))
                .setMimeType(ContentService.MimeType.JSON);
        }
    }

    return ContentService.createTextOutput(JSON.stringify({ status: "error", message: "Item not found" }))
        .setMimeType(ContentService.MimeType.JSON);
}

function deleteItem(id) {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const data = sheet.getDataRange().getValues();

    for (let i = 1; i < data.length; i++) {
        if (data[i][0] == id) {
            sheet.deleteRow(i + 1);
            return ContentService.createTextOutput(JSON.stringify({ status: "success" }))
                .setMimeType(ContentService.MimeType.JSON);
        }
    }

    return ContentService.createTextOutput(JSON.stringify({ status: "error", message: "Item not found" }))
        .setMimeType(ContentService.MimeType.JSON);
}

// Exposed for client-side JS in HTML
function markAsReadFromWeb(id) {
    markAsRead(id);
}

function checkUpdates() {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const data = sheet.getDataRange().getValues();

    for (let i = 1; i < data.length; i++) {
        const url = data[i][1];
        const oldHash = data[i][5];
        const isRead = data[i][6];

        if (isRead) continue;

        try {
            const response = UrlFetchApp.fetch(url);
            const content = response.getContentText();
            const newHash = Utilities.computeDigest(Utilities.DigestAlgorithm.MD5, content).toString();

            if (oldHash && newHash !== oldHash) {
                sheet.getRange(i + 1, 5).setValue(new Date());
                sheet.getRange(i + 1, 6).setValue(newHash);
                console.log(`Updated: ${url}`);
            }
        } catch (e) {
            console.error(`Failed to check ${url}: ${e}`);
        }
    }
}

function fetchRss() {
    const sheetRss = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_RSS);
    if (!sheetRss) return;

    const rssData = sheetRss.getDataRange().getValues();

    for (let i = 1; i < rssData.length; i++) {
        const feedUrl = rssData[i][0];
        if (!feedUrl) continue;

        try {
            const response = UrlFetchApp.fetch(feedUrl);
            const xml = response.getContentText();
            const document = XmlService.parse(xml);
            const root = document.getRootElement();
            const channel = root.getChild("channel");
            const items = channel.getChildren("item");

            for (let j = 0; j < Math.min(items.length, 5); j++) {
                const item = items[j];
                const link = item.getChildText("link");
                const title = item.getChildText("title");

                if (!isUrlExists(link)) {
                    addItem(link, title);
                }
            }

            sheetRss.getRange(i + 1, 2).setValue(new Date());

        } catch (e) {
            console.error(`Failed to fetch RSS ${feedUrl}: ${e}`);
        }
    }
}

function isUrlExists(url) {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_ARTICLES);
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
        if (data[i][1] === url) return true;
    }
    return false;
}
