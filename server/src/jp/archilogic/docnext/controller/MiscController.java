package jp.archilogic.docnext.controller;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;

import jp.archilogic.docnext.logic.RepositoryPathManager;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class MiscController {
    @Autowired
    private RepositoryPathManager repositoryPathManager;

    @RequestMapping( "/misc/doConcat" )
    @ResponseBody
    public String doConcat( @RequestParam( "id" ) final long id ) {
        try {
            final File dir = new File( repositoryPathManager.getImageDirPath( id ) );

            for ( int page = 0 ; ; page++ ) {
                if ( new File( repositoryPathManager.getImagePath( id , page , 0 , 0 , 0 , true ) ).exists() ) {
                    runConcat( id , dir , page , true );
                } else if ( new File( repositoryPathManager.getImagePath( id , page , 0 , 0 , 0 , false ) ).exists() ) {
                    runConcat( id , dir , page , false );
                } else {
                    break;
                }
            }

            return "done";
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private void runConcat( final long id , final File dir , final int page , final boolean isWebp ) throws IOException {
        for ( int level = 0 ; ; level++ ) {
            if ( !new File( repositoryPathManager.getImagePath( id , page , level , 0 , 0 , isWebp ) ).exists() ) {
                break;
            }

            final OutputStream os = FileUtils.openOutputStream( new File( dir , String.format( "texture-%d-%d.concat" , page , level ) ) );

            for ( int py = 0 ; ; py++ ) {
                if ( !new File( repositoryPathManager.getImagePath( id , page , level , 0 , py , isWebp ) ).exists() ) {
                    break;
                }
                for ( int px = 0 ; ; px++ ) {
                    final File file = new File( repositoryPathManager.getImagePath( id , page , level , px , py , isWebp ) );

                    if ( !file.exists() ) {
                        break;
                    }

                    os.write( ByteBuffer.allocate( Long.SIZE / 8 ).putLong( file.length() ).array() );

                    final InputStream is = FileUtils.openInputStream( file );
                    IOUtils.copy( is , os );
                    IOUtils.closeQuietly( is );
                }
            }

            IOUtils.closeQuietly( os );
        }
    }
}
