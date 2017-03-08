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

    private final static String sn = "kYEZWlQ9yN/1XutuPbqTPOJkLqCS5+4I75b/SoD/CKytvBjW6q+muA==";
    private final static String key = "ezKXjm/atGhzdHouI0W0jOrQ7J1oyG55b8dIP+/ON1y1R/N2I6hZZym7thraBIt1Fcso47vZ2ehqdcUocV7+12sLvUDlLWn55zKRes8iD4KknQnMtHyAe8cQU6Uv9zMFYAYNQnh4s/TBbMMBK8GorFxxeEzGJQ8uNEYhCd8XpjMCnhOJDrNZ1unz9mgFty/7ySAo56W/xknuPY/ssIINrZcQrQ69VPwhYB1cgm+IyTocCmmaNqCS7DuWt4XVl/zOG/WQJcjfXWx65dUKyEV4fyphVK57rySd+a1XsAyK7yFnOyZCGX4kEbAxbK521Ht5kQQ9pRYjeeNKDFf2WqSDpSZhg5o34VnA6ououVY7PmPPx9QiDdySIw16SX1x7V07wfM32iHM/U9khJVlnMe8U501T2aHB9xdCBHrDv9ogYqe/D/r03R6/N80nO+uGVkBPQPS6ZzdV/lYPhP2BHiypY8oLB4i2X2AFmuOVQNFd5KjrQwgp2ize+cNPqxFGzGA0mGk2Pq7co5oNh5hWrhGyclvUTlnGeHMMZ2hHr5Ejzzmq6m39sPjU4FhmTOct1aGacifwHnl9/pggwGTG80QJ+Rsma/s+Mz1c20O+dLD/kJBFR0dN2xPsgjqpFsvxNga6hKOcazUKlnUdQj/1ogDODMCK4VMf+aHUJaihgG5PrGu9ww/e+5YLs1YurDporOy7yS2OUKpDZcULozIWc7Thb7nyeAjDlAAU0B6aGcMNgwnitrFjjuZjYBBAhaLSLZYCiaz68QY8BOheLhdBzBVusAI2t5L34FfWqs9qgnJQqhp6KSFA5tSOhHPT111miYM2R+xnAE91YnBuGOFCUmObYzVaXTTeWn5pGsj3pxyvcR3I2qoP79xKrfVvtnsCY3uJHyquJF0wz0376JU3MGf6SEFgxCJVy7I9NHdoi0aA8b/+U4hHKPhwzxGBA6fLsaKqQkP0QImHTCwwjoC/35/HBePqmzpiq4DKAnjqxZqGpvXMdqYFErMx9+tKOA39xWcrRfHHvyXb37IMIZTpEkOHB8nrToaeaTLpe6oKDh/OSrWQa7rIws92/uRMLsY9+WVaA9vcgaSLB43c0jXRrRlKnRXtzmb6btngXY+pYbYvv4CUk3nUz13LAjozHpUU6Iob6bABr0B7JtqagF49T3JX57oefX+7qjOSYj3ayqv/BZ1u6R2xt6/jAUwDQLxwadKD6dNsw==";

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
