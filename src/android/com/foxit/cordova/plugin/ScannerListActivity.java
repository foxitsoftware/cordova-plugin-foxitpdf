package com.foxit.cordova.plugin;


import android.os.Bundle;

import com.foxit.scanner.R;
import com.foxit.uiextensions.modules.scan.IPDFScanManagerListener;
import com.foxit.uiextensions.modules.scan.PDFScanManager;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;

public class ScannerListActivity extends FragmentActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.fx_scanner_list_activity);

        FragmentManager fm = getSupportFragmentManager();
        Fragment fragment = fm.findFragmentById(com.foxit.uiextensions.R.id.fragmentContainer);
        if (fragment == null) {
            fragment = PDFScanManager.createScannerFragment();
            fm.beginTransaction().add(com.foxit.uiextensions.R.id.fragmentContainer, fragment).commitAllowingStateLoss();
        }

        PDFScanManager.registerManagerListener(scanManagerListener);
    }

    private IPDFScanManagerListener scanManagerListener = new IPDFScanManagerListener() {
        @Override
        public void onDocumentAdded(int errorCode, String path) {
//            if (mScanListener != null) {
//                dismissScannerList();
//                updateThumbnail(path);
//                mScanListener.onDocumentAdded(errorCode, path);
//            }
        }
    };

    @Override
    protected void onDestroy() {
        super.onDestroy();
        PDFScanManager.unregisterManagerListener(scanManagerListener);
    }

}
