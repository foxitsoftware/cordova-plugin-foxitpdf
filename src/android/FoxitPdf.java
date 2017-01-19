package FoxitPdf;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.widget.RelativeLayout;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.common.Library;
import com.foxit.sdk.common.PDFException;
import com.foxit.uiextensions.UIExtensionsManager;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {

    private final static String sn = "N/AX7ZuQjab0Cxf7MQ3P7VLnZCVs6aerDQKl70LhvXsTIlEbPxq76g==";
    private final static String key = "ezJvj83HvWp3NEt5JFl9RotbDgaOTdD414oOK2PgSZ7FjlX+D+tHZ4kSbhEjv3/HHVfZTiWtieJvJiQn5Pxe12FGM03bperbsMqtepvCJ0qHs0McHXqAWTeg7jK5qJI445fmxooqD6tTklCQot5UGsvXfUd8p29t3dBAIa84+o1R4QwnLf6ASOHpnf+j6sSBvzlU6yV4hYEwZzZBPGjMEG2jICe/Crsgl84UNJnvgLtf+qb0hbm2goWeCcdYxSkeSQ0eccgdVFJdNTXneWh0jZ7EXhyxoaoye/bru3gn5EuHaQZKcSLYBzZsuIp3OMnPyNK3hqvCg5KKGDif3koDrRCb/i3Lfy8+TINyF7Wp2XPjKHHVckNXjSxA29HNJy+Tmvc5n6mrtQA5XSNoaxUSOr8N5K5GIWi1urrJhgL/PmrGPUEQPESPPN8Au8DlEa36AMAo9GmRfFlsSbrK4FbJ6vgLP3+tpz6zQxh7iiGjyj2cOWD6vEQI07BU2mzQ/qZzZVXJVh5lFneyJkxBYHPO3Pxlc8XOiUbRo2NbP0xMLVL+oC+RmIv9cJMaP7iSn/46RsLL2CvNNsjWbk7bmzqYvztJ8BKqXeJtPhmyVYC6lPupA+v6/IaqM5f02V4wbiV3vuLHQE7Ws4wgF5sgMWku+v4Ecn0aoy35YYOLfD/L1HbRO3/9P/HHAtEfMTNY5KPEminLEkGLWRDHzO6R27Bbt+c4nQ1RzeF1Tet/m5+GPsjSjMKYA24DUXO3cZmgZrG1Czm4lPIzS/lW1fbWbDGNrITxN+qLOz/0spQxUR04sa9C1D/G7uF39U7JYXj5GHWgJ+GHyKOIvQr2VJnDKPBp73xoQvYgpGHe7ZwrlO5pUE2YPL1PU2UKxyoZTdyPaHjQ8HIUIgCg4+VlzKNmKA1+7ydyXbcyIczrTOf0ieOHgLTZsdbB7IavMphXAPxTGYJHVyd+QJNxhkr0WnxCjN0Seh1gozzy1V16A+VUjYLf3o1w1hzqPaYOk/L1UtXy5HNlFaUPncvXQ9c1vPU33AJWQ8kVxy5WOY2C2HsmCYT37hGWFwNDz9Voc0BWkwsIr7mz4zYAa9j47wzvBQWnUnOuIjdhApStaSwC7BGA8V2WLbBDos4xNDtDU1umUEu518lPY/NKOQpE0DAL9wcyXyUKJuzj3Zwgq2rqGv9uTvxhDMry7Flv/B+oNdkT+tVxgeokgQWwI2sr5Q==";

    private static int errCode = PDFException.e_errSuccess;
    private PDFViewCtrl pdfViewCtrl = null;
    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        this.init(callbackContext);
        if (action.equals("init")) {

            return true;
        } else if (action.equals("Preview")){
            String filePath = args.getString(0);
            this.openDoc(filePath, callbackContext);
            return true;
        }

        return false;
    }

    private void init(CallbackContext callbackContext) {
        try {
            Library.init(sn, key);
        } catch (PDFException e) {
            errCode = e.getLastError();
            callbackContext.error("Failed to initialize Foxit library.");
        }

        errCode = PDFException.e_errSuccess;
        callbackContext.error("Succeed to initialize Foxit library.");
    }

    private void openDoc(final String path, CallbackContext callbackContext) {
        if (path == null || path.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return;
        }

        if (errCode != PDFException.e_errSuccess) {
            callbackContext.error("Please initialize Foxit library Firstly.");
        }

        final Context context = this.cordova.getActivity();
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                RelativeLayout relativeLayout = new RelativeLayout(context);
                RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                        RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);

                pdfViewCtrl = new PDFViewCtrl(context);

                relativeLayout.addView(pdfViewCtrl, params);
                relativeLayout.setWillNotDraw(false);
                relativeLayout.setBackgroundColor(Color.argb(0xff, 0xe1, 0xe1, 0xe1));
                relativeLayout.setDrawingCacheEnabled(true);
                setContentView(relativeLayout);

                UIExtensionsManager uiExtensionsManager = new UIExtensionsManager(context,
                        relativeLayout, pdfViewCtrl);

                pdfViewCtrl.setUIExtensionsManager(uiExtensionsManager);

                pdfViewCtrl.openDoc(path, null);
            }
        });

//        callbackContext.success("Open document success.");
    }

    private void setContentView(View view) {
        this.cordova.getActivity().setContentView(view);
    }
}
