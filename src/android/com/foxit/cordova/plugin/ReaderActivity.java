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
import android.os.Environment;
import android.provider.Settings;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.View;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.pdf.PDFDoc;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.config.Config;
import com.foxit.uiextensions.controls.toolbar.BaseBar;
import com.foxit.uiextensions.controls.toolbar.IBarsHandler;
import com.foxit.uiextensions.utils.ActManager;
import com.foxit.uiextensions.utils.AppFileUtil;
import com.foxit.uiextensions.utils.AppStorageManager;
import com.foxit.uiextensions.utils.AppTheme;
import com.foxit.uiextensions.utils.UIToast;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

public class ReaderActivity extends FragmentActivity {
    private static final int REQUEST_ALL_FILES_ACCESS_PERMISSION = 111;
    private static final int REQUEST_EXTERNAL_STORAGE = 222;

    protected static PDFViewCtrl pdfViewCtrl;
    private UIExtensionsManager uiextensionsManager;

    private static final String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);
        ActManager.getInstance().setCurrentActivity(this);

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
        setContentView(uiextensionsManager.getContentView());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                intent.setData(Uri.parse("package:" + getApplicationContext().getPackageName()));
                startActivityForResult(intent, REQUEST_ALL_FILES_ACCESS_PERMISSION);
                return;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            int permission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
            if (permission != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, PERMISSIONS_STORAGE, REQUEST_EXTERNAL_STORAGE);
                return;
            }
        }

        openDocument();
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
                openDocument();
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                setResult(FoxitPdf.RDK_CANCELED_EVENT);
            }
        } else {
            if (uiextensionsManager != null) {
                uiextensionsManager.handleRequestPermissionsResult(requestCode, permissions, grantResults);
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
        if (requestCode == REQUEST_ALL_FILES_ACCESS_PERMISSION) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (Environment.isExternalStorageManager()) {
                    openDocument();
                } else {
                    UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                    setResult(FoxitPdf.RDK_CANCELED_EVENT);
                }
            }
        } else if (uiextensionsManager != null) {
            uiextensionsManager.handleActivityResult(this, requestCode, resultCode, data);
        }
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
        public void onDocLoading(PDFDoc doc, int progress) {
        }

        @Override
        public void onDocWillOpen() {
        }

        @Override
        public void onDocOpened(PDFDoc pdfDoc, int errCode) {
            FoxitPdf.onDocOpened(errCode);
        }

        @Override
        public void onDocWillClose(PDFDoc pdfDoc) {
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

}
