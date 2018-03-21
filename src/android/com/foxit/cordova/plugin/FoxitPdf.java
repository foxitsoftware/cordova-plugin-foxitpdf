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

    private final static String sn = "kodA5hXToII68+m883B0fFiOETZkUFGZRPktPMKLYpt3VOX3jVDEOQ==";
    private final static String key = "ezKXjl0mvB5z9JsXIVWofHWLDLFmKsHExK2CJLJspFCuErfD1p1vJ0xZnmDwRyUs1jyQRlzV1U0iqnxUdJ2lwzeVe+qeh7OOJbe4i+sqnwyHu0OcHnmF02U25GSP8rMoPxZcRuxFKsbG3RKkMN8+vzifQzh6xj2OHr9gudzS9xToLSvPx6C9cc+6FvzNsN1FRMjuf87bvdeXYQqSRAvPGvIalkFzTeVRoMEn5ZFtg1Mhz8f2cgwx1zOKPu8PqYoo1Z7kgBjsa/MfQ3M4y2mKzZZ3faWclFJ/t7rMYWe/J8GSb36u19dUU1SLZfZ+eJd57ukDBj4hzUsocElmOfR5LYu4r7vI9G4ux0NbjmHoWujkgfq2vl3d/Wfq91m4Kv/qyXdH7lSa6BazwlheMpok4bwR20MHjkQ9SJXkhQMGjr4LcubeBP/cBvH0HgUbjB4znm5nbeeXTREfEuh4gfyNJ+S79lYZMDeoh9yg1p6hPN7HhMVl/t5fV642fFbHts7cd/SpdNebAPG8XYQuQilIaa3/MUtVpwODI74p05yjN62UsfvfTcIyzNKSUoTwz6Afn2OfczegMCsjF3Rp5cLF/Ki8ud9S52KwcVPfIbaSOuKvFK9KAV32bmQmGoZtDmrZW5lQZFPQZVlUTpEgQpslLglVQr7NQQN02TNZ0MAAuKMTkL7MhHAJJexlZUL3tpMHzla2JiLnM+oGh9uvCJXEey75VV3r/AY04fpSJNNfyqn7sBsqcCzvYu4A7sthtyArU0noEP3tBRpR9BRAxvsi5/PDy1XTbIASPAwX94X/5dA47ZF59hYsMAQxpCKxDV83dBnUzC+LOrPuAyF5xzjqZps5Ls0I/KLaWpk1h2wS+GhHolpkpWnZvjrnqeUIeDKBquCXMhGQfVg97NEwQivJsp0xxF41UYQ2z+AXJkUNGBwbiRISrQXGegU0mNA+XxNUkcy5tSXgZpNZeQQqeiP4wjLr8inupBWt2uQKYvRac5OSBXng8RA8DzNY70BOxiV08qy3KgibNqtdtDkCc+axL6sB+LA20aWtBlFr0VTPTqcU3qx9GWsmbakFbWP/YtBDgkaRSZht6wNH6V7flKFnXLEDlcQaK4xMbylJJZqQ6//vFp199gguQMbOXHpUTlY6lhD9VFTn4jzGK4IZepVoXhutXGwcmBxbhUQuvcw1FNatboYIxlPc6hgrACjfyk56dQYt";

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
