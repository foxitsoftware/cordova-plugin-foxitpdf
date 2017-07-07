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

    private final static String sn = "nU4V+cyy5M+IG3djLjKCTZFiXwUdERkohg+6MB1+pm+BDxbMNIPN2g==";
    private final static String key = "ezJvjl3GtG539PsXZqXcIkmEbhuio9ACWf3giDepTwvhp7njD2b+w6Nd/Rr0cOkBP+scVC59Exkp+IOxgP2w42MKnVbnQ/xNfre4UGyTt40QX92XO1hUaeeYALnFXN7tLRqSCt2G6ETeAPGa74kwS4RBgpSdjACC/b9AsdzS9xjqRProhtG98l8Zks4smHGpJB8wC0R6jLWVgZjBOxqTQoRcy47k26HtttlfLh1LkvyD+LgQphwhMR2H5sQzcCbLE3Jzf3HTy/My/44Tm5ql0Ky9RLW2OLK91ryIJOT3yXeepxEgzu260UhAxCRdmNAtaqxk9su+PTbujlYhOX4ZiKXVQfXXA6ZASbVFkDvFOzphoqIfG3M+aWIIaIipdvsMww44peyWg9rqSiu0hZsmzZkQqJhzi90eTTTRxa+/KSaqNnrQl107g9kqiiuYdO6MCgdI+qrsqO66fS08M8fRJ+d5Y89Y/wdydAZwHkmrXBTMx6pt/BgUmvUvIRabH7xyiSOhyPeDfh3uaIcXje4PfXIQS+XzntkUTKhbLcVK3OoKFmPrG/ox8kv2P+3P2Ojju240Lxg6FtPe+Ze2ZYFvDJQ7pzsx+nAA0bzDmq+nPY/sMNHuQwfkb+1oc3OscGPpO4sXvxhmx1cutnT4gNs51Q7eZJiKbnEUymZLVSFk2m+2Y/3cFU4PdrQHSYoi+OBsqcQ8Ve4kWzPO6KFqVJgrRtw9W52Hb7fElbFp9Po4pYEiT+e6HZ4ZSF8m8odCV9W5oy8vVQAVhCULtcaci6yZxh7oMT+jDII5XvqLIYF0eI3FD3Dl1tW+fh7b+Pg2hJrK1lpGgLyknaUuqLWjYpXjVekMkUenBF7OkZ/Cg4y74JOXanzoA71P+qAfHoZes1FPa60NAF20Db6IFMLKrqLiVCmgbpwp2Ko4deHPSNE1CgCZd8P2HLRDvU7yYQVXOz3DgsL5rW23cHuoMnYeWC5ujFl4imEUfjCOutRZwDJvIa0SubCwfBJJO0v2+HEbSTBpw+XtXJ6JJEAsI1pVsP8Op9TFmrznN6BeyY2DPB3KF3Wp3428h274GJSBXzwPJjvspMS/g2pT0LIYb3KfHCW9qDCLjmgn6rgbLxgT8ZjABJqLQsI36QP2ikQPaztDRh56/7vIgurfFpkchWCjhl7mSmt2HgeGzAm/mpEFK5qNbbUn2jn6h2vhGrOAfCRJKxpTeBhlgHMe1EU/FlgzzYHqA4rpfMPN8jko6F2i6SiSCQ==";

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
