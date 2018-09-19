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

您可以在[这里](https://github.com/foxitsoftware/cordova-plugin-foxitpdf/issues)给我们提出在使用中碰到的问题或Bug。

你也可以发送邮件**huang_niu@foxitsoftware.com**说明您的问题。

如果你有更好代码实现,请 fork 此项目并发起您的 Pull-Request，我们会及时处理。感谢!


## Request a Quote
如果遇到 “Invalid license” 的提示，请到以下网址申请正式 key
http://www.foxitsdk.com/products/mobile-pdf-sdk/request-quote/?from=cordova-plugin-foxitpdf


## More Support

http://forums.foxitsoftware.com/forum/portable-document-format-pdf-tools/foxit-cloud/cordova-plugin-foxitpdf

## 
