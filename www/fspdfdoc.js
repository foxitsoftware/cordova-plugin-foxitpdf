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


var FSForm = function(){
};
// return all form fields array
FSForm.prototype.getAllFormFields =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getAllFormFields", [{}]);
                       });
};
// return form info dictionary
FSForm.prototype.info =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFormInfo", [{}]);
                       });
};

// alignment  int type. to set form alignment
// return alignment after set
FSForm.prototype.alignment =  function(alignment) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormAlignment", [{'alignment': alignment,}]);
                       });
};

// appearance  object type. to set form defaultAppearance
// return appearance after set
FSForm.prototype.defaultAppearance =  function(appearence) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormDefaultAppearance", [{'appearence': appearence,}]);
                       });
};

// FSFieldType  int type. to set field type
// field_name  string type. to set field name
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.validateFieldName =  function(FSFieldType,field_name) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormValidateFieldName", [{
                                                                               'FSFieldType': FSFieldType,
                                                                               'field_name': field_name,
                                                                               }]);
                       });
};

// field_index  int type. field index
// new_field_name  string type. field name
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.renameField =  function(field_index,new_field_name) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormRenameField", [{
                                                                               'field_index': field_index,
                                                                               'new_field_name': new_field_name,
                                                                               }]);
                       });
};

// field_index  int type. field index
// return none
FSForm.prototype.removeField =  function(field_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormRemoveField", [{
                                                                             'field_index': field_index,
                                                                             }]);
                       });
};

// field_index  int type. field index
// filter       string type. filter value
// return field object
FSForm.prototype.getField =  function(field_index,filter) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormGetField", [{
                                                                             'field_index': field_index,
                                                                             'filter': filter,
                                                                             }]);
                       });
};

// reset form
FSForm.prototype.reset =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormReset", [{}]);
                       });
};

// file_path       string type. export file path
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.exportToXML =  function(file_path) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormExportToXML", [{'file_path': file_path,}]);
                       });
};

// file_path       string type. import file path
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.importFromXML =  function(file_path) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormImportFromXML", [{'file_path': file_path,}]);
                       });
};

module.exports = FSForm;


var FSField = function(){
};

// appearance  object type. to set form defaultAppearance
// return appearance after set
FSField.prototype.defaultAppearance =  function(appearence) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FSFieldDefaultAppearance", [{'appearence': appearence,}]);
                       });
};

// fsfield  object type. new field value
// return none
FSField.prototype.updateField =  function(fsfield) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FSFieldUpdateField", [{'fsfield' : fsfield }]);
                       });
};

// reset field
FSField.prototype.reset =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FSFieldReset", [{}]);
                       });
};

module.exports = FSField;
