package jp.archilogic.docnext.android.coreview.image;

public class UnbindQueueItem {
    public int page;
    public int level;
    public int px;
    public int py;

    public UnbindQueueItem( final int page , final int level , final int px , final int py ) {
        this.page = page;
        this.level = level;
        this.px = px;
        this.py = py;
    }
}
