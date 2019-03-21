var exec = require('cordova/exec');
var channel = require('cordova/channel');

channels = {
    'onDocSaved': channel.create('onDocSaved'),
};

var pdf = function(){};
successfunction = function(){};

pdf.prototype._eventHandler = function (event) {
   if (event && (event.type in channels)) {
       channels[event.type].fire(event);
   }else{
     successfunction(event);
   }
};

pdf.prototype.initialize = function(sn, key) {
    return new Promise(function(success, error) {
      exec(success, error, "FoxitPdf", "initialize", [{
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
    return new Promise(function(success, error) {
        successfunction = success;
        exec(this._eventHandler, error, "FoxitPdf", "openDocument", [{
            'path': path,
            'password': password,
        }]);
    });
};

pdf.prototype.setSavePath = function(savePath) {
    return new Promise(function(success, error) {
        exec(success, error, "FoxitPdf", "setSavePath", [{
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

var pdf = new pdf();
module.exports = pdf;
