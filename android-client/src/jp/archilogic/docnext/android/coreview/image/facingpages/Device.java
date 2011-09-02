package jp.archilogic.docnext.android.coreview.image.facingpages;

import android.content.Context;

public class Device {
    static enum Rotation {
        PORTRAIT , LANDSCAPE
    };

    static CoreImageState state;
    static int width = 0;
    static int height = 0;

    public static int getPageHelper() {
        if ( isTablet() && isLandscape() ) {
            return 2;
        } else {
            return 1;
        }
    }

    static Rotation getRotation() {
        if ( width < height ) {
            return Rotation.PORTRAIT;
        } else {
            return Rotation.LANDSCAPE;
        }
    }

    public static void init( final Context context ) {
        width = context.getResources().getDisplayMetrics().widthPixels;
        height = context.getResources().getDisplayMetrics().heightPixels;
    }

    public static boolean isLandscape() {
        if ( getRotation() == Rotation.LANDSCAPE ) {
            return true;
        } else {
            return false;
        }
    }

    public static boolean isSmartphone() {
        final int size = Math.max( width , height );

        if ( size < 1024 ) {
            return true;
        } else {
            return false;
        }
    }

    public static boolean isTablet() {
        return !isSmartphone();
    }

    public static int pagePerDisplay() {
        if ( state != null ) {
            return pagePerDisplay( state.page );
        }

        return getPageHelper();
    }

    public static int pagePerDisplay( final int page ) {
        if ( state.direction == CoreImageDirection.R2L && !state.facingFirstPages.contains( page - 1 ) ) {
            return 1;
        } else if ( state.direction == CoreImageDirection.L2R && !state.facingFirstPages.contains( page ) ) {
            return 1;
        }

        return getPageHelper();
    }

    public static void setState( final CoreImageState state2 ) {
        state = state2;
    }
}
