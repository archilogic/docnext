package jp.archilogic.docnext.android.coreview.image;

import android.view.animation.Interpolator;

public class CubicEaseOutInterpolator implements Interpolator {
    @Override
    public float getInterpolation( final float value ) {
        return ( float ) ( 1f - Math.pow( 1f - value , 3f ) );
    }
}
