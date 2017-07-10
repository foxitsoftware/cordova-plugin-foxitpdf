package com.foxit.cordova.plugin;

import android.graphics.Color;
import android.os.Bundle;
import android.view.Menu;
import android.widget.RelativeLayout;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.pdfreader.impl.PDFReader;

import org.apache.cordova.CordovaActivity;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.Charset;

/**
 * <br><time>2017/7/3</time>
 *
 * @author yibin.io
 * @see
 */
public class ReaderActivity extends FragmentActivity {

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

        PDFViewCtrl pdfViewCtrl = new PDFViewCtrl(this);

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

        PDFReader mPDFReader = (PDFReader) uiextensionsManager.getPDFReader();
        mPDFReader.onCreate(this, pdfViewCtrl, null);
        mPDFReader.openDocument(getIntent().getExtras().getString("path"), null);
        setContentView(mPDFReader.getContentView());
        mPDFReader.onStart(this);
    }
}
