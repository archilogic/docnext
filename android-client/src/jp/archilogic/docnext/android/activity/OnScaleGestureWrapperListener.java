package jp.archilogic.docnext.android.activity;

public interface OnScaleGestureWrapperListener {
    boolean onScale( final ScaleGestureDetectorWrapper detector );

    boolean onScaleBegin( final ScaleGestureDetectorWrapper detector );

    void onScaleEnd( final ScaleGestureDetectorWrapper detector );
}
