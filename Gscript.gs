function sheet_(name) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(name);
  if (!sheet) {
    throw new Error('หา Sheet "' + name + '" ไม่เจอ');
  }
  return sheet;
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function orders_() {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Orders');
}

function doPost(e) {
  var lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);
    var d = JSON.parse(e.postData.contents);
    var s = orders_();
    var id = 'ORD-' + ('000' + s.getLastRow()).slice(-3);
    s.appendRow([id, d.table_no, d.item_details, d.total_price, d.status, new Date()]);
    return json_({ ok: true, order_id: id });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

function doGet(e) {
  try {
    var rows = orders_().getDataRange().getValues();
    var out = [];
    for (var i = 1; i < rows.length; i++) {
      if (String(rows[i][1]).trim() === e.parameter.table_no) {
        out.push({
          order_id: rows[i][0],
          table_no: rows[i][1],
          item_details: rows[i][2],
          total_price: rows[i][3],
          status: rows[i][4]
        });
      }
    }
    return json_(out);
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  }
}