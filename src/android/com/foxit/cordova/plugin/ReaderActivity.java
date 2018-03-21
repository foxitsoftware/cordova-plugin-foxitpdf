package com.foxit.cordova.plugin;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.widget.RelativeLayout;
import android.support.v4.app.FragmentActivity;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.pdfreader.impl.PDFReader;
import com.foxit.sdk.pdf.PDFDoc;

import org.apache.cordova.CordovaActivity;
import org.apache.cordova.LOG;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.Charset;
import android.content.res.Configuration;
import android.view.KeyEvent;

public class ReaderActivity extends FragmentActivity {
    public PDFReader mPDFReader;

    public PDFViewCtrl pdfViewCtrl;
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        RelativeLayout relativeLayout = new RelativeLayout(this);
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);

        pdfViewCtrl = new PDFViewCtrl(this);

        relativeLayout.addView(pdfViewCtrl, params);
        relativeLayout.setWillNotDraw(false);
        relativeLayout.setBackgroundColor(Color.argb(0xff, 0xe1, 0xe1, 0xe1));
        relativeLayout.setDrawingCacheEnabled(true);
        setContentView(relativeLayout);

        String UIExtensionsConfig = "{\n" +
                "    \"defaultReader\": true,\n" +
                "    \"modules\": {\n" +
                "        \"readingbookmark\": true,\n" +
                "        \"outline\": true,\n" +
                "        \"annotations\": true,\n" +
                "        \"thumbnail\" : true,\n" +
                "        \"attachment\": true,\n" +
                "        \"signature\": true,\n" +
                "        \"search\": true,\n" +
                "        \"pageNavigation\": true,\n" +
                "        \"form\": true,\n" +
                "        \"selection\": true,\n" +
                "        \"encryption\" : true\n" +
                "    }\n" +
                "}\n";

        InputStream stream = new ByteArrayInputStream(UIExtensionsConfig.getBytes(Charset.forName("UTF-8")));
        UIExtensionsManager.Config config = new UIExtensionsManager.Config(stream);

        UIExtensionsManager uiextensionsManager = new UIExtensionsManager(this, relativeLayout, pdfViewCtrl, config);
        uiextensionsManager.setAttachedActivity(this);

        pdfViewCtrl.setUIExtensionsManager(uiextensionsManager);

        pdfViewCtrl.registerDocEventListener(docListener);
        String path = getIntent().getExtras().getString("path").replace("file://", "");
        mPDFReader = (PDFReader) uiextensionsManager.getPDFReader();
        mPDFReader.onCreate(this, pdfViewCtrl, null);
        mPDFReader.openDocument(path, null);
        setContentView(mPDFReader.getContentView());
        mPDFReader.onStart(this);

    }

    @Override
    protected void onStart() {
        super.onStart();
        if(mPDFReader == null)
            return;
        mPDFReader.onStart(this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        if(mPDFReader == null)
            return;
        mPDFReader.onPause(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if(mPDFReader == null)
            return;
        mPDFReader.onResume(this);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if(mPDFReader == null)
            return;
        mPDFReader.onStop(this);
    }

    @Override
    protected void onDestroy() {
        if(mPDFReader != null)
            mPDFReader.onDestroy(this);
        super.onDestroy();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if(mPDFReader != null)
            mPDFReader.onActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if(mPDFReader == null)
            return;
        mPDFReader.onConfigurationChanged(this, newConfig);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (mPDFReader != null && mPDFReader.onKeyDown(this, keyCode, event))
            return true;
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        if (mPDFReader != null && !mPDFReader.onPrepareOptionsMenu(this, menu))
            return false;
        return super.onPrepareOptionsMenu(menu);
    }

    PDFViewCtrl.IDocEventListener docListener = new PDFViewCtrl.IDocEventListener() {
        @Override
        public void onDocWillOpen() {
        }

        @Override
        public void onDocOpened(PDFDoc pdfDoc, int errCode) {
        }

        @Override
        public void onDocModified(PDFDoc pdfDoc) {

        }

        @Override
        public void onDocWillClose(PDFDoc pdfDoc) {
        }

        @Override
        public void onDocClosed(PDFDoc pdfDoc, int i) {
        }

        @Override
        public void onDocWillSave(PDFDoc pdfDoc) {
        }

        @Override
        public void onDocSaved(PDFDoc pdfDoc, int i) {
            Intent intent = new Intent();

            intent.putExtra("key", "info");

            setResult(RESULT_OK, intent);

            pdfViewCtrl.unregisterDocEventListener(this);

            finish();
        }


    };
}
