package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.foxit.sdk.common.Constants;
import com.foxit.sdk.common.Library;

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
    private static final String RDK_DOCSAVED_EVENT = "onDocSaved";
    private static final int result_flag = 1000;

    private static int errCode = Constants.e_ErrInvalidLicense;
    private static String mLastSn;
    private static String mLastKey;
    private static boolean isLibraryInited = false;

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        if (action.equals("initialize")) {
            JSONObject options = args.optJSONObject(0);
            String sn = options.getString("foxit_sn");
            String key = options.getString("foxit_key");

            if (isLibraryInited == false){
                errCode = Library.initialize(sn, key);
                isLibraryInited = true;
            } else if(!mLastSn.equals(sn) || !mLastKey.equals(key)){
                Library.release();
                errCode = Library.initialize(sn, key);
            }

            mLastSn = sn;
            mLastKey = key;
            switch (errCode) {
                case Constants.e_ErrSuccess:
                    return true;
                case Constants.e_ErrInvalidLicense:
                    callbackContext.error("The License is invalid!");
                    return false;
                default:
                    callbackContext.error("Failed to initialize Foxit library.");
                    return false;
            }
        } else if (action.equals("Preview") || action.equals("openDocument")) {
            if (errCode != Constants.e_ErrSuccess) {
                callbackContext.error("Please initialize Foxit library Firstly.");
                return false;
            }

            JSONObject options = args.optJSONObject(0);
            String filePath = options.getString("filePath");
            String fileSavePath = options.getString("filePathSaveTo");
            openDoc(filePath, fileSavePath, callbackContext);
            return true;
        }
        return false;
    }

    private void openDoc(String inputPath, String outPath, CallbackContext callbackContext) {
        if (inputPath == null || inputPath.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return;
        }

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                openDocument(inputPath, outPath, callbackContext);
            }
        });
    }

    private void openDocument(String inputPath, String outPath, CallbackContext callbackContext) {
        Intent intent = new Intent(this.cordova.getActivity(), ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path", inputPath);
        bundle.putString("filePathSaveTo", TextUtils.isEmpty(outPath) ? "" : outPath);
        intent.putExtras(bundle);
        this.cordova.startActivityForResult(this, intent, result_flag);
        this.cordova.setActivityResultCallback(this);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Succeed open this file");
        pluginResult.setKeepCallback(true);
        this.callbackContext.sendPluginResult(pluginResult);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (resultCode == Activity.RESULT_OK && requestCode == result_flag) {
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
