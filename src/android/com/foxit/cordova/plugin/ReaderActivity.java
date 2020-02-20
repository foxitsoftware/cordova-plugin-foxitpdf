/**
 * Copyright (C) 2003-2020, Foxit Software Inc..
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
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.KeyEvent;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.pdf.PDFDoc;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.config.Config;
import com.foxit.uiextensions.utils.AppTheme;
import com.foxit.uiextensions.utils.UIToast;

import java.io.IOException;
import java.io.InputStream;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

public class ReaderActivity extends FragmentActivity {

    protected static PDFViewCtrl pdfViewCtrl;
    private UIExtensionsManager uiextensionsManager;

    private static final int REQUEST_EXTERNAL_STORAGE = 1;
    private static final String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);

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

        String filePathSaveTo = getIntent().getExtras().getString("filePathSaveTo");
        if (!TextUtils.isEmpty(filePathSaveTo)) {
            uiextensionsManager.setSavePath(filePathSaveTo);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            int permission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
            if (permission != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, PERMISSIONS_STORAGE, REQUEST_EXTERNAL_STORAGE);
            } else {
                uiextensionsManager.openDocument(getIntent().getStringExtra("path"), getIntent().getByteArrayExtra("password"));
            }
        } else {
            uiextensionsManager.openDocument(getIntent().getStringExtra("path"), getIntent().getByteArrayExtra("password"));
        }

        setContentView(uiextensionsManager.getContentView());
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_EXTERNAL_STORAGE) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                uiextensionsManager.openDocument(getIntent().getStringExtra("path"), getIntent().getByteArrayExtra("password"));
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                setResult();
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

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
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

    private void setResult() {
        Intent intent = new Intent();
        intent.putExtra("key", "info");
        setResult(RESULT_OK, intent);
        pdfViewCtrl.unregisterDocEventListener(docListener);
        finish();
    }
}
