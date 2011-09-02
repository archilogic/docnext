package jp.archilogic.docnext.android.util;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

public class PrefAccessor {
    private static final String KEY_BRIGHTNESS = "brightness";
    private static final String KEY_CAN_ROTATE = "can_rotate";

    private static PrefAccessor _instance = null;

    public static PrefAccessor get( final Context appContext ) {
        if ( _instance == null ) {
            _instance = new PrefAccessor( appContext );
        }

        return _instance;
    }

    private final Context _context;

    private PrefAccessor( final Context context ) {
        _context = context;
    }

    public boolean canRotate() {
        return p().getBoolean( KEY_CAN_ROTATE , false );
    }

    public float getBrightness() {
        return p().getFloat( KEY_BRIGHTNESS , -1 );
    }

    private SharedPreferences p() {
        return PreferenceManager.getDefaultSharedPreferences( _context );
    }

    public void reset() {
        p().edit().remove( KEY_BRIGHTNESS ).remove( KEY_CAN_ROTATE ).commit();
    }

    public void setBrightness( final float value ) {
        p().edit().putFloat( KEY_BRIGHTNESS , value ).commit();
    }

    public void setCanRotate( final boolean value ) {
        p().edit().putBoolean( KEY_CAN_ROTATE , value ).commit();
    }
}
