/**
 * Copyright (C) 2003-2025, Foxit Software Inc..
 * All Rights Reserved.
 * <p>
 * http://www.foxitsoftware.com
 * <p>
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */
package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Color;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.SparseArray;

import com.foxit.pdfscan.IPDFScanManagerListener;
import com.foxit.pdfscan.PDFScanManager;
import com.foxit.sdk.PDFException;
import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.common.Constants;
import com.foxit.sdk.common.Library;
import com.foxit.sdk.fdf.FDFDoc;
import com.foxit.sdk.pdf.PDFDoc;
import com.foxit.sdk.pdf.PDFPage;
import com.foxit.sdk.pdf.annots.DefaultAppearance;
import com.foxit.sdk.pdf.interform.ChoiceOption;
import com.foxit.sdk.pdf.interform.ChoiceOptionArray;
import com.foxit.sdk.pdf.interform.Control;
import com.foxit.sdk.pdf.interform.Field;
import com.foxit.sdk.pdf.interform.Form;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.utils.AppUtil;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.math.BigDecimal;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {
    private static final String SCANNER_DOCADDED_EVENT = "onDocumentAdded";
    private static final String RDK_DOCSAVED_EVENT = "onDocSaved";
    private static final String RDK_DOCWILLSAVE_EVENT = "onDocWillSave";
    private static final String RDK_DOCOPENED_EVENT = "onDocOpened";
    static final String RDK_CANCELED_EVENT = "onCanceled";
    //
    private static final int CALLBACK_FOR_PREVIEW = 0;
    private static final int CALLBACK_FOR_OPENDOC = 1;
    private static final int CALLBACK_FOR_SCANNER = 2;
    //
    private static final int READER_REQUEST_CODE = 100;
    private static final int SCANNER_REQUEST_CODE = 101;
    //
    private static int errCode = Constants.e_ErrInvalidLicense;
    private static String mLastSn;
    private static String mLastKey;
    //
    private static SparseArray<CallbackContext> mCallbackArrays = new SparseArray<>();

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "initialize": {
                JSONObject options = args.optJSONObject(0);
                String sn = options.getString("foxit_sn");
                String key = options.getString("foxit_key");

                if (!FoxitReader.instance().isLibraryInitialized()) {
                    errCode = Library.initialize(sn, key);
                    FoxitReader.instance().setLibraryInitialized(true);
                } else if (!mLastSn.equals(sn) || !mLastKey.equals(key)) {
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
            }
            case "Preview": {
                mCallbackArrays.put(CALLBACK_FOR_PREVIEW, callbackContext);
                if (errCode != Constants.e_ErrSuccess) {
                    callbackContext.error("Please initialize Foxit library Firstly.");
                    return false;
                }

                JSONObject options = args.optJSONObject(0);
                String filePath = options.getString("filePath");
                String fileSavePath = options.getString("filePathSaveTo");
                FoxitReader.instance().setSavePath(fileSavePath);
                return openDoc(filePath, null, callbackContext);
            }
            case "openDocument": {
                mCallbackArrays.put(CALLBACK_FOR_OPENDOC, callbackContext);
                if (errCode != Constants.e_ErrSuccess) {
                    callbackContext.error("Please initialize Foxit library Firstly.");
                    return false;
                }

                JSONObject options = args.optJSONObject(0);
                String filePath = options.getString("path");
                if (TextUtils.isEmpty(filePath)) {
                    callbackContext.error("Please input the correct path.");
                    return false;
                }
                filePath = getAbsolutePath(this.cordova.getActivity().getApplicationContext(), Uri.parse(filePath));
                String pw = options.getString("password");
                byte[] password = null;
                if (!TextUtils.isEmpty(pw)) {
                    password = pw.getBytes();
                }
                return openDoc(filePath, password, callbackContext);
            }
            case "setSavePath": {
                JSONObject options = args.optJSONObject(0);
                String savePath = options.getString("savePath");
                setSavePath(savePath, callbackContext);
                return true;
            }
            case "importFromFDF": {
                JSONObject options = args.optJSONObject(0);
                JSONArray pageRangeArray = options.getJSONArray("pageRange");
                int len = pageRangeArray.length();
                com.foxit.sdk.common.Range range = new com.foxit.sdk.common.Range();
                for (int i = 0; i < len; i++) {
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
            }
            case "exportToFDF": {
                JSONObject options = args.optJSONObject(0);
                JSONArray pageRangeArray = options.getJSONArray("pageRange");
                int len = pageRangeArray.length();
                com.foxit.sdk.common.Range range = new com.foxit.sdk.common.Range();
                for (int i = 0; i < len; i++) {
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
            case "enableAnnotations": {
                JSONObject options = args.optJSONObject(0);
                FoxitReader.instance().setEnableAnnotations(options.getBoolean("enable"));
                callbackContext.success();
                return true;
            }
            case "getForm":
                return getFormInfo(callbackContext);
            case "updateForm":
                JSONObject data = args.getJSONObject(0);
                JSONObject formInfo = data.getJSONObject("forminfo");
                return updateFormInfo(formInfo, callbackContext);
            case "getAllFormFields":
                return getAllFormFields(callbackContext);
            case "formValidateFieldName": {
                JSONObject obj = args.getJSONObject(0);
                int fieldType = obj.getInt("fieldType");
                String fieldName = obj.getString("fieldName");
                return validateFieldName(fieldType, fieldName, callbackContext);
            }
            case "formRenameField": {
                JSONObject obj = args.getJSONObject(0);
                int fieldIndex = obj.getInt("fieldIndex");
                String fieldName = obj.getString("newFieldName");
                return renameField(fieldIndex, fieldName, callbackContext);
            }
            case "formRemoveField": {
                JSONObject obj = args.getJSONObject(0);
                int fieldIndex = obj.getInt("fieldIndex");
                return removeField(fieldIndex, callbackContext);
            }
            case "formReset":
                return resetForm(callbackContext);
            case "formExportToXML": {
                JSONObject obj = args.getJSONObject(0);
                String filePath = obj.getString("filePath");
                return exportToXML(filePath, callbackContext);
            }
            case "formImportFromXML": {
                JSONObject obj = args.getJSONObject(0);
                String filePath = obj.getString("filePath");
                return importFromXML(filePath, callbackContext);
            }
            case "formGetPageControls": {
                JSONObject obj = args.getJSONObject(0);
                int pageIndex = obj.getInt("pageIndex");
                return getPageControls(pageIndex, callbackContext);
            }
            case "formRemoveControl": {
                JSONObject obj = args.getJSONObject(0);
                int pageIndex = obj.getInt("pageIndex");
                int controlIndex = obj.getInt("controlIndex");
                return removeControl(pageIndex, controlIndex, callbackContext);
            }
            case "formAddControl": {
                JSONObject obj = args.getJSONObject(0);
                int pageIndex = obj.getInt("pageIndex");
                String fieldName = obj.getString("fieldName");
                int fieldType = obj.getInt("fieldType");
                JSONObject json_rect = obj.getJSONObject("rect");
                float left = BigDecimal.valueOf(json_rect.getDouble("left")).floatValue();
                float top = BigDecimal.valueOf(json_rect.getDouble("top")).floatValue();
                float right = BigDecimal.valueOf(json_rect.getDouble("right")).floatValue();
                float bottom = BigDecimal.valueOf(json_rect.getDouble("bottom")).floatValue();
                com.foxit.sdk.common.fxcrt.RectF rectF = new com.foxit.sdk.common.fxcrt.RectF(left, top, right, bottom);
                return addControl(pageIndex, fieldName, fieldType, rectF, callbackContext);
            }
            case "formUpdateControl": {
                JSONObject obj = args.getJSONObject(0);
                int pageIndex = obj.getInt("pageIndex");
                int controlIndex = obj.getInt("controlIndex");
                JSONObject controlInfo = obj.getJSONObject("control");
                return updateControl(pageIndex, controlIndex, controlInfo, callbackContext);
            }
            case "getFieldByControl": {
                JSONObject obj = args.getJSONObject(0);
                int pageIndex = obj.getInt("pageIndex");
                int controlIndex = obj.getInt("controlIndex");
                return getFieldByControl(pageIndex, controlIndex, callbackContext);
            }
            case "FieldUpdateField": {
                JSONObject obj = args.getJSONObject(0);
                int fieldIndex = obj.getInt("fieldIndex");
                JSONObject fieldInfo = obj.getJSONObject("field");
                return updateField(fieldIndex, fieldInfo, callbackContext);
            }
            case "FieldReset": {
                JSONObject obj = args.getJSONObject(0);
                int fieldIndex = obj.getInt("fieldIndex");
                return resetField(fieldIndex, callbackContext);
            }
            case "getFieldControls": {
                JSONObject obj = args.getJSONObject(0);
                int fieldIndex = obj.getInt("fieldIndex");
                return getFieldControls(fieldIndex, callbackContext);
            }
            case "initializeScanner":
                if (!PDFScanManager.isInitializeScanner()) {
                    JSONObject options = args.optJSONObject(0);
                    long serial1 = options.getLong("serial1");
                    long serial2 = options.getLong("serial2");
                    PDFScanManager.initializeScanner(this.cordova.getActivity().getApplication(), serial1, serial2);
                }
                return true;
            case "initializeCompression":
                if (!PDFScanManager.isInitializeCompression()) {
                    JSONObject options = args.optJSONObject(0);
                    long serial1 = options.getLong("serial1");
                    long serial2 = options.getLong("serial2");
                    PDFScanManager.initializeCompression(this.cordova.getActivity().getApplication(), serial1, serial2);
                }
                return true;
            case "createScanner":
                if (PDFScanManager.isInitializeScanner() && PDFScanManager.isInitializeCompression()) {
                    mCallbackArrays.put(CALLBACK_FOR_SCANNER, callbackContext);
                    Intent intent = new Intent(this.cordova.getActivity(), ScannerListActivity.class);
                    this.cordova.startActivityForResult(this, intent, SCANNER_REQUEST_CODE);
                    return true;
                }
                break;
            case "setBottomToolbarItemVisible": {
                JSONObject options = args.optJSONObject(0);
                int index = options.getInt("index");
                boolean visible = options.getBoolean("visible");
                FoxitReader.instance().setBottomBarItemStatus(index, visible);
                callbackContext.success();
                return true;
            }
            case "setTopToolbarItemVisible": {
                JSONObject options = args.optJSONObject(0);
                int index = options.getInt("index");
                boolean visible = options.getBoolean("visible");
                FoxitReader.instance().setTopBarItemStatus(index, visible);
                callbackContext.success();
                return true;
            }
            case "setToolbarItemVisible": {
                JSONObject options = args.optJSONObject(0);
                int index = options.getInt("index");
                boolean visible = options.getBoolean("visible");
                FoxitReader.instance().setToolBarItemStatus(index, visible);
                callbackContext.success();
                return true;
            }
            case "setAutoSaveDoc": {
                JSONObject options = args.optJSONObject(0);
                boolean enable = options.getBoolean("enable");
                this.setAutoSaveDoc(enable, callbackContext);
                return true;
            }
            case "setToolbarBackgroundColor":{
                JSONObject options = args.optJSONObject(0);
                int position = options.getInt("position");
                int light = parseColor(options.optString("light"));
                int dark  = parseColor(options.optString("dark"));
                FoxitReader.instance().setToolbarBackgroundColor(position, light, dark);
                return true;
            }
            case "setTabItemSelectedColor":{
                JSONObject options = args.optJSONObject(0);
                int light = parseColor(options.optString("light"));
                int dark  = parseColor(options.optString("dark"));
                FoxitReader.instance().setTabItemSelectedColor(light, dark);
                return true;
            }
            case "setPrimaryColor":
            case "setSecondaryColor":
                return handleSetColor(action, args, callbackContext);
        }

        return false;
    }

    private boolean handleSetColor(String action, JSONArray args, CallbackContext callbackContext) {
        JSONObject options = args.optJSONObject(0);
        if (options == null) {
            callbackContext.error("Please input validate color.");
            return false;
        }
        int light = parseColor(options.optString("light"));
        int dark  = parseColor(options.optString("dark"));
        int[] colors = new int[]{ light, dark };

        FoxitReader reader = FoxitReader.instance();
        switch (action) {
            case "setPrimaryColor":
                reader.setPrimaryColor(colors);
                break;
            case "setSecondaryColor":
                reader.setSecondaryColor(colors);
                break;
        }
        callbackContext.success();
        return true;
    }

    private boolean openDoc(String inputPath, byte[] password, CallbackContext callbackContext) {
        if (inputPath == null || inputPath.trim().isEmpty()) {
            callbackContext.error("Please input validate path.");
            return false;
        }

        openDocument(inputPath, password, callbackContext);
        return true;
    }

    private void openDocument(String inputPath, byte[] password, CallbackContext callbackContext) {
        Intent intent = new Intent(this.cordova.getActivity(), ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path", inputPath);
        bundle.putByteArray("password", password);
        intent.putExtras(bundle);
        this.cordova.startActivityForResult(this, intent, READER_REQUEST_CODE);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Succeed open this file");
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }

    private void setSavePath(String savePath, CallbackContext callbackContext) {
        boolean ret = FoxitReader.instance().setSavePath(savePath);
        if (!ret) {
            callbackContext.error("Please open document first.");
            return;
        }
        callbackContext.success();
    }

    private void setAutoSaveDoc(boolean auto, CallbackContext callbackContext) {
        boolean ret = FoxitReader.instance().setAutoSaveDoc(auto);
        if (!ret) {
            callbackContext.error("Please open document first.");
            return;
        }
        callbackContext.success();
    }

    private boolean importFromFDF(String fdfPath, int type, com.foxit.sdk.common.Range range, CallbackContext callbackContext) {
        if (fdfPath == null || fdfPath.trim().isEmpty()) {
            callbackContext.error("Please input validate path.");
            return false;
        }

        PDFViewCtrl pdfview = FoxitReader.instance().getPDFViewCtrl();
        if (pdfview == null || pdfview.getUIExtensionsManager() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        try {
            PDFViewCtrl.lock();
            boolean success;

            if (pdfview.getDoc() != null) {
                FDFDoc fdfDoc = new FDFDoc(fdfPath);
                success = pdfview.getDoc().importFromFDF(fdfDoc, type, range);

                if (success) {
                    ((UIExtensionsManager) pdfview.getUIExtensionsManager()).getDocumentManager().setDocModified(true);
                    int pageIndex = pdfview.getCurrentPage();
                    Rect rect = new Rect(0, 0, pdfview.getPageViewWidth(pageIndex), pdfview.getPageViewHeight(pageIndex));
                    pdfview.refresh(pageIndex, rect);

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
            if (exportPath == null || exportPath.trim().isEmpty()) {
                callbackContext.error("Please input validate path.");
                return false;
            }

            PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
            if (viewCtrl == null) {
                callbackContext.error("Please open document first.");
                return false;
            }
            boolean success = false;
            PDFViewCtrl.lock();
            if (viewCtrl.getDoc() != null) {
                FDFDoc fdfDoc = new FDFDoc(fdfDocType);
                success = viewCtrl.getDoc().exportToFDF(fdfDoc, type, range);
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
        if ((resultCode == Activity.RESULT_OK || resultCode == Activity.RESULT_CANCELED)) {

            CallbackContext callbackContext = null;
            if (requestCode == SCANNER_REQUEST_CODE)
                callbackContext = mCallbackArrays.get(CALLBACK_FOR_SCANNER);
            else if (requestCode == READER_REQUEST_CODE)
                callbackContext = mCallbackArrays.get(CALLBACK_FOR_OPENDOC);

            if (callbackContext != null) {
                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", resultCode == Activity.RESULT_OK ? intent.getStringExtra("type") : RDK_CANCELED_EVENT);
                    if (resultCode == Activity.RESULT_OK) {
                        obj.put("info", intent.getStringExtra("key"));
                    }

                    PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } catch (JSONException ex) {
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
                }
            }
        }
    }

    static void onDocOpened(int errCode) {
        CallbackContext callbackContext = mCallbackArrays.get(CALLBACK_FOR_OPENDOC);
        if (callbackContext != null) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCOPENED_EVENT);
                obj.put("error", errCode);
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

    static void onDocWillSave() {
        CallbackContext callbackContext = mCallbackArrays.get(CALLBACK_FOR_OPENDOC);
        if (callbackContext != null) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCWILLSAVE_EVENT);
                PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            } catch (JSONException ex) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
            }
        }
    }

    static void onDocSave(String data) {
        CallbackContext callbackContext = mCallbackArrays.get(CALLBACK_FOR_OPENDOC);
        if (callbackContext != null) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOCSAVED_EVENT);
                obj.put("info", data);

                PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            } catch (JSONException ex) {
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
            }
        }
    }

    static void onDocumentAdded(int errorCode, String path) {
        CallbackContext callbackContext = mCallbackArrays.get(CALLBACK_FOR_SCANNER);
        if (callbackContext != null) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", SCANNER_DOCADDED_EVENT);
                obj.put("info", path);
                obj.put("error", errorCode);
                PluginResult.Status status;
                if (errorCode == IPDFScanManagerListener.e_ErrSuccess) {
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

    private String getAbsolutePath(final Context context, final Uri uri) {
        if (null == uri) return null;
        final String scheme = uri.getScheme();
        String path = null;
        if (scheme == null)
            path = uri.getPath();
        else if (ContentResolver.SCHEME_FILE.equals(scheme)) {
            path = uri.getPath();
        } else if (ContentResolver.SCHEME_CONTENT.equals(scheme)) {
            Cursor cursor = context.getContentResolver().query(uri,
                    new String[]{MediaStore.Images.ImageColumns.DATA}, null, null, null);
            if (null != cursor) {
                if (cursor.moveToFirst()) {
                    int index = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA);
                    if (index > -1) {
                        path = cursor.getString(index);
                    }
                }
                cursor.close();
            }
        }

        //if cannot get path data when sometime. We should get the path use other way.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && AppUtil.isBlank(path)) {
            if ("com.android.providers.media.documents".equals(uri.getAuthority())) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                Uri contentUri = null;
                if ("image".equals(type)) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                }

                final String selection = "_id=?";
                final String[] selectionArgs = new String[]{
                        split[1]
                };

                path = getAbsolutePath(this.cordova.getActivity(), contentUri, selection, selectionArgs);
            } else if ("com.android.providers.downloads.documents".equals(uri.getAuthority())) {
                Uri contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"),
                        Long.parseLong(DocumentsContract.getDocumentId(uri)));
                path = getAbsolutePath(this.cordova.getActivity(), contentUri, null, null);
            } else if ("com.android.externalstorage.documents".equals(uri.getAuthority())) {
                String[] split = DocumentsContract.getDocumentId(uri).split(":");
                if ("primary".equalsIgnoreCase(split[0])) {
                    path = Environment.getExternalStorageDirectory() + "/" + split[1];
                }
            }
        }
        return path;
    }

    private String getAbsolutePath(Context context, Uri uri, String selection, String[]
            selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {column};

        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }

    //For Form
    private boolean getFormInfo(CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            int alignment = form.getAlignment();
            boolean needConstructAppearances = form.needConstructAppearances();
            JSONObject obj = new JSONObject();
            obj.put("alignment", alignment);
            obj.put("needConstructAppearances", needConstructAppearances);
            DefaultAppearance da = form.getDefaultAppearance();
            JSONObject defaultApObj = new JSONObject();
            defaultApObj.put("flags", da.getFlags());
            defaultApObj.put("textColor", da.getText_color());
            defaultApObj.put("textSize", da.getText_size());
            obj.put("defaultAppearance", defaultApObj);

            PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean updateFormInfo(JSONObject formInfo, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);

            boolean isModified = false;
            if (formInfo.has("alignment")) {
                int alignment = formInfo.getInt("alignment");
                form.setAlignment(alignment);
                isModified = true;
            }

            if (formInfo.has("needConstructAppearances")) {
                boolean needConstructAppearances = formInfo.getBoolean("needConstructAppearances");
                form.setConstructAppearances(needConstructAppearances);
                isModified = true;
            }

            if (formInfo.has("defaultAppearance")) {
                JSONObject daObj = formInfo.getJSONObject("defaultAppearance");
                DefaultAppearance da = form.getDefaultAppearance();
                if (daObj.has("flags")) {
                    da.setFlags(daObj.getInt("flags"));
                    isModified = true;
                }

                if (daObj.has("textSize")) {
                    float textSize = BigDecimal.valueOf(daObj.getDouble("textSize")).floatValue();
                    da.setText_size(textSize);
                    isModified = true;
                }

                if (daObj.has("textColor")) {
                    da.setText_color(daObj.getInt("textColor"));
                    isModified = true;
                }

                form.setDefaultAppearance(da);
            }

            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(isModified);
            callbackContext.success("Succeed to update form information.");
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean getAllFormFields(CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            int fieldCount = form.getFieldCount(null);
            if (fieldCount == 0) {
                callbackContext.error("The current document does not have form fields.");
                return false;
            }
            JSONArray infos = new JSONArray();
            for (int i = 0; i < fieldCount; i++) {
                Field field = form.getField(i, null);
                int type = field.getType();
                JSONObject obj = new JSONObject();
                obj.put("fieldIndex", i);
                obj.put("fieldType", type);
                obj.put("fieldFlag", field.getFlags());
                obj.put("name", field.getName());
                obj.put("defValue", field.getDefaultValue());
                obj.put("value", field.getValue());
                obj.put("alignment", field.getAlignment());
                obj.put("alternateName", field.getAlternateName());
                obj.put("mappingName", field.getMappingName());
                obj.put("maxLength", field.getMaxLength());
                obj.put("topVisibleIndex", field.getTopVisibleIndex());
                DefaultAppearance da = field.getDefaultAppearance();
                JSONObject defaultApObj = new JSONObject();
                defaultApObj.put("flags", da.getFlags());
                defaultApObj.put("textColor", da.getText_color());
                defaultApObj.put("textSize", da.getText_size());
                obj.put("defaultAppearance", defaultApObj);

                if (type == Field.e_TypeComboBox || type == Field.e_TypeListBox) {
                    ChoiceOptionArray options = field.getOptions();
                    long optionCount = options.getSize();
                    if (optionCount > 0) {
                        JSONArray optArray = new JSONArray();
                        for (int j = 0; j < optionCount; j++) {
                            JSONObject optObj = new JSONObject();
                            ChoiceOption option = options.getAt(j);
                            optObj.put("optionValue", option.getOption_value());
                            optObj.put("optionLabel", option.getOption_label());
                            optObj.put("selected", option.getDefault_selected());
                            optObj.put("defaultSelected", option.getSelected());
                            optArray.put(optObj);
                        }
                        obj.put("choiceOptions", optArray);
                    }

                }

                infos.put(obj);
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK, infos);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean validateFieldName(int fieldType, String fieldName, CallbackContext
            callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            boolean ret = form.validateFieldName(fieldType, fieldName);
            if (ret) {
                callbackContext.success("Succeed to validate field name.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean renameField(int fieldIndex, String fieldName, CallbackContext
            callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            Field field = form.getField(fieldIndex, null);
            boolean ret = form.renameField(field, fieldName);
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(ret);
            if (ret) {
                callbackContext.success("Succeed to rename field.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean removeField(int fieldIndex, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            Field field = form.getField(fieldIndex, null);
            form.removeField(field);
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(true);
            callbackContext.success("Succeed to remove field.");
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean resetForm(CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            boolean ret = form.reset();
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(ret);
            if (ret) {
                callbackContext.success("Succeed to reset form.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean exportToXML(String filePath, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(filePath)) {
            callbackContext.error("Please input validate path.");
            return false;
        }

        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            boolean ret = form.exportToXML(filePath);
            if (ret) {
                callbackContext.success("Succeed to export form to xml.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean importFromXML(String filePath, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(filePath)) {
            callbackContext.error("Please input validate path.");
            return false;
        }

        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            boolean ret = form.importFromXML(filePath);
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(ret);
            if (ret) {
                callbackContext.success("Succeed to import form from xml.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean getPageControls(int pageIndex, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            PDFPage page = pdfDoc.getPage(pageIndex);
            if (!page.isParsed()) {
                page.startParse(PDFPage.e_ParsePageNormal, null, false);
            }
            int controlCount = form.getControlCount(page);
            if (controlCount == 0) {
                callbackContext.error("The current document does not have field controls.");
                return false;
            }
            JSONArray infos = new JSONArray();
            for (int i = 0; i < controlCount; i++) {
                Control control = form.getControl(page, i);
                JSONObject obj = new JSONObject();
                obj.put("controlIndex", i);
                obj.put("exportValue", control.getExportValue());
                obj.put("isChecked", control.isChecked());
                obj.put("isDefaultChecked", control.isDefaultChecked());
                infos.put(obj);
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK, infos);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean removeControl(int pageIndex, int controlIndex, CallbackContext
            callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            PDFPage page = pdfDoc.getPage(pageIndex);
            if (!page.isParsed()) {
                page.startParse(PDFPage.e_ParsePageNormal, null, false);
            }

            form.removeControl(form.getControl(page, controlIndex));
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(true);
            callbackContext.success("Succeed to remove the specified control.");
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean addControl(int pageIndex, String fieldName, int fieldType, com.
            foxit.sdk.common.fxcrt.RectF rectF, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            Form form = new Form(pdfDoc);
            PDFPage page = pdfDoc.getPage(pageIndex);
            if (!page.isParsed()) {
                page.startParse(PDFPage.e_ParsePageNormal, null, false);
            }

            Control control = form.addControl(page, fieldName, fieldType, rectF);
            JSONObject obj = new JSONObject();
            obj.put("controlIndex", form.getControlCount(page) - 1);
            obj.put("exportValue", control.getExportValue());
            obj.put("isChecked", control.isChecked());
            obj.put("isDefaultChecked", control.isDefaultChecked());

            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(true);
            PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean updateControl(int pageIndex, int controlIndex, JSONObject
            controlInfo, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            PDFPage page = pdfDoc.getPage(pageIndex);
            if (!page.isParsed()) {
                page.startParse(PDFPage.e_ParsePageNormal, null, false);
            }

            boolean isModified = false;
            Control control = form.getControl(page, controlIndex);
            if (controlInfo.has("exportValue")) {
                control.setExportValue(controlInfo.getString("exportValue"));
                isModified = true;
            }

            if (controlInfo.has("isChecked")) {
                control.setChecked(controlInfo.getBoolean("isChecked"));
                isModified = true;
            }

            if (controlInfo.has("isDefaultChecked")) {
                control.setDefaultChecked(controlInfo.getBoolean("isDefaultChecked"));
                isModified = true;
            }

            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(isModified);
            callbackContext.success("Succeed to update the specified control information.");
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean getFieldByControl(int pageIndex, int controlIndex, CallbackContext
            callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            PDFPage page = pdfDoc.getPage(pageIndex);
            if (!page.isParsed()) {
                page.startParse(PDFPage.e_ParsePageNormal, null, false);
            }

            Control control = form.getControl(page, controlIndex);
            Field field = control.getField();
            int type = field.getType();
            JSONObject obj = new JSONObject();
            int fieldCount = form.getFieldCount(null);
            for (int i = 0; i < fieldCount; i++) {
                Field other = form.getField(i, null);
                if (field.getDict().getObjNum() == other.getDict().getObjNum()) {
                    obj.put("fieldIndex", i);
                    break;
                }
            }
            obj.put("fieldType", type);
            obj.put("fieldFlag", field.getFlags());
            obj.put("name", field.getName());
            obj.put("defValue", field.getDefaultValue());
            obj.put("value", field.getValue());
            obj.put("alignment", field.getAlignment());
            obj.put("alternateName", field.getAlternateName());
            obj.put("mappingName", field.getMappingName());
            obj.put("maxLength", field.getMaxLength());
            obj.put("topVisibleIndex", field.getTopVisibleIndex());
            DefaultAppearance da = field.getDefaultAppearance();
            JSONObject defaultApObj = new JSONObject();
            defaultApObj.put("flags", da.getFlags());
            defaultApObj.put("textColor", da.getText_color());
            defaultApObj.put("textSize", da.getText_size());
            obj.put("defaultAppearance", defaultApObj);

            if (type == Field.e_TypeComboBox || type == Field.e_TypeListBox) {
                ChoiceOptionArray options = field.getOptions();
                long optionCount = options.getSize();
                if (optionCount > 0) {
                    JSONArray optArray = new JSONArray();
                    for (int j = 0; j < optionCount; j++) {
                        JSONObject optObj = new JSONObject();
                        ChoiceOption option = options.getAt(j);
                        optObj.put("optionValue", option.getOption_value());
                        optObj.put("optionLabel", option.getOption_label());
                        optObj.put("selected", option.getDefault_selected());
                        optObj.put("defaultSelected", option.getSelected());
                        optArray.put(optObj);
                    }
                    obj.put("choiceOptions", optArray);
                }

            }
            PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean updateField(int fieldIndex, JSONObject fieldInfo, CallbackContext
            callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            Field field = form.getField(fieldIndex, null);

            boolean isModified = false;
            if (fieldInfo.has("fieldFlag")) {
                field.setFlags(fieldInfo.getInt("fieldFlag"));
                isModified = true;
            }

            if (fieldInfo.has("defValue")) {
                field.setDefaultValue(fieldInfo.getString("defValue"));
                isModified = true;
            }

            if (fieldInfo.has("value")) {
                field.setValue(fieldInfo.getString("value"));
                isModified = true;
            }

            if (fieldInfo.has("alignment")) {
                field.setAlignment(fieldInfo.getInt("alignment"));
                isModified = true;
            }

            if (fieldInfo.has("alternateName")) {
                field.setAlternateName(fieldInfo.getString("alternateName"));
                isModified = true;
            }

            if (fieldInfo.has("mappingName")) {
                field.setMappingName(fieldInfo.getString("mappingName"));
                isModified = true;
            }

            if (fieldInfo.has("maxLength")) {
                field.setMaxLength(fieldInfo.getInt("maxLength"));
                isModified = true;
            }

            if (fieldInfo.has("topVisibleIndex")) {
                field.setTopVisibleIndex(fieldInfo.getInt("topVisibleIndex"));
                isModified = true;
            }

            if (fieldInfo.has("defaultAppearance")) {
                JSONObject daObj = fieldInfo.getJSONObject("defaultAppearance");
                DefaultAppearance da = field.getDefaultAppearance();
                if (daObj.has("flags")) {
                    da.setFlags(daObj.getInt("flags"));
                    isModified = true;
                }

                if (daObj.has("textSize")) {
                    float textSize = BigDecimal.valueOf(daObj.getDouble("textSize")).floatValue();
                    da.setText_size(textSize);
                    isModified = true;
                }

                if (daObj.has("textColor")) {
                    da.setText_color(daObj.getInt("textColor"));
                    isModified = true;
                }
                field.setDefaultAppearance(da);
            }

            if (fieldInfo.has("choiceOptions")) {
                int type = field.getType();
                if (type == Field.e_TypeListBox || type == Field.e_TypeComboBox) {
                    JSONArray jsonArray = fieldInfo.getJSONArray("choiceOptions");
                    if (jsonArray.length() > 0) {
                        ChoiceOptionArray optionArray = new ChoiceOptionArray();
                        for (int i = 0; i < jsonArray.length(); i++) {
                            ChoiceOption option = new ChoiceOption();
                            JSONObject jsonOption = jsonArray.getJSONObject(i);
                            if (jsonOption.has("optionValue")) {
                                option.setOption_value(jsonOption.getString("optionValue"));
                            }

                            if (jsonOption.has("optionLabel")) {
                                option.setOption_label(jsonOption.getString("optionLabel"));
                            }

                            if (jsonOption.has("selected")) {
                                option.setSelected(jsonOption.getBoolean("selected"));
                            }

                            if (jsonOption.has("defaultSelected")) {
                                option.setDefault_selected(jsonOption.getBoolean("defaultSelected"));
                            }

                            optionArray.add(option);
                        }
                        field.setOptions(optionArray);
                        isModified = true;
                    }
                }
            }

            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(isModified);
            callbackContext.success("Succeed to update the specified field information.");
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }

    private boolean resetField(int fieldIndex, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            Field field = form.getField(fieldIndex, null);
            boolean ret = field.reset();
            ((UIExtensionsManager) viewCtrl.getUIExtensionsManager()).getDocumentManager().setDocModified(ret);
            if (ret) {
                callbackContext.success("Succeed to reset the specified form field.");
            } else {
                callbackContext.error("Unknown error.");
            }
            return ret;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        }
        return false;
    }

    private boolean getFieldControls(int fieldIndex, CallbackContext callbackContext) {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        if (viewCtrl == null || viewCtrl.getDoc() == null) {
            callbackContext.error("Please open document first.");
            return false;
        }

        PDFDoc pdfDoc = viewCtrl.getDoc();
        try {
            if (!pdfDoc.hasForm()) {
                callbackContext.error("The current document does not have interactive form.");
                return false;
            }
            Form form = new Form(pdfDoc);
            Field field = form.getField(fieldIndex, null);
            int controlCount = field.getControlCount();
            if (controlCount == 0) {
                callbackContext.error("The specified form field does not have field controls.");
                return false;
            }
            JSONArray infos = new JSONArray();
            for (int i = 0; i < controlCount; i++) {
                Control control = field.getControl(i);
                JSONObject obj = new JSONObject();
                obj.put("controlIndex", i);
                obj.put("exportValue", control.getExportValue());
                obj.put("isChecked", control.isChecked());
                obj.put("isDefaultChecked", control.isDefaultChecked());
                infos.put(obj);
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK, infos);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } catch (PDFException e) {
            callbackContext.error(e.getMessage() + ", Error code = " + e.getLastError());
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }
        return false;
    }


    private int parseColor(String color) {
        try {
            if (TextUtils.isEmpty(color)) {
                return -1;
            }

            if (color.startsWith("#")) {
                return Color.parseColor(color);
            }

            if (color.startsWith("0x") || color.startsWith("0X")) {
                color = color.replace("0x", "#").replace("0X", "#");
                return Color.parseColor(color);
            }

            Pattern rgbPattern = Pattern.compile("rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*(\\d*\\.?\\d+))?\\)");
            Matcher matcher = rgbPattern.matcher(color);
            if (matcher.matches() && matcher.groupCount() >= 3) {
                String red = matcher.group(1);
                String green = matcher.group(2);
                String blue = matcher.group(3);
                if (red != null && green != null && blue != null) {
                    String alphaStr = matcher.group(4);
                    int alpha = alphaStr != null ? (int) (Float.parseFloat(alphaStr) * 255) : 255;
                    return Color.argb(alpha, Integer.parseInt(red), Integer.parseInt(green), Integer.parseInt(blue));
                }
            }

            int decimalColor = Integer.parseInt(color);
            if ((decimalColor & 0xFF000000) == 0) {
                decimalColor |= 0xFF000000;
            }
            return decimalColor;
        } catch (Exception e) {
            return -1;
        }
    }
}
