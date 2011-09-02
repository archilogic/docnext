package jp.archilogic.docnext.android.setting;

import jp.archilogic.docnext.android.util.PrefAccessor;
import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.view.Display;
import android.view.Window;
import android.view.WindowManager;

public class SettingOperator {
    private static SettingOperator _instance = null;

    public static SettingOperator get( final Context appContext ) {
        if ( _instance == null ) {
            _instance = new SettingOperator( appContext );
        }

        return _instance;
    }

    private final PrefAccessor _pref;

    private SettingOperator( final Context context ) {
        _pref = PrefAccessor.get( context );
    }

    public void apply( final Activity activity ) {
        activity.setRequestedOrientation( _pref.canRotate() ? ActivityInfo.SCREEN_ORIENTATION_SENSOR : getScreenOrientation( activity ) );

        setWindowBrightness( activity , _pref.getBrightness() );
    }

    private int getScreenOrientation( final Activity activity ) {
        final Display display = activity.getWindowManager().getDefaultDisplay();

        if ( display.getWidth() > display.getHeight() ) {
            return ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        } else {
            return ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
        }
    }

    private void setWindowBrightness( final Activity activity , final float value ) {
        final Window w = activity.getWindow();

        final WindowManager.LayoutParams lp = w.getAttributes();
        lp.screenBrightness = value;
        w.setAttributes( lp );
    }
}
