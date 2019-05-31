var exec = require('cordova/exec');

var FSPdfdoc = function(){
    this.ptr = '';
    this.path = '';
};

FSPdfdoc.prototype.initDocWithPath =  function(filePath) {
    var dealdata = function(data,callback){
        console.log(data);
        this.ptr = data['docptr'];
        this.path = filePath;
        callback();
    };
    return new Promise(function(resolve, reject) {
                       exec(function(data){dealdata(data,resolve);}, reject, "FoxitPdf", "initDocWithPath", [{
                                                                       'path': filePath,
                                                                       }]);
                });
};

FSPdfdoc.prototype.getPageCount =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getPageCount", [{'docptr': this.ptr,}]);
                       });
};

module.exports = FSPdfdoc;
