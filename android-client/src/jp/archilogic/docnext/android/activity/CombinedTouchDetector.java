package jp.archilogic.docnext.android.activity;

import android.content.Context;
import android.view.GestureDetector;
import android.view.GestureDetector.OnDoubleTapListener;
import android.view.GestureDetector.OnGestureListener;
import android.view.MotionEvent;

public class CombinedTouchDetector {
    public interface OnCombinedTouchListener {
        void onDoubleTap( float pointX , float pointY );

        void onFling( float velocityX , float velocityY );

        void onLongPress();

        void onScale( float scaleFactor , float focusX , float focusY );

        void onScroll( float distanceX , float distanceY );

        void onSingleTap( float pointX , float pointY );

        void onTouchBegin();

        void onTouchEnd();
    }

    private final OnCombinedTouchListener _listener;

    private final GestureDetector _gestureDetector;
    private final ScaleGestureDetectorWrapper _scaleGestureDetector;

    private boolean _isJustAfterScale = false;

    private final OnGestureListener _gestureListener = new OnGestureListener() {
        @Override
        public boolean onDown( final MotionEvent e ) {
            return false;
        }

        @Override
        public boolean onFling( final MotionEvent e1 , final MotionEvent e2 , final float velocityX , final float velocityY ) {
            if ( _isJustAfterScale ) {
                _isJustAfterScale = false;
            } else {
                _listener.onFling( velocityX , velocityY );
            }

            return true;
        }

        @Override
        public void onLongPress( final MotionEvent e ) {
            if ( !_scaleGestureDetector.isInProgress() ) {
                _listener.onLongPress();
            }
        }

        @Override
        public boolean onScroll( final MotionEvent e1 , final MotionEvent e2 , final float distanceX , final float distanceY ) {
            if ( _isJustAfterScale ) {
                _isJustAfterScale = false;
            } else {
                _listener.onScroll( distanceX , distanceY );
            }

            return true;
        }

        @Override
        public void onShowPress( final MotionEvent e ) {
        }

        @Override
        public boolean onSingleTapUp( final MotionEvent e ) {
            return false;
        }
    };

    private final OnDoubleTapListener _doubleTapListener = new OnDoubleTapListener() {
        @Override
        public boolean onDoubleTap( final MotionEvent e ) {
            if ( _isJustAfterScale ) {
                _isJustAfterScale = false;
            } else {
                // hack for this method called before ACTION_UP (actually invoked by ACTION_DOWN)
                _listener.onTouchEnd();
                _listener.onDoubleTap( e.getX() , e.getY() );
            }

            return true;
        }

        @Override
        public boolean onDoubleTapEvent( final MotionEvent e ) {
            return false;
        }

        @Override
        public boolean onSingleTapConfirmed( final MotionEvent e ) {
            if ( _isJustAfterScale ) {
                _isJustAfterScale = false;
            } else {
                // hack for this method called before ACTION_UP (actually invoked by ACTION_DOWN)
                _listener.onTouchEnd();
                _listener.onSingleTap( e.getX() , e.getY() );
            }

            return true;
        }
    };

    private final OnScaleGestureWrapperListener _scaleGestureListener = new OnScaleGestureWrapperListener() {
        @Override
        public boolean onScale( final ScaleGestureDetectorWrapper detector ) {
            _listener.onScale( detector.getScaleFactor() , detector.getFocusX() , detector.getFocusY() );

            return true;
        }

        @Override
        public boolean onScaleBegin( final ScaleGestureDetectorWrapper detector ) {
            return true;
        }

        @Override
        public void onScaleEnd( final ScaleGestureDetectorWrapper detector ) {
            _isJustAfterScale = true;
        }
    };

    public CombinedTouchDetector( final Context context , final OnCombinedTouchListener listener ) {
        _listener = listener;

        _scaleGestureDetector = new ScaleGestureDetectorWrapper( context , _scaleGestureListener );
        _gestureDetector = new GestureDetector( context , _gestureListener );
        _gestureDetector.setOnDoubleTapListener( _doubleTapListener );
    }

    private int getPointerCount( final MotionEvent event ) {
        try {
            return ( Integer ) MotionEvent.class.getMethod( "getPointerCount" ).invoke( event );
        } catch ( final Exception e ) {
            return 1;
        }
    }

    public boolean onTouchEvent( final MotionEvent event ) {
        switch ( event.getAction() ) {
        case MotionEvent.ACTION_DOWN:
            _listener.onTouchBegin();
            break;
        case MotionEvent.ACTION_UP:
            _listener.onTouchEnd();
            break;
        }

        if ( _scaleGestureDetector.isInProgress() ) {
            // workaround by https://code.google.com/p/android/issues/detail?id=12976

            if ( getPointerCount( event ) > 1 ) {
                _scaleGestureDetector.onTouchEvent( event );
            }
        } else {
            if ( getPointerCount( event ) > 1 ) {
                _scaleGestureDetector.onTouchEvent( event );
            }

            _gestureDetector.onTouchEvent( event );
        }

        return true;
    }
}
