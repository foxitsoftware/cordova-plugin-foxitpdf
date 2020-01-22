package com.foxit.cordova.plugin;


import android.content.DialogInterface;
import android.os.Bundle;

import com.foxit.scanner.R;
import com.foxit.uiextensions.modules.scan.IPDFScanManagerListener;
import com.foxit.uiextensions.modules.scan.PDFScanManager;
import com.foxit.uiextensions.utils.AppTheme;

import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;

public class ScannerListActivity extends FragmentActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppTheme.setThemeFullScreen(this);
        setContentView(R.layout.fx_scanner_list_activity);

        FragmentManager fm = getSupportFragmentManager();
        Fragment fragment = fm.findFragmentById(com.foxit.uiextensions.R.id.fragmentContainer);
        if (fragment == null) {
            fragment = PDFScanManager.createScannerFragment(new DialogInterface.OnDismissListener() {
                @Override
                public void onDismiss(DialogInterface dialog) {
                    ScannerListActivity.this.finish();
                }
            });
            fm.beginTransaction().add(com.foxit.uiextensions.R.id.fragmentContainer, fragment).commitAllowingStateLoss();
        }
        PDFScanManager.registerManagerListener(scanManagerListener);
    }

    private IPDFScanManagerListener scanManagerListener = new IPDFScanManagerListener() {
        @Override
        public void onDocumentAdded(int errorCode, String path) {
            FoxitPdf.onDocumentAdded(errorCode, path);
        }
    };

    @Override
    protected void onDestroy() {
        super.onDestroy();
        PDFScanManager.unregisterManagerListener(scanManagerListener);
    }

}
