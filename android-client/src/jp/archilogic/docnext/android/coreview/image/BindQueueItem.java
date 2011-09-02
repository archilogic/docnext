package jp.archilogic.docnext.android.coreview.image;

import android.graphics.Bitmap;

public class BindQueueItem {
    public int page;
    public int level;
    public int px;
    public int py;
    public boolean isWebp;
    public Bitmap bitmap;
    public int pointer;

    public BindQueueItem( final int page , final int level , final int px , final int py , final Bitmap bitmap ) {
        this.page = page;
        this.level = level;
        this.px = px;
        this.py = py;
        this.bitmap = bitmap;
        isWebp = false;
    }

    public BindQueueItem( final int page , final int level , final int px , final int py , final int pointer ) {
        this.page = page;
        this.level = level;
        this.px = px;
        this.py = py;
        this.pointer = pointer;
        isWebp = true;
    }
}
