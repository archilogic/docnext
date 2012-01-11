package jp.archilogic.docnext.logic;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;

import javax.imageio.ImageIO;

import jp.archilogic.docnext.bean.PropBean;
import jp.archilogic.docnext.dao.DocumentDao;
import jp.archilogic.docnext.dto.Region;
import jp.archilogic.docnext.dto.TextInfo;
import jp.archilogic.docnext.entity.Document;
import jp.archilogic.docnext.exception.EncryptedPDFException;
import jp.archilogic.docnext.exception.MalformedPDFException;
import jp.archilogic.docnext.exception.UnsupportedFormatException;
import jp.archilogic.docnext.logic.ImageGenerator.PDFInfo;
import jp.archilogic.docnext.logic.PDFAnnotationParser.PageAnnotationInfo;
import jp.archilogic.docnext.logic.PDFTextParser.PageTextInfo;
import jp.archilogic.docnext.logic.PersistManager.ImageJson;
import jp.archilogic.docnext.logic.PersistManager.InfoJson;
import jp.archilogic.docnext.logic.ProgressManager.ErrorType;
import jp.archilogic.docnext.logic.ProgressManager.Step;

import org.apache.commons.compress.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress.archivers.zip.ZipFile;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.apache.lucene.analysis.cjk.CJKAnalyzer;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Field.Index;
import org.apache.lucene.document.Field.Store;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.IndexWriterConfig;
import org.apache.lucene.store.FSDirectory;
import org.apache.lucene.util.Version;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.task.TaskExecutor;
import org.springframework.stereotype.Component;

import com.artofsolving.jodconverter.DocumentConverter;
import com.artofsolving.jodconverter.openoffice.connection.OpenOfficeException;
import com.google.common.collect.Lists;
import com.sun.star.task.ErrorCodeIOException;

@Component
public class UploadProcessor {
    private static class Size {
        int width;
        int height;

        Size( final int width , final int height ) {
            this.width = width;
            this.height = height;
        }
    }

    private class UploadTask implements Runnable {
        private final String tempPath;
        private final Document doc;
        private final boolean isWebp;
        private final int pageLimit;

        public UploadTask( final String tempPath , final Document doc , final boolean isWebp , final int pageLimit ) {
            this.tempPath = tempPath;
            this.doc = doc;
            this.isWebp = isWebp;
            this.pageLimit = pageLimit;
        }

        private Size getSize( final InputStream is ) throws IOException {
            final BufferedImage image = ImageIO.read( is );

            return new Size( image.getWidth() , image.getHeight() );
        }

        private boolean isSupportedImage( final String path ) {
            final String[] WHITE_LIST = { ".jpg" , ".png" , ".bmp" , ".gif" };

            for ( final String ext : WHITE_LIST ) {
                if ( path.endsWith( ext ) ) {
                    return true;
                }
            }

            return false;
        }

        private void parseText( final String cleanedPath , final int pages , final long id ) {
            try {
                final String tmp = prop.tmp + id + "/image.text.index";

                final IndexWriter writer =
                        new IndexWriter( FSDirectory.open( new File( tmp ) ) , new IndexWriterConfig( Version.LUCENE_31 , new CJKAnalyzer(
                                Version.LUCENE_31 ) ) );

                List< PageTextInfo > infos = null;
                if ( cleanedPath != null ) {
                    infos = pdfTextParser.parse( cleanedPath );
                }

                for ( int page = 0 ; page < pages ; page++ ) {
                    if ( infos != null ) {
                        final TextInfo text = TextInfo.newInstance();
                        text.text = infos.get( page ).text;
                        // persistManager.writeTextJson( id , page , text );
                    }
                    persistManager.writeImageTextRegions( id , page , infos != null ? infos.get( page ).regions : Lists.< Region > newArrayList() );

                    final org.apache.lucene.document.Document doc = new org.apache.lucene.document.Document();

                    doc.add( new Field( "id" , Long.toString( id ) , Store.YES , Index.NO ) );
                    doc.add( new Field( "page" , Integer.toString( page ) , Store.YES , Index.ANALYZED ) );

                    doc.add( new Field( "text" , infos != null ? infos.get( page ).text : "" , Store.YES , Index.ANALYZED ) );

                    writer.addDocument( doc );
                }

                writer.optimize();
                writer.commit();

                writer.close();

                persistManager.packImageTextIndex( id , tmp );
            } catch ( final IOException e ) {
                throw new RuntimeException( e );
            }
        }

        private void procArchive() throws Exception {
            final int N_SKIP = 4;

            final ZipFile file = new ZipFile( tempPath );

            final List< String > paths = Lists.newArrayList();
            for ( final Enumeration< ? > e = file.getEntries() ; e.hasMoreElements() ; ) {
                final ZipArchiveEntry entry = ( ZipArchiveEntry ) e.nextElement();

                if ( !entry.isDirectory() && isSupportedImage( entry.getName() ) ) {
                    paths.add( entry.getName() );
                }
            }

            Collections.sort( paths );

            // old size detection
            Size target = null;

            if ( paths.size() > N_SKIP * 2 ) {
                target = new Size( Integer.MIN_VALUE , Integer.MIN_VALUE );

                for ( int index = N_SKIP ; index < paths.size() - N_SKIP ; index++ ) {
                    final Size size = getSize( file.getInputStream( file.getEntry( paths.get( index ) ) ) );

                    target.width = Math.max( target.width , size.width );
                    target.height = Math.max( target.height , size.height );
                }
            } else {
                target = getSize( file.getInputStream( file.getEntry( paths.get( paths.size() / 2 ) ) ) );
            }

            int page = 0;
            for ( final String path : paths ) {
                // save as png for imlib2

                final BufferedImage image = ImageIO.read( file.getInputStream( file.getEntry( path ) ) );

                final String tmpPath = prop.tmp + "tmp.png";

                final OutputStream out = new FileOutputStream( tmpPath );
                ImageIO.write( image , "png" , out );
                IOUtils.closeQuietly( out );

                imageGenerator.createFromImage( tmpPath , doc.id , page , false , target.width , target.height , page == 0 , isWebp );

                persistManager.writeImageAnnotationJson( doc.id , page , Lists.< PageAnnotationInfo > newArrayList() );

                page++;
            }

            final InfoJson info = persistManager.readInfoJson( doc.id );
            info.pages = page;
            persistManager.writeInfoJson( doc.id , info );

            final ImageJson image = persistManager.readImageJson( doc.id );
            image.width = target.width;
            image.height = target.height;
            image.maxLevel = ( int ) Math.floor( Math.log( 1.0 * target.width / ImageGenerator.TEXTURE_SIZE ) / Math.log( 2 ) );
            persistManager.writeImageInfoJson( doc.id , image );

            parseText( null , page , doc.id );
        }

        private void procDocument() {
            LOGGER.info( "Begin UploadTask#procDocument" );

            final String tempPdfPath = saveAsPdf( doc.getFileName() , tempPath , doc.id );

            LOGGER.info( "saveAsPdf done" );

            try {
                pdfAnnotationParser.checkCanParse( tempPdfPath );
            } catch ( final MalformedPDFException e ) {
                progressManager.setError( doc.id , ErrorType.MALFORMED );

                throw new RuntimeException( e );
            } catch ( final EncryptedPDFException e ) {
                progressManager.setError( doc.id , ErrorType.ENCRYPTED );

                throw new RuntimeException( e );
            }

            LOGGER.info( "checkCanParse done" );

            {
                int page = 0;
                for ( final List< PageAnnotationInfo > anno : pdfAnnotationParser.parse( tempPdfPath ) ) {
                    persistManager.writeImageAnnotationJson( doc.id , page++ , anno );
                }
            }

            final String cleanedPath = FilenameUtils.getFullPathNoEndSeparator( tempPdfPath ) + File.separator + "cleaned" + doc.id + ".pdf";
            pdfAnnotationParser.clean( tempPdfPath , cleanedPath );

            LOGGER.info( "clean done" );

            progressManager.setTotalThumbnail( doc.id , imageGenerator.getPages( cleanedPath ) );
            progressManager.setStep( doc.id , Step.CREATING_THUMBNAIL );

            final PDFInfo res = imageGenerator.createFromPDF( cleanedPath , doc.id , isWebp );

            LOGGER.info( "createFromPDF done" );

            final InfoJson info = persistManager.readInfoJson( doc.id );
            info.pages = res.pages;
            persistManager.writeInfoJson( doc.id , info );

            final ImageJson image = persistManager.readImageJson( doc.id );
            image.width = res.width;
            image.height = res.height;
            image.maxLevel = ( int ) Math.floor( Math.log( 1.0 * res.width / ImageGenerator.TEXTURE_SIZE ) / Math.log( 2 ) );
            persistManager.writeImageInfoJson( doc.id , image );

            parseText( cleanedPath , res.pages , doc.id );

            LOGGER.info( "End UploadTask#procDocument" );
        }

        @Override
        public void run() {
            try {
                final long t = System.currentTimeMillis();
                LOGGER.info( "Begin UploadTask" );

                progressManager.setStep( doc.id , Step.INITIALIZING );

                FileUtils.copyFile( new File( tempPath ) , new File( repositoryPathManager.getRawPath( doc.id ) ) );

                LOGGER.info( "Copy uploaded file to raw" );

                new File( repositoryPathManager.getImageDirPath( doc.id ) ).mkdirs();

                if ( FilenameUtils.getExtension( doc.getFileName() ).equals( "zip" ) ) {
                    procArchive();
                } else {
                    procDocument();
                }

                doc.processing = false;
                documentDao.update( doc );
                progressManager.clearCompleted( doc.id );

                LOGGER.info( "End UploadTask. Tooks " + ( System.currentTimeMillis() - t ) + "ms" );
            } catch ( final Exception e ) {
                progressManager.clearCompleted( doc.id );

                throw new RuntimeException( e );
            }
        }

        private String saveAsPdf( final String path , final String tempPath , final long documentId ) {
            try {
                if ( FilenameUtils.getExtension( path ).equals( "pdf" ) ) {
                    return tempPath;
                } else {
                    final String tempDir = FilenameUtils.getFullPathNoEndSeparator( tempPath );
                    final String tempPdfPath = tempDir + File.separator + "temp" + documentId + ".pdf";
                    converter.convert( new File( tempPath ) , new File( tempPdfPath ) );
                    return tempPdfPath;
                }
            } catch ( final OpenOfficeException e ) {
                // currently, unnecessary code though...
                if ( e.getCause() instanceof ErrorCodeIOException ) {
                    throw new UnsupportedFormatException();
                } else {
                    throw e;
                }
            }
        }
    }

    private static final Logger LOGGER = LoggerFactory.getLogger( UploadProcessor.class );

    @Autowired
    private ImageGenerator imageGenerator;
    @Autowired
    private DocumentConverter converter;
    @Autowired
    private PropBean prop;
    @Autowired
    private DocumentDao documentDao;
    @Autowired
    private RepositoryPathManager repositoryPathManager;
    @Autowired
    private PersistManager persistManager;
    @Autowired
    private PDFTextParser pdfTextParser;
    @Autowired
    private PDFAnnotationParser pdfAnnotationParser;
    @Autowired
    private TaskExecutor taskExecutor;
    @Autowired
    private ProgressManager progressManager;

    public void proc( final String tempPath , final Document doc , final int pageLimit ) {
        taskExecutor.execute( new UploadTask( tempPath , doc , false , pageLimit ) );
    }

    public void procSync( final String tempPath , final Document doc , final boolean isWebp , final int pageLimit ) {
        new UploadTask( tempPath , doc , isWebp , pageLimit ).run();
    }
}
