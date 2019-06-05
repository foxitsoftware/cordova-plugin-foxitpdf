var exec = require('cordova/exec');

var Field = function(){
};

// fieldIndex int type. index of field
// Field  object type. new field value
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
Field.prototype.updateField =  function(fieldIndex,field) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FieldUpdateField", [{
                                                                                'fieldIndex':fieldIndex,
                                                                                'field' : field
                                                                                
                                                                                }]);
                       });
};

// reset field
// fieldIndex int type. index of field
// return  none
Field.prototype.reset =  function(fieldIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "FieldReset", [{'fieldIndex':fieldIndex,}]);
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
Field.prototype.getFieldControls =  function(fieldIndex) {
    return new Promise(function(resolve, reject) {
                       exec(resolve, reject, "FoxitPdf", "getFieldControls ", [{'fieldIndex':fieldIndex,}]);
                       });
};


var field = new Field();
module.exports = field;
