package jp.archilogic.docnext.controller;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import jp.archilogic.docnext.bean.PropBean;
import jp.archilogic.docnext.dao.DocumentDao;
import jp.archilogic.docnext.entity.Document;
import jp.archilogic.docnext.logic.PersistManager;
import jp.archilogic.docnext.logic.PersistManager.ImageJson;
import jp.archilogic.docnext.logic.PersistManager.InfoJson;
import jp.archilogic.docnext.logic.ProgressManager;
import jp.archilogic.docnext.logic.ProgressManager.Step;
import jp.archilogic.docnext.logic.UploadProcessor;
import jp.archilogic.docnext.type.DocumentType;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import com.google.common.collect.Lists;

@Controller
public class AdminController {
    private static final Logger LOGGER = LoggerFactory.getLogger( AdminController.class );

    @Autowired
    private DocumentDao documentDao;
    @Autowired
    private PropBean prop;
    @Autowired
    private UploadProcessor uploadProcessor;
    @Autowired
    private ProgressManager progressManager;
    @Autowired
    private PersistManager persistManager;

    private String doBatch( final boolean isWebp ) {
        int nFiles = 0;
        int nSucceeded = 0;

        for ( final File file : new File( prop.batchTargetDir ).listFiles() ) {
            nFiles++;

            try {
                final Document doc = new Document();
                doc.setName( file.getName() );
                doc.setFileName( file.getName() );
                doc.processing = true;

                documentDao.create( doc );

                persistManager.writeInfoJson( doc.id , new InfoJson( doc.id , Lists.newArrayList( DocumentType.IMAGE ) ) );

                persistManager.writeImageInfoJson( doc.id , new ImageJson( -1 , -1 , -1 , -1 , false , isWebp ) );

                final String path = prop.tmp + doc.id + File.separator + "uploaded" + doc.id + "." + FilenameUtils.getExtension( file.getName() );
                FileUtils.copyFile( file , new File( path ) );

                uploadProcessor.procSync( path , doc , isWebp );

                tryMoveAndRename( file , new File( prop.batchCompleteDir , file.getName() ) );

                final BufferedWriter writer = new BufferedWriter( new FileWriter( prop.batchCompleteDir + "result.tsv" , true ) );
                writer.append( FilenameUtils.getBaseName( file.getName() ) + "\t" + doc.id + "\n" );
                IOUtils.closeQuietly( writer );

                nSucceeded++;
            } catch ( final Exception e ) {
                try {
                    LOGGER.warn( "Document conversion failed for " + file.getName() , e );

                    final String logPath = prop.batchCompleteDir + FilenameUtils.getBaseName( file.getName() ) + ".error.log";

                    final PrintWriter writer = new PrintWriter( logPath );
                    e.printStackTrace( writer );
                    IOUtils.closeQuietly( writer );
                } catch ( final FileNotFoundException ee ) {
                    throw new RuntimeException( ee );
                }
            }
        }

        if ( nSucceeded < nFiles ) {
            return String.format( "Document conversion finished. %d file(s) failed in %d file(s) " , nFiles - nSucceeded , nFiles );
        } else {
            return String.format( "Document conversion finished. No files failed in %d file(s) " , nSucceeded , nFiles );
        }
    }

    @RequestMapping( "/admin/getProgress" )
    @ResponseBody
    public String getProgress( @RequestParam( "id" ) final long id ) {
        return progressManager.getProgressJSON( id );
    }

    @RequestMapping( "/admin/invokeBatch" )
    @ResponseBody
    public String invokeBatch( @RequestParam( "isWebp" ) final boolean isWebp ) {
        return doBatch( isWebp );
    }

    private String procUpload( final String name , final MultipartFile file , final int actualWidth ) throws IOException {
        final Document doc = new Document();
        doc.setName( name );
        doc.setFileName( file.getOriginalFilename() );
        doc.processing = true;

        documentDao.create( doc );

        persistManager.writeInfoJson( doc.id , new InfoJson( doc.id , Lists.newArrayList( DocumentType.IMAGE ) ) );
        persistManager.writeImageInfoJson( doc.id , new ImageJson( -1 , -1 , -1 , actualWidth , false , false ) );

        final String path = prop.tmp + doc.id + File.separator + "uploaded" + doc.id + "." + FilenameUtils.getExtension( file.getOriginalFilename() );
        FileUtils.writeByteArrayToFile( new File( path ) , file.getBytes() );

        uploadProcessor.proc( path , doc );

        progressManager.setStep( doc.id , Step.WAITING_EXEC );

        return String.valueOf( doc.id );
    }

    private void tryMoveAndRename( final File src , final File dst ) throws IOException {
        File renamed = new File( dst.getAbsolutePath() );

        while ( renamed.exists() ) {
            renamed = new File( renamed.getAbsolutePath() + "_" );
        }

        FileUtils.moveFile( src , renamed );
    }

    @RequestMapping( "/admin/upload" )
    @ResponseBody
    public String upload( @RequestParam( "name" ) final String name , @RequestParam( "file" ) final MultipartFile file ,
            @RequestParam( "actualWidth" ) final int actualWidth ) throws IOException {
        return procUpload( name , file , actualWidth );
    }
}
