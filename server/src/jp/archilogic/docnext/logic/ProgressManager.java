package jp.archilogic.docnext.logic;

import java.util.Map;

import jp.archilogic.docnext.dao.DocumentDao;
import jp.archilogic.docnext.entity.Document;
import net.arnx.jsonic.JSON;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.google.common.collect.Maps;

@Component
public class ProgressManager {
    public enum ErrorType {
        UNKNOWN , ENCRYPTED , MALFORMED;
    }

    public class Progress {
        public Step step;
        public int createdThumbnail;
        public int totalThumbnail;
        public ErrorType error;

        public Progress() {
        }

        public Progress( final Step step ) {
            this.step = step;
        }
    }

    public class ProgressJSON {
        public String step;
        public int createdThumbnail;
        public int totalThumbnail;
        public String error;

        public ProgressJSON( final Progress progress ) {
            step = progress.step.toString();
            createdThumbnail = progress.createdThumbnail;
            totalThumbnail = progress.totalThumbnail;
            error = progress.error != null ? progress.error.toString() : "no error";
        }
    }

    public enum Step {
        WAITING_EXEC , INITIALIZING , CREATING_THUMBNAIL , COMPLETED , FAILED;
    }

    @Autowired
    private DocumentDao documentDao;

    private final Map< Long , Progress > _data = Maps.newHashMap();

    public void clearCompleted( final long id ) {
        _data.remove( id );
    }

    public String getProgressJSON( final long id ) {
        Progress progress = _data.get( id );

        // clear Progress which is set by setError
        if ( progress != null && progress.step == Step.FAILED ) {
            _data.remove( id );
        }

        if ( progress == null ) {
            final Document document = documentDao.findById( id );

            if ( document != null && !document.processing ) {
                progress = new Progress( Step.COMPLETED );
            } else {
                progress = new Progress( Step.FAILED );
                progress.error = ErrorType.UNKNOWN;
            }
        }

        return JSON.encode( new ProgressJSON( progress ) );
    }

    public void setCreatedThumbnail( final long id , final int created ) {
        Progress progress = _data.get( id );

        if ( progress == null ) {
            _data.put( id , progress = new Progress() );
        }

        progress.createdThumbnail = created;
    }

    public void setError( final long id , final ErrorType error ) {
        setStep( id , Step.FAILED );

        _data.get( id ).error = error;
    }

    public void setStep( final long id , final Step step ) {
        Progress progress = _data.get( id );

        if ( progress == null ) {
            _data.put( id , progress = new Progress() );
        }

        progress.step = step;
    }

    public void setTotalThumbnail( final long id , final int total ) {
        Progress progress = _data.get( id );

        if ( progress == null ) {
            _data.put( id , progress = new Progress() );
        }

        progress.totalThumbnail = total;
    }
}
