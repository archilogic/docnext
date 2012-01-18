package jp.archilogic.docnext.android.activity;

import jp.archilogic.docnext.android.R;
import android.app.Activity;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnPreparedListener;
import android.os.Bundle;
import android.widget.MediaController;
import android.widget.VideoView;

public class VideoViewActivity extends Activity {

    private String path;
    private VideoView videoView;

    @Override
    public void onCreate( Bundle bundle ) {
        super.onCreate( bundle );
        setContentView( R.layout.videoview );
        videoView = ( VideoView ) findViewById( R.id.surface_view );

        path = getIntent().getStringExtra( "uri" );
        if ( path == null ) {
            throw new RuntimeException( "assert" );
        } else {
            videoView.setVideoPath( path );
            videoView.setMediaController( new MediaController( this ) );
            videoView.requestFocus();

            OnPreparedListener listener = new OnPreparedListener() {

                @Override
                public void onPrepared( MediaPlayer mp ) {
                    videoView.start();
                }
            };

            videoView.setOnPreparedListener( listener );
        }
    }
}