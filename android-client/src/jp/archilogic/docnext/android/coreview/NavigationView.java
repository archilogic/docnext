package jp.archilogic.docnext.android.coreview;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import net.arnx.jsonic.JSONException;
import android.content.Context;
import android.content.Intent;
import android.graphics.PointF;
import android.os.Bundle;
import android.widget.LinearLayout;

public abstract class NavigationView extends LinearLayout implements CoreView , HasPage {
    protected CoreViewDelegate _delegate;
    protected String _id;
    protected String _localDir;
    protected int _page;

    public NavigationView( final Context context ) {
        super( context );

        setOrientation( VERTICAL );
    }

    @Override
    public int getPage() {
        return _page;
    }

    @Override
    public int getPages() {
        try {
            return Kernel.getLocalProvider().getInfo( _localDir ).pages;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
        }
        return _page;
    }

    protected void goTo( final int page ) {
        try {
            final Intent intent = new Intent();
            intent.putExtra( CoreViewActivity.EXTRA_PAGE , page );
            _delegate.backToRootView( intent );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
        }
    }

    public abstract void init();

    @Override
    public void onDoubleTapGesture( final PointF point ) {
    }

    @Override
    public void onDragGesture( final PointF delta ) {
    }

    @Override
    public void onFlingGesture( final PointF velocity ) {
    }

    @Override
    public void onGestureBegin() {
    }

    @Override
    public void onGestureEnd() {
    }

    @Override
    public void onMenuVisibilityChange( final boolean isMenuVisible ) {
    }

    @Override
    public void onPause() {
    }

    @Override
    public void onResume() {
    }

    @Override
    public void onTapGesture( final PointF point ) {
    }

    @Override
    public void onZoomGesture( final float scaleDelta , final PointF center ) {
    }

    @Override
    public void restoreState( final Bundle state ) {
    }

    @Override
    public void saveState( final Bundle state ) {
    }

    @Override
    public void setDelegate( final CoreViewDelegate delegate ) {
        _delegate = delegate;
    }

    @Override
    public void setDocId( final String id ) {
        _id = id;
    }

    @Override
    public void setLocalDir( final String localDir ) {
        _localDir = localDir;
    }

    @Override
    public void setPage( final int page ) {
        _page = page;
    }
}
