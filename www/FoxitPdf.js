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

pdf.prototype.init = function(success, error) {
    exec(success, error, "FoxitPdf", "init", []);
};

pdf.prototype.preview =  function(arg0, success, error) {
    successfunction = success
    exec(this._eventHandler, error, "FoxitPdf", "Preview", [arg0]);
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
