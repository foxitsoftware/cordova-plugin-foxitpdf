var exec = require('cordova/exec');
var channel = require('cordova/channel');

var channels = {
    'onDocOpened': channel.create('onDocOpened'),
    'onDocWillSave': channel.create('onDocWillSave'),
    'onDocSaved': channel.create('onDocSaved'),
    'onCanceled': channel.create('onCanceled'),
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

pdf.prototype.importFromFDF = function(fdf_doc_path, data_type, page_range) {
    if (typeof page_range === 'undefined') {page_range = [];}
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

pdf.prototype.exportToFDF = function(export_path, data_type, fdf_doc_type, page_range) {
    if (typeof page_range === 'undefined') {page_range = [];}
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

pdf.prototype.enableAnnotations = function(enable) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "enableAnnotations", [{
            'enable': enable,
        }]);
    });
}

pdf.prototype.setBottomToolbarItemVisible = function(index, visible) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "setBottomToolbarItemVisible", [{
            'index': index,
            'visible': visible,
        }]);
    });
}

pdf.prototype.setTopToolbarItemVisible = function(index, visible) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "setTopToolbarItemVisible", [{
            'index': index,
            'visible': visible,
        }]);
    });
}

pdf.prototype.setToolbarItemVisible = function(index, visible) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "setToolbarItemVisible", [{
            'index': index,
            'visible': visible,
        }]);
    });
}
    
pdf.prototype.setPrimaryColor = function(light, dark) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "setPrimaryColor", [{
            'light': light,
            'dark': dark,
        }]);
    });
}
    
pdf.prototype.setAutoSaveDoc = function(enable) {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, "FoxitPdf", "setAutoSaveDoc", [{
            'enable': enable,
        }]);
    });
}

var pdf = new pdf();
module.exports = pdf;
