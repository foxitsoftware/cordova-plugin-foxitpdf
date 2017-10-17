package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.foxit.sdk.common.Library;
import com.foxit.sdk.common.PDFException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {

    private final static String sn = "Ljs06YddedKXpyZ7qymbkAe1EFe1jstVhjZXa5aXvrPPzGF3l36HHQ==";
    private final static String key = "ezJvj90ntBhz9LvoL0WQjY7NL4K81WvxfWfgcutRsppWR4/JzmaDxKzphJp0Qh8ydhGQUB7Fm/B/Uoc+/etFj3VvOgh+85PS/TSEHVVoS40YW96WOlgUaeac4DrlXHVNg528UOumzHxeH/GY510NHROP3ZJljR6C/d9AsdzSJx/qRPpoidG99h8Jkk4sqPFGhK0Fy0V4jtUrzyjDhR/303bOyI6k26PtttlfLg1Lsvyf+LgQE99mryKDjWrX64cU+dnub5ShxwMqvV/CTlY3Zj2fPSXR02xW1MJ8DKRlVeqURxCihfdX2BfPyQ+a0nwKgy6E8vFwD2yMVaT/BRJMSOel+C6CHadKZOyXILn+kvZum4pfY6OGuV3Ialvd7LPXNN2yW79kHDKheHoWbvmT/t9sdjwEqIXpnxVI4LUzLsPbeJtXTZBsjXyXpoX4I0lsIO+fGoa8N5SQS5RILd7cCFYLLzTkfKSpHXwWtmV8efpcW+JlCS9KzF5UhfDfv4dhdKCq35lrUdxg8TYSjh3xHNQz1OcpsKdHsOm83GvNwUY+O942u32f50i17g6AOCPpthZCli1B3qwoGQQMnOYTcATzbzODRXEape2j50uJybrpuSrSPa0hReSfHM3C9ndA7PdPzkHF5aHxmyKh9RNRgBbegdbnuBkzBkP1WzDxGmbRIjlF4sjvc2PhAnXMSQOea6N4fsurKAsH//KFpKzb7uJGF+Fi+F59qyR/iRDe1LiPHkrz8d9oTZsBj9tB8YXCzMcioNAR4ABLKdMMr5rSCgZMYc/AbZViLBvMMg3hVnaDFItcEVBH2pq3Y79J4e/1zPmnxsovsxyqaOTXdslQMtcgKIL5Jl17EvlA9FzjKemrUOzeOFZjF+i9WXs5H40ZPcKM/dsy2FNGVCTHiqzoIYumgfPSMYKCKWzby8vNiWU+nFXV8QrQB8v8DYv69Sm7k5uqb70G6l2Q2+yrlgntCeNM+JQDGkt3BEVAt22AuyfW6oNXYh/h9M20STvpu2pP8VidkhakFCk1uoWz8WVn79jMn5lzClbdfj0k1E3ZulClT/PdrmbmPuIjg8XwnKTfpUHyT9UhHVwdKRhPqisb4sXU8zEK4QTDjnkL8OOY7PD0885xDFySR3GG9ooBt4goUSRiM4oN6npPb/y8CN+X4VHThT2rNXOERw0TNj8Ho47pL5XZEbNoULTrk5gLCS9lDwNO3qE5B1DyiLW+qqH7S3NA";

    private static int errCode = PDFException.e_errSuccess;
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

    private void openDoc(final String path, final CallbackContext callbackContext) {
        if (path == null || path.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return;
        }

        if (errCode != PDFException.e_errSuccess) {
            callbackContext.error("Please initialize Foxit library Firstly.");
        }

        final Context context = this.cordova.getActivity();
		final Activity activity =  this.cordova.getActivity();
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
//                RelativeLayout relativeLayout = new RelativeLayout(context);
//                RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
//                        RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
//
//				PDFViewCtrl pdfViewCtrl = new PDFViewCtrl(context);
//
//                relativeLayout.addView(pdfViewCtrl, params);
//                relativeLayout.setWillNotDraw(false);
//                relativeLayout.setBackgroundColor(Color.argb(0xff, 0xe1, 0xe1, 0xe1));
//                relativeLayout.setDrawingCacheEnabled(true);
//                setContentView(relativeLayout);
//
//				String UIExtensionsConfig = "{\n" +
//						"    \"defaultReader\": true,\n" +
//						"    \"modules\": {\n" +
//						"        \"readingbookmark\": true,\n" +
//						"        \"outline\": true,\n" +
//						"        \"annotations\": true,\n" +
//						"        \"thumbnail\" : true,\n" +
//						"        \"attachment\": true,\n" +
//						"        \"signature\": true,\n" +
//						"        \"search\": true,\n" +
//						"        \"pageNavigation\": true,\n" +
//						"        \"form\": true,\n" +
//						"        \"selection\": true,\n" +
//						"        \"encryption\" : true\n" +
//						"    }\n" +
//						"}\n";
//
//				InputStream stream = new ByteArrayInputStream(UIExtensionsConfig.getBytes(Charset.forName("UTF-8")));
//				UIExtensionsManager.Config config = new UIExtensionsManager.Config(stream);
//
//				UIExtensionsManager uiextensionsManager = new UIExtensionsManager(context, relativeLayout, pdfViewCtrl,config);
//				uiextensionsManager.setAttachedActivity(activity);
//
//				pdfViewCtrl.setUIExtensionsManager(uiextensionsManager);
//
//				PDFReader mPDFReader= (PDFReader) uiextensionsManager.getPDFReader();
//				mPDFReader.onCreate(activity, pdfViewCtrl, null);
//				mPDFReader.openDocument(path, null);
//				setContentView(mPDFReader.getContentView());
//				mPDFReader.onStart(activity);
                openDocument(path,callbackContext);
            }
        });
    }

    
//    private void setContentView(View view) {
//        this.cordova.getActivity().setContentView(view);
//    }

    private void openDocument(String file,CallbackContext callbackContext){
        Intent intent = new Intent(this.cordova.getActivity(),ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path",file);
        intent.putExtras(bundle);
        this.cordova.getActivity().startActivity(intent);
    }
}
