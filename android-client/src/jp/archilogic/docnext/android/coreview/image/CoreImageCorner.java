package jp.archilogic.docnext.android.coreview.image;

import jp.archilogic.docnext.android.info.SizeInfo;

public enum CoreImageCorner {
    TOP_LEFT , TOP_RIGHT , BOTTOM_LEFT , BOTTOM_RIGHT;

    float getX( final float scale , final SizeInfo surface , final SizeInfo page ) {
        switch ( this ) {
        case TOP_LEFT:
        case BOTTOM_LEFT:
            return 0;
        case TOP_RIGHT:
        case BOTTOM_RIGHT:
            return surface.width - page.width * scale;
        default:
            throw new RuntimeException();
        }
    }

    float getY( final float scale , final SizeInfo surface , final SizeInfo page ) {
        switch ( this ) {
        case TOP_LEFT:
        case TOP_RIGHT:
            return 0;
        case BOTTOM_LEFT:
        case BOTTOM_RIGHT:
            return surface.height - page.height * scale;
        default:
            throw new RuntimeException();
        }
    }
}
