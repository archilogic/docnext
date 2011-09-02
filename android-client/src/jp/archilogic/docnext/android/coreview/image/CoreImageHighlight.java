package jp.archilogic.docnext.android.coreview.image;

public class CoreImageHighlight {
    public enum HighlightColor {
        RED;
    }

    public float x;
    public float y;
    public float w;
    public float h;
    public HighlightColor color;

    public CoreImageHighlight( final float x , final float y , final float w , final float h , final HighlightColor color ) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.color = color;
    }
}
