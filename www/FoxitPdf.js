var exec = require('cordova/exec');
var channel = require('cordova/channel');

channels = {
    'onDocOpened': channel.create('onDocOpened'),
    'onDocSaved': channel.create('onDocSaved'),
};

var pdf = function(){};
var successfunction = function(){};

pdf.prototype._eventHandler = function (event) {
    successfunction(event);
    
   if (event && (event.type in channels)) {
       channels[event.type].fire(event);
//    } else {
//      successfunction(event);
   }
};

pdf.prototype.initialize = function(sn, key) {
    return new Promise(function(resolve, reject) {
      exec(resolve, reject, "FoxitPdf", "initialize", [{
        'foxit_sn': sn,
        'foxit_key': key,
      }]);
    });
};

pdf.prototype.preview =  function(arg0, success, error) {
    successfunction = success
    exec(this._eventHandler, error, "FoxitPdf", "Preview", [arg0]);
};

pdf.prototype.openDocument = function(path, password) {
    return new Promise(function(resolve, reject) {
        successfunction = resolve;
        exec(pdf._eventHandler, reject, "FoxitPdf", "openDocument", [{
            'path': path,
            'password': password == null ? '' : password,
        }]);
    });
};

pdf.prototype.setSavePath = function(savePath) {
    return new Promise(function(resolve, reject) {
        exec(resolve, reject, "FoxitPdf", "setSavePath", [{
            'savePath': savePath,
        }]);
    });
};

pdf.prototype.addEventListener = function (eventname, f) {
    if (eventname in channels) {
        if (channels[eventname].numHandlers < 1) {
          channels[eventname].subscribe(f);
        }
    }
};

pdf.prototype.removeEventListener = function (eventname, f) {
    if (eventname in channels) {
        channels[eventname].unsubscribe(f);
    }
};

pdf.prototype.importFromFDF = function(fdf_doc_path, data_type, page_range = []) {
    return new Promise(function(resolve, reject) {
        if (!(page_range && page_range instanceof Array)) {
            reject('page range is not array');
            return;
        }
        exec(resolve, reject, "FoxitPdf", "importFromFDF", [{
            'fdfPath': fdf_doc_path,
            'dataType': data_type,
            'pageRange': page_range,
        }]);
    });
};

pdf.prototype.exportToFDF = function(export_path, data_type, fdf_doc_type, page_range = []) {
    return new Promise(function(resolve, reject) {
        if (!(page_range && page_range instanceof Array)) {
            reject('page range is not array');
            return;
        }
        exec(resolve, reject, "FoxitPdf", "exportToFDF", [{
            'exportPath': export_path,
            'dataType': data_type,
            'fdfDocType': fdf_doc_type,
            'pageRange': page_range,
        }]);
    });
};

var pdf = new pdf();
module.exports = pdf;

