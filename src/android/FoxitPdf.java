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

    private final static String sn = "ZMYvoWEcTaSZaPzWK06FQHMyTFYvjUJs+Vic2AlnRw54MCZuc6qxzA==";
    private final static String key = "ezKXjt0ntBhz9LvoL0WQjYra6L8MRhW2h+8oMOY2s5pWx011YwYlxvRb4F1MS0SJQxM8Y3146g2o8GWXQU8UVd4qcZVl62b0XvYl93uVypUIVB+J8DikaOXIOqdxmE7tNgw4QikFXI7zBxJXuazGaf/3YUbOJQ9uDF4hCd8X3q0FHhJZ5ml1PtsfzjKRnhHnXtI1f8m3T245tAeZ7CrKLFRq9M7HtGC4qAs710H7ogV3JTqROeIylUFieYV5+tWPJtMgefGEU79C7bacyK3qYXjrrPR1oVbxJSyQYCp+/JYHXloUNmkaqn5jR9By9MiZbTn4w0vT924BhiZ4ke0/p92zT+FC3eFhVOLRoww8AmwxDnD3diFw6BzuKQ8yFSO2yoHJyHjGuOrQGXE6Mpog7EjPhSjPRxZrXFIXfSaUPPv9xfMQmqmCtUWFSPjBUHg/8HKGeXmVqSgYlycAuY44eUV1oYTmfHzTm0pUqrNN3RyRc6fleHu7yGz7jovgu2HoEYDyIlz8u8TwDq1efrnecz4Ut2PBaf1TEAL/iK1uqZritHgwHgHUUN4EZwqEd6Zpd9MUSQanAML7WXXOYdCDn177zJlxUr5aKgC5m7qBlewW3cF8YFCP7nXi7LBT2ZztjJ8kqz5ii+a7NucnCnfZBazmsYumPfyXOksPFmVoUkV5pNGsil8/MXsVsY3p198ngYgb7NsUZuUi6xWZxcIt0dcqJtxjz59P9R4d22LV1gBArZ06eA/7WL3V8p+37CMEQYXvs0sv37r1neOXTSnWOoOu9ipijXUWJy6vvrogQsgrfxh07wNdGU4C8zJ1aTRZVhFLD6KqP2PO3OYxWk+JYtUKxDFwIKS40381PpqQ5lReiMfYXYRDwxeTT3K5IaH1Exa9/KwbKAFQNeyqff31Z9HQS05PUhOQTSqdoq4bGwp+NqdCTLvZNBp3lu/NpUBYYUnm0UtmI97/0AwNoCc8IKm/xY88w9/70nfVlqAj0I3QnqMbIARPEQkyd84Jd4DFe3YNdhHq++rHWxqG1Aq1owt0A3MT4o+rvcPMwnIW+NP2v7dXBtYNG9CbMQXqwV5Ju4TTWazmFdVfa6XvDGf7WVUmPHbGpAq4wJnZjAVEfUkd9eJqqZTrclQ3Xdb9VhcI8+pHl50fgiz3bIgB9FS+oivfE+0YwUzeCp0597KdMD7FNSIyJkFYZO3te6jRLT6qP5qc4BQ=";

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
