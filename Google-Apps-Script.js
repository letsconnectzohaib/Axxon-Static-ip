// Google Apps Script for Static IP Database
// Created by Mr. Zohaib

function doPost(e) {
  try {
    // Parse the incoming data
    var data = JSON.parse(e.postData.contents);
    
    // Get the active spreadsheet (using your specific sheet ID)
    var sheet = SpreadsheetApp.openById('1YmH3QJy5huZC8NWJ13NcHmJ3gpWf3tIJZSsbp5wNakIU-Sb6NyuqtnM0').getSheetByName('Sheet1');
    
    // Add a new row with the data (matching your column structure)
    sheet.appendRow([
      data.name,        // Name column
      data.ip,          // IP column
      data.adapter,      // Adapter column
      new Date().toLocaleDateString(), // Date column
      new Date().toLocaleTimeString()  // Time column
    ]);
    
    // Return a success response
    return ContentService.createTextOutput(JSON.stringify({
      "status": "success",
      "message": "Data saved successfully to Static IP Database"
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    // Return an error response
    return ContentService.createTextOutput(JSON.stringify({
      "status": "error",
      "message": error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
