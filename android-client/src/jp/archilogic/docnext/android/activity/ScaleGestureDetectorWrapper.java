package jp.archilogic.docnext.android.activity;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

import android.content.Context;
import android.os.Build;
import android.view.MotionEvent;

public class ScaleGestureDetectorWrapper {
    private OnScaleGestureWrapperListener _listener;

    private Object _delegateInstance = null;
    private Method _getFocusXMethod;
    private Method _getFocusYMethod;
    private Method _getScaleFactorMethod;
    private Method _isInProgressMethod;
    private Method _onTouchEventMethod;

    private final InvocationHandler _delegateListenerHandler = new InvocationHandler() {
        @Override
        public Object invoke( final Object proxy , final Method method , final Object[] args )
                throws Throwable {
            final String name = method.getName();

            if ( name.equals( "onScale" ) ) {
                return _listener.onScale( ScaleGestureDetectorWrapper.this );
            } else if ( name.equals( "onScaleBegin" ) ) {
                return _listener.onScaleBegin( ScaleGestureDetectorWrapper.this );
            } else if ( name.equals( "onScaleEnd" ) ) {
                _listener.onScaleEnd( ScaleGestureDetectorWrapper.this );

                return null;
            } else {
                throw new RuntimeException();
            }
        }
    };

    public ScaleGestureDetectorWrapper( final Context context ,
            final OnScaleGestureWrapperListener listener ) {
        try {
            if ( Build.VERSION.SDK_INT >= 8 ) {
                _listener = listener;

                final Class< ? > listenerClass =
                        Class.forName( "android.view.ScaleGestureDetector$OnScaleGestureListener" );
                final Object listenerProxy =
                        Proxy.newProxyInstance( getClass().getClassLoader() ,
                                new Class[] { listenerClass } , _delegateListenerHandler );

                final Class< ? > instanceClass =
                        Class.forName( "android.view.ScaleGestureDetector" );

                _delegateInstance =
                        instanceClass.getConstructor( Context.class , listenerClass ).newInstance(
                                context , listenerProxy );
                _getFocusXMethod = instanceClass.getMethod( "getFocusX" );
                _getFocusYMethod = instanceClass.getMethod( "getFocusY" );
                _getScaleFactorMethod = instanceClass.getMethod( "getScaleFactor" );
                _isInProgressMethod = instanceClass.getMethod( "isInProgress" );
                _onTouchEventMethod = instanceClass.getMethod( "onTouchEvent" , MotionEvent.class );
                
            }
        } catch ( final Exception e ) {
            throw new RuntimeException( e );
        }
    }

    public float getFocusX() {
        if ( _delegateInstance != null ) {
            try {
                return ( Float ) _getFocusXMethod.invoke( _delegateInstance );
            } catch ( final IllegalAccessException e ) {
                throw new RuntimeException( e );
            } catch ( final InvocationTargetException e ) {
                throw new RuntimeException( e );
            }
        } else {
            return 0f;
        }
    }

    public float getFocusY() {
        if ( _delegateInstance != null ) {
            try {
                return ( Float ) _getFocusYMethod.invoke( _delegateInstance );
            } catch ( final IllegalAccessException e ) {
                throw new RuntimeException( e );
            } catch ( final InvocationTargetException e ) {
                throw new RuntimeException( e );
            }
        } else {
            return 0f;
        }
    }

    public float getScaleFactor() {
        if ( _delegateInstance != null ) {
            try {
                return ( Float ) _getScaleFactorMethod.invoke( _delegateInstance );
            } catch ( final IllegalAccessException e ) {
                throw new RuntimeException( e );
            } catch ( final InvocationTargetException e ) {
                throw new RuntimeException( e );
            }
        } else {
            return 0f;
        }
    }

    public boolean isInProgress() {
        if ( _delegateInstance != null ) {
            try {
                return ( Boolean ) _isInProgressMethod.invoke( _delegateInstance );
            } catch ( final IllegalAccessException e ) {
                throw new RuntimeException( e );
            } catch ( final InvocationTargetException e ) {
                throw new RuntimeException( e );
            }
        } else {
            return false;
        }
    }

    public boolean onTouchEvent( final MotionEvent event ) {
        if ( _delegateInstance != null ) {
            try {
                return ( Boolean ) _onTouchEventMethod.invoke( _delegateInstance , event );
            } catch ( final IllegalAccessException e ) {
                throw new RuntimeException( e );
            } catch ( final InvocationTargetException e ) {
                throw new RuntimeException( e );
            }
        } else {
            return false;
        }
    }
}
