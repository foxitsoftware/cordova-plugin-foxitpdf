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

    private final static String sn = "MvD5a4qu0ec8nuKMaSZdrqjrANCqd3YQEwOqlrTCgUO5i7/lQNpJbg==";
    private final static String key = "ezKXjl0mvB5z9JsXIVWofHdLDOkEiYekSxjqXg/HjXLfSwtHlN9kezVMTo7lWfm1RW1WwA4TRMUtXhjqK/55exaTe4PaQkb+nqMd/Pw8yvg6ZNmXPTCkKbAAIB99Ezq12TutSF1ksYuCPSM31cQfJjrcY2IDYKop+aFnIS5uquP56fYZeduEsyCOFHCZi0ihT+H4a3CDgHgPvcBApA1MdgyM80sWm+A/tn3+IfbujVHf0UAIbLbTujDRPaOiAKzD8ciBliNCXslfXLMjTkpLPM+JlKRRb7DUTHpsX0Nv1cqfLaJ39GUe4ev9NVDkntBU0qgJ2A72OhO8v6sf9NMcStXGsAU6Zq1JmULZj2GAlARjLCg2IPdigW5Aizn6dbJPXLdw1wmDalq72ZTS6nXYVE3wLuqHjKEjuOVfOXryYCCJXY1gP3ZUU1ELaCQRIBVCh6K2ZV4XIthA31EogV25Xgr4cssap3/kp5gzJxCigQR+Z6tVB3nGKJj6mNgM8wLdKSB6pKQ5NlcJ975U6iwqTg8k5QTwkOFd7cCbZvjvU2rcGGbPEWz6E+ltkl6klBgQ38TOTxi1J1+0fy5/QxQTeaAUBtdfPPFejbxbklFDd50x8Ij5GZv7f8Xofan8SHOUturY6Z9e4pE0sM0Z5w1yGIC60H1EYyZDWp9ust23wFJPnKRYdwO35lWhCWs34IPf2tcNT1enmtBUL9cHOnB2yIRA+VEhSWFqCYxLfmYDuxiQOcnwdtZfFW95H0keckrddCQTRb/niqGPgoZiG91+jZYDont1H0Ku9S9XJtLBF+jK+ncG462plkzd2ICqkIVZmQpebKV8sbdeflWPBQA9dw72Fn1TyRKZA9PR29tOo8kk9qdgsnNtNv+aIWGZyqvr0+Xr6OnqGtG4MCCAz8vxlcbhAvuaYRACpEOAcCdLAPkdr/HmQHK1dP4YZGzMzBGLmqPMxmqfAp40oPzC5ewZi2XnwjFGBQTlREQ4iJb0tUMffAsggpVrFuxSkxlCTnOUVy6XoZYyILAn8EFel3QVVz/xEjhON7K68NakHzmQbQOXs0xrkaIZJCQJKrZJtBUXkNn94Hx3JDTad301ebpsPY7mtS7gKRG8rq8SHXuw8GJglHTcvIocbA/RN5vQ5hLpB2DdrnRjxMFyycXCsYGUbfdPHihFZvn5+TwaCa/rEW+GyISQp0xSyyIiHkjN3W6Wfgb9";

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
