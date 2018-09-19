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

## Installation
```bash
cordova plugin add cordova-plugin-foxitpdf
```

It is also possible to install via repo url directly ( unstable )

    cordova plugin add https://github.com/foxitsoftware/cordova-plugin-foxitpdf.git

Because of some large file in our project ,if you update faild please try the other way
1. clone this project
2. add plugin from local by this command :

```bash
cordova plugin add ~/abc/cordova-plugin-foxitpdf (This address is replaced by your own)
```

## Note
    we just provide Trial key for 10 days ，if you try this plugin and then faild maybe the key is invalid .so please note the key expiration tiem.
    if you want longer time key , please contact us.

    now the key expiration day is ## 4-21 ,please note.

## Major update
    Now our plugin is also using Foxit RDK 5.1

## Usage Instructions for iOS
Thanks to the new version, and now we use the plug-in iOS only need a few simple steps on it (no longer like the 3.0 version of the kind of cumbersome operation)

1. Target -> Build setting -> Other Linker Flags -> + ->  `-lstdc++`
    ![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/ios_step1.png)
2. If appear FoxitRDK.framework `image not found` error, Make sure that Target -> General -> Embedded Binaries -> have FoxitRDK.framework
```diff
-PS:
-    Maybe xcode does not help us to add FoxitRDK.framework or libFoxitRDKUIExtensions.a correctly
-    Just delete it and re-add it
```   
3. Target -> Build Phases -> Copy Bundle Resources ->  +  -> `Resource`

    Resource folder -- found in the `Plugins/cordova-plugin-foxitpdf/uiextensions/resource` folder

    or use the method of `Add Files to xxx` ,remember check the option of `Create Group`
4. Target -> General -> Linked Frameworks and Libraries ->  +  -> WebKit.framework

> `Note` Do not forget to add pdf files  
   You can add the PDF to Copy Bundle Resources directly. Just left-click the your project, find Copy Bundle Resources in the Build Phases tab, press on the + button, and choose the file to add. You can refer to any PDF file, just add it to the Xcode’s Copy Bundle Resources.



The preparatory work has been completed，Now,you can use this code everywhere in your project


## window.FoxitPdf.preview

> function of preview

    window.FoxitPdf.preview(options,successcallback,errorcallback);

- __options__: preview configuration options. we now support two option

  - __filePath__: document path of what u want open
  - __filePathSaveTo__: document path that prevent overwrite of the preview file  _(if u set)_

- __successcallback__: the function that executes when the preview success. The function is passed an object as a parameter.

- __errorcallback__: the function that executes when the preview faild. The function is passed an object as a parameter.


## Example (In iOS)

```javascript

let pdfviewOptions = {
  'filePath':cordova.file.applicationDirectory + 'getting_started_ios.pdf',
  'filePathSaveTo': cordova.file.documentsDirectory + 'getting_started_ios_2.pdf',
};
window.FoxitPdf.preview(pdfviewOptions,
  function(succ){
    console.log('succ',succ);
  },function(err){
    console.log('err',err);
  });

```
These files address is replaced by your own

## window.FoxitPdf.addEventListener


> Add a listener for an event


    window.FoxitPdf.addEventListener(eventname,callback);

- __eventname__: the event to listen for _(String)_

  - __onDocSaved__: event fires when document saved.

- __callback__: the function that executes when the event fires. The function is passed an object as a parameter.



## Example

```javascript

window.FoxitPdf.addEventListener('onDocSaved',function(data){
  console.log('onDocSaved callback ',data);
});

```


## Usage Instructions for Android
Android do not have to make any changes, you can use the function like this sample code

```js
var successcallback = function(data){
  console.log(data);
}
var errorcallback = function(data){
  console.log(data);
}
// var filePath = "/mnt/sdcard/getting_started_ios.pdf";
let pdfviewOptions = {
  'filePath':'/mnt/sdcard/getting_started_ios.pdf',
  'filePathSaveTo': '/mnt/sdcard/getting_started_ios2.pdf',
};
window.FoxitPdf.preview(pdfviewOptions,successcallback,errorcallback);
```

These files address is replaced by your own


## PPT
Want to see more details, see forums.

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



## IOS Quirks

1. The first argument in the preview method currently only supports absolute paths for incoming files.

    You can obtain the absolute path to the file using the method provided by the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin.

    Use the following command to add the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin to your project

    ```bash
    cordova plugin add cordova-plugin-file
    ```

2. Note: in some cases the resource folder are not added correctly and the number of items is the same because of XCode bug.（e.g.  Xcode 8.3.3）
In that case remove the added reference from project tree and then add the Resource using the project tree - Add files to "YourProjectName" ,remember when use this method enable the option of
"copy items if needed" and "create groups"

If something like the error in the following picture appears, try the method in step 2
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/lack_resource.png)



## Quick Example

The PDF file needs to be placed in the project beforehand. The location is in the project root by default

```javascript

let pdfviewOptions = {
  'filePath':cordova.file.applicationDirectory + 'getting_started_ios.pdf',
  'filePathSaveTo': cordova.file.documentsDirectory + 'getting_started_ios_2.pdf',
};
window.FoxitPdf.preview(pdfviewOptions,
  function(succ){
    console.log('succ',succ);
  },function(err){
    console.log('err',err);
  });

```


## Attention

1. The product is still in the early stage of development. We will continue to focus on refining and improving this project.

2. if you cordova version is 7.0.0 maybe you will encounter this problem
no such file or directory, open 'xxxx/platforms/android/AndroidManifest.xml'
this is cordova bug,on this link has solution:
https://cordova.apache.org/announcements/2017/12/04/cordova-android-7.0.0.html

>However this a major breaking change for people creating standalone Cordova Android projects. This also means that the locations of files have changed and have been brought in line to the structure used by Android Studio.
This may affect plugin.xml files and config.xml files that use edit-config, and make it so plugins that use edit-config will not be able to be compatible with both Android 6.x and Android 7.x. To fix this issue, please do the following in your XML files


## Feedback or contribution code

You can ask us questions or report bugs in [here](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/issues).

You can also send email **huang_niu@foxitsoftware.com** to explain your problem.

If you have a better code implementation, please fork this project and launch your Pull-Request, we will promptly deal with. Thanks!


## Request a Quote
If you encounter “Invalid license” tips, please go to the following URL for official trial license key:

http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf

## More Support

http://forums.foxitsoftware.com/forum/portable-document-format-pdf-tools/foxit-cloud/cordova-plugin-foxitpdf
