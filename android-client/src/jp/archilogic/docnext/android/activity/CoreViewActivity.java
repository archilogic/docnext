package jp.archilogic.docnext.android.activity;

import java.io.File;
import java.io.IOException;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.ViewerFacade;
import jp.archilogic.docnext.android.ViewerFacade.ResultExtra;
import jp.archilogic.docnext.android.activity.CombinedTouchDetector.OnCombinedTouchListener;
import jp.archilogic.docnext.android.coreview.CoreView;
import jp.archilogic.docnext.android.coreview.CoreViewDelegate;
import jp.archilogic.docnext.android.coreview.HasPage;
import jp.archilogic.docnext.android.coreview.Highlightable;
import jp.archilogic.docnext.android.coreview.NavigationView;
import jp.archilogic.docnext.android.coreview.NeedCleanup;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.info.DownloadInfo;
import jp.archilogic.docnext.android.meta.DocumentType;
import jp.archilogic.docnext.android.provider.local.LocalPathManager;
import jp.archilogic.docnext.android.service.DownloadService;
import jp.archilogic.docnext.android.setting.SettingOperator;
import jp.archilogic.docnext.android.type.TaskErrorType;
import jp.archilogic.docnext.android.util.AnimationUtils2;
import jp.archilogic.docnext.android.util.ConnectivityUtil;
import jp.archilogic.docnext.android.util.FileUtils2;
import jp.archilogic.docnext.android.widget.CoreViewMenu;
import jp.archilogic.docnext.android.widget.CoreViewMenu.CoreViewMenuDelegate;
import jp.archilogic.docnext.android.widget.CoreViewStatusBar;
import net.arnx.jsonic.JSONException;

import org.apache.commons.io.FileUtils;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.ActivityManager.RunningServiceInfo;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.NotificationManager;
import android.app.SearchManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.PointF;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import android.widget.Toast;

public class CoreViewActivity extends Activity implements CoreViewDelegate , CoreViewMenuDelegate {
    public static final int LOADING_PROGRESS_SIZE = 50;

    private static final String PREFIX = CoreViewActivity.class.getName();

    public static final String BROADCAST_ERROR_NO_SD_CARD = PREFIX + ".broadcast.error.no.sd.card";
    public static final String BROADCAST_ERROR_BROKEN_FILE = PREFIX + ".broadcast.error.broken.file";

    public static final String EXTRA_ID = PREFIX + "extra.id";
    public static final String EXTRA_LOCAL_DIR = PREFIX + "extra.local.dir";
    public static final String EXTRA_ENDPOINT = PREFIX + "extra.endpoint";
    public static final String EXTRA_IS_SAMPLE = PREFIX + "extra.is.sample";
    public static final String EXTRA_PAGE = PREFIX + "extra.page";

    public static final String SAMPLE_LOCAL_DIR_PARENT = Environment.getExternalStorageDirectory() + "/docnext/sample/";
    public static final String SAMPLE_LOCAL_DIR_CHILD = SAMPLE_LOCAL_DIR_PARENT + "1/";
    public static final String SAMPLE_LOCAL_DIR_FORMAT = SAMPLE_LOCAL_DIR_PARENT + "1/%s/";

    private static final String STATE_TYPE = PREFIX + "state.type";
    private static final String STATE_ROOT_TYPE = PREFIX + "state.root.type";
    public static final String STATE_MENU_VISIBILITY = PREFIX + "state.menu.visibility";
    private static final String STATE_STATUS_BAR_PROGRESS = PREFIX + "state.status.bar.progress";
    private static final String STATE_ROOT_PAGE = PREFIX + "state.root.page";

    public static final int REQ_BOOKMARK = 11;
    public static final int REQ_TOC = 22;

    private static final int DIALOG_CONFIRM_RESTORE = 11;

    private final CoreViewActivity _self = this;

    private ViewGroup _rootViewGroup;
    private ViewGroup _holderViewGroup;
    private CoreView _view;
    private CoreViewMenu _menu;
    private DocumentType _rootType;
    private int _rootPage;

    private View _initProgressView;

    private String _id;
    private String _localDir;
    private String _endpoint;
    private DocumentType _type;
    private boolean _isSample;

    private CombinedTouchDetector _touchDetector;
    private boolean _comfirmedPageRestorsion = false;
    private boolean _willFinish = false;

    private CoreViewStatusBar _statusBar;

    private final OnCombinedTouchListener _touchListener = new OnCombinedTouchListener() {
        @Override
        public void onDoubleTap( final float pointX , final float pointY ) {
            // because view initialized lazy
            if ( _view != null ) {
                _view.onDoubleTapGesture( new PointF( pointX , pointY ) );
            }
        }

        @Override
        public void onFling( final float velocityX , final float velocityY ) {
            // because view initialized lazy
            if ( _view != null ) {
                _view.onFlingGesture( new PointF( velocityX , velocityY ) );
            }
        }

        @Override
        public void onLongPress() {
            if ( isShowingCoreView() ) {
                toggleMenu();
            }
        }

        @Override
        public void onScale( final float scaleFactor , final float focusX , final float focusY ) {
            // because view initialized lazy
            if ( _view != null ) {
                _view.onZoomGesture( scaleFactor , new PointF( focusX , focusY ) );
            }
        }

        @Override
        public void onScroll( final float distanceX , final float distanceY ) {
            // because view initialized lazy
            if ( _view != null ) {
                _view.onDragGesture( new PointF( distanceX , distanceY ) );
            }
        }

        @Override
        public void onSingleTap( final float pointX , final float pointY ) {
            if ( _view != null ) {
                _view.onTapGesture( new PointF( pointX , pointY ) );
            }
        }

        @Override
        public void onTouchBegin() {
            if ( _view != null ) {
                _view.onGestureBegin();
            }
        }

        @Override
        public void onTouchEnd() {
            if ( _view != null ) {
                _view.onGestureEnd();
            }
        }
    };

    private final BroadcastReceiver _remoteProviderReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive( final Context context , final Intent intent ) {
            if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_INIT_DOWNLOADED ) ) {
                showCoreView();
                onResume();
            } else if ( intent.getAction().equals( HasPage.BROADCAST_PAGE_CHANGED ) ) {
                if ( _menu != null ) {
                    _menu.onPageChanged();
                }
                if ( _view != null ) {
                    setLastOpendPage();
                }
            } else if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_FAILED ) ) {
                final TaskErrorType error = ( TaskErrorType ) intent.getSerializableExtra( DownloadService.EXTRA_ERROR );
                ( ( NotificationManager ) getSystemService( NOTIFICATION_SERVICE ) ).cancel( DownloadService.NETWORK_ERROR_NOTIFICATION_ID );

                switch ( error ) {
                case NETWORK_UNAVAILABLE:
                    waitAndRetry( R.string.network_unavailable );
                    break;
                case NETWORK_ERROR:
                    waitAndRetry( R.string.message_network_error );
                    break;
                case STATUS_CODE_408:
                    waitAndRetry( R.string.message_network_error );
                    break;
                case STATUS_CODE_401:
                    finishWithAlert( ResultExtra.ERROR_NETWORK , R.string.download_abort_error );
                    break;
                case STATUS_CODE_403:
                case STATUS_CODE_403_USERID:
                case STATUS_CODE_403_UA:
                    finishWithAlert( ResultExtra.ERROR_NETWORK , R.string.fatal_error );
                    break;
                case STATUS_CODE_404:
                case STATUS_CODE_500:
                    finishWithAlert( ResultExtra.ERROR_NETWORK , R.string.trouble_with_file_error );
                    break;
                case NO_STORAGE_SPACE:
                    finishWithAlert( ResultExtra.ERROR_NETWORK , R.string.no_space_error );
                    break;
                case STORAGE_NOT_MOUNTED:
                    finishWithAlert( ResultExtra.ERROR_NETWORK , R.string.no_sdcard_error );
                    break;
                default:
                    throw new RuntimeException( "assert" );
                }
            } else if ( intent.getAction().equals( BROADCAST_ERROR_NO_SD_CARD ) ) {
                finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            } else if ( intent.getAction().equals( BROADCAST_ERROR_BROKEN_FILE ) ) {
                finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
            }
        }

        private void setLastOpendPage() {
            try {
                Kernel.getLocalProvider().setLastOpenedPage( _localDir , ( ( HasPage ) _view ).getPage() );
            } catch ( final NoMediaMountException e ) {
                e.printStackTrace();
                finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            }
        }
    };

    @Override
    public void backToRootView( final Intent data ) {
        if ( _rootType == null ) {
            throw new RuntimeException( "assert" );
        }

        changeCoreViewType( _rootType , data );
    }

    private IntentFilter buildRemoteProviderReceiverFilter() {
        final IntentFilter filter = new IntentFilter();

        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_INIT_DOWNLOADED );
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_FAILED );
        filter.addAction( HasPage.BROADCAST_PAGE_CHANGED );
        filter.addAction( BROADCAST_ERROR_NO_SD_CARD );
        filter.addAction( BROADCAST_ERROR_BROKEN_FILE );

        return filter;
    }

    @Override
    public void changeCoreViewType( final DocumentType type , final Intent extra ) {
        if ( !checkTypeAndAlert( type ) ) {
            return;
        }

        if ( _menu.getVisibility() != View.GONE ) {
            toggleMenu();
        }

        if ( _view instanceof NeedCleanup ) {
            ( ( NeedCleanup ) _view ).cleanup();
        }

        _holderViewGroup.removeView( ( View ) _view );
        if ( type.isRoot() ) {
            _rootType = null;
        } else if ( _type.isRoot() ) {
            _rootType = _type;

            if ( _view instanceof HasPage ) {
                _rootPage = ( ( HasPage ) _view ).getPage();
            }
        }

        _type = type;

        setCoreView( type , extra.getIntExtra( EXTRA_PAGE , 0 ) );

        _menu.setType( type );
    }

    private void checkAndRun( final String id , final String localDir , final String endpoint , final boolean isSample ) {
        final String EXPIRED_MESSAGE = "has expired";

        try {
            if ( Kernel.getLocalProvider().isCompleted( localDir ) ) {
                showCoreView();
                confirmRestorePage();

                return;
            }

            // endpoint is null only for completed document
            if ( endpoint.equals( EXPIRED_MESSAGE ) ) {
                final boolean isInit = isInitDownloaded( localDir );

                new AlertDialog.Builder( _self ).setMessage( R.string.download_limit_expired ).setCancelable( false )
                        .setPositiveButton( R.string.ok , new OnClickListener() {
                            @Override
                            public void onClick( final DialogInterface dialog , final int which ) {
                                if ( isInit ) {
                                    confirmRestorePage();
                                } else {
                                    finish();
                                }
                            }
                        } ).show();

                if ( isInit ) {
                    showCoreView();
                }

                return;
            }

            final DownloadInfo info = Kernel.getLocalProvider().getDownloadInfo();

            if ( info != null && ( info.isSample || !new File( info.localDir ).exists() ) ) {
                Kernel.getLocalProvider().setDownloadInfo( null );
                startService( new Intent( _self , DownloadService.class ) );

                new Handler().postDelayed( new Runnable() {
                    @Override
                    public void run() {
                        try {
                            checkAndRunIncomplete( id , localDir , endpoint , isSample );
                        } catch ( final NoMediaMountException e ) {
                            e.printStackTrace();
                            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
                        } catch ( final JSONException e ) {
                            e.printStackTrace();
                            finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
                        }
                    }
                } , 1000 );
            } else {
                checkAndRunIncomplete( id , localDir , endpoint , isSample );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
        }
    }

    private void checkAndRunIncomplete( final String id , final String localDir , final String endpoint , final boolean isSample )
            throws NoMediaMountException , JSONException {
        final DownloadInfo current = Kernel.getLocalProvider().getDownloadInfo();

        if ( current == null ) {
            if ( isDownloadServiceRunning() ) {
                Log.e( "docnext" , "Enter deprecated block" );

                Kernel.getLocalProvider().setDownloadInfo( null );
                startService( new Intent( _self , DownloadService.class ) );

                new Handler().postDelayed( new Runnable() {
                    @Override
                    public void run() {
                        try {
                            Kernel.getLocalProvider().setDownloadInfo( new DownloadInfo( id , localDir , endpoint , isSample ) );
                            startService( new Intent( _self , DownloadService.class ) );
                        } catch ( final NoMediaMountException e ) {
                            e.printStackTrace();
                            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
                        } catch ( final JSONException e ) {
                            e.printStackTrace();
                            finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
                        }
                    }
                } , 1000 );
            } else {
                Kernel.getLocalProvider().setDownloadInfo( new DownloadInfo( id , localDir , endpoint , isSample ) );
                startService( new Intent( _self , DownloadService.class ) );
            }

            showSuitableView( localDir );
        } else if ( id.equals( current.id ) ) {
            if ( !isDownloadServiceRunning() ) {
                Kernel.getLocalProvider().setDownloadInfo( new DownloadInfo( id , localDir , endpoint , isSample ) );
                startService( new Intent( _self , DownloadService.class ) );
            }

            showSuitableView( _localDir );
        } else {
            Toast.makeText( _self , getString( R.string.cannot_download_in_parallel ) , Toast.LENGTH_LONG ).show();

            finish( ResultExtra.NORMAL_FINISH );
        }
    }

    private boolean checkTypeAndAlert( final DocumentType type ) {
        try {
            final DocInfo doc = Kernel.getLocalProvider().getInfo( _localDir );

            switch ( type ) {
            case IMAGE:
                if ( !doc.types.contains( DocumentType.IMAGE ) ) {
                    Toast.makeText( _self , R.string.message_no_image_view , Toast.LENGTH_LONG ).show();
                    return false;
                }

                if ( !Kernel.getLocalProvider().isImageInitDownloaded( _localDir ) ) {
                    Toast.makeText( _self , R.string.message_image_view_not_ready , Toast.LENGTH_LONG ).show();
                    return false;
                }

                break;
            case THUMBNAIL:
                if ( !doc.types.contains( DocumentType.IMAGE ) ) {
                    Toast.makeText( _self , R.string.message_no_thumbnail_view , Toast.LENGTH_LONG ).show();
                    return false;
                }

                if ( Kernel.getLocalProvider().getImageThumbnailPath( _localDir , doc.pages - 1 ) == null ) {
                    Toast.makeText( _self , R.string.message_thumbnail_view_not_ready , Toast.LENGTH_LONG ).show();
                    return false;
                }

                break;
            }

            return true;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
        }

        return false;
    }

    private void confirmFinish() {
        final OnClickListener yesClick = new OnClickListener() {
            @Override
            public void onClick( final DialogInterface dialog , final int which ) {
                try {
                    if ( _isSample ) {
                        // stop rendering thread
                        _view.onPause();

                        final DownloadInfo current = Kernel.getLocalProvider().getDownloadInfo();

                        if ( current != null && current.id.equals( _id ) ) {
                            Kernel.getLocalProvider().setDownloadInfo( null );
                            startService( new Intent( _self , DownloadService.class ) );
                        } else {
                            deleteLocalDir();
                        }
                    }

                    finish();
                } catch ( final NoMediaMountException e ) {
                    e.printStackTrace();
                    finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
                } catch ( final JSONException e ) {
                    e.printStackTrace();
                    finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
                }
            }
        };

        new AlertDialog.Builder( _self ).setMessage( R.string.confirm_finish ).setPositiveButton( R.string.yes , yesClick )
                .setNegativeButton( R.string.no , null ).show();
    }

    private void confirmRestorePage() {
        if ( !_comfirmedPageRestorsion && new File( new LocalPathManager().getLastOpenedPagePath( _localDir ) ).exists() ) {
            _comfirmedPageRestorsion = true;

            showDialog( DIALOG_CONFIRM_RESTORE );
        }
    }

    private void deleteLocalDir() {
        try {
            FileUtils.deleteDirectory( new File( _localDir ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private int dp( final int value ) {
        return Math.round( value * getResources().getDisplayMetrics().density );
    }

    private void finish( final ResultExtra result ) {
        try {
            if ( _isSample ) {
                final DownloadInfo current = Kernel.getLocalProvider().getDownloadInfo();

                if ( current != null && current.id.equals( _id ) ) {
                    Kernel.getLocalProvider().setDownloadInfo( null );
                    startService( new Intent( _self , DownloadService.class ) );
                } else {
                    deleteLocalDir();
                }
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            // ignore to avoid infinite recursion
        } catch ( final JSONException e ) {
            e.printStackTrace();
        } catch ( final Exception e ) {
            e.printStackTrace();
        }

        setResult( RESULT_OK , new Intent().putExtra( ViewerFacade.EXTRA_RESULT , result ) );

        finish();
    }

    private void finishWithAlert( final ResultExtra result , final int messageId ) {
        _willFinish = true;

        final OnClickListener yesClick = new OnClickListener() {
            @Override
            public void onClick( final DialogInterface dialog , final int which ) {
                finish( result );
            }
        };

        new AlertDialog.Builder( _self ).setMessage( messageId ).setPositiveButton( R.string.yes , yesClick ).setCancelable( false ).show();
    }

    @Override
    public CoreView getCoreView() {
        return _view;
    }

    @Override
    public void goBack() {
        if ( _rootType == null ) {
            confirmFinish();

            return;
        }

        final Intent intent = new Intent();
        intent.putExtra( EXTRA_PAGE , _rootPage );
        backToRootView( intent );
        _rootType = null;
    }

    private boolean isDownloadServiceRunning() {
        for ( final RunningServiceInfo info : ( ( ActivityManager ) getSystemService( ACTIVITY_SERVICE ) ).getRunningServices( Integer.MAX_VALUE ) ) {
            if ( info.service.getClassName().equals( DownloadService.class.getName() ) ) {
                return true;
            }
        }

        return false;
    }

    private boolean isInitDownloaded( final String localDir ) {
        try {
            Kernel.getLocalProvider().updateImageInitDownloaded( localDir );

            return Kernel.getLocalProvider().isImageInitDownloaded( localDir );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );

            return false;
        }
    }

    private boolean isShowingCoreView() {
        return _view != null;
    }

    @Override
    public void onActivityResult( final int requestCode , final int resultCode , final Intent data ) {
        if ( resultCode == Activity.RESULT_OK ) {
            if ( requestCode == REQ_BOOKMARK || requestCode == REQ_TOC ) {
                if ( _view instanceof HasPage ) {
                    ( ( HasPage ) _view ).setPage( data.getIntExtra( EXTRA_PAGE , 0 ) );
                    _menu.onPageChanged();
                }
            }
        }
    }

    @Override
    public void onCreate( final Bundle savedInstanceState ) {
        super.onCreate( savedInstanceState );

        requestWindowFeature( Window.FEATURE_NO_TITLE );

        setContentView( _rootViewGroup = new FrameLayout( _self ) );

        registerReceiver( _remoteProviderReceiver , buildRemoteProviderReceiverFilter() );

        _id = getIntent().getStringExtra( EXTRA_ID );
        _localDir = getIntent().getStringExtra( EXTRA_LOCAL_DIR );
        _endpoint = getIntent().getStringExtra( EXTRA_ENDPOINT );
        _isSample = getIntent().getBooleanExtra( EXTRA_IS_SAMPLE , false );

        if ( _isSample ) {
            _localDir = String.format( SAMPLE_LOCAL_DIR_FORMAT , _id );
        }

        // some parameters can be null on Guest
        if ( _id == null || _localDir == null ) {
            finishWithAlert( ResultExtra.ERROR_ILLEGAL_ARGUMENT , R.string.fatal_error );
            return;
        }

        if ( !Environment.MEDIA_MOUNTED.equals( Environment.getExternalStorageState() ) ) {
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            return;
        }

        try {
            final File testFile = new File( _localDir + "/test" );
            FileUtils2.touch( testFile );
            testFile.delete();
        } catch ( final IOException e ) {
            Log.e( "docnext" , "permission error" , e );
            finishWithAlert( ResultExtra.ERROR_PERMISSION , R.string.unexpected_error );
            return;
        }

        _touchDetector = new CombinedTouchDetector( _self , _touchListener );
    }

    @Override
    protected Dialog onCreateDialog( final int id ) {
        Dialog dialog = super.onCreateDialog( id );

        if ( id == DIALOG_CONFIRM_RESTORE ) {
            try {
                final int target = Kernel.getLocalProvider().getLastOpenedPage( _localDir );

                final DialogInterface.OnClickListener yesClick = new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick( final DialogInterface dialog , final int which ) {
                        if ( _view instanceof HasPage ) {
                            ( ( HasPage ) _view ).setPage( target );
                            _menu.onPageChanged();
                        }
                    }
                };

                dialog =
                        new AlertDialog.Builder( _self ).setMessage( R.string.confirm_restore ).setPositiveButton( R.string.yes , yesClick )
                                .setNegativeButton( R.string.no , null ).create();
            } catch ( final NoMediaMountException e ) {
                e.printStackTrace();
                finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            }
        }

        return dialog;
    }

    @Override
    public boolean onCreateOptionsMenu( final Menu menu ) {
        return true;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if ( isShowingCoreView() ) {
            if ( _view instanceof NeedCleanup ) {
                ( ( NeedCleanup ) _view ).cleanup();
            }
        }

        if ( _statusBar != null ) {
            _statusBar.onDestroy();
        }

        _rootViewGroup = null;
        _holderViewGroup = null;
        _view = null;
        _menu = null;

        unregisterReceiver( _remoteProviderReceiver );

        System.gc();
    }

    @Override
    public boolean onKeyDown( final int keyCode , final KeyEvent event ) {
        if ( keyCode == KeyEvent.KEYCODE_BACK ) {
            if ( isShowingCoreView() && _menu.getVisibility() != View.GONE ) {
                toggleMenu();
            } else {
                goBack();
            }

            return true;
        }

        return super.onKeyDown( keyCode , event );
    }

    @Override
    protected void onNewIntent( final Intent intent ) {
        super.onNewIntent( intent );

        try {
            Kernel.getLocalProvider().cleanupImageTextIndex();
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            return;
        }

        if ( intent.getAction() == null ) {
            // on launch multiple activity instantly
            return;
        }

        int page;
        String keyword;
        if ( intent.getAction().equals( Intent.ACTION_VIEW ) ) {
            page = Integer.parseInt( intent.getData().getLastPathSegment() );
            keyword = intent.getStringExtra( SearchManager.EXTRA_DATA_KEY );
        } else if ( intent.getAction().equals( Intent.ACTION_SEARCH ) ) {
            page = -1;
            keyword = intent.getStringExtra( SearchManager.QUERY );
        } else {
            throw new RuntimeException();
        }

        if ( _view instanceof HasPage ) {
            if ( page != -1 ) {
                ( ( HasPage ) _view ).setPage( page );
            }
        }

        if ( _view instanceof Highlightable ) {
            ( ( Highlightable ) _view ).highlight( keyword );
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        if ( isShowingCoreView() ) {
            _view.onPause();
        }
    }

    // Need to use onPrepareOptionsMenu?
    @Override
    public boolean onPrepareOptionsMenu( final Menu menu ) {
        if ( !isShowingCoreView() ) {
            return false;
        }

        toggleMenu();

        return true;
    }

    @Override
    protected void onRestoreInstanceState( final Bundle inState ) {
        super.onRestoreInstanceState( inState );

        final DocumentType type = ( DocumentType ) inState.getSerializable( STATE_TYPE );

        if ( type != null ) {
            _type = type;

            showCoreView( inState.getInt( EXTRA_PAGE ) );

            _view.restoreState( inState );

            _rootType = ( DocumentType ) inState.getSerializable( STATE_ROOT_TYPE );
            _rootPage = inState.getInt( STATE_ROOT_PAGE );

            if ( inState.getBoolean( STATE_MENU_VISIBILITY ) ) {
                toggleMenu();
            }

            final float progress = inState.getFloat( STATE_STATUS_BAR_PROGRESS , -1 );
            if ( progress >= 0 && _statusBar != null ) {
                _statusBar.setProgress( progress );
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        if ( _willFinish ) {
            return;
        }

        SettingOperator.get( getApplicationContext() ).apply( this );

        if ( isShowingCoreView() ) {
            _view.onResume();
        } else {
            checkAndRun( _id , _localDir , _endpoint , _isSample );
        }
    }

    @Override
    protected void onSaveInstanceState( final Bundle outState ) {
        super.onSaveInstanceState( outState );

        if ( isShowingCoreView() ) {
            outState.putSerializable( STATE_TYPE , _type );

            if ( _view instanceof HasPage ) {
                outState.putInt( EXTRA_PAGE , ( ( HasPage ) _view ).getPage() );
            }

            outState.putBoolean( STATE_MENU_VISIBILITY , _menu.getVisibility() != View.GONE );

            _view.saveState( outState );

            outState.putSerializable( STATE_ROOT_TYPE , _rootType );
            outState.putInt( STATE_ROOT_PAGE , _rootPage );

            if ( _statusBar != null ) {
                outState.putFloat( STATE_STATUS_BAR_PROGRESS , _statusBar.getProgress() );
            }
        }
    }

    @Override
    public boolean onSearchRequested() {
        if ( !isShowingCoreView() ) {
            return false;
        }

        try {
            if ( !Kernel.getLocalProvider().isImageTextIndexExists( _localDir ) ) {
                Toast.makeText( _self , R.string.message_search_not_ready , Toast.LENGTH_LONG ).show();
                return false;
            }

            Kernel.getLocalProvider().prepareImageTextIndex( _localDir );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
        }

        return super.onSearchRequested();
    }

    @Override
    public boolean onTouchEvent( final MotionEvent event ) {
        if ( !isShowingCoreView() ) {
            return false;
        }

        // translate to _view location
        final View v = getWindow().findViewById( Window.ID_ANDROID_CONTENT );

        event.offsetLocation( -v.getLeft() , -v.getTop() );

        return _touchDetector.onTouchEvent( event );
    }

    private void setCoreView( final DocumentType type , final int page ) {
        _view = _type.buildView( _self );

        _holderViewGroup.addView( ( View ) _view );

        _view.setDocId( _id );
        _view.setLocalDir( _localDir );
        _view.setDelegate( _self );

        if ( _view instanceof HasPage ) {
            ( ( HasPage ) _view ).setPage( page );
        }

        if ( _view instanceof NavigationView ) {
            ( ( NavigationView ) _view ).init();
        }
    }

    private void showCoreView() {
        showCoreView( 0 );
    }

    private void showCoreView( final int page ) {
        try {
            if ( _initProgressView != null ) {
                _rootViewGroup.removeView( _initProgressView );
                _initProgressView = null;
            }

            if ( _type == null ) {
                _type = validateCoreViewType();
            }

            _holderViewGroup = new FrameLayout( _self );
            _rootViewGroup.addView( _holderViewGroup );

            setCoreView( _type , page );

            _menu = new CoreViewMenu( _self , _localDir , _self );
            _menu.setType( _type );
            _rootViewGroup.addView( _menu );

            if ( !Kernel.getLocalProvider().isCompleted( _localDir ) ) {
                _statusBar = new CoreViewStatusBar( _self );
                _rootViewGroup.addView( _statusBar );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
            return;
        }
    }

    private void showLoadingView() {
        _initProgressView = new ProgressBar( _self );
        _initProgressView
                .setLayoutParams( new FrameLayout.LayoutParams( dp( LOADING_PROGRESS_SIZE ) , dp( LOADING_PROGRESS_SIZE ) , Gravity.CENTER ) );

        _rootViewGroup.addView( _initProgressView );
    }

    private void showRetryDialog( final int messageId ) {
        final OnClickListener yesClick = new OnClickListener() {
            @Override
            public void onClick( final DialogInterface dialog , final int which ) {
                try {
                    Kernel.getLocalProvider().setDownloadInfo( new DownloadInfo( _id , _localDir , _endpoint , _isSample ) );
                    startService( new Intent( _self , DownloadService.class ) );
                } catch ( final NoMediaMountException e ) {
                    e.printStackTrace();
                    finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
                } catch ( final JSONException e ) {
                    e.printStackTrace();
                    finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
                }
            }
        };

        final OnClickListener noClick = new OnClickListener() {
            @Override
            public void onClick( final DialogInterface dialog , final int which ) {
                if ( !isShowingCoreView() ) {
                    finish( ResultExtra.ERROR_NETWORK );
                }
            }
        };

        new AlertDialog.Builder( _self ).setMessage( messageId ).setPositiveButton( R.string.yes , yesClick )
                .setNegativeButton( R.string.no , noClick ).show();
    }

    private void showSuitableView( final String localDir ) {
        if ( isInitDownloaded( localDir ) ) {
            showCoreView();
            confirmRestorePage();
        } else {
            showLoadingView();
        }
    }

    private void toggleMenu() {
        final boolean willVisible = _menu.getVisibility() == View.GONE;

        if ( _statusBar != null ) {
            AnimationUtils2.toggle( _self , _statusBar );
        }

        AnimationUtils2.toggle( _self , _menu );

        _view.onMenuVisibilityChange( willVisible );
    }

    private DocumentType validateCoreViewType() {
        try {
            return Kernel.getLocalProvider().getInfo( _localDir ).types.get( 0 );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_NO_SD_CARD , R.string.no_sdcard_error );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            finishWithAlert( ResultExtra.ERROR_BROKEN_FILE , R.string.trouble_with_file_error );
        }

        return null;
    }

    private void waitAndRetry( final int messageId ) {
        final int DURATION_TO_WAIT = 3000;

        new Handler().postDelayed( new Runnable() {
            @Override
            public void run() {
                if ( _self != null ) {
                    if ( ConnectivityUtil.isNetworkConnected( _self ) ) {
                        showRetryDialog( messageId );
                    } else {
                        OnClickListener click = null;

                        if ( !isShowingCoreView() ) {
                            click = new OnClickListener() {
                                @Override
                                public void onClick( final DialogInterface dialog , final int which ) {
                                    finish( ResultExtra.ERROR_NETWORK );
                                }
                            };
                        }

                        new AlertDialog.Builder( _self ).setCancelable( false ).setMessage( R.string.network_unavailable )
                                .setPositiveButton( R.string.yes , click ).show();
                    }
                }
            }
        } , DURATION_TO_WAIT );
    }
}
