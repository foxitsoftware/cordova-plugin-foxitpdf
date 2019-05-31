var FSForm = function(){
};
// return all form fields array
//返回值 :
//返回一个对象数组，对象里面包括了key/value的信息，如defValue, flag.
//[{
// Choice =         (
//                   {
//                   "default_selected" = 1;
//                   "option_label" = 1;
//                   "option_value" = 1;
//                   selected = 1;
//                   },
//                   {
//                   "default_selected" = 0;
//                   "option_label" = 2;
//                   "option_value" = 2;
//                   selected = 0;
//                   },
//                   {
//                   "default_selected" = 0;
//                   "option_label" = 3;
//                   "option_value" = 3;
//                   selected = 0;
//                   },
//                   {
//                   "default_selected" = 0;
//                   "option_label" = 4;
//                   "option_value" = 4;
//                   selected = 0;
//                   }
//                   );
// alignment = 0;
// alternateName = 0;
// defValue = 1;
// defaultAppearance =         {
// flags = 3;
// font = Helvetica;
// "text_color" = 3;
// "text_size" = 3;
// };
// fieldFlag = 7;
// fieldIndex = 3;
// fieldType = 4;
// mappingName = "map_combobox";
// maxLength = 0;
// name = "Combo Box1";
// topVisibleIndex = 0;
// value = 1;
 },{},{},...]
FSForm.prototype.getAllFormFields =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getAllFormFields", [{}]);
                       });
};

// field_index  int type. field index
// filter       string type. filter value
// return field object 返回一个字典对象，里面包括了相关的信息
//{
//    Choice =         (
//                      {
//                      "default_selected" = 1;
//                      "option_label" = 1;
//                      "option_value" = 1;
//                      selected = 1;
//                      },
//                      {
//                      "default_selected" = 0;
//                      "option_label" = 2;
//                      "option_value" = 2;
//                      selected = 0;
//                      },
//                      {
//                      "default_selected" = 0;
//                      "option_label" = 3;
//                      "option_value" = 3;
//                      selected = 0;
//                      },
//                      {
//                      "default_selected" = 0;
//                      "option_label" = 4;
//                      "option_value" = 4;
//                      selected = 0;
//                      }
//                      );
//    alignment = 0;
//    alternateName = 0;
//    defValue = 1;
//    defaultAppearance =         {
//        flags = 3;
//        font = Helvetica;
//        "text_color" = 3;
//        "text_size" = 3;
//    };
//    fieldFlag = 7;
//    fieldIndex = 3;
//    fieldType = 4;
//    mappingName = "map_combobox";
//    maxLength = 0;
//    name = "Combo Box1";
//    topVisibleIndex = 0;
//    value = 1;
//}
FSForm.prototype.getField =  function(field_index,filter) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormGetField", [{
                                                                          'field_index': field_index,
                                                                          'filter': filter,
                                                                          }]);
                       });
};

// return form info dictionary
//{
//    alignment : "0", // 0 :left , 1 : center , 2 : right
//    NeedConstructAppearances : false,
//    defaultAppearance :  {
//        flags: flags,
//        font:font,
//        text_size:text_size,
//        text_color:text_color
//    }
//}
FSForm.prototype.getFormInfo =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFormInfo", [{}]);
                       });
};

//update form info.
//参数：
//{
//    alignment : "0", // 0 :left , 1 : center , 2 : right
//    NeedConstructAppearances : false,
//    defaultAppearance :  {
//        flags: flags,
//        font:font,
//        text_size:text_size,
//        text_color:text_color
//    }
//}
FSForm.prototype.updateFormInfo =  function(forminfo) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "updateFormInfo", [{'forminfo':forminfo}]);
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

// page_index  int type. index of a page
// retrun control count of a page
FSForm.prototype.getControlCount =  function(page_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormGetControlCount", [{'page_index': page_index,}]);
                       });
};

// page_index  int type. index of a page
// control_index  int type. index of a control
// retrun control object
//{
//    control_index : 1,
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
FSForm.prototype.getControl =  function(page_index,control_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormGetControl", [{'page_index': page_index,
                                                                               'control_index': control_index,}]);
                       });
};

// control_index  int type. index of a control
// return  none
FSForm.prototype.removeControl =  function(control_index) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormRemoveControl", [{'control_index': control_index,}]);
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
                       exec(resolve, reject, "FoxitPdf", "FormAddControl", [{
                                                                               'page_index': page_index,
                                                                               'field_name': field_name,
                                                                               'field_type': field_type,
                                                                               'rect': rect,
                                                                               }]);
                       });
};

// control_index  int type. index of a control
// control        object type.
//{
//    control_index : 1,
//    exportValue : "",
//    isChecked : true,
//    isDefaultChecked : true,
//}
// return none
FSForm.prototype.updateControl =  function(control_index, control) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FormUpdateControl", [{
                                                                            'control_index': control_index,
                                                                            'control':control
                                                                            }]);
                       });
};

module.exports = FSForm;


var FSField = function(){
};

// field_index int type. index of field
// fsfield  object type. new field value
// return none
FSField.prototype.updateField =  function(field_index,fsfield) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FSFieldUpdateField", [{
                                                                                'field_index':field_index,
                                                                                'fsfield' : fsfield
                                                                                
                                                                                }]);
                       });
};

// reset field
FSField.prototype.reset =  function() {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FSFieldReset", [{}]);
                       });
};

module.exports = FSField;
