package jp.archilogic.docnext.android.coreview;

import android.graphics.PointF;
import android.os.Bundle;

public interface CoreView {
    void onDoubleTapGesture( PointF point );

    void onDragGesture( PointF delta );

    void onFlingGesture( PointF velocity );

    void onGestureBegin();

    void onGestureEnd();

    void onMenuVisibilityChange( boolean isMenuVisible );

    void onPause();

    void onResume();

    void onTapGesture( PointF point );

    /**
     * Invoked when pinch or spread
     */
    void onZoomGesture( float scaleDelta , PointF center );

    void restoreState( Bundle state );

    void saveState( Bundle state );

    void setDelegate( CoreViewDelegate delegate );

    void setDocId( String id );

    void setLocalDir( String localDir );
}
