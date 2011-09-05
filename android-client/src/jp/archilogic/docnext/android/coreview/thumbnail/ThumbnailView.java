package jp.archilogic.docnext.android.coreview.thumbnail;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.coreview.NavigationView;
import jp.archilogic.docnext.android.coreview.thumbnail.ThumbnailImageAdapter.Direction;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.type.BindingType;
import net.arnx.jsonic.JSONException;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.TextView;

public class ThumbnailView extends NavigationView {
    private static final String PREFIX = ThumbnailView.class.getName();
    private static final String STATE_PAGE = PREFIX + "state.page";

    private TextView _pageTextView;
    private CoverFlow _coverFlow;
    private SeekBar _seekBar;

    private int _currentPage;

    public ThumbnailView( final Context context ) {
        super( context );
    }

    private void assignWidget() {
        _pageTextView = ( TextView ) findViewById( R.id.pageTextView );
        _coverFlow = ( CoverFlow ) findViewById( R.id.coverFlow );
        _seekBar = ( SeekBar ) findViewById( R.id.seekBar );
    }

    private void bindPageText( final int page , final int pages ) {
        _pageTextView.setText( String.format( "%d / %d" , page + 1 , pages ) );
    }

    private int getLeftOriginPosition( final int page , final int pages , final Direction direction ) {
        return direction == Direction.LEFT ? pages - 1 - page : page;
    }

    @Override
    public void init() {
        try {
            LayoutInflater.from( getContext() ).inflate( R.layout.thumbnail , this , true );

            assignWidget();

            final DocInfo info = Kernel.getLocalProvider().getInfo( _localDir );

            final int pages = info.pages;
            final Direction direction = info.binding == BindingType.LEFT ? Direction.RIGHT : Direction.LEFT;

            _coverFlow.setAdapter( new ThumbnailImageAdapter( getContext() , _id , _localDir , direction ) );
            _coverFlow.setOnItemClickListener( new OnItemClickListener() {
                @Override
                public void onItemClick( final AdapterView< ? > parent , final View v , final int position , final long id ) {
                    goTo( getLeftOriginPosition( position , pages , direction ) );
                }
            } );
            _coverFlow.setOnItemSelectedListener( new OnItemSelectedListener() {
                @Override
                public void onItemSelected( final AdapterView< ? > parent , final View v , final int position , final long id ) {
                    bindPageText( getLeftOriginPosition( position , pages , direction ) , pages );
                    _seekBar.setProgress( position );
                    _currentPage = position;
                }

                @Override
                public void onNothingSelected( final AdapterView< ? > parnet ) {
                }
            } );

            _seekBar.setMax( pages - 1 );
            _seekBar.setOnSeekBarChangeListener( new OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged( final SeekBar seekBar , final int progress , final boolean fromUser ) {
                    bindPageText( getLeftOriginPosition( progress , pages , direction ) , pages );
                    _coverFlow.setSelection( progress );
                    _currentPage = progress;
                }

                @Override
                public void onStartTrackingTouch( final SeekBar seekBar ) {
                }

                @Override
                public void onStopTrackingTouch( final SeekBar seekBar ) {
                }
            } );

            _coverFlow.setSelection( getLeftOriginPosition( _page , pages , direction ) );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    @Override
    public void restoreState( final Bundle state ) {
        super.restoreState( state );

        final int page = state.getInt( STATE_PAGE );

        _coverFlow.setSelection( page );
    }

    @Override
    public void saveState( final Bundle state ) {
        super.saveState( state );

        state.putInt( STATE_PAGE , _currentPage );
    }
}
