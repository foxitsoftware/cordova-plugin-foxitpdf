package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.foxit.sdk.common.Library;
import com.foxit.sdk.PDFException;
import com.foxit.sdk.common.Constants;

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

    private final static String sn = "or9KRYCB3GAERv8tzQpHft7o6Gaq1rfYw29VdUmGSQpo5kTQAlwiFg==";
    private final static String key = "ezJvjt8ntBh39DvoP0WQjYrNZTRmhRa4R21gOPYEOpxzh55qIaPfyL1l3WcFH/0LP582Frv4Q3Ik8cIoAG5ihbTakSztENPVS0ZPLVrrMkDfpsss322MTaeQNzjxoB9ZgXqM5lRCaVHPv8jeIEpIKTcj2iVZEpcqF+M7bPGKGsADMBC3IgdBd9graMLwfIdRmbOaop5dUeL9PVHGnRJH8vjdgN794MhwrtaF4DqKMMSZ7VakOOdt+XxVvInv2soolY7soBzoHklfmMUqLS1w8V2+YK9QE4tx5vW406NbinNEeaaoyR2cuDWnxA/5oRhjBR2KKLKjhX3/V5zC3EOU/mFhkW3lnMOfgOUUnW6ioH7vTEcEjWL1cYxVhb8ZFLFR48trtgy9UDqZwQvaQhvycttPS902iujMBrMNQpSCDiurSoqJXqvMGvMjnPy/8TPTOxo0Z4Z1ScZ1JvlnukEGHreqkAkJVsXH2s6aJtXoqLwU9wXIM6MtxsHcg/ziLvfmDn3/1lvkfvMQqSbKJz9dpcz83gzFJ/svTI891y63CrvnBJA8W3H8HMd2YpEdd/LnTqYQPPIKGyUaH/TaNWylBEq6/NxUbeYfTjbOpbqbKgv+zUq0TZE4Xk4n+9KALKzvhzqZC4DIdh2m+voPlK9dDUu2qTOU70Wj9wOL5FXmLB/cTq+zoOLZdCIoqQF85VMUOOGkaEXoJihEMNYq/vHKxKKr12LcbY+VL2u4OwDXkdEEbt9Yo0FthxU0KJNh+BiF0tKyiywWjYliu+l/Nau3euhZ8FCKWLqKJdk8iSIeVOPRHNV+pVKc2x3WjdLyYwHrpLjpxqGxjHS1Wiz89hOHMRLfBJwVcSMFg1d1T//xlNIwXAHNl1bsmV4Kx44AFxosH7zPwsTFPF6qTs6MXwI1AD1zZT6tOv6xu3A7yo0CkWKZUfveLTz8xexjisBw6LbWEDDVfiESla00BEbClXjpOUnY7AUqAHqxP8y69zrPLhfGvpzhomS0Q0Q4M4aWQ4ZXV+HhPA3dM+OF/7pwcbCptoraN3RC8sAoC/tO6v8u/Jb2v5/79YzVMpXKI0QCl7Kx8jwLJvod3/jXivalfEQoJPp3ZboT77fGAXKylErdo12u2kleHxsy/tehmToIdmp77wNvuyEa88WO5m3Kemm9C584SEkUH0XhjcBlKaPuzmQfq2Mp3oVH746yM7BYP/cDaPbSR2QMmTKjdk578ijF2JLu/gSMGF6cTUnQxU6JF00d/Q==";

    private static int errCode = Constants.e_ErrSuccess;


    public final static int result_flag = 1000;
    public String filePathSaveTo;
    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        errCode = Library.initialize(sn, key);
        switch (errCode) {
            case Constants.e_ErrSuccess:
                break ;
            case Constants.e_ErrInvalidLicense:
                callbackContext.error("The License is invalid!");
                return false;
            default:
                callbackContext.error("Failed to initialize Foxit library.");
                return false;
        }

        errCode = Constants.e_ErrSuccess;
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

        if (errCode != Constants.e_ErrSuccess) {
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
