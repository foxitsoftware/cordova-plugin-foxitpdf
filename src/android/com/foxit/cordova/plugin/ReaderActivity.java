/**
 * Copyright (C) 2003-2023, Foxit Software Inc..
 * All Rights Reserved.
 * <p>
 * http://www.foxitsoftware.com
 * <p>
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */
package com.foxit.cordova.plugin;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.View;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.pdf.PDFDoc;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.config.Config;
import com.foxit.uiextensions.controls.toolbar.BaseBar;
import com.foxit.uiextensions.controls.toolbar.IBarsHandler;
import com.foxit.uiextensions.controls.toolbar.ToolItemBean;
import com.foxit.uiextensions.controls.toolbar.ToolProperty;
import com.foxit.uiextensions.pdfreader.MainCenterItemBean;
import com.foxit.uiextensions.utils.ActManager;
import com.foxit.uiextensions.utils.AppFileUtil;
import com.foxit.uiextensions.utils.AppSharedPreferences;
import com.foxit.uiextensions.utils.AppStorageManager;
import com.foxit.uiextensions.utils.AppTheme;
import com.foxit.uiextensions.utils.AppUtil;
import com.foxit.uiextensions.utils.UIToast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

public class ReaderActivity extends FragmentActivity {
    private static final String SP_NAME = "Cord_Foxit_Plugin_SP";
    private static final String KEY_TAB_ITEMS = "Tab_Items";

    protected static PDFViewCtrl pdfViewCtrl;
    private UIExtensionsManager uiextensionsManager;

    public static final int REQUEST_OPEN_DOCUMENT_TREE = 0xF001;
    public static final int REQUEST_SELECT_DEFAULT_FOLDER = 0xF002;

    public static final int REQUEST_EXTERNAL_STORAGE_MANAGER = 111;
    public static final int REQUEST_EXTERNAL_STORAGE = 222;

    private static final String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);
        ActManager.getInstance().setCurrentActivity(this);
        AppStorageManager.setOpenTreeRequestCode(REQUEST_OPEN_DOCUMENT_TREE);

        Config config = null;
        try {
            String configPath = "www/plugins/cordova-plugin-foxitpdf/uiextensions_config.json";
            InputStream stream = getApplicationContext().getResources().getAssets().open(configPath);
            config = new Config(stream);
            config.modules.enableAnnotations(FoxitPdf.mEnableAnnotations);
        } catch (IOException e) {
            e.printStackTrace();
        }
        pdfViewCtrl = new PDFViewCtrl(getApplicationContext());
        uiextensionsManager = new UIExtensionsManager(this, pdfViewCtrl, config);
        uiextensionsManager.setAttachedActivity(this);
        pdfViewCtrl.setUIExtensionsManager(uiextensionsManager);
        pdfViewCtrl.setAttachedActivity(this);
        pdfViewCtrl.registerDocEventListener(docListener);
        uiextensionsManager.onCreate(this, pdfViewCtrl, null);
        for (Map.Entry<Integer, Boolean> entry : FoxitPdf.mBottomBarItemStatus.entrySet()) {
            int index = entry.getKey();
            int visible = entry.getValue() ? View.VISIBLE : View.GONE;
            uiextensionsManager.getBarManager().setItemVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, index, visible);
        }

        for (Map.Entry<Integer, Boolean> entry : FoxitPdf.mTopBarItemStatus.entrySet()) {
            int index = entry.getKey();
            int visible = entry.getValue() ? View.VISIBLE : View.GONE;
            if (index == 0) {
                uiextensionsManager.getBarManager().setItemVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_LT, index, visible);
            } else {
                uiextensionsManager.getBarManager().setItemVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, index - 1, visible);
            }
        }

        String filePathSaveTo = getIntent().getExtras().getString("filePathSaveTo");
        if (!TextUtils.isEmpty(filePathSaveTo)) {
            uiextensionsManager.setSavePath(filePathSaveTo);
        }

        restoreItems();

        if (Build.VERSION.SDK_INT >= 30 && !AppFileUtil.isExternalStorageLegacy()) {
            AppStorageManager storageManager = AppStorageManager.getInstance(this);
            boolean needPermission = storageManager.needManageExternalStoragePermission();
            if (!AppStorageManager.isExternalStorageManager() && needPermission) {
                storageManager.requestExternalStorageManager(this, REQUEST_EXTERNAL_STORAGE_MANAGER);
            } else if (!needPermission) {
                checkStorageState();
            } else {
                openDocument();
            }
        } else if (Build.VERSION.SDK_INT >= 23) {
            checkStorageState();
        } else {
            openDocument();
        }

        setContentView(uiextensionsManager.getContentView());
    }

    private void checkStorageState() {
        int permission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
        if (permission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, PERMISSIONS_STORAGE, REQUEST_EXTERNAL_STORAGE);
        } else {
            selectDefaultFolderOrNot();
        }
    }

    private void selectDefaultFolderOrNot() {
        if (AppFileUtil.needScopedStorageAdaptation()) {
            if (TextUtils.isEmpty(AppStorageManager.getInstance(this).getDefaultFolder())) {
                AppFileUtil.checkCallDocumentTreeUriPermission(this, REQUEST_SELECT_DEFAULT_FOLDER,
                        Uri.parse(AppFileUtil.getExternalRootDocumentTreeUriPath()));
                UIToast.getInstance(getApplicationContext()).show("Please select the default folder,you can create one when it not exists.");
            } else {
                openDocument();
            }
        } else {
            openDocument();
        }
    }

    private void openDocument() {
        Intent intent = getIntent();
        String filePath = intent.getStringExtra("path");
        byte[] password = intent.getByteArrayExtra("password");
        uiextensionsManager.openDocument(filePath, password);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_EXTERNAL_STORAGE) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                selectDefaultFolderOrNot();
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                setResult(FoxitPdf.RDK_CANCELED_EVENT);
            }
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (uiextensionsManager == null)
            return;
        uiextensionsManager.onStart(this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (uiextensionsManager == null)
            return;
        uiextensionsManager.onPause(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (uiextensionsManager == null)
            return;
        uiextensionsManager.onResume(this);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (uiextensionsManager == null)
            return;
        uiextensionsManager.onStop(this);
    }

    @Override
    protected void onDestroy() {
        if (uiextensionsManager != null)
            uiextensionsManager.onDestroy(this);
        pdfViewCtrl.unregisterDocEventListener(docListener);
        super.onDestroy();
    }

    @SuppressLint("WrongConstant")
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_EXTERNAL_STORAGE_MANAGER) {
            AppFileUtil.updateIsExternalStorageManager();
            if (!AppFileUtil.isExternalStorageManager()) {
                checkStorageState();
            } else {
                openDocument();
            }
        } else if (requestCode == AppStorageManager.getOpenTreeRequestCode() || requestCode == REQUEST_SELECT_DEFAULT_FOLDER) {
            if (resultCode == Activity.RESULT_OK) {
                if (data == null || data.getData() == null) return;
                Uri uri = data.getData();
                int modeFlags = data.getFlags() & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                getContentResolver().takePersistableUriPermission(uri, modeFlags);
                AppStorageManager storageManager = AppStorageManager.getInstance(getApplicationContext());
                if (TextUtils.isEmpty(storageManager.getDefaultFolder())) {
                    String defaultPath = AppFileUtil.toPathFromDocumentTreeUri(uri);
                    storageManager.setDefaultFolder(defaultPath);
                    openDocument();
                }
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                finish();
            }
        }

        if (uiextensionsManager != null)
            uiextensionsManager.handleActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (uiextensionsManager != null)
            uiextensionsManager.onConfigurationChanged(this, newConfig);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (uiextensionsManager != null && uiextensionsManager.onKeyDown(this, keyCode, event))
            return true;
        return super.onKeyDown(keyCode, event);
    }

    PDFViewCtrl.IDocEventListener docListener = new PDFViewCtrl.IDocEventListener() {
        @Override
        public void onDocWillOpen() {
        }

        @Override
        public void onDocOpened(PDFDoc pdfDoc, int errCode) {
            FoxitPdf.onDocOpened(errCode);
        }

        @Override
        public void onDocWillClose(PDFDoc pdfDoc) {
            saveTabItems();
            FoxitPdf.mEnableAnnotations = true;
            FoxitPdf.mBottomBarItemStatus.clear();
            FoxitPdf.mTopBarItemStatus.clear();
        }

        @Override
        public void onDocClosed(PDFDoc pdfDoc, int i) {
        }

        @Override
        public void onDocWillSave(PDFDoc pdfDoc) {
            FoxitPdf.onDocWillSave();
        }

        @Override
        public void onDocSaved(PDFDoc pdfDoc, int i) {
            FoxitPdf.onDocSave("onDocSaved");
        }

    };

    private void setResult(String type) {
        Intent intent = new Intent();
        intent.putExtra("key", "info");
        intent.putExtra("type", type);
        setResult(RESULT_OK, intent);
        pdfViewCtrl.unregisterDocEventListener(docListener);
        finish();
    }

    private void restoreItems(){
        String tabItems = AppSharedPreferences.getInstance(getApplicationContext()).getString(SP_NAME, KEY_TAB_ITEMS, "");
        if (!AppUtil.isEmpty(tabItems)) {
            try {
                JSONObject rootObj = new JSONObject(tabItems);
                JSONArray centerItemsObj = rootObj.getJSONArray("centerItems");

                ArrayList<MainCenterItemBean> items = new ArrayList<>();
                for (int i = 0; i < centerItemsObj.length(); i ++) {
                    JSONObject centerObj = centerItemsObj.getJSONObject(i);

                    MainCenterItemBean centerItem = new MainCenterItemBean();
                    centerItem.type = centerObj.getInt("type");
                    centerItem.position = centerObj.getInt("position");
                    if (!centerObj.has("toolItems")){
                        items.add(centerItem);
                        continue;
                    }

                    centerItem.toolItems = new ArrayList<>();
                    JSONArray toolItemsObj = centerObj.getJSONArray("toolItems");
                    for (int toolIndex = 0; toolIndex < toolItemsObj.length(); toolIndex ++) {
                        JSONObject toolObj = toolItemsObj.getJSONObject(toolIndex);

                        ToolItemBean toolItem = new ToolItemBean();
                        toolItem.itemStyle = toolObj.getInt("itemStyle");
                        toolItem.type = toolObj.getInt("type");
                        toolItem.property = new ToolProperty();
                        {
                            ToolProperty property = toolItem.property;
                            JSONObject propObj = toolObj.getJSONObject("property");

                            if (!setToolPropVal(property, propObj)) {
                                toolItem.property = null;
                            }
                        }
                        centerItem.toolItems.add(toolItem);
                    }
                    items.add(centerItem);
                }
                uiextensionsManager.getMainFrame().setCenterItems(items);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    boolean setToolPropVal(ToolProperty property, JSONObject propObj) {
        try {
            boolean haveProp = false;
            if (propObj.has("type")) {
                property.type = propObj.getInt("type");
                haveProp = true;
            }
            if (propObj.has("color")) {
                property.color = propObj.getInt("color");
                haveProp = true;
            }
            if (propObj.has("fillColor")) {
                property.fillColor = propObj.getInt("fillColor");
                haveProp = true;
            }
            if (propObj.has("opacity")) {
                property.opacity = propObj.getInt("opacity");
                haveProp = true;
            }
            if (propObj.has("style")) {
                property.style = propObj.getInt("style");
                haveProp = true;
            }
            if (propObj.has("rotation")) {
                property.rotation = propObj.getInt("rotation");
                haveProp = true;
            }
            if (propObj.has("lineWidth")) {
                property.lineWidth = (float) propObj.getDouble("lineWidth");
                haveProp = true;
            }
            if (propObj.has("fontSize")) {
                property.fontSize = (float) propObj.getDouble("fontSize");
                haveProp = true;
            }
            if (propObj.has("fontName")) {
                property.fontName = propObj.getString("fontName");
                haveProp = true;
            }
            if (propObj.has("scaleFromUnitIndex")) {
                property.scaleFromUnitIndex = propObj.getInt("scaleFromUnitIndex");
                haveProp = true;
            }
            if (propObj.has("scaleToUnitIndex")) {
                property.scaleToUnitIndex = propObj.getInt("scaleToUnitIndex");
                haveProp = true;
            }
            if (propObj.has("scaleFromValue")) {
                property.scaleFromValue = BigDecimal.valueOf(propObj.getDouble("scaleFromValue")).floatValue();
                haveProp = true;
            }
            if (propObj.has("scaleToValue")) {
                property.scaleToValue = BigDecimal.valueOf(propObj.getDouble("scaleToValue")).floatValue();
                haveProp = true;
            }
            if (propObj.has("eraserShape")) {
                property.eraserShape = propObj.getInt("eraserShape");
                haveProp = true;
            }
            if (propObj.has("tag")) {
                property.mTag = propObj.get("tag");
                haveProp = true;
            }
            return haveProp;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private void saveTabItems(){
        List<MainCenterItemBean> items = uiextensionsManager.getMainFrame().getCenterItems();

        try {
            JSONObject rootObj = new JSONObject();
            JSONArray centerItemsObj = new JSONArray();
            rootObj.put("centerItems", centerItemsObj);

            for (MainCenterItemBean centerItem : items) {
                JSONObject centerObj = new JSONObject();
                centerObj.put("type", centerItem.type);
                centerObj.put("position", centerItem.position);

                if (centerItem.toolItems != null) {
                    JSONArray toolItemsObj = new JSONArray();
                    centerObj.put("toolItems", toolItemsObj);
                    for (ToolItemBean toolItem : centerItem.toolItems) {
                        JSONObject toolObj = new JSONObject();
                        toolObj.put("itemStyle", toolItem.itemStyle);
                        toolObj.put("type", toolItem.type);
                        {
                            ToolProperty property = toolItem.property;
                            JSONObject propObj = new JSONObject();

                            if (property != null) {
                                setToolPropObjVal(propObj, property);
                            }
                            toolObj.put("property", propObj);
                        }
                        toolItemsObj.put(toolObj);
                    }
                }
                centerItemsObj.put(centerObj);
            }

            AppSharedPreferences.getInstance(getApplicationContext()).setString(SP_NAME, KEY_TAB_ITEMS, rootObj.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    void setToolPropObjVal(JSONObject propObj, ToolProperty property) {
        try {
            propObj.put("type", property.type);
            propObj.put("color", property.color);
            propObj.put("fillColor", property.fillColor);
            propObj.put("opacity", property.opacity);
            propObj.put("style", property.style);
            propObj.put("rotation", property.rotation);
            propObj.put("lineWidth", property.lineWidth);
            propObj.put("fontSize", property.fontSize);
            propObj.put("fontName", property.fontName);
            propObj.put("scaleFromUnitIndex", property.scaleFromUnitIndex);
            propObj.put("scaleToUnitIndex", property.scaleToUnitIndex);
            propObj.put("scaleFromValue", property.scaleFromValue);
            propObj.put("scaleToValue", property.scaleToValue);
            propObj.put("eraserShape", property.eraserShape);
            if (property.mTag != null)
                propObj.put("tag", property.mTag);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
