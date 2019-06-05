var exec = require('cordova/exec');

var FSField = function(){
};

// fieldIndex int type. index of field
// fsfield  object type. new field value
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

// return none
FSField.prototype.updateField =  function(fieldIndex,fsfield) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "fSFieldUpdateField", [{
                                                                                'fieldIndex':fieldIndex,
                                                                                'fsfield' : fsfield
                                                                                
                                                                                }]);
                       });
};

// reset field
// fieldIndex int type. index of field
// return  none
FSField.prototype.reset =  function(fieldIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "fSFieldReset", [{'fieldIndex':fieldIndex,}]);
                       });
};

// fieldIndex int type. index of field
// retrun array
//[{
// controIndex : 1,
// exportValue : "",
// isChecked : true,
// isDefaultChecked : true,
// },{},{}...]
FSField.prototype.getFieldControls =  function(fieldIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFieldControls ", [{'fieldIndex':fieldIndex,}]);
                       });
};



module.exports = FSField;
