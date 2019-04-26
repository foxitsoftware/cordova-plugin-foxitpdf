package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Rect;
import android.os.Bundle;
import android.text.TextUtils;

import com.foxit.sdk.PDFException;
import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.common.Constants;
import com.foxit.sdk.common.Library;
import com.foxit.sdk.fdf.FDFDoc;
import com.foxit.uiextensions.UIExtensionsManager;

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
    private static final String RDK_DOCWILLSAVE_EVENT = "onDocWillSave";
    private static final String RDK_DOCOPENED_EVENT = "onDocOpened";
    private static final int result_flag = 1000;

    private static int errCode = Constants.e_ErrInvalidLicense;
    private static String mLastSn;
    private static String mLastKey;
    private static boolean isLibraryInited = false;

    private static CallbackContext callbackContext;
    private String mSavePath = null;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
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
                    callbackContext.success();
                    return true;
                case Constants.e_ErrInvalidLicense:
                    callbackContext.error("The License is invalid!");
                    return false;
                default:
                    callbackContext.error("Failed to initialize Foxit library.");
                    return false;
            }
        } else if (action.equals("Preview")) {
            this.callbackContext = callbackContext;
            if (errCode != Constants.e_ErrSuccess) {
                callbackContext.error("Please initialize Foxit library Firstly.");
                return false;
            }

            JSONObject options = args.optJSONObject(0);
            String filePath = options.getString("filePath");
            String fileSavePath = options.getString("filePathSaveTo");
            return openDoc(filePath, null, fileSavePath, callbackContext);
        } else if (action.equals("openDocument")) {
            this.callbackContext = callbackContext;
            if (errCode != Constants.e_ErrSuccess) {
                callbackContext.error("Please initialize Foxit library Firstly.");
                return false;
            }

            JSONObject options = args.optJSONObject(0);
            String filePath = options.getString("path");
            String pw = options.getString("password");
            byte[] password = null;
            if (!TextUtils.isEmpty(pw)) {
                password = pw.getBytes();
            }
            return openDoc(filePath, password, mSavePath, callbackContext);
        } else if (action.equals("setSavePath")) {
            JSONObject options = args.optJSONObject(0);
            String savePath = options.getString("savePath");
            setSavePath(savePath, callbackContext);
            return true;
        } else if (action.equals("importFromFDF")) {
            JSONObject options = args.optJSONObject(0);
            JSONArray pageRangeArray = options.getJSONArray("pageRange");
            int len = pageRangeArray.length();
            com.foxit.sdk.common.Range range = new com.foxit.sdk.common.Range();
            for (int i = 0; i < len; i ++) {
                JSONArray array = pageRangeArray.getJSONArray(i);
                if (array.length() != 2) {
                    callbackContext.error("Please input right page range.");
                    return false;
                }
                range.addSegment(array.getInt(0), array.getInt(0) + array.getInt(1) - 1, com.foxit.sdk.common.Range.e_All);
            }

            String fdfPath = options.getString("fdfPath");
            int type = options.getInt("dataType");
            return importFromFDF(fdfPath, type, range, callbackContext);
        } else if (action.equals("exportToFDF")) {
            JSONObject options = args.optJSONObject(0);
            JSONArray pageRangeArray = options.getJSONArray("pageRange");
            int len = pageRangeArray.length();
            com.foxit.sdk.common.Range range = new com.foxit.sdk.common.Range();
            for (int i = 0; i < len; i ++) {
                JSONArray array = pageRangeArray.getJSONArray(i);
                if (array.length() != 2) {
                    callbackContext.error("Please input right page range.");
                    return false;
                }
                range.addSegment(array.getInt(0), array.getInt(0) + array.getInt(1) - 1, com.foxit.sdk.common.Range.e_All);
            }

            int fdfDocType = options.getInt("fdfDocType");
            int type = options.getInt("dataType");
            String exportPath = options.getString("exportPath");

            return exportToFDF(fdfDocType, type, range, exportPath, callbackContext);
        }
        return false;
    }

    private boolean openDoc(String inputPath, byte[]password, String outPath, CallbackContext callbackContext) {
        if (inputPath == null || inputPath.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return false;
        }

//        this.cordova.getActivity().runOnUiThread(new Runnable() {
//            @Override
//            public void run() {
                openDocument(inputPath, password, outPath, callbackContext);
//            }
//        });
        return true;
    }

    private void openDocument(String inputPath, byte[] password, String outPath, CallbackContext callbackContext) {
        Intent intent = new Intent(this.cordova.getActivity(), ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path", inputPath);
        bundle.putByteArray("password", password);
        bundle.putString("filePathSaveTo", TextUtils.isEmpty(outPath) ? "" : outPath);
        intent.putExtras(bundle);
        this.cordova.startActivityForResult(this, intent, result_flag);
//        this.cordova.setActivityResultCallback(this);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Succeed open this file");
        pluginResult.setKeepCallback(true);
        this.callbackContext.sendPluginResult(pluginResult);
    }

    private boolean setSavePath(String savePath, CallbackContext callbackContext) {
        if (ReaderActivity.pdfViewCtrl == null || ReaderActivity.pdfViewCtrl.getUIExtensionsManager() == null) {
            mSavePath = savePath;
            return false;
        }

        if (!TextUtils.isEmpty(savePath)) {
            ((UIExtensionsManager) ReaderActivity.pdfViewCtrl.getUIExtensionsManager()).setSavePath(savePath);
        }
        callbackContext.success();
        return true;
    }

    private boolean importFromFDF(String fdfPath, int type, com.foxit.sdk.common.Range range, CallbackContext callbackContext) {
        if (fdfPath == null || fdfPath.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return false;
        }

        if (ReaderActivity.pdfViewCtrl == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        try {
            PDFViewCtrl.lock();
            boolean success = false;
            if (ReaderActivity.pdfViewCtrl.getDoc() != null) {
                FDFDoc fdfDoc = new FDFDoc(fdfPath);
                success = ReaderActivity.pdfViewCtrl.getDoc().importFromFDF(fdfDoc, type, range);

                if (success) {
                    ((UIExtensionsManager) ReaderActivity.pdfViewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(true);
                    int[] pages = ReaderActivity.pdfViewCtrl.getVisiblePages();
                    for (int i = 0; i < pages.length; i++) {
                        Rect rect = new Rect(0, 0, ReaderActivity.pdfViewCtrl.getPageViewWidth(i), ReaderActivity.pdfViewCtrl.getPageViewHeight(i));
                        ReaderActivity.pdfViewCtrl.refresh(i, rect);
                    }
                    callbackContext.success();
                    return true;
                }
            }
            callbackContext.error("Unknown error");
        } catch (PDFException e) {
            callbackContext.error(e.getMessage());
        } finally {
            PDFViewCtrl.unlock();
        }
        return false;
    }

    private boolean exportToFDF(int fdfDocType, int type, com.foxit.sdk.common.Range range, String exportPath, CallbackContext callbackContext) {
        try {
            if (exportPath == null || exportPath.trim().length() < 1) {
                callbackContext.error("Please input validate path.");
                return false;
            }
            if (ReaderActivity.pdfViewCtrl == null) {
                callbackContext.error("Please open document first.");
                return false;
            }
            boolean success = false;
            PDFViewCtrl.lock();
            if (ReaderActivity.pdfViewCtrl.getDoc() != null) {
                FDFDoc fdfDoc = new FDFDoc(fdfDocType);
                success = ReaderActivity.pdfViewCtrl.getDoc().exportToFDF(fdfDoc, type, range);
                if (success) {
                    success = fdfDoc.saveAs(exportPath);
                }
            }
            if (success) {
                callbackContext.success();
            } else {
                callbackContext.error("Unknown error");
            }
        } catch (PDFException e) {
            callbackContext.error(e.getMessage());
            return false;
        } finally {
            PDFViewCtrl.unlock();
        }
        return true;
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
//                    if (!true) {
//                        callbackContext = null;
//                    }
                }
            } catch (JSONException ex) {
//                Log.e("JSONException", "URI passed in has caused a JSON error.");
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
            }
        }
    }

    public static void onDocOpened(int errCode) {
        if (callbackContext != null) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCOPENED_EVENT);
                obj.put("errorCode", errCode);
                PluginResult.Status status;
                if (errCode == 0) {
                    status = PluginResult.Status.OK;
                } else {
                    status = PluginResult.Status.ERROR;
                }
                PluginResult result = new PluginResult(status, obj);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            } catch (JSONException e) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
            }
        }
    }

    public static void onDocWillSave() {
        try {
            if (callbackContext != null) {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCWILLSAVE_EVENT);
                PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            }
        } catch (JSONException ex) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
    }

}
