package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.foxit.sdk.common.Library;
import com.foxit.sdk.common.PDFException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {
    private CallbackContext callbackContext;
    private static final String RDK_DOCSAVED_EVENT = "onDocSaved";

    private final static String sn = "k/pGvr6A5W7HQWbJhLNllH+Y71xCg0LH2tkLICIvZ7+sCLiFk3WseQ==";
    private final static String key = "ezJvj93HtBp39Js1IV0+hME/742j8lpbzmNKK0O5R57SklEhj6V071lEehrSXOCbbYXY8ub700pPF38haJYh4dfrT6jlVqIvZV7K90iIRQuX3zMc/HiFfa+A2jb+ZRkqGlsJtsTzOga3BUYy24tKQghN0tIUKAxL2NjGAAFYvj+yfo4kibvyHVJIvjbn2cVIOTUbq1BYK8+YJ4iA6GMuKwtrj76ee3qjdz9lULG9Y/5ZKX/dI0AJ+vYUsriRKkkwv07OePJ3eWaPRn+X/BlVo/YExpgHK6gCez7r++fAjNMifvptexGMdvuXKcPv9futrsQbLx2TGbefFULvJr7pVuR+aSUt9Q7hacAIOAESUcxmFGQD6p7KMUN12Zf+b2A1wAj4H23ypN/Cfz/RsINBs/DbS217Hf0a2b9RI9NsATC/G5EY7XpOZ9Qqm8SU/WdGMtqxUI0GeHidpyH5Z5Pvs0ZokIObiW7R08gObVFgM4OFYYWdnvrZ1DLo2ccR00jP/Cm+KWqByRQ4vLAu0ctzASN3LpqZikn7Ywo06bpF9lGE75r9SJI6Eol75ZsBmybmm1tQSGGZWQYRDCPp6jcYzfpw8eYqSpBEoYuQ/5DUJau90afnE38L1485E4xrBfYAyKFX6F6OvMX3RIPhtRLbf2rgOkCS1++3jFHQ1OQD1UhbDtPfsD9nNPWkye9EHRRTRRjMztQYVAaeq0K3hIA6TrUykM0RLXQSpCmsR36UXsTeAbHKE0gw1lZxt8r/SPiKGok+B43Yrt3ei6y5/OvjfyYwLfnLxCk0+k2vVAbqRYiiXbJ0lNneOQzSLWeC409+aFY3Rb63XiWEKELNnVO4YdunQgS5DO85gIxnJ0ic+r0gqxpTyra2Xu8XNM2vw2TwRciDTfCd29Q9hjH2udBNVhbqUq3M0W0vRYP5cjMMYIelpzdf2zAFSIuLPoLBhrWPXwlFNnsYUX62SNsOBQTeox3aCmOuZoArRxaJ98nVsHfBqYmgLSZhWR3BA7McmKfy1BxoQaH7yoeX9SrH7VfmaBAs5jD5NMwQR2jYxqLdMBfAq1JfXoi6Ryqhu1Vg77sQBgAqZMAUz+YhUFcq4m1m+BIlrapjVTfTtJ9qAGQEGkXxIx6JsO5fEV3a1uwnVST0Tn/G+U9Td4STAP6CsmN4haabmieq/gL8ldcvGSYFTjclx3E=";

    private static int errCode = PDFException.e_errSuccess;

    public final static int result_flag = 1000;
    public String filePathSaveTo;
    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        try {
            Library.initialize(sn, key);
        } catch (PDFException e) {
            errCode = e.getLastError();
            callbackContext.error("Failed to initialize Foxit library.");
            return false;
        }

        errCode = PDFException.e_errSuccess;
//        callbackContext.success("Succeed to initialize Foxit library.");

        if (action.equals("init")) {

            return true;
        } else if (action.equals("Preview")){
            JSONObject options = args.optJSONObject(0);
            String filePath = options.getString("filePath");

            filePathSaveTo = options.getString("filePathSaveTo");
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
        final Activity activity = this.cordova.getActivity();
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                openDocument(path, callbackContext);
            }
        });
    }

    private void openDocument(String file,CallbackContext callbackContext){
        Intent intent = new Intent(this.cordova.getActivity(),ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path",file);
        bundle.putString("filePathSaveTo", TextUtils.isEmpty(filePathSaveTo) ? "" : filePathSaveTo);

        intent.putExtras(bundle);
        //this.cordova.getActivity().startActivity(intent);
        this.cordova.startActivityForResult(this,intent,result_flag);
        this.cordova.setActivityResultCallback(this);

//        callbackContext.success("Succeed open this file");

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK,"Succeed open this file");
        pluginResult.setKeepCallback(true);
        this.callbackContext.sendPluginResult(pluginResult);

    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (resultCode == Activity.RESULT_OK && requestCode == result_flag){
            String returnedData = intent.getStringExtra("key");

            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCSAVED_EVENT);
                obj.put("info", returnedData);

                if (callbackContext != null) {
                    PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                    if (!true) {
                        callbackContext = null;
                    }
                }


            } catch (JSONException ex) {
                Log.e("JSONException", "URI passed in has caused a JSON error.");
            }
        }
    }
}
