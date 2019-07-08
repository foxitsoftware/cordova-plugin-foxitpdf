var exec = require('cordova/exec');

var Form = function(){
};
// return all form fields array
//返回值 :
//返回一个对象数组，对象里面包括了key/value的信息，如defValue, flag.
//[{
// choiceOptions :         (
//                   {
//                   "defaultSelected" : true,
//                   "optionLabel" : "1",
//                   "optionValue" : "1",
//                   selected : true,
//                   },
//                   {
//                   "defaultSelected" : false,
//                   "optionLabel" : "2",
//                   "optionValue" : "2",
//                   selected : false,
//                   },
//                   {
//                   "defaultSelected" : false,
//                   "optionLabel" : "3",
//                   "optionValue" : "3",
//                   selected : false,
//                   },
//                   {
//                   "defaultSelected" :false,
//                   "optionLabel" : "4",
//                   "optionValue" : "4",
//                   selected : false,
//                   }
//                   ),
// alignment : 0,
// alternateName : "0",
// defValue : "1",
// defaultAppearance :         {
// flags : 3,
// font : "Helvetica",
// "textColor" : 3,
// "textSize" : 3,
// },
// fieldFlag : 7,
// fieldIndex : 3,
// fieldType : 4,
// mappingName : "map_combobox",
// maxLength : 0,
// name : "Combo Box1",
// topVisibleIndex : 0,
// value : "1",
// },{},{},...]
Form.prototype.getAllFormFields =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getAllFormFields", [{}]);
                       });
};

// return form info dictionary
//{
//    alignment : "0", // 0 :left , 1 : center , 2 : right
//    needConstructAppearances : false,
//    defaultAppearance :  {
//        flags: flags,
//        font:font,
//        textSize:10,
//        textColor:0X00000
//    }
//}
Form.prototype.getForm =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getForm", [{}]);
                       });
};

//update form info.
//参数：
//{
//    alignment : "0", // 0 :left , 1 : center , 2 : right
//    needConstructAppearances : false,
//    defaultAppearance :  {
//        flags: flags,
//        font:font,
//        textSize:10,
//        textColor:0X0000
//    }
//}
Form.prototype.updateForm =  function(forminfo) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "updateForm", [{'forminfo':forminfo}]);
                       });
};

// fieldType  int type. to set field type
// fieldName  string type. to set field name
// <b>true</b> means success, while <b>false</b> means failure.
Form.prototype.validateFieldName =  function(fieldType,fieldName) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formValidateFieldName", [{
                                                                                   'fieldType': fieldType,
                                                                                   'fieldName': fieldName,
                                                                                   }]);
                       });
};

// fieldIndex  int type. field index
// newFieldName  string type. field name
// <b>true</b> means success, while <b>false</b> means failure.
Form.prototype.renameField =  function(fieldIndex,newFieldName) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRenameField", [{
                                                                             'fieldIndex': fieldIndex,
                                                                             'newFieldName': newFieldName,
                                                                             }]);
                       });
};

// fieldIndex  int type. field index
// return none
Form.prototype.removeField =  function(fieldIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRemoveField", [{
                                                                             'fieldIndex': fieldIndex,
                                                                             }]);
                       });
};

// reset form
Form.prototype.reset =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formReset", [{}]);
                       });
};

// filePath       string type. export file path
// <b>true</b> means success, while <b>false</b> means failure.
Form.prototype.exportToXML =  function(filePath) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formExportToXML", [{'filePath': filePath,}]);
                       });
};

// filePath       string type. import file path
// <b>true</b> means success, while <b>false</b> means failure.
Form.prototype.importFromXML =  function(filePath) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formImportFromXML", [{'filePath': filePath,}]);
                       });
};

// pageIndex  int type. index of a page
// retrun array
//[{
// controlIndex : 1, //The index of current form control among all the controls of the specified page.
// exportValue : "",
// isChecked : true,
// isDefaultChecked : true,
// },{},{}...]
Form.prototype.getPageControls =  function(pageIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formGetPageControls", [{'pageIndex': pageIndex,}]);
                       });
};


// pageIndex  int type. index of a page
// controlIndex  int type. The index of current form control among all the controls of the specified page.
// return  none
Form.prototype.removeControl =  function(pageIndex,controlIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRemoveControl", [{
                                                                               'pageIndex': pageIndex,
                                                                               'controlIndex': controlIndex,
                                                                               }]);
                       });
};

// pageIndex  int type. index of a page
// fieldName  string type. the name of control
// fieldType    int type, the type of control
// rect    object type, tye rect of control . {left: 100,top: 200,right: 200,bottom: 100}
// retrun control object
//{
//    controlIndex : 1, //The index of current form control among all the controls of the specified page.
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
Form.prototype.addControl =  function(pageIndex,fieldName,fieldType,rect) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formAddControl", [{
                                                                            'pageIndex': pageIndex,
                                                                            'fieldName': fieldName,
                                                                            'fieldType': fieldType,
                                                                            'rect': rect,
                                                                            }]);
                       });
};

// pageIndex  int type. index of a page
// controlIndex  int type. The index of current form control among all the controls of the specified page.
// control        object type.
//{
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
// return none
Form.prototype.updateControl =  function(pageIndex,controlIndex, control) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formUpdateControl", [{
                                                                               'pageIndex': pageIndex,
                                                                               'controlIndex': controlIndex,
                                                                               'control':control
                                                                               }]);
                       });
};

// pageIndex  int type. index of a page
// controlIndex  int type. The index of current form control among all the controls of the specified page.
// retrun field object
//{
// choiceOptions :         (
//                   {
//                   "defaultSelected" : true,
//                   "optionLabel" : "1",
//                   "optionValue" : "1",
//                   selected : true,
//                   },
//                   {
//                   "defaultSelected" : false,
//                   "optionLabel" : "2",
//                   "optionValue" : "2",
//                   selected : false,
//                   },
//                   {
//                   "defaultSelected" : false,
//                   "optionLabel" : "3",
//                   "optionValue" : "3",
//                   selected : false,
//                   },
//                   {
//                   "defaultSelected" :false,
//                   "optionLabel" : "4",
//                   "optionValue" : "4",
//                   selected : false,
//                   }
//                   ),
// alignment : 0,
// alternateName : "0",
// defValue : "1",
// defaultAppearance :         {
// flags : 3,
// font : "Helvetica",
// "textColor" : 3,
// "textSize" : 3,
// },
// fieldFlag : 7,
// fieldIndex : 3,
// fieldType : 4,
// mappingName : "map_combobox",
// maxLength : 0,
// name : "Combo Box1",
// topVisibleIndex : 0,
// value : "1",
// }
Form.prototype.getFieldByControl =  function(pageIndex,controlIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFieldByControl", [{'pageIndex': pageIndex,
                                                                               'controlIndex': controlIndex,}]);
                       });
};

var form = new Form();
module.exports = form;