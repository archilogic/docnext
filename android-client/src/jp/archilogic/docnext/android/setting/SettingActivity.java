package jp.archilogic.docnext.android.setting;

import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.util.PrefAccessor;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;

public class SettingActivity extends Activity {
    private static final float MIN_BRIGHTNESS = 0.1f;
    private static final float MAX_BRIGHTNESS = 1.0f;

    private CheckBox _automaticBrightnessCheckBox;
    private LinearLayout _brightnessLayout;
    private SeekBar _brightnessSeekBar;
    private CheckBox _canRotateCheckBox;
    private Button _resetButton;

    private PrefAccessor _pref;
    private final SettingActivity _self = this;

    private final OnCheckedChangeListener _automaticBrightnessCheckBoxCheckedChange = new OnCheckedChangeListener() {
        @Override
        public void onCheckedChanged( final CompoundButton buttonView , final boolean isChecked ) {
            applyBrightnessMode( isChecked );
        }
    };

    private final OnSeekBarChangeListener _brightnessSeekBarChange = new OnSeekBarChangeListener() {
        @Override
        public void onProgressChanged( final SeekBar seekBar , final int progress , final boolean fromUser ) {
            applyBrightness( progressToBrightness( progress , _brightnessSeekBar.getMax() ) );
        }

        @Override
        public void onStartTrackingTouch( final SeekBar seekBar ) {
        }

        @Override
        public void onStopTrackingTouch( final SeekBar seekBar ) {
        }
    };

    private final OnCheckedChangeListener _canRotateCheckBoxCheckedChange = new OnCheckedChangeListener() {
        @Override
        public void onCheckedChanged( final CompoundButton buttonView , final boolean isChecked ) {
            applyScreenOrientation( isChecked );
        }
    };

    private final android.content.DialogInterface.OnClickListener _resetButtonClick = new android.content.DialogInterface.OnClickListener() {
        @Override
        public void onClick( final DialogInterface dialog , final int which ) {
            _pref.reset();
            applyBrightnessState();
        }
    };

    private final OnClickListener _resetCheckBoxClick = new OnClickListener() {
        @Override
        public void onClick( final View v ) {
            new AlertDialog.Builder( _self ).setMessage( R.string.setting_reset_message ).setPositiveButton( R.string.yes , _resetButtonClick )
                    .setNegativeButton( R.string.no , null ).show();
        }
    };

    private void applyBrightness( final float brightness ) {
        _pref.setBrightness( brightness );

        SettingOperator.get( getApplicationContext() ).apply( this );
    }

    private void applyBrightnessMode( final boolean isAuto ) {
        applyBrightness( 0.5f );
        Settings.System.putInt( getContentResolver() , SettingsSystemWrapper.SCREEN_BRIGHTNESS_MODE , isAuto
                ? SettingsSystemWrapper.SCREEN_BRIGHTNESS_MODE_AUTOMATIC : SettingsSystemWrapper.SCREEN_BRIGHTNESS_MODE_MANUAL );

        applyBrightnessState();
    }

    private void applyBrightnessState() {
        if ( SettingsSystemWrapper.IS_SCREEN_BRIGHTNESS_MODE_SUPPORTED ) {
            _automaticBrightnessCheckBox.setVisibility( View.VISIBLE );
            _brightnessLayout.setVisibility( _automaticBrightnessCheckBox.isChecked() ? View.GONE : View.VISIBLE );
        } else {
            _automaticBrightnessCheckBox.setVisibility( View.GONE );
            _brightnessLayout.setVisibility( View.VISIBLE );
        }

        bindPref();
    }

    private void applyScreenOrientation( final boolean canRotate ) {
        _pref.setCanRotate( !canRotate );

        SettingOperator.get( getApplicationContext() ).apply( this );
    }

    private void assignWidget() {
        _automaticBrightnessCheckBox = ( CheckBox ) findViewById( R.id.automaticBrightnessCheckBox );
        _brightnessLayout = ( LinearLayout ) findViewById( R.id.brightnessLayout );
        _brightnessSeekBar = ( SeekBar ) findViewById( R.id.brightnessSeekBar );
        _canRotateCheckBox = ( CheckBox ) findViewById( R.id.canRotateCheckBox );
        _resetButton = ( Button ) findViewById( R.id.resetButton );
    }

    private void bindPref() {
        _canRotateCheckBox.setChecked( !_pref.canRotate() );

        _brightnessSeekBar.setProgress( brightnessToProgress( _pref.getBrightness() , _brightnessSeekBar.getMax() ) );
    }

    private int brightnessToProgress( final float brightness , final int max ) {
        return ( int ) ( ( brightness - MIN_BRIGHTNESS ) * max / ( MAX_BRIGHTNESS - MIN_BRIGHTNESS ) );
    }

    @Override
    public void onCreate( final Bundle savedInstanceState ) {
        super.onCreate( savedInstanceState );
        setContentView( R.layout.setting );

        _pref = PrefAccessor.get( getApplicationContext() );

        assignWidget();

        _automaticBrightnessCheckBox.setOnCheckedChangeListener( _automaticBrightnessCheckBoxCheckedChange );
        _brightnessSeekBar.setOnSeekBarChangeListener( _brightnessSeekBarChange );
        _canRotateCheckBox.setOnCheckedChangeListener( _canRotateCheckBoxCheckedChange );
        _resetButton.setOnClickListener( _resetCheckBoxClick );
    }

    @Override
    protected void onResume() {
        super.onResume();

        applyBrightnessState();
    }

    private float progressToBrightness( final int progress , final int max ) {
        return ( MAX_BRIGHTNESS - MIN_BRIGHTNESS ) * progress / max + MIN_BRIGHTNESS;
    }
}
