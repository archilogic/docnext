package jp.archilogic.docnext.android.setting;

import android.os.Build;
import android.provider.Settings;

public class SettingsSystemWrapper {
    public static boolean IS_SCREEN_BRIGHTNESS_MODE_SUPPORTED;
    public static String SCREEN_BRIGHTNESS_MODE;
    public static int SCREEN_BRIGHTNESS_MODE_AUTOMATIC;
    public static int SCREEN_BRIGHTNESS_MODE_MANUAL;

    static {
        try {
            if ( Build.VERSION.SDK_INT >= 8 ) {
                IS_SCREEN_BRIGHTNESS_MODE_SUPPORTED = true;

                SCREEN_BRIGHTNESS_MODE = ( String ) Settings.System.class.getField( "SCREEN_BRIGHTNESS_MODE" ).get( null );
                SCREEN_BRIGHTNESS_MODE_AUTOMATIC = ( Integer ) Settings.System.class.getField( "SCREEN_BRIGHTNESS_MODE_AUTOMATIC" ).get( null );
                SCREEN_BRIGHTNESS_MODE_MANUAL = ( Integer ) Settings.System.class.getField( "SCREEN_BRIGHTNESS_MODE_MANUAL" ).get( null );
            } else {
                IS_SCREEN_BRIGHTNESS_MODE_SUPPORTED = false;
            }
        } catch ( final SecurityException e ) {
            throw new RuntimeException( e );
        } catch ( final IllegalArgumentException e ) {
            throw new RuntimeException( e );
        } catch ( final IllegalAccessException e ) {
            throw new RuntimeException( e );
        } catch ( final NoSuchFieldException e ) {
            throw new RuntimeException( e );
        }
    }
}
