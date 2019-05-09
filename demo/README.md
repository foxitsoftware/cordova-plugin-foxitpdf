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

# How to use this demo

## Open /demo/demoApp, Execute these commands

###
```bash
cordova platform add ios (to add test platform)

cordova plugin add cordova-plugin-foxitpdf

cordova plugin add cordova-plugin-file
```

## Unzip Foxit PDF SDK for iOS and copy libs folder into the component ios folder. (Please use Foxit PDF SDK for iOS 6.3 )

## Open demoApp/platforms/ios/demoApp.xcworkspace

1. Target -> General ->Embedded Binaries， Add dynamic framework "FoxitRDK.framework" and "uiextensionsDynamic.framework" to framework folder and also to Xcode’s Embedded Binaries

2. Target -> General -> Linked Frameworks and Libraries -> + -> WebKit.framework

![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/demo/readmeimg/cordovademo1.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/feature/adddemo/demo/readmeimg/cordovademo1.png)



## Put pdf file to document folder
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/demo/readmeimg/cordovademo2.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/feature/adddemo/demo/readmeimg/cordovademo2.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/demo/readmeimg/cordovademo3.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/feature/adddemo/demo/readmeimg/cordovademo3.png)


## Chang filepath and sn/key in index.js
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/demo/readmeimg/cordovademo4.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/feature/adddemo/demo/readmeimg/cordovademo4.png)


## Execute command
```bash
cordova prepare
```

## Xcode run  , click cordova app ’s  preview button .
Congratulations! You kan preview this pdf file now.
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/master/demo/readmeimg/cordovademo5.png)
![](https://raw.githubusercontent.com/foxitsoftware/cordova-plugin-foxitpdf/feature/adddemo/demo/readmeimg/cordovademo5.png)
