<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

# cordova-plugin-foxitpdf
    This plugin adds the ability to easily preview any PDF file in your Cordova application
  
- [Installation](#installation)
- [Usage Instructions for iOS](#usage-instructions-for-ios)
- [Usage Instructions for Android](#usage-instructions-for-android)
- [API Reference](#api-reference)
- [Supported Platforms](#supported-platforms)
- [Quick Example](#quick-example)
- [Attention](#attention)
- [Versions](#versions)
## Installation
```bash
cordova plugin add cordova-plugin-foxitpdf
```

It is also possible to install via repo url directly ( unstable )

    cordova plugin add https://github.com/foxitsoftware/cordova-plugin-foxitpdf.git

Large files in the plugin may cause your update to fail. If that is the case, please try again following the steps below:
1. Clone this project
2. Add plugin from local using this command :

```bash
cordova plugin add ~/abc/cordova-plugin-foxitpdf (This address is replaced by your own)
```

## Note
    The trial key period provided is 10 days，if you try the plugin and fail to access, it may be due to an invalid/expired key. Please note the key expiration date.
    If you need an extension of your trial period key, please contact us.

    Please note the current key expiration date is ## 4-15 2019.

## Major update
    Now our plugin is using Foxit PDF SDK version 6.3 for Android ,Foxit PDF SDK version 6.3 for iOS .

## Usage Instructions for iOS
Thanks to the new Foxit PDF SDK for iOS 6.3 API, the iOS version of the cordova plug-in only needs a few simple steps to deploy (It involves much lighter operations when compared to our previous version 6.1)


1. Unzip Foxit PDF SDK for iOS and copy libs folder into the component ios folder. (Please use Foxit PDF SDK for iOS 6.3 )
2. Add dynamic framework
    "FoxitRDK.framework" and "uiextensionsDynamic.framework"
    to framework folder and also to Xcode’s Embedded Binaries  
3. Target -> General -> Linked Frameworks and Libraries ->  +  -> WebKit.framework


> `Note` Do not forget to add pdf files  
   You can add the PDF to Copy Bundle Resources directly. Just left-click the project, find 'Copy Bundle Resources' in the 'Build Phases' tab, click on the + button, and choose the file to add. You can refer to any PDF file, just add it to the Xcode’s Copy Bundle Resources.



Now that the preparatory work has been completed，you can use this code everywhere in your project.


## window.FoxitPdf.initialize 

> initialize = function(sn, key)

```javascript
 var sn = 'foxit_sn';
 var key = 'foxit_key';
 window.FoxitPdf.initialize(sn,key);
```    

- __options__: Initialization options.

- __foxit_sn__: the `rdk_sn`
- __foxit_key__: the `rdk_key`  

`foxit_sn` and `foxit_key` is required, otherwise the initialization will fail. `rdk_key` and `rdk_sn` can be found in the libs folder of `foxitpdfsdk_(version_no)_ios.zip`.

## window.FoxitPdf.openDocument

> openDocument = function(path, password)

```javascript
    var path = 'Your file path';
    var password = 'password'; // If the PDF document is not encrypted by password, just pass an empty string.

    window.FoxitPdf.openDocument(path, password);
```    

-__Note__: The document can only be opened if the initialization is successful.

  - __path__: Document path you wish to open
  - __password__: The password used to load the PDF document content. It can be either user password or owner password.
  If the PDF document is not encrypted by password, just pass an empty string.
  
## window.FoxitPdf.setSavePath (iOS)

> setSavePath = function(savePath)

```js
    var savePath = 'Your file path';// Document path that prevents overwriting on the preview file  _(if set)_
    window.FoxitPdf.setSavePath(savePath);
```    

  - __savePath__: Document path that prevents overwriting on the preview file  _(if set)_
  
## window.FoxitPdf.importFromFDF (iOS)

> importFromFDF = function(fdf_doc_path, data_type, page_range = [])

```js
    var fdf_doc_path = 'Your file path';// FDF file path 
    var data_type = 0x0002;
    var page_range = [[0,1],[2,3]]
    window.FoxitPdf.importFromFDF(fdfPath, data_type);
```    

  - __`fdf_doc_path`__: A valid fdf file path, from which form fields and annotations will be imported.
  - __`data_type`__: Used to decide which kind of data will be imported. this can be one or a combination of as following values:
	1. `0x0001` : Form fields are to imported from or exported to FDF/XFDF document. 
	2. `0x0002` : Annotations are to imported from or exported to FDF/XFDF document. 
	3. `0x0004` : Annotations (except link annotations) are to imported from or exported to FDF/XFDF document.
  - __`page_range`__: A integer range array that specifies some pages. Data (in specified types) from FDF/XFDF document will be imported to these specified pages. range for importing. In this array, 2 numbers are a pair: the first integer is the starting page index, and the second integer is the page count. `it should contains at least 2 numbers, and the count of elements should be a multiples of 2.`  Default value: an empty range by default and not set any value.

## window.FoxitPdf.exportToFDF (iOS)

> exportToFDF = function(export_path, data_type, fdf_doc_type, page_range = [])

```js

    var fdf_doc_type = 0;
    var exportPath = '/Documents/annot_export.fdf';
    var page_range = [[0,1],[2,3]]
    var data_type = 0x0002;
    window.FoxitPdf.exportToFDF(fdfPath, data_type, fdf_doc_type, page_range);
```  
  
  - __`export_path`__: A valid path to which form fields and annotations will be exported.
  - __`data_type`__: Used to decide which kind of data will be imported. this can be one or a combination of as following values:
	1. `0x0001` : Form fields are to imported from or exported to FDF/XFDF document. 
	2. `0x0002` : Annotations are to imported from or exported to FDF/XFDF document. 
	3. `0x0004` : Annotations (except link annotations) are to imported from or exported to FDF/XFDF document.
  - __`fdf_doc_type`__: FDF document type. `0 means FDF, and 1 means XFDF`.
  - __`page_range`__: A integer range array that specifies some pages. Data (in specified types) from FDF/XFDF document will be imported to these specified pages. range for importing. In this array, 2 numbers are a pair: the first integer is the starting page index, and the second integer is the page count. `it should contains at least 2 numbers, and the count of elements should be a multiples of 2.`  Default value: an empty range by default and not set any value.


## window.FoxitPdf.addEventListener

> Add a listener for an event

    window.FoxitPdf.addEventListener(eventname,callback);

- __eventname__: The name of the event to listen for _(String)_

  - __onDocWillSave__: This event fires when the document will be saved.
  - __onDocSaved__: This event fires when the document is saved.
  - __onDocOpened__: This event fires when the document is Opened.

- __callback__: This function is executed when the event fires. The function is passed an object as a parameter.


## Example

```javascript

window.FoxitPdf.addEventListener('onDocSaved',function(data){
  console.log('onDocSaved callback ',data);
});

window.FoxitPdf.addEventListener('onDocOpened',function(data){
  console.log('onDocOpened callback ',data);
});

```

&nbsp;&nbsp;

## Usage Instructions for Android
1:Download `foxitpdfsdk_(version_no)_android.zip` from [https://developers.foxitsoftware.com/pdf-sdk/android/](https://developers.foxitsoftware.com/pdf-sdk/android/) (Please use Foxit PDF SDK for Android 6.3)

2:Unzip `foxitpdfsdk_(version_no)_android.zip` and copy libs folder into the component android folder.

3:Initialize the plugin with ` window.FoxitPdf.initialize` .

4:Open the document with `window.FoxitPdf.openDocument` after initialization is complete.

## API Reference

#### window.FoxitPdf.initialize (Android)

> initialize = function(sn, key)

```js

    var sn = 'foxit_sn';
    var key = 'foxit_key';

    window.FoxitPdf.initialize(initOptions,successcallback,errorcallback);
```    

  - __foxit_sn__: the `rdk_sn`
  - __foxit_key__: the `rdk_key`  

   `foxit_sn` and `foxit_key` is required, otherwise the initialization will fail. `rdk_key` and `rdk_sn` can be found in the libs folder of `foxitpdfsdk_(version_no)_android.zip`.


#### window.FoxitPdf.openDocument (Android)

> openDocument = function(path, password)

```js

    var path = 'Your file path';
    var password = 'password'; // If the PDF document is not encrypted by password, just pass an empty string.

    window.FoxitPdf.openDocument(path, password);
```    

-__Note__: The document can only be opened if the initialization is successful.

  - __path__: Document path you wish to open
  - __password__: The password used to load the PDF document content. It can be either user password or owner password.
  If the PDF document is not encrypted by password, just pass an empty string.

#### window.FoxitPdf.setSavePath (Android)

> setSavePath = function(savePath)

```js

    var savePath = 'Your file path';// Document path that prevents overwriting on the preview file  _(if set)_

    window.FoxitPdf.setSavePath(savePath);
```    

  - __savePath__: Document path that prevents overwriting on the preview file  _(if set)_


#### window.FoxitPdf.importFromFDF (Android)

> importFromFDF = function(fdf_doc_path, data_type, page_range = [])

```js

    var fdf_doc_path = 'Your file path';// FDF file path 
    var data_type = 0x0002;
    window.FoxitPdf.importFromFDF(fdfPath, data_type);
```    

  - __`fdf_doc_path`__: A valid fdf file path, from which form fields and annotations will be imported.
  - __`data_type`__: Used to decide which kind of data will be imported. this can be one or a combination of as following values:
	1. `0x0001` : Form fields are imported from or exported to FDF/XFDF document. 
	2. `0x0002` : Annotations (except Movie, Widget, Screen, PrinterMark and TrapNet) are imported from or exported to FDF/XFDF document. 
	3. `0x0004` : links are imported from or exported to XFDF document.**NOT SUPPORT** right now
  - __`page_range`__: A integer range array that specifies some pages. Data (in specified types) from FDF/XFDF document will be imported to these specified pages. range for importing. In this array, 2 numbers are a pair: the first integer is the starting page index, and the second integer is the page count. `it should contains at least 2 numbers, and the count of elements should be a multiples of 2.`  Default value: an empty range by default and not set any value.
  It only support annotations.

#### window.FoxitPdf.exportToFDF (Android)

> exportToFDF = function(export_path, data_type, fdf_doc_type, page_range = [])

```js

    var fdf_doc_type = 0;
    var exportPath = '/mnt/sdcard/FoxitSDK/annot_export.fdf';
    var data_type = 0x0002;
    window.FoxitPdf.exportToFDF(fdfPath, data_type, fdf_doc_type);
```  
  
  - __`export_path`__: A valid path to which form fields and annotations will be exported.
  - __`data_type`__: Used to decide which kind of data will be imported. this can be one or a combination of as following values:
	1. `0x0001` : Form fields are imported from or exported to FDF/XFDF document. 
	2. `0x0002` : Annotations (except Movie, Widget, Screen, PrinterMark and TrapNet) are imported from or exported to FDF/XFDF document. 
	3. `0x0004` : links are imported from or exported to XFDF document.**NOT SUPPORT** right now
  - __`fdf_doc_type`__: FDF document type. `0 means FDF, and 1 means XFDF`.
  - __`page_range`__: A integer range array that specifies some pages. Data (in specified types) from FDF/XFDF document will be imported to these specified pages. range for importing. In this array, 2 numbers are a pair: the first integer is the starting page index, and the second integer is the page count. `it should contains at least 2 numbers, and the count of elements should be a multiples of 2.`  Default value: an empty range by default and not set any value.
  It only support annotations.

### Example( android)
```js

	// First Step: Initialization
    var sn = 'foxit_sn'; // rdk_sn
    var key = 'foxit_key'; // rdk_key
	window.FoxitPdf.initialize(sn, key);
	  
	// Second Step: Open document
    var path = 'Your file path'; // Document path you wish to open. e.g. /mnt/sdcard/getting_started_android.pdf
    var password = 'password';
	window.FoxitPdf.openDocument(path, passowrd);

	// Third step: set save path (can be set before open document)
	var savePath = 'xxx'; //Document path that prevents overwriting on the preview file  _(if set)_. e.g. /mnt/sdcard/getting_started_android_save.pdf
	window.FoxitPdf.setSavePath(savePath);
```


&nbsp;&nbsp;

## PPT
Please see our forum for more detailed information:

[PPTX - How to use cordova-plugin-foxitpdf](http://forums.foxitsoftware.com/forum/portable-document-format-pdf-tools/foxit-cloud/cordova-plugin-foxitpdf/162972-ppt-how-to-use-cordova-plugin-foxitpdf)

## YOUTUBE
[![How to use cordova-plugin-foxitpdf](http://img.youtube.com/vi/3stdbwcm68k/maxresdefault.jpg)](https://youtu.be/3stdbwcm68k)


## iOS Screen Shot
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/plugin_ios.gif)



## Android Screen Shot
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/plugin_android.gif)


## Supported Platforms

- iOS

- Android



## iOS Quirks

1. The first argument in the preview method currently only supports absolute paths for incoming files.

    You can obtain the absolute path to the file using the method provided by the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin.

    Use the following command to add the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin to your project

    ```bash
    cordova plugin add cordova-plugin-file
    ```

2. Note: in some cases the resource folders are not added correctly and the number of items is the same because of XCode bug.（e.g.  Xcode 8.3.3）
In that case, remove the added reference from the project tree and add the Resource using the project tree - Add files to "YourProjectName". Remember to enable the option of "copy items if needed" and "create groups" when using this method.

If an error similar to the one in the following picture appears, try the method in step 2
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/lack_resource.png)



## Quick Example

A PDF file needs to be placed in the project beforehand. The location is in the project root by default

```javascript

var filePathSaveTo = cordova.file.documentsDirectory + 'getting_started_ios_2.pdf'
window.FoxitPdf.setSavePath(filePathSaveTo);

var filePath cordova.file.applicationDirectory + 'getting_started_ios.pdf';
window.FoxitPdf.openDocument(filePath,'');

window.FoxitPdf.addEventListener('onDocOpened',function(data){
                                     console.log('onDocOpened callback ',data);
                                     console.log('onDocOpened callback info',data.info);
                                     if (data.error == 0){
                                        var data_type = 0x0002;
                                        window.FoxitPdf.importFromFDF(cordova.file.documentsDirectory + 'Annot_all.fdf',data_type, [[0, 1]]);
                                     }
                                     });

```

## Attention

1. The product is still in its early stage of development. We will continue to focus on refining and improving this project.

2. If your cordova version is 7.0.0, you might encounter this problem:
no such file or directory, open 'xxxx/platforms/android/AndroidManifest.xml'
this is a cordova bug, and the solution is provided in the link below:
https://cordova.apache.org/announcements/2017/12/04/cordova-android-7.0.0.html

>However this a major breaking change for people creating standalone Cordova Android projects. This also means that the locations of files have changed and have been brought in line to the structure used by Android Studio.
This may affect plugin.xml files and config.xml files that use edit-config, and make it so plugins that use edit-config will not be able to be compatible with both Android 6.x and Android 7.x. To fix this issue, please do the following in your XML files


## Versions
>[v6.3.0](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/tree/V6.3.0)

>[v6.2.1](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/tree/V6.2.1)

>[v6.2](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/tree/V6.2)

>[v6.1](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/tree/V6.1)

## Feedback or contribution code

You can ask us questions or report bugs in [here](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/issues).

You can also send email **huang_niu@foxitsoftware.com** to explain your problem.

If you have a better code implementation, please fork this project and launch your Pull-Request, we will promptly deal with. Thanks!


## Request a Quote
If you encounter “Invalid license” tips, please go to the following URL for official trial license key:

http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf

## More Support

http://forums.foxitsoftware.com/forum/portable-document-format-pdf-tools/foxit-cloud/cordova-plugin-foxitpdf
