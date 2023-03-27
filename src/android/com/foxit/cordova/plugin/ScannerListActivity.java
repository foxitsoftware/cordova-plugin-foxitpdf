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
import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

import com.foxit.pdfscan.IPDFScanManagerListener;
import com.foxit.pdfscan.PDFScanManager;
import com.foxit.pdfscan.activity.ScannerCameraActivity;
import com.foxit.uiextensions.utils.ActManager;
import com.foxit.uiextensions.utils.AppDisplay;
import com.foxit.uiextensions.utils.AppTheme;
import com.foxit.uiextensions.utils.UIToast;

public class ScannerListActivity extends FragmentActivity {

    private static final int REQUEST_EXTERNAL_STORAGE = 111;
    private static final int REQUEST_CAMERA = 222;
    private static final int REQUEST_ALL_FILES_ACCESS_PERMISSION = 333;

    private static final String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
    };
    private static final String[] PERMISSIONS_CAMERA = {
            Manifest.permission.CAMERA,
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);
        AppDisplay.Instance(getApplicationContext());
        getApplication().registerActivityLifecycleCallbacks(mLifecycleCallbacks);

        if (Build.VERSION.SDK_INT >= 30) {
            if (!Environment.isExternalStorageManager()) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                intent.setData(Uri.parse("package:" + getApplicationContext().getPackageName()));
                startActivityForResult(intent, REQUEST_ALL_FILES_ACCESS_PERMISSION);
            } else {
                requestPermission();
            }
        } else if (Build.VERSION.SDK_INT >= 23) {
            requestPermission();
        }
    }

    private void requestPermission() {
        int writePermission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
        int cameraPermission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.CAMERA);
        if (writePermission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, PERMISSIONS_STORAGE, REQUEST_EXTERNAL_STORAGE);
        } else if (cameraPermission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, PERMISSIONS_CAMERA, REQUEST_CAMERA);
        } else {
            showScannerList();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_EXTERNAL_STORAGE) {
            if (verifyPermissions(grantResults)) {
                int cameraPermission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.CAMERA);
                if (cameraPermission != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, PERMISSIONS_CAMERA, REQUEST_CAMERA);
                } else {
                    showScannerList();
                }
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                finish();
            }
        } else if (requestCode == REQUEST_CAMERA) {
            if (verifyPermissions(grantResults)) {
                showScannerList();
            } else {
                UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                finish();
            }
        }
    }

    private boolean verifyPermissions(int[] grantResults) {
        if (grantResults.length < 1) {
            return false;
        }
        for (int grantResult : grantResults) {
            if (grantResult != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    private void showScannerList() {
        final PDFScanManager pdfScanManager = PDFScanManager.instance();
        pdfScanManager.showUI(ScannerListActivity.this);
        PDFScanManager.registerManagerListener(scanManagerListener);
    }

    private final IPDFScanManagerListener scanManagerListener = new IPDFScanManagerListener() {
        @Override
        public void onDocumentAdded(int errorCode, String path) {
            FoxitPdf.onDocumentAdded(errorCode, path);
        }
    };

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_ALL_FILES_ACCESS_PERMISSION) {
            if (Build.VERSION.SDK_INT >= 30) {
                if (Environment.isExternalStorageManager()) {
                    requestPermission();
                } else {
                    UIToast.getInstance(getApplicationContext()).show("Permission Denied");
                    finish();
                }
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        getApplication().unregisterActivityLifecycleCallbacks(mLifecycleCallbacks);
    }

    private final Application.ActivityLifecycleCallbacks mLifecycleCallbacks = new Application.ActivityLifecycleCallbacks() {
        @Override
        public void onActivityCreated(@NonNull Activity activity, Bundle savedInstanceState) {
            ActManager.getInstance().setCurrentActivity(activity);
        }

        @Override
        public void onActivityStarted(@NonNull Activity activity) {
        }

        @Override
        public void onActivityResumed(@NonNull Activity activity) {
            ActManager.getInstance().setCurrentActivity(activity);
        }

        @Override
        public void onActivityPaused(@NonNull Activity activity) {
        }

        @Override
        public void onActivityStopped(@NonNull Activity activity) {
        }

        @Override
        public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {
        }

        @Override
        public void onActivityPreDestroyed(@NonNull Activity activity) {
        }

        @Override
        public void onActivityDestroyed(@NonNull Activity activity) {
            if (activity instanceof ScannerCameraActivity) {
                PDFScanManager.unregisterManagerListener(scanManagerListener);
                ScannerListActivity.this.finish();
            }
        }
    };

}
