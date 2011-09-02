package jp.archilogic.docnext.android.coreview.image.facingpages;

import jp.archilogic.docnext.android.coreview.image.CubicEaseOutInterpolator;
import jp.archilogic.docnext.android.info.SizeInfo;
import android.os.SystemClock;
import android.view.animation.Interpolator;

public class CoreImageCleanupValue {
    private static final Interpolator INTERPOLATOR = new CubicEaseOutInterpolator();

    boolean isIn = false;

    CoreImageMatrix srcMat = new CoreImageMatrix();
    CoreImageMatrix dstMat = new CoreImageMatrix();

    boolean shouldAdjust;
    long start;
    long duration;

    float goal;

    public void calcDoubleTap( final float px , final float py , final CoreImageMatrix curMat , final float minScale , final float maxScale ,
            final SizeInfo surface , final float hPad , final float vPad ) {
        float dstScale;

        if ( curMat.scale < maxScale ) {
            // 1.01 for rounding
            final float delta = ( float ) Math.pow( maxScale / minScale , 1.01 / getNumberOfZoomLevel( minScale , maxScale ) );

            dstScale = Math.min( maxScale , delta * curMat.scale );
        } else {
            dstScale = minScale;
        }

        calcZoom( px , py , curMat , surface , hPad , vPad , dstScale );
    }

    public void calcFling( final float vx , final float vy , final CoreImageMatrix curMat , final SizeInfo tex , final SizeInfo screen ) {
        srcMat.copy( curMat );

        // divide by 2 is for interpolation (smoothing)
        final float dx = vx / 3;
        final float dy = vy / 3;

        dstMat.set( curMat.scale , curMat.tx + dx , curMat.ty + dy );

        shouldAdjust = true;
        start = SystemClock.elapsedRealtime();
        duration = 1000;

        final float xLimit = vx > 0 ? -curMat.tx / dx : ( screen.width - tex.width * curMat.scale - curMat.tx ) / dx;
        final float yLimit = vy > 0 ? -curMat.ty / dy : ( screen.height - tex.height * curMat.scale - curMat.ty ) / dy;

        goal = Math.min( Math.max( xLimit , yLimit ) , 1 );

        isIn = true;
    }

    public void calcLevelZoom( final CoreImageMatrix curMat , final float minScale , final float maxScale , final SizeInfo surface ,
            final float hPad , final float vPad , final int delta ) {
        // 1.01 for rounding
        final float scaleDelta = ( float ) Math.pow( maxScale / minScale , 1.01 / getNumberOfZoomLevel( minScale , maxScale ) * delta );

        final float dstScale = Math.max( minScale , Math.min( maxScale , scaleDelta * curMat.scale ) );

        calcZoom( surface.width / 2 , surface.height / 2 , curMat , surface , hPad , vPad , dstScale );
    }

    public void calcNormal( final CoreImageMatrix curMat , final float minScale , final float maxScale , final SizeInfo page ,
            final SizeInfo surface , final CoreImageCorner corner ) {
        if ( curMat.scale < minScale || curMat.scale > maxScale || curMat.tx > 0 || curMat.ty > 0
                || curMat.tx < surface.width - page.width * curMat.scale * Device.pagePerDisplay()
                || curMat.ty < surface.height - page.height * curMat.scale ) {
            if ( curMat.scale < minScale ) {
                srcMat.copy( curMat );
                dstMat.set( minScale , 0 , 0 );
            } else if ( curMat.scale > maxScale ) {
                srcMat.copy( curMat );
                dstMat.set( maxScale , ( maxScale * curMat.tx - ( maxScale - curMat.scale ) * surface.width / 2 ) / curMat.scale , ( maxScale
                        * curMat.ty - ( maxScale - curMat.scale ) * surface.height / 2 )
                        / curMat.scale );
            } else {
                srcMat.copy( curMat );

                if ( corner != null ) {
                    dstMat.set( curMat.scale , corner.getX( curMat.scale , surface , page ) , corner.getY( curMat.scale , surface , page ) );
                } else {
                    dstMat.copy( curMat );
                }

                dstMat.adjust( surface , page );
            }

            shouldAdjust = false;
            start = SystemClock.elapsedRealtime();
            duration = 200;
            goal = -1;

            isIn = true;
        } else {
            isIn = false;
        }
    }

    private void calcZoom( final float px , final float py , final CoreImageMatrix curMat , final SizeInfo surface , final float hPad ,
            final float vPad , final float dstScale ) {
        srcMat.copy( curMat );
        dstMat.set( dstScale , dstScale / curMat.scale * ( curMat.tx - ( px - hPad ) ) + surface.width / 2 , dstScale / curMat.scale
                * ( curMat.ty - ( py - vPad ) ) + surface.height / 2 );

        shouldAdjust = true;
        start = SystemClock.elapsedRealtime();
        duration = 250;
        goal = -1;

        isIn = true;
    }

    private int getNumberOfZoomLevel( final float minScale , final float maxScale ) {
        return ( int ) Math.ceil( Math.log( maxScale / minScale ) / Math.log( 2 ) );
    }

    public void update( final CoreImageMatrix curMat , final SizeInfo page , final SizeInfo surface ) {
        float elapsed = 1f * ( SystemClock.elapsedRealtime() - start ) / duration;

        boolean willFinish = false;

        if ( elapsed > 1 ) {
            elapsed = 1f;
            willFinish = true;
        }

        final float val = INTERPOLATOR.getInterpolation( elapsed );

        if ( goal > 0 && val > goal ) {
            willFinish = true;
        }

        curMat.interpolate( srcMat , dstMat , val );

        if ( shouldAdjust ) {
            curMat.adjust( surface , page );
        }

        if ( willFinish ) {
            isIn = false;
        }
    }
}
