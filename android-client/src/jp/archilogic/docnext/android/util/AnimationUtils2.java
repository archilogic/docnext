package jp.archilogic.docnext.android.util;

import android.content.Context;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.Animation.AnimationListener;
import android.view.animation.AnimationUtils;

public class AnimationUtils2 {
    public static void toggle( final Context context , final View view ) {
        final boolean willVisible = view.getVisibility() == View.GONE;

        final Animation anim = willVisible ? AnimationUtils.makeInAnimation( context , true ) : //
                AnimationUtils.makeOutAnimation( context , true );

        anim.setAnimationListener( new AnimationListener() {
            @Override
            public void onAnimationEnd( final Animation animation ) {
                if ( !willVisible ) {
                    view.setVisibility( View.GONE );
                }
            }

            @Override
            public void onAnimationRepeat( final Animation animation ) {
            }

            @Override
            public void onAnimationStart( final Animation animation ) {
            }
        } );

        if ( willVisible ) {
            view.setVisibility( View.VISIBLE );
        }

        view.startAnimation( anim );
    }
}
