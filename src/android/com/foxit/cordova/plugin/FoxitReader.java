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
import android.text.TextUtils;
import android.view.View;
import android.view.Window;

import com.foxit.sdk.PDFViewCtrl;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.controls.toolbar.BaseBar;
import com.foxit.uiextensions.controls.toolbar.IBarsHandler;
import com.foxit.uiextensions.controls.toolbar.ToolbarItemConfig;
import com.foxit.uiextensions.theme.DynamicColorProvider;
import com.foxit.uiextensions.theme.ThemeConfig;
import com.foxit.uiextensions.utils.AppDisplay;
import com.foxit.uiextensions.utils.AppUtil;
import com.foxit.uiextensions.utils.SystemUiHelper;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

interface IntConsumer {
    void accept(int value);
}

final class FoxitReader {
    private FoxitReader() {
    }

    private static final FoxitReader instance = new FoxitReader();

    public static FoxitReader instance() {
        return instance;
    }

    private String savePath = null;
    private int[] primaryColor;
    private int[] secondaryColor;
    private int[] tabItemSelectedColors;
    private boolean enableAnnotations = true;
    private boolean isAutoSaveDoc = false;
    private boolean isLibraryInitialized = false;
    private final Map<Integer, Boolean> bottomBarItemStatus = new HashMap<>();
    private final Map<Integer, Boolean> topBarItemStatus = new HashMap<>();
    private final Map<Integer, Boolean> toolBarItemStatus = new HashMap<>();
    private final Map<Integer, int[]> toolbarBackgroundColors = new HashMap<>();
    //
    private WeakReference<PDFViewCtrl> pdfview;

    public boolean setSavePath(String filePath) {
        this.savePath = filePath;
        if (isPDFViewCtrlReady()) {
            UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
            if (!TextUtils.isEmpty(filePath)) {
                uiExt.setSavePath(filePath);
                return true;
            }
        }
        return false;
    }

    public String getSavePath() {
        return this.savePath;
    }

    public void setEnableAnnotations(boolean enable) {
        this.enableAnnotations = enable;
        if (isPDFViewCtrlReady()) {
            UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
            uiExt.getConfig().modules.enableAnnotations(enable);
        }
    }

    public boolean getEnableAnnotations() {
        return this.enableAnnotations;
    }

    public void setBottomBarItemStatus(int item, boolean enable) {
        this.bottomBarItemStatus.put(item, enable);
        this.updateBottomToolbarItemVisible();
    }

    public boolean getBottomBarItemStatus(int item) {
        return Boolean.TRUE.equals(this.bottomBarItemStatus.get(item));
    }

    public Map<Integer, Boolean> getBottomBarItemStatus() {
        return bottomBarItemStatus;
    }

    public void setTopBarItemStatus(int item, boolean enable) {
        this.topBarItemStatus.put(item, enable);
        this.updateTopToolbarItemVisible();
    }

    public boolean getTopBarItemStatus(int item) {
        return Boolean.TRUE.equals(this.topBarItemStatus.get(item));
    }

    public Map<Integer, Boolean> getTopBarItemStatus() {
        return topBarItemStatus;
    }

    public void setToolBarItemStatus(int item, boolean enable) {
        this.toolBarItemStatus.put(item, enable);
        this.updateToolbarItemVisible();
    }

    public boolean getToolBarItemStatus(int item) {
        return Boolean.TRUE.equals(this.toolBarItemStatus.get(item));
    }

    public Map<Integer, Boolean> getToolBarItemStatus() {
        return toolBarItemStatus;
    }

    public PDFViewCtrl getPDFViewCtrl() {
        if (pdfview == null) {
            return null;
        }
        return pdfview.get();
    }

    public void setPDFViewCtrl(PDFViewCtrl pdfview) {
        this.pdfview = new WeakReference<>(pdfview);
    }

    public void release() {
        this.savePath = null;
        this.enableAnnotations = true;
        this.bottomBarItemStatus.clear();
        this.topBarItemStatus.clear();
        this.toolBarItemStatus.clear();
        this.isAutoSaveDoc = false;
        this.pdfview.clear();
    }

    public boolean isLibraryInitialized() {
        return this.isLibraryInitialized;
    }

    public void setLibraryInitialized(boolean initialized) {
        this.isLibraryInitialized = initialized;
    }

    public boolean isAutoSaveDoc() {
        return isAutoSaveDoc;
    }

    public boolean setAutoSaveDoc(boolean autoSaveDoc) {
        isAutoSaveDoc = autoSaveDoc;
        if (isPDFViewCtrlReady()) {
            UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
            uiExt.setAutoSaveDoc(autoSaveDoc);
            return true;
        }
        return false;
    }

    private void applyCustomColor(int[] customColors, IntConsumer applyColor) {
        if (!isPDFViewCtrlReady() || customColors == null || customColors.length == 0) {
            return;
        }
        UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        Activity activity = uiExt.getAttachedActivity();
        if (activity == null) {
            return;
        }

        boolean isDark = AppUtil.isDarkMode(activity);
        int color = (isDark && customColors.length > 1) ? customColors[1] : customColors[0];
        if (color != -1) {
            applyColor.accept(color);
        }
    }

    public int[] getPrimaryColor() {
        return primaryColor;
    }

    public void setPrimaryColor(int[] primaryColor) {
        this.primaryColor = primaryColor;
        this.updatePrimaryColor();
    }

    public void updateThemeColor() {
        updatePrimaryColor();
        updateSecondaryColor();
        updateTabSelectedColors();
        updateToolbarsBackgroundColor();
        updateStatusBarColor();
    }

    public void updatePrimaryColor() {
        int[] colors = FoxitReader.instance().getPrimaryColor();
        applyCustomColor(colors, new IntConsumer() {
            @Override
            public void accept(int value) {
                if (getPDFViewCtrl() == null) {
                    return;
                }
                ThemeConfig.getInstance(getPDFViewCtrl().getContext()).primaryColor(value);
            }
        });
    }

    public int[] getSecondaryColor() {
        return secondaryColor;
    }

    // Secondary
    public void setSecondaryColor(int[] secondaryColor) {
        this.secondaryColor = secondaryColor;
        updateSecondaryColor();
    }

    public void updateSecondaryColor() {
        int[] colors = FoxitReader.instance().getSecondaryColor();
        applyCustomColor(colors, new IntConsumer() {
            @Override
            public void accept(int value) {
                if (getPDFViewCtrl() == null) {
                    return;
                }
                ThemeConfig.getInstance(getPDFViewCtrl().getContext()).b2(value);
            }
        });
    }

    public void setToolbarBackgroundColor(int position, int lightColor, int darkColor) {
        this.toolbarBackgroundColors.put(position, new int[]{lightColor, darkColor});
        this.updateToolBackgroundColor(position, lightColor, darkColor);
    }

    public int[] getToolbarBackgroundColor(int position) {
        return this.toolbarBackgroundColors.get(position);
    }

    public void updateToolBackgroundColor(int position, int lightColor, int darkColor) {
        if (!isPDFViewCtrlReady()) {
            return;
        }

        UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        switch (position) {
            case 0: //top bar
                uiExt.getBarManager().setBackgroundColor(IBarsHandler.BarName.TOP_BAR, lightColor, darkColor);
                break;
            case 1:// tab tool bar
                uiExt.getBarManager().getTabActionToolbar().setBackgroundColor(lightColor, darkColor);
                break;
            case 2: // bottom bar
                uiExt.getBarManager().setBackgroundColor(IBarsHandler.BarName.BOTTOM_BAR, lightColor, darkColor);
                break;
            default:
                break;
        }
    }

    public void updateToolbarsBackgroundColor() {
        if (!isPDFViewCtrlReady()) {
            return;
        }

        for (Map.Entry<Integer, int[]> entry : toolbarBackgroundColors.entrySet()) {
            int position = entry.getKey();
            int[] colors = entry.getValue();
            if (colors == null || colors.length == 0) {
                continue;
            }
            int lightColor = colors[0];
            int darkColor = colors.length > 1 ? colors[1] : lightColor;
            this.updateToolBackgroundColor(position, lightColor, darkColor);
        }
    }

    public void updateStatusBarColor(){
        if (!isPDFViewCtrlReady()) {
            return;
        }
        UIExtensionsManager uiExt = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        Activity activity = uiExt.getAttachedActivity();
        if (activity == null) {
            return;
        }

        int[] topBarBackgroundColor = this.getToolbarBackgroundColor(0);
        boolean isDark = AppUtil.isDarkMode(activity);
        Window window = activity.getWindow();
        int statusBarColor;
        if (topBarBackgroundColor != null && topBarBackgroundColor.length > 0) {
            statusBarColor = (topBarBackgroundColor.length > 1 && isDark)
                    ? topBarBackgroundColor[1]
                    : topBarBackgroundColor[0];
        } else {
            statusBarColor = isDark
                    ? activity.getResources().getColor(com.foxit.uiextensions.R.color.ui_color_top_bar_main, null)
                    : ThemeConfig.getInstance(activity).getPrimaryColor();
        }
        SystemUiHelper.getInstance().setStatusBarColor(window, statusBarColor);
    }

    public void setTabItemSelectedColor(int lightColor, int darkColor) {
        this.tabItemSelectedColors = new int[]{lightColor, darkColor};
        this.updateTabSelectedColors();
    }

    public int[] getTabItemSelectedColors() {
        return tabItemSelectedColors;
    }

    public void updateTabSelectedColors() {
        final int[] colors = FoxitReader.instance().getTabItemSelectedColors();
        if (!isPDFViewCtrlReady() || colors == null || colors.length == 0) {
            return;
        }

        ThemeConfig.getInstance(getPDFViewCtrl().getContext()).setAccentColorProvider(new DynamicColorProvider() {
            @Override
            public int getColor(boolean isDark) {
                int lightColor = colors[0];
                int darkColor = colors.length > 1 ? colors[1] : lightColor;
                return isDark ? darkColor : lightColor;
            }
        });
    }

    public boolean isPDFViewCtrlReady() {
        PDFViewCtrl viewCtrl = FoxitReader.instance().getPDFViewCtrl();
        return viewCtrl != null && viewCtrl.getUIExtensionsManager() != null;
    }

    /**
     * @noinspection deprecation
     */
    boolean updateTopToolbarItemVisible() {
        if (!isPDFViewCtrlReady()) {
            return false;
        }

        UIExtensionsManager uiextensionsManager = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        Map<Integer, Boolean> map = this.getTopBarItemStatus();
        for (Map.Entry<Integer, Boolean> entry : map.entrySet()) {
            int tag = entry.getKey();
            int visibility = entry.getValue() ? View.VISIBLE : View.GONE;
            IBarsHandler barManager = uiextensionsManager.getBarManager();
            switch (tag) {
                case 0://back
                    barManager.setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_LT, ToolbarItemConfig.ITEM_TOPBAR_BACK, visibility);
                    break;
                case 1: //panel
                    barManager.setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_LT, ToolbarItemConfig.ITEM_TOPBAR_PANEL, visibility);
                    break;
                case 2: //thumbnail
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_THUMBNAIL, visibility);
                    break;
                case 3: //bookmark
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_BOOKMARK, visibility);
                    break;
                case 4: //search
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_SEARCH, visibility);
                    break;
                case 5: //more
                    barManager.setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_MORE, visibility);
                    break;
                default:
                    break;
            }
        }
        return true;
    }

    /**
     * @noinspection deprecation
     */
    boolean updateBottomToolbarItemVisible() {
        if (!isPDFViewCtrlReady()) {
            return false;
        }

        UIExtensionsManager uiextensionsManager = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        Map<Integer, Boolean> map = this.getBottomBarItemStatus();
        for (Map.Entry<Integer, Boolean> entry : map.entrySet()) {
            int tag = entry.getKey();
            int visibility = entry.getValue() ? View.VISIBLE : View.GONE;
            IBarsHandler barManager = uiextensionsManager.getBarManager();
            switch (tag) {
                case 0://panel
                    barManager.setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_LIST, visibility);
                    break;
                case 1: //view
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_VIEW, visibility);
                    break;
                case 2: //thumbnail
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_THUMBNAIL, visibility);
                    break;
                case 3: //bookmark
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_BOOKMARK, visibility);
                    break;
                default:
                    break;
            }
        }
        return true;
    }


    /**
     * @noinspection deprecation
     */
    boolean updateToolbarItemVisible() {
        if (!isPDFViewCtrlReady()) {
            return false;
        }

        UIExtensionsManager uiextensionsManager = (UIExtensionsManager) getPDFViewCtrl().getUIExtensionsManager();
        Map<Integer, Boolean> map = this.getToolBarItemStatus();
        for (Map.Entry<Integer, Boolean> entry : map.entrySet()) {
            int tag = entry.getKey();
            boolean visible = entry.getValue();
            switch (tag) {
                case 0://back
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_LT, ToolbarItemConfig.ITEM_TOPBAR_BACK, visible ? View.VISIBLE : View.GONE);
                    break;
                case 1: //more
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_MORE, visible ? View.VISIBLE : View.GONE);
                    break;
                case 2: //search
                    uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_SEARCH, visible ? View.VISIBLE : View.GONE);
                    break;
                case 3: //panel
                    if (AppDisplay.isPad()) {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_LT, ToolbarItemConfig.ITEM_TOPBAR_PANEL, visible ? View.VISIBLE : View.GONE);
                    } else {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_LIST, visible ? View.VISIBLE : View.GONE);
                    }
                    break;
                case 4: //view
                case 11:
                    if (AppDisplay.isPad()) {
                        if (!visible) {
                            uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_VIEW_TAB);
                        }
                    } else {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_VIEW, visible ? View.VISIBLE : View.GONE);
                    }
                    break;
                case 5: //thumbnail
                    if (AppDisplay.isPad()) {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_THUMBNAIL, visible ? View.VISIBLE : View.GONE);
                    } else {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_THUMBNAIL, visible ? View.VISIBLE : View.GONE);
                    }
                    break;
                case 6: //bookmark
                    if (AppDisplay.isPad()) {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.TOP_BAR, BaseBar.TB_Position.Position_RB, ToolbarItemConfig.ITEM_TOPBAR_BOOKMARK, visible ? View.VISIBLE : View.GONE);
                    } else {
                        uiextensionsManager.getBarManager().setVisibility(IBarsHandler.BarName.BOTTOM_BAR, BaseBar.TB_Position.Position_CENTER, ToolbarItemConfig.ITEM_BOTTOMBAR_BOOKMARK, visible ? View.VISIBLE : View.GONE);
                    }
                    break;
                case 7: //home
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_HOME_TAB);
                    }
                    break;
                case 8: //edit
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_EDIT_TAB);
                    }
                    break;
                case 9: //comment
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_COMMENT_TAB);
                    }
                    break;
                case 10: //drawing
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_DRAWING_TAB);
                    }
                    break;
                case 12: //form
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_FORM_TAB);
                    }
                    break;
                case 13: //sign
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_FILLSIGN_TAB);
                    }
                    break;
                case 14: //protect
                    if (!visible) {
                        uiextensionsManager.getMainFrame().removeTab(ToolbarItemConfig.ITEM_PROTECT_TAB);
                    }
                    break;
                default:
                    break;
            }
        }

        return true;
    }

    public void applySetting() {
        setSavePath(this.savePath);
        setAutoSaveDoc(this.isAutoSaveDoc);
        setEnableAnnotations(this.enableAnnotations);

        updateTopToolbarItemVisible();
        updateBottomToolbarItemVisible();
        updateToolbarItemVisible();
        updateThemeColor();
    }

}
