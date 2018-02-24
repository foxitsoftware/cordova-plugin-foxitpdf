package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.foxit.sdk.common.Library;
import com.foxit.sdk.common.PDFException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {

    private final static String sn = "bgz0XjRACpxIdWe1xLZOo2gjXG1MYXxj+yPTSml903F8T7Hv6tt8xQ==";
    private final static String key = "ezJvj93HvBh39LusL0W0ja6n7P901Et7D1kNPS1MELvfNklxI+pXl0k2vWX5IVNHmA54JOed1UEqUKj1Ks56tzIN0MfkLNmKJLcoqOuqn1aQqXicX3GUqaczTFgbKwo+8T6C4A/3q+HQsd7pcO+HhCzxgJesJFWr2uCLE3sMQZdY/Xr54SsObkFs9lQeltVHy33k13/0DKAZECDkOJl8Tja4NHwOOXDGiFXRTczy50MH6V11U71jUNoCNYEj1UyqnveOVE7/xlgsCPx4QbFOX0EHzeNNVk0dpubLTT8rOkcOnxILBn6WwU+Br9r9WXz2y8oG+59+wechhquSWqx8KPPylLbPQuehVeI1dQ0hOq66PYmWGeEdNpay27KdaElYuuZa2/zaqaDHKoXbl3PSzdONw4dqq8shFNMemO6IzyB0tnh0CATRbfMHCVNanOKMCUMurepBAqwgigxxaN+U2zX6SKYXTNrPp6v223jt/6nuQnMefthXp54KGZwLsR/d40bE3AH2x+TNJ/yUc0Frz8DwpgPRuIhmxj9QZkmV4nbKFtXQ9pySpfHE00hWjyhf7C+W8A5S0U/U63sTIzJcGrWa4FPPZIai2sVhdJRgpbcGZ1nL4dqxQcAhDOckHP66QkgTtHGa+JwtSm0zUuznX8Ajdw3C7a+0octliOXmrazwAAVseXN/KbiYcw9Buld9hrI60O2yo92CYbofqLzsT5IsgW1AU3CLNsLLkYUhoRsx07XAYWtneJq9QRZMGWjLOH2cMOydEn5ISeOzKO4W+/yipgSFmZdeJUTqOrCXnWlQNdhbpKrXpiHG6ZO4exBqNByZTCsQAI+Dt/NsjdgaaOZ5h8UDTOHiDXVYzjZZScRBO0v9TBmB1E33htIH7wS0n29hijsSz1mzkW95hgemrDnVpjh/UdznfejXIV4sc7ze3IL+IAcOWuQ+ulUX5Ww4f57CiNYabi1MfquxRArTwUIGkd7iWcVq4PI0gO12CRMOgrDrox/F2hvHTfuXu1UM+saXAwbg4OY6C+ckgWa7QccmBo6MAf4VkjFuI6QzYy5aPXVErybQ0D0IZ4R2fyYzrtmrSO1wmRsBoGdnS3tNI3a9LQi2C/Sjm8UHM+uFrMEbmQRyUztmgpUE4cg4VlUhYzomlUib2Jgj0zfAjh+IWyFG0qMTyX1JwTcG30g7h6A3GAMIwX2g6+St5Q7c7cSu0/e7tNPe";

    private static int errCode = PDFException.e_errSuccess;
    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        try {
            Library.init(sn, key);
        } catch (PDFException e) {
            errCode = e.getLastError();
            callbackContext.error("Failed to initialize Foxit library.");
            return false;
        }

        errCode = PDFException.e_errSuccess;
        callbackContext.success("Succeed to initialize Foxit library.");

        if (action.equals("init")) {

            return true;
        } else if (action.equals("Preview")){
            String filePath = args.getString(0);
            this.openDoc(filePath, callbackContext);
            return true;
        }

        return false;
    }

    private void openDoc(final String path, final CallbackContext callbackContext) {
        if (path == null || path.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return;
        }

        if (errCode != PDFException.e_errSuccess) {
            callbackContext.error("Please initialize Foxit library Firstly.");
        }

        final Context context = this.cordova.getActivity();
		final Activity activity =  this.cordova.getActivity();
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
//                RelativeLayout relativeLayout = new RelativeLayout(context);
//                RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
//                        RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
//
//				PDFViewCtrl pdfViewCtrl = new PDFViewCtrl(context);
//
//                relativeLayout.addView(pdfViewCtrl, params);
//                relativeLayout.setWillNotDraw(false);
//                relativeLayout.setBackgroundColor(Color.argb(0xff, 0xe1, 0xe1, 0xe1));
//                relativeLayout.setDrawingCacheEnabled(true);
//                setContentView(relativeLayout);
//
//				String UIExtensionsConfig = "{\n" +
//						"    \"defaultReader\": true,\n" +
//						"    \"modules\": {\n" +
//						"        \"readingbookmark\": true,\n" +
//						"        \"outline\": true,\n" +
//						"        \"annotations\": true,\n" +
//						"        \"thumbnail\" : true,\n" +
//						"        \"attachment\": true,\n" +
//						"        \"signature\": true,\n" +
//						"        \"search\": true,\n" +
//						"        \"pageNavigation\": true,\n" +
//						"        \"form\": true,\n" +
//						"        \"selection\": true,\n" +
//						"        \"encryption\" : true\n" +
//						"    }\n" +
//						"}\n";
//
//				InputStream stream = new ByteArrayInputStream(UIExtensionsConfig.getBytes(Charset.forName("UTF-8")));
//				UIExtensionsManager.Config config = new UIExtensionsManager.Config(stream);
//
//				UIExtensionsManager uiextensionsManager = new UIExtensionsManager(context, relativeLayout, pdfViewCtrl,config);
//				uiextensionsManager.setAttachedActivity(activity);
//
//				pdfViewCtrl.setUIExtensionsManager(uiextensionsManager);
//
//				PDFReader mPDFReader= (PDFReader) uiextensionsManager.getPDFReader();
//				mPDFReader.onCreate(activity, pdfViewCtrl, null);
//				mPDFReader.openDocument(path, null);
//				setContentView(mPDFReader.getContentView());
//				mPDFReader.onStart(activity);
                openDocument(path,callbackContext);
            }
        });
    }

    
//    private void setContentView(View view) {
//        this.cordova.getActivity().setContentView(view);
//    }

    private void openDocument(String file,CallbackContext callbackContext){
        Intent intent = new Intent(this.cordova.getActivity(),ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path",file);
        intent.putExtras(bundle);
        this.cordova.getActivity().startActivity(intent);
    }
}
