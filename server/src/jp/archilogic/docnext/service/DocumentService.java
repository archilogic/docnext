package jp.archilogic.docnext.service;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.List;

import jp.archilogic.docnext.converter.DocumentConverter;
import jp.archilogic.docnext.converter.ListConverter;
import jp.archilogic.docnext.dao.DocumentDao;
import jp.archilogic.docnext.dto.DividePage;
import jp.archilogic.docnext.dto.DocumentResDto;
import jp.archilogic.docnext.dto.Frame;
import jp.archilogic.docnext.dto.TOCElem;
import jp.archilogic.docnext.entity.Document;
import jp.archilogic.docnext.exception.NotFoundException;
import jp.archilogic.docnext.logic.PersistManager;
import jp.archilogic.docnext.logic.PersistManager.ImageJson;
import jp.archilogic.docnext.logic.PersistManager.InfoJson;
import jp.archilogic.docnext.logic.RepositoryPathManager;
import net.arnx.jsonic.JSON;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.stereotype.Component;

@Component
@RemotingDestination
public class DocumentService {
    @Autowired
    private DocumentDao documentDao;
    @Autowired
    private DocumentConverter documentConverter;
    @Autowired
    private RepositoryPathManager repositoryPathManager;
    @Autowired
    private PersistManager persistManager;

    public Long createDocument( final String json ) {
        final Document doc = JSON.decode( json , Document.class );
        doc.setName( "multiple documents" );
        doc.processing = false;
        return documentDao.create( doc );
    }

    public List< DocumentResDto > findAll() {
        return ListConverter.toDtos( documentDao.findAlmostAll() , documentConverter );
    }

    public DocumentResDto findById( final long id ) {
        final Document document = documentDao.findById( id );

        if ( document == null ) {
            throw new NotFoundException();
        }

        return documentConverter.toDto( document );
    }

    public String getAnnotation( final long id , final int page ) {
        // return packManager.readAnnotation( id , page );
        return null;
    }

    public List< DividePage > getDividePage( final long id ) {
        // return packManager.readDividePage( id );
        return null;
    }

    public List< Frame > getFrames( final long id ) {
        // return packManager.readFrames( id );
        return null;
    }

    public ImageJson getImageInfo( final long id ) {
        return persistManager.readImageJson( id );
    }

    public String getImageText( final long id , final int page ) {
        // deprecated?
        // return packManager.readImageText( id , page );
        return null;
    }

    public InfoJson getInfo( final long id ) {
        return persistManager.readInfoJson( id );
    }

    public byte[] getPageTexture( final long id , final int page , final int level , final int px , final int py ) {
        try {
            // TODO only for jpg
            return IOUtils.toByteArray( new FileInputStream( repositoryPathManager.getImagePath( id , page , level , px , py , false ) ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public byte[] getRegions( final long id , final int page ) {
        try {
            return FileUtils.readFileToByteArray( new File( repositoryPathManager.getImageTextRegionsPath( id , page ) ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public List< Integer > getSinglePageInfo( final long id ) {
        return persistManager.readInfoJson( id ).singlePages;
    }

    public byte[] getThumb( final long id , final int page ) {
        try {
            return FileUtils.readFileToByteArray( new File( repositoryPathManager.getThumbnailPath( id , page ) ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public List< TOCElem > getTOC( final long id ) {
        return persistManager.readInfoJson( id ).toc;
    }

    public void repack( final long id ) {
        // packManager.repack( id );
    }

    public void setBinding( final long id , final String binding ) {
        // packManager.writeBinding( id , binding );
    }

    public void setDividePage( final long id , final List< DividePage > dividePage ) {
        // packManager.writeDividePage( id , dividePage );
    }

    public void setFrames( final long id , final List< Frame > frames ) {
        // packManager.writeFrames( id , frames );
    }

    public void setImageInfo( final long id , final ImageJson json ) throws IOException {
        persistManager.writeImageInfoJson( id , json );
    }

    public void setInfo( final long id , final InfoJson json ) throws IOException {
        persistManager.writeInfoJson( id , json );
    }

    public void setSinglePageInfo( final long id , final List< Integer > singlePageInfo ) {
        final InfoJson info = persistManager.readInfoJson( id );
        info.singlePages = singlePageInfo;
        persistManager.writeInfoJson( id , info );
    }

    public void setText( final long id , final int page , final String text ) {
        // packManager.writeText( id , page , text.replaceAll( "\r\n" , "\n" ).replaceAll( "\r" , "\n" ) );
    }

    public void setTOC( final long id , final List< TOCElem > toc ) {
        final InfoJson info = persistManager.readInfoJson( id );
        info.toc = toc;
        persistManager.writeInfoJson( id , info );
    }
}
