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
This plugin provides the ability to preview PDF files with Foxit MobilePDF SDK (aka Foxit RDK) on a mobile device using Apache Cordova.


## Installation
```bash
cordova plugin add cordova-plugin-foxitpdf
```

## iOS How To Use

1. Remove references to FoxitSource and UI Extensions. Create the FoxitSource group (because Cordova plug-in can not create iOS group).
2. Turn off arc mode, Build Settings -> Objective-C Automatic Reference Counting to NO
3. Embed Foxit RDK.framework General -> Embed Frameworks -> + -> FoxitRDK.framework
4. Insert the following code into the AppDelegate.h file

	```objective-c
	#import "UIExtensionsSharedHeader.h"
	#import "Defines.h"
	#define DEMO_APPDELEGATE  ((AppDelegate*)[[UIApplication sharedApplication] delegate])

	@property (nonatomic, strong) FSPDFViewCtrl* pdfViewCtrl;
	@property (nonatomic, assign) BOOL isFileEdited;
	@property (nonatomic, copy) NSString* filePath;
	@property (nonatomic, assign) BOOL isScreenLocked;
	```

5. In the project configuration to increase the direction of support
	General -> Deployment info -> Device Orientation ,   Check
	Portrait , Landscape Left , Landscape Right


Use this everywhere in your project

```js
var success = function(data){
    console.log(data);
}
var error = function(data){
    console.log(data);
}

var filePath = 'file://path/to/your/file';
//var filePath = cordova.file.applicationDirectory + 'Sample.pdf';
window.FoxitPdf.preview(filePath,success,error);
```


## Android How to use
```js
var success = function(data){
    console.log(data);
}
var error = function(data){
    console.log(data);
}
var filePath = 'file://path/to/your/file';
// var filePath = "/mnt/sdcard/getting_started_ios.pdf";
window.FoxitPdf.preview(filePath,success,error);
```


## iOS Screen Shot
![](https://raw.githubusercontent.com/niuemperor/cordova-plugin-foxitpdf/master/images/cordova-plugin-foxitpdf2.gif)


## Android Screen Shot
![](https://raw.githubusercontent.com/niuemperor/cordova-plugin-foxitpdf/master/images/cordova-plugin-foxitodf-android.png)


## Supported Platforms

- iOS

- Android

----



## IOS Quirks

The first argument in the preview method currently only supports absolute paths for incoming files.

You can obtain the absolute path to the file using the method provided by the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin.

Use the following command to add the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin to your project

```bash
cordova plugin add cordova-plugin-file
```


## Android Quirks
NOTE: Since the functionality associated with Reply in UIExtension is using FragmentActivity, the current plugin does not handle it, so there is a problem with using it. Will do further processing.

In addition: the current plug-ins already contain armeabi-v7a library, if you want to support other platforms, you need to refer to the Foxit RDK library for other libraries which can be introduced into the project.


### Quick Example

The PDF file needs to be placed in the project beforehand. The location is in the project root by default

```js
var success = function(data){
    console.log(data);
}
var error = function(data){
    console.log(data);
}
function preview(){
    var filePath = cordova.file.applicationDirectory + 'getting_started_ios.pdf';
    window.FoxitPdf.preview(filePath,success,error);
}
```


## Attention

The product is still in the early stage of development. We will continue to focus on refining and improving this project.

## Feedback or contribution code

You can ask us questions or report bugs in [here](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/issues).

You can also send email **huang_niu@foxitsoftware.com** to explain your problem.

If you have a better code implementation, please fork this project and launch your Pull-Request, we will promptly deal with. Thanks!


## Request a Quote
If you encounter “Invalid license” tips, please go to the following URL for official trial license key:

http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf

## More Support

http://forums.foxitsoftware.com/forum/portable-document-format-pdf-tools/foxit-cloud/cordova-plugin-foxitpdf

