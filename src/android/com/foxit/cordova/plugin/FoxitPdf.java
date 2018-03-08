package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
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

    private final static String sn = "bgz0XjRACpxIdWe1xLZOo2gjXG1MYXxj+yPTSml903F8T7Hv6tt8xQ==";
    private final static String key = "ezJvj93HvBh39LusL0W0ja6n7P901Et7D1kNPS1MELvfNklxI+pXl0k2vWX5IVNHmA54JOed1UEqUKj1Ks56tzIN0MfkLNmKJLcoqOuqn1aQqXicX3GUqaczTFgbKwo+8T6C4A/3q+HQsd7pcO+HhCzxgJesJFWr2uCLE3sMQZdY/Xr54SsObkFs9lQeltVHy33k13/0DKAZECDkOJl8Tja4NHwOOXDGiFXRTczy50MH6V11U71jUNoCNYEj1UyqnveOVE7/xlgsCPx4QbFOX0EHzeNNVk0dpubLTT8rOkcOnxILBn6WwU+Br9r9WXz2y8oG+59+wechhquSWqx8KPPylLbPQuehVeI1dQ0hOq66PYmWGeEdNpay27KdaElYuuZa2/zaqaDHKoXbl3PSzdONw4dqq8shFNMemO6IzyB0tnh0CATRbfMHCVNanOKMCUMurepBAqwgigxxaN+U2zX6SKYXTNrPp6v223jt/6nuQnMefthXp54KGZwLsR/d40bE3AH2x+TNJ/yUc0Frz8DwpgPRuIhmxj9QZkmV4nbKFtXQ9pySpfHE00hWjyhf7C+W8A5S0U/U63sTIzJcGrWa4FPPZIai2sVhdJRgpbcGZ1nL4dqxQcAhDOckHP66QkgTtHGa+JwtSm0zUuznX8Ajdw3C7a+0octliOXmrazwAAVseXN/KbiYcw9Buld9hrI60O2yo92CYbofqLzsT5IsgW1AU3CLNsLLkYUhoRsx07XAYWtneJq9QRZMGWjLOH2cMOydEn5ISeOzKO4W+/yipgSFmZdeJUTqOrCXnWlQNdhbpKrXpiHG6ZO4exBqNByZTCsQAI+Dt/NsjdgaaOZ5h8UDTOHiDXVYzjZZScRBO0v9TBmB1E33htIH7wS0n29hijsSz1mzkW95hgemrDnVpjh/UdznfejXIV4sc7ze3IL+IAcOWuQ+ulUX5Ww4f57CiNYabi1MfquxRArTwUIGkd7iWcVq4PI0gO12CRMOgrDrox/F2hvHTfuXu1UM+saXAwbg4OY6C+ckgWa7QccmBo6MAf4VkjFuI6QzYy5aPXVErybQ0D0IZ4R2fyYzrtmrSO1wmRsBoGdnS3tNI3a9LQi2C/Sjm8UHM+uFrMEbmQRyUztmgpUE4cg4VlUhYzomlUib2Jgj0zfAjh+IWyFG0qMTyX1JwTcG30g7h6A3GAMIwX2g6+St5Q7c7cSu0/e7tNPe";

    private static int errCode = PDFException.e_errSuccess;

    public final static int result_flag = 1000;
    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        try {
            Library.init(sn, key);
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
