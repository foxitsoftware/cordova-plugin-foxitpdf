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

    private final static String sn = "gRI5dRyuiPk58HT6aIfuei5dmn0I9FubnqBOJEHCh4aZkuf7/bok1w==";
    private final static String key = "ezKXjt8ntBh39DvoP0WUjYrU7x9qvLxeXws5NqatDyr/hXt/jGPoyb1l3WeFBAcNiG7/AHrJmdOIscZbkRZTTwB6IAwRPCQt8qy3CULwbyB9XBnIZ3kFbe9wLRG21xymRjmEL1nJSY4TewJXWCzZbs/3kaY5DGYJruvKG8MXLZFCFRWDe37FGt5+ZNOEwbhRdRsiHoVY8XY9H5hFpkmnYV3LIv78RMx/SjeI0F/As/174FCtNxsP5YTpezOS3ntDRLI4qm53KyiXsocP78rImK9xxaDir18HAqwwnDyCFLLKWqhNACkMNxO/BvzvltIL9NEgMHLUQzTlBBlZ2c7h+p3KXYEyHnZ+rOAaf2NDiPaHeF/kRRDh1t2/lmIIxNiFn5YLmhbJKC2rNmrmpGW+wpt815RhOhpicC7qDv9ogYomKthIQsm8/rkQk+HFqEry+9Mnz8mrNYhqUi8XK/wOIJ3aJJ4ik7Yx7Se0WQNF9yUjzXLwkvq3DccVLkTqjVWNCR+A4MbSjaR4JonbnuHFrclvUTlXGSkrY0/Nwmp+ennVkRbCFdfYP29fsp2pU4LhNH1sN24bEr7F1VxoVVOeamnr6dreGcP1c61O7+Hdfigt/Azni/FI9+nG2i0/I7MQT65732foqgns7BYTaDGRY71FYHEzZCIfVUtkaeoOyX1Xu2jjqNC53MOsj6rg6/btopvp3Wp6yXPaN+Mupj7ZQNGqGy0TlmlcaV4WUibqD0F0iUVK/oImN/AhOEmPfng/FOaW8nXkBo+A5C/I8etW1sJjq/d5yWStOP+sabDRuhUJvOA0ezYuqDq2u4/fBIK5utZMkStTrizQemOFCUmObYzViXTTeWn5pBs7jnDJqZTWYY8joL0c2otYNYmYXLaCQ3KsuJFEwzE3j75U3MG/6aGHHu0aRNRdOnhYUxuT1Qq3sH59Vzb1wD9GBA+fLsaqsQkP8QImnyCwyjgC/37HkBFfZO4B3HVtZyK22YFJYGxD5OpaemUSrPzmzJCx7+7sdSMJtBTneThCOHKVGF/JIz2lwhdeC2d9Ib4cVmBkHTMz8+f1W3Vw2FUkXFCYGzZZHC83Xi6901GTdkjXRrRlKnRXtzmb6btng0b1HcLnRDiX7H0jADSHfDC0jv79egJ/AQTjFsPBeqIFxw2BymNIyWpKPZUQ0W87ny7O1oZB3CZEA+fVRF++DYvby3lxz0w6wfkt9NzG";

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
