cordova.define("cordova-plugin-foxitpdf.FoxitPdf", function(require, exports, module) {
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
}

pdf.prototype.initialize = function(arg0, success, error) {
    exec(success, error, "FoxitPdf", "initialize", [arg0]);
};

pdf.prototype.preview =  function(arg0, success, error) {
    successfunction = success
    exec(this._eventHandler, error, "FoxitPdf", "Preview", [arg0]);
};

pdf.prototype.openDocument =  function(arg0, success, error) {
    successfunction = success
    exec(this._eventHandler, error, "FoxitPdf", "openDocument", [arg0]);
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

});
