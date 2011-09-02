package jp.archilogic.docnext.android.coreview;

public interface HasPage {
    String BROADCAST_PAGE_CHANGED = HasPage.class.getName() + ".page.changed";
    
    String BROADCAST_EXTRA_PAGE =  HasPage.class.getName() + ".extra.changed";

    int getPage();

    int getPages();

    void setPage( int page );
}
