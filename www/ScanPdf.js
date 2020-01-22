var exec = require('cordova/exec');
var channel = require('cordova/channel');

channels = {
    'onDocumentAdded': channel.create('onDocumentAdded')
};

var ScanPdf = function(){};
var successfunction = function(){};

ScanPdf.prototype._eventHandler = function (event) {
    successfunction(event);
   if (event && (event.type in channels)) {
       channels[event.type].fire(event);
   }
};

ScanPdf.prototype.initializeScanner = function(serial1, serial2) {
    return new Promise(function(resolve, reject) {
      exec(resolve, reject, "FoxitPdf", "initializeScanner", [{
        'serial1': serial1,
        'serial2': serial2,
      }]);
    });
};

ScanPdf.prototype.initializeCompression = function(serial1, serial2) {
    return new Promise(function(resolve, reject) {
      exec(resolve, reject, "FoxitPdf", "initializeCompression", [{
        'serial1': serial1,
        'serial2': serial2,
      }]);
    });
};

ScanPdf.prototype.createScannerFragment = function() {
    return new Promise(function(resolve, reject) {
      successfunction = resolve;
      exec(scan._eventHandler, reject, "FoxitPdf", "createScannerFragment",  [{}]);
    });
};

ScanPdf.prototype.addEventListener = function (eventname, f) {
    if (eventname in channels) {
        if (channels[eventname].numHandlers < 1) {
          channels[eventname].subscribe(f);
        }
    }
};

ScanPdf.prototype.removeEventListener = function (eventname, f) {
    if (eventname in channels) {
        channels[eventname].unsubscribe(f);
    }
};

var scan = new ScanPdf();
module.exports = scan;
