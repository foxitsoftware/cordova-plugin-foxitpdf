var FSForm = function(){
};
// return all form fields array
//返回值 :
//返回一个对象数组，对象里面包括了key/value的信息，如defValue, flag.
//[{
// choiceOptions :         (
//                   {
//                   "default_selected" : 1,
//                   "option_label" : "1",
//                   "option_value" : "1",
//                   selected : 1,
//                   },
//                   {
//                   "default_selected" : 0,
//                   "option_label" : "2",
//                   "option_value" : "2",
//                   selected : 0,
//                   },
//                   {
//                   "default_selected" : 0,
//                   "option_label" : "3",
//                   "option_value" : "3",
//                   selected : 0,
//                   },
//                   {
//                   "default_selected" : 0,
//                   "option_label" : "4",
//                   "option_value" : "4",
//                   selected : 0,
//                   }
//                   ),
// alignment : 0,
// alternateName : "0",
// defValue : "1",
// defaultAppearance :         {
// flags : 3,
// font : "Helvetica",
// "text_color" : 3,
// "text_size" : 3,
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
FSForm.prototype.getAllFormFields =  function() {
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
//        text_size:text_size,
//        text_color:text_color
//    }
//}
FSForm.prototype.getForm =  function() {
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
//        text_size:text_size,
//        text_color:text_color
//    }
//}
FSForm.prototype.updateForm =  function(forminfo) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "updateForm", [{'forminfo':forminfo}]);
                       });
};

// FSFieldType  int type. to set field type
// field_name  string type. to set field name
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.validateFieldName =  function(FSFieldType,field_name) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formValidateFieldName", [{
                                                                                   'fSFieldType': FSFieldType,
                                                                                   'field_name': field_name,
                                                                                   }]);
                       });
};

// field_index  int type. field index
// new_field_name  string type. field name
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.renameField =  function(field_index,new_field_name) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRenameField", [{
                                                                             'field_index': field_index,
                                                                             'new_field_name': new_field_name,
                                                                             }]);
                       });
};

// field_index  int type. field index
// return none
FSForm.prototype.removeField =  function(field_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRemoveField", [{
                                                                             'field_index': field_index,
                                                                             }]);
                       });
};

// reset form
FSForm.prototype.reset =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formReset", [{}]);
                       });
};

// file_path       string type. export file path
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.exportToXML =  function(file_path) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formExportToXML", [{'file_path': file_path,}]);
                       });
};

// file_path       string type. import file path
// <b>true</b> means success, while <b>false</b> means failure.
FSForm.prototype.importFromXML =  function(file_path) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formImportFromXML", [{'file_path': file_path,}]);
                       });
};

// page_index  int type. index of a page
// retrun array
//[{
// control_index : 1,
// exportValue : "",
// isChecked : true,
// isDefaultChecked : true,
// },{},{}...]
FSForm.prototype.getPageControls =  function(page_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formGetPageControls", [{'page_index': page_index,}]);
                       });
};


// page_index  int type. index of a page
// control_index  int type. index of a control
// return  none
FSForm.prototype.removeControl =  function(page_index,control_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formRemoveControl", [{
                                                                               'page_index': page_index,
                                                                               'control_index': control_index,
                                                                               }]);
                       });
};

// page_index  int type. index of a page
// field_name  string type. the name of control
// field_type    int type, the type of control
// rect    object type, tye rect of control . {0,0,100,100}
// retrun control object
//{
//    control_index : 1,
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
FSForm.prototype.addControl =  function(page_index,field_name,field_type,rect) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formAddControl", [{
                                                                            'page_index': page_index,
                                                                            'field_name': field_name,
                                                                            'field_type': field_type,
                                                                            'rect': rect,
                                                                            }]);
                       });
};

// page_index  int type. index of a page
// control_index  int type. index of a control
// control        object type.
//{
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
// return none
FSForm.prototype.updateControl =  function(page_index,control_index, control) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "formUpdateControl", [{
                                                                               'page_index': page_index,
                                                                               'control_index': control_index,
                                                                               'control':control
                                                                               }]);
                       });
};

// page_index  int type. index of a page
// control_index  int type. index of a control
// retrun field object
//{
//    Choice :         (
//                      {
//                      "default_selected" : 1,
//                      "option_label" : "1",
//                      "option_value" : "1",
//                      selected : 1,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "2",
//                      "option_value" : "2",
//                      selected : 0,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "3",
//                      "option_value" : "3",
//                      selected : 0,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "4",
//                      "option_value" : "4",
//                      selected : 0,
//                      }
//                      ),
//    alignment : 0,
//    alternateName : "0",
//    defValue : "1",
//    defaultAppearance :         {
//        flags : 3,
//        font : "Helvetica",
//        "text_color" : 3,
//        "text_size" : 3,
//    },
//    fieldFlag : 7,
//    fieldType : 4,
//    fieldIndex : 1,
//    mappingName : "map_combobox",
//    maxLength : 0,
//    name : "Combo Box1",
//    topVisibleIndex : 0,
//    value : "1",
//}
FSForm.prototype.getFieldByControl =  function(page_index,control_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFieldByControl", [{'page_index': page_index,
                                                                               'control_index': control_index,}]);
                       });
};

module.exports = FSForm;


var FSField = function(){
};

// field_index int type. index of field
// fsfield  object type. new field value
//{
//    Choice :         (
//                      {
//                      "default_selected" : 1,
//                      "option_label" : "1",
//                      "option_value" : "1",
//                      selected : 1,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "2",
//                      "option_value" : "2",
//                      selected : 0,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "3",
//                      "option_value" : "3",
//                      selected : 0,
//                      },
//                      {
//                      "default_selected" : 0,
//                      "option_label" : "4",
//                      "option_value" : "4",
//                      selected : 0,
//                      }
//                      ),
//    alignment : 0,
//    alternateName : "0",
//    defValue : "1",
//    defaultAppearance :         {
//        flags : 3,
//        font : "Helvetica",
//        "text_color" : 3,
//        "text_size" : 3,
//    },
//    fieldFlag : 7,
//    fieldType : 4,
//    mappingName : "map_combobox",
//    maxLength : 0,
//    name : "Combo Box1",
//    topVisibleIndex : 0,
//    value : "1",
//}
//
// return none
FSField.prototype.updateField =  function(field_index,fsfield) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "fSFieldUpdateField", [{
                                                                                'field_index':field_index,
                                                                                'fsfield' : fsfield
                                                                                
                                                                                }]);
                       });
};

// reset field
// field_index int type. index of field
// return  none
FSField.prototype.reset =  function(field_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "fSFieldReset", [{'field_index':field_index,}]);
                       });
};

// field_index int type. index of field
// retrun array
//[{
// control_index : 1,
// exportValue : "",
// isChecked : true,
// isDefaultChecked : true,
// },{},{}...]
FSField.prototype.getFieldControls =  function(field_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFieldControls ", [{'field_index':field_index,}]);
                       });
};



module.exports = FSField;
