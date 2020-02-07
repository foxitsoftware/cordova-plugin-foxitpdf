package com.foxit.cordova.plugin;


import android.Manifest;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;

import com.foxit.uiextensions.modules.scan.IPDFScanManagerListener;
import com.foxit.uiextensions.modules.scan.PDFScanManager;
import com.foxit.uiextensions.utils.AppTheme;
import com.foxit.uiextensions.utils.UIToast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.DialogFragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

public class ScannerListActivity extends FragmentActivity {

    private static final String SANNER_LIST_TAG = "SANNER_LIST_TAG";
    private static final int REQUEST_EXTERNAL_STORAGE = 1;
    private static final String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            int permission = ContextCompat.checkSelfPermission(this.getApplicationContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
            if (permission != PackageManager.PERMISSION_GRANTED)
                ActivityCompat.requestPermissions(this, PERMISSIONS_STORAGE, REQUEST_EXTERNAL_STORAGE);
            else
                showScannerList();
        } else {
            showScannerList();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_EXTERNAL_STORAGE) {
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
        FragmentManager fm = getSupportFragmentManager();
        DialogFragment fragment = (DialogFragment) fm.findFragmentByTag(SANNER_LIST_TAG);
        FragmentTransaction transaction = fm.beginTransaction();
        if (fragment == null) {
            fragment = PDFScanManager.createScannerFragment(new DialogInterface.OnDismissListener() {
                @Override
                public void onDismiss(DialogInterface dialog) {
                    PDFScanManager.unregisterManagerListener(scanManagerListener);
                    ScannerListActivity.this.finish();
                }
            });
        } else {
            transaction.remove(fragment);
        }
        transaction.add(fragment, SANNER_LIST_TAG);
        transaction.commitAllowingStateLoss();
        PDFScanManager.registerManagerListener(scanManagerListener);
    }

    private IPDFScanManagerListener scanManagerListener = new IPDFScanManagerListener() {
        @Override
        public void onDocumentAdded(int errorCode, String path) {
            FoxitPdf.onDocumentAdded(errorCode, path);
        }
    };

}
