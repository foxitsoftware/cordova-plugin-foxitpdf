// There are some js interface unit test code for pdf form
// and form interface must be excuted after doc opened

Form.getAllFormFields().then(function(data){
    console.log(data);
},function(){
    console.log('error');
});

Form.getForm().then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

Form.updateForm({alignment:0}).then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

Form.validateFieldName(0,"text1").then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

Form.renameField(0,"Signature_0_0").then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

// Form.removeField(0).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

// Form.reset().then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

var exportPath = cordova.file.documentsDirectory +'export.xml';
Form.exportToXML(exportPath).then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

// var importPath = cordova.file.documentsDirectory +'improt.xml';
// Form.importFromXML(importPath).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

Form.getPageControls(0).then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

// Form.removeControl(0,0).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

// Form.addControl(0,"text111",0,{left:100,top:10,right:100,bottom:100}).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

// Form.updateControl(0,0,{exportValue:"test"}).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

Form.getFieldByControl(0).then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});

// var field = {};
// Field.updateField(0,field).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

// Field.reset(0).then(function(data){
//     console.log(data);
// }).catch(function(){
//     console.log('error');
// });

Field.getFieldControls(17).then(function(data){
    console.log(data);
}).catch(function(){
    console.log('error');
});
// 17