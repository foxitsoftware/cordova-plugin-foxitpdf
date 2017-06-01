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

    private final static String sn = "Xzz20N1dgWxJmz0seWOP54wqzhSKaLTXEje18SSUlZF9DVfYrMvyWQ==";
    private final static String key = "ezKXjt8ntBh39DvoP0WQjYrUrx9qvbxe38QoPVU5LSr/hXt/7xBt01lwdEe+GX1++LZWB6cDWuVs8xYEMRYmjtpTRWVw62b0XvYl93uVSpW4apyWClgUaea8M3ySf8fMjjbmdBHnl5rEw9VPQUZ2jK40naM9DGVpsufKG8MXEV5B1eBiDrNZ1dVz9mgCjy/7ySAo56W/xkgcTI/s4IINvZUOZcqitBHZy409+sR5BmLMd/koMDrf2TmcHDNEcO/j2u5gBGedgX3Re4e6J3sae3nrrPR1obbyJSyQYCp+/JYHXFoUNkkaqn5jR9By9MiZbTn4w0vT927BhSZ4ke0/J96zTwEjweHl1eLRK6+VFilEcYI1DTLSeHV7CnZUgVOI/+TvACcrRKCT2qNZdslyilu5qZDdVWJwHjoY1BMgQkdfGEsWWNgTQjCeicjUFYHh2ujskos+DeQ0TiTpSRKb3ol/7Q18heWYgnMJfeV5ldFTq9kN1+XeashPsSsf8Yf+vHV4UYXJF96y8gj0IvycGUxquG1GHsAnD9YxPP27c5kEn6rKwGnq0ai5Uf/klffe4Fm+Rq7Pp3YE+gNHwFvNsIpKE9uZFwwIPLY5iJ6clQQBLqgforbeYqwkEWP+oxjutfD0YuYHEj5wbrAm2qtotyRMvYC+Lt3UGB2XscPiB79hnGWuF6vHQf+K7lMUiwgXzeiesyHK1x+6HYS4lnVcTU+0D5h6BfO2REQg1U6naA6CO8xWg/UgFdjj3aBB2WriwwgcIaN5rQtFjRvl3oJ5F8RwUtL3PK5St6LpBU6YVCMTGwDraVd8yi0n5JsezPm8A118PyzvEmlyf6G6HRFWS5PrNEkU4BmXJWVzLUANBP7uTpTzRSrWdvwD2ZU2hhVIkTRIgDY1EprylUq9M9UXH7wRvAfK7XrHag8up0ciswM7Dr3NbN7f3uCT2SndAi0+19my5Go4YEzOhMvPAsLhhTNnEyOQKk99Z1m33QF5Zule5OKNpz9B+cbwp8G+3jilSsyekPP6/LlOn2+dY3v0PfcytJR7xnOgpX24qFnQNs6WVygqcws5sV1Qvh0yeyPvZ5dFd1jN6obBMUa7qw6LYcY6V323en1qcYYY+YrYvv4CUk3nWIR5LA/qDXtUU6Iobwa3yNWUiAAYLQquSuJn7ilxyUmqTeKKynz0nLKwaa8WbV1mJq9geqYjhAvU3ymuMfvq4N0=";

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
