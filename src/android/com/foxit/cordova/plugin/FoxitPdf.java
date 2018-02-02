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

    private final static String sn = "aDNKDiqm639Z6RqqBazD6rJ3vxkm10zmBVjI06KM/B6bDumXrvGGKg==";
    private final static String key = "ezJvj93HtGhz9LvoL0WQjY6n7q2DskrbykNKI0MicbTltpNxCSRq01lkum771xm7FU5HIH1Y7tkt96WmUUxWWbbz3DJUlfS0Zl+6yWiJuLLzCzdx3DiGbddA1Ls2GIJlGxzw71jx/kk04SCEJN01e1QmkdKCoioOZ3Ic0FWJqSdaBaNyQPPPjzwS6q/2wqb7iJwAsuloQgesJRzGuMhFEMxrZENO7OXARDChZKZ05s0kR+YIXb/hRoFmqK53cq8nAGrcLUKlhwjJfqpNQ8yklgozymeFIH6PMhHIi2ndBtFEG7dxB0totxK7b+PMZO5ws6o/kL0jdd1r8PHoc5Z13goHyzLENxUjnvd7Wu4NISj0C9361GgVPaddyAIUWt0Gmlo1AHy6vWXxvw6Gq467tA+TKX8Bj4Qjk6AZBr99tuA/MP+PCEYWNMN7WBfUYJ1d9ZqrRWE7gZB/uQe2Zz3Za78TekGuNcTa9DCvgWRk6hv7TJDhLwx18OcliKIFYTYhFHJne/NjYTuYa0HRd83leL/jiidwNqAWORVmMT2Nnx6wwXpdtamRq1GTy7PSt3F/wHyusNQnLj7pYdbvhaVLnuueKLM6XceKiyctJet4eO3VsXd627ObLdCc9MMfYq3enKRnV28dLj+/paV59c9mlg1U2UKIV+L3pjxVKAd8V4Y3GdtV+ITRMYLKzuS6a7rbX8Tt5XY6wygAovuc77Ne7rc8W8R2bfiLjTWtkcYBtJllXTPkLx6js9I/8P4ifqx4mJatw3r1Y4Ehhcl6g+KbTDGVhyKOox1VzSRq1Y1AJD5FDX/WZWOUurQEf95jxFbhrBtLD5tU4lGqwJT8vav/PBdHOJc/Fnr4lRFZTxa0cD1/WGEf1Yi5ypvoWH0TRY4bnlct3vzn2vn+CMy7FdFF9a8gHwOQf2Xq4IKYeRENHdBiSW2Z16anU21I6iONRXpzdPYxKJ8RDOfNPakiSYiFAsucRMynliZBe5DSOQ5cIq3BWcbXiZkllTiN/TUfKvhDKzHRlo7W45mPp+kKwqKuArQL+XC4PaJHtJxQgc9aqJksw1okB6qVrqAcOf2bRGYH8SZgWDikbh3JoRD2O6HhK1Mzgy6/FT87dndannoYhd52C0Dl+DcXrW7aIzpzxg5GSD91hRfg9/m8ZCt6D8jNFammIe7FNIxUNYNeZpnYODqQ2r8C/3pCynyr+2/ZoIqsIeZRBrMLmWkcITxG8WTqbg==";

    private static int errCode = PDFException.e_errSuccess;
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
