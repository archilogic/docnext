package jp.archilogic.docnext.android.coreview.image.facingpages;

import jp.archilogic.docnext.android.info.SizeInfo;

public class CoreImageMatrix {
    float scale;
    float tx;
    float ty;

    CoreImageMatrix adjust( final SizeInfo surface , final SizeInfo page ) {
        tx = Math.min( Math.max( tx , surface.width - page.width * Device.pagePerDisplay() * scale ) , 0 );
        ty = Math.min( Math.max( ty , surface.height - page.height * scale ) , 0 );

        return this;
    }

    CoreImageMatrix copy( final CoreImageMatrix that ) {
        scale = that.scale;
        tx = that.tx;
        ty = that.ty;

        return this;
    }

    private float i( final float src , final float dst , final float value ) {
        return src + ( dst - src ) * value;
    }

    CoreImageMatrix interpolate( final CoreImageMatrix src , final CoreImageMatrix dst , final float value ) {
        scale = i( src.scale , dst.scale , value );
        tx = i( src.tx , dst.tx , value );
        ty = i( src.ty , dst.ty , value );

        return this;
    }

    boolean isInPage( final SizeInfo surface , final SizeInfo page ) {
        return tx <= 0 && tx >= surface.width - page.width * Device.pagePerDisplay() * scale && ty <= 0 && ty >= surface.height - page.height * scale;
    }

    float length( final float length ) {
        return length * scale;
    }

    CoreImageMatrix set( final float scale , final float tx , final float ty ) {
        this.scale = scale;
        this.tx = tx;
        this.ty = ty;

        return this;
    }

    float x( final float x ) {
        return x * scale + tx;
    }

    float y( final float y ) {
        return y * scale + ty;
    }
}
