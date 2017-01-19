var exec = require('cordova/exec');

var pdf = function(){};

pdf.prototype.init = function(success, error) {
    exec(success, error, "FoxitPdf", "init", []);
};

pdf.prototype.preview =  function(arg0, success, error) {
    exec(success, error, "FoxitPdf", "Preview", [arg0]);
};

var pdf = new pdf();
module.exports = pdf;