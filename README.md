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
This plugin provides the ability to preview pdf files with Foxit RDK on a device.


## iOS Screen Shot
![](https://raw.githubusercontent.com/niuemperor/cordova-plugin-foxitpdf/master/images/cordova-plugin-foxitpdf2.gif)


## Android Screen Shot
![](https://raw.githubusercontent.com/niuemperor/cordova-plugin-foxitpdf/master/images/cordova-plugin-foxitodf-android.png)


## What change
1. 整合了Foxit RDK UI部分，新增跳转翻页，全文搜索，缩略图预览等功能
2. 调整了插件集成方式，使集成更简单更方便
3. 增加了对android平台的支持


## Installation
```bash
cordova plugin add cordova-plugin-foxitpdf
```


## iOS How To Use
1. 删除 FoxitSource ,uitextensions的引用。再创建 FoxitSource group。(因为cordova 插件不能创建ios group)
2. 关闭 arc 模式，Build Settings -> Objective-C Automatic Reference Counting 改为 NO
3. 在 AppDelegate.h 文件中插入以下代码

	```objective-c
	#import "UIExtensionsSharedHeader.h"
	#import "Defines.h"
	#define DEMO_APPDELEGATE  ((AppDelegate*)[[UIApplication sharedApplication] delegate])

	@property (nonatomic, strong) FSPDFViewCtrl* pdfViewCtrl;
	@property (nonatomic, assign) BOOL isFileEdited;
	@property (nonatomic, copy) NSString* filePath;
	@property (nonatomic, assign) BOOL isScreenLocked;
    ```
4. 嵌入 FoxitRDK.framework
	General ->Embed Frameworks -> + -> FoxitRDK.framework

5. 在项目配置里增加方向支持
	General -> Deployment info -> Device Orientation 下勾选
	Portrait , Landscape Left , Landscape Right


在你项目中任意位置使用以下代码

```js
var success = function(data){
    console.log(data);
}
var error = function(data){
    console.log(data);
}
var filePath = 'file://path/to/your/file';
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


## Supported Platforms

- iOS

- Android

----


## IOS Quirks
preiview方法的第一个参数，目前只支持传入文件的绝对路径。

可以使用 [cordova-plugin-file](https://github.com/apache/cordova-plugin-file) 插件提供的方法，获取到文件的绝对路径。

使用以下命令，添加 [cordova-plugin-file](https://github.com/apache/cordova-plugin-file) 插件到你的项目中


```bash
cordova plugin add cordova-plugin-file
```


## Android Quirks
NOTE：由于UIExtension中的和Reply相关的功能是使用FragmentActivity，当前的插件没有做处理，所以使用该功能时会有问题。后面会做进一步的处理。

另外：当前该插件已经包含armeabi-v7a的库，如果想要支持其他平台，需要参考Foxit RDK将其他平台的库引入工程中即可。


### Quick Example

需要事先将pdf文件放入项目中。位置默认放在项目根目录

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

产品目前还是处于刚开发阶段. 后期将会着重于功能的完善和细化.


## Feedback or contribution code

您可以在[这里](https://github.com/niuemperor/cordova-plugin-foxitpdf/issues)给我们提出在使用中碰到的问题或Bug。

你也可以发送邮件**huang_niu@foxitsoftware.com**说明您的问题。

如果你有更好代码实现,请 fork 此项目并发起您的 Pull-Request，我们会及时处理。感谢!


## Request a Quote
如果遇到 “Invalid license” 的提示，请到以下网址申请正式 key
http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf


## 





## What change

1. Integrated Foxit RDK UI section, add jump page, full text search, thumbnail preview and other functions
2. Adjust the plug-in integration, so that integration easier and more convenient
3. Added support for android platform


## Installation
```bash
cordova plugin add cordova-plugin-foxitpdf
```


## iOS How To Use

1. Remove references to FoxitSource, uitextensions. Create the FoxitSource group. (Because cordova plug-in can not create ios group)
2. Turn off arc mode, Build Settings -> Objective-C Automatic Reference Counting to NO
3. Insert the following code into the AppDelegate.h file

	```objective-c
	#import "UIExtensionsSharedHeader.h"
	#import "Defines.h"
	#define DEMO_APPDELEGATE  ((AppDelegate*)[[UIApplication sharedApplication] delegate])

	@property (nonatomic, strong) FSPDFViewCtrl* pdfViewCtrl;
	@property (nonatomic, assign) BOOL isFileEdited;
	@property (nonatomic, copy) NSString* filePath;
	@property (nonatomic, assign) BOOL isScreenLocked;
	```
4. Embed Foxit RDK.framework
	General -> Embed Frameworks -> + -> FoxitRDK.framework

5. In the project configuration to increase the direction of support
	General -> Deployment info -> Device Orientation ,   Check
	Portrait , Landscape Left , Landscape Right


Use this ,in everywhere in your project

```js
var success = function(data){
    console.log(data);
}
var error = function(data){
    console.log(data);
}
var filePath = 'file://path/to/your/file';
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


## Supported Platforms

- iOS

- Android

----



## IOS Quirks

The first argument to the preiview method, currently only supports absolute paths to incoming files.

You can obtain the absolute path to the file using the method provided by the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin.

Use the following command to add the [cordova-plugin-file] (https://github.com/apache/cordova-plugin-file) plugin to your project

```bash
cordova plugin add cordova-plugin-file
```


## Android Quirks
NOTE: Since the functionality associated with Reply in UIExtension is using FragmentActivity, the current plugin does not handle it, so there is a problem with using it. Will do further processing.

In addition: the current plug-ins already contains armeabi-v7a library, if you want to support other platforms, you need to refer to the Foxit RDK library to other projects can be introduced into the project.


### Quick Example

The pdf file needs to be placed in the project beforehand. The location is placed in the project root by default

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

The product is still in the early stage of development. Later will focus on the function of refinement and refinement.


## Feedback or contribution code

You can ask us questions or bugs in [here](https://github.com/niuemperor/cordova-plugin-foxitpdf/issues).

You can also send email **huang_niu@foxitsoftware.com** to explain your problem.

If you have a better code implementation, please fork this project and launch your Pull-Request, we will promptly deal with. thank!


## Request a Quote
If you encounter “Invalid license” tips, please go to the following URL for official key

http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf