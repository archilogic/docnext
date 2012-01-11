package jp.archilogic.docnext.controller;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jp.archilogic.docnext.logic.RepositoryPathManager;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class ViewerController {
    @Autowired
    private RepositoryPathManager repositoryPathManager;

    @RequestMapping( "/static/docnext_p/{id}/{path0}" )
    public void handleConcat1( @RequestParam( value = "names" , required = false ) final String names , final HttpServletRequest req ,
            final HttpServletResponse res ) {
        if ( names == null ) {
            outFile( new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/docnext_p/".length() ) ) , res );
        } else {
            try {
                final File dir =
                        new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/docnext_p/".length() ) );
                for ( final String name : names.split( "," ) ) {
                    final File file = new File( dir , name );
                    res.getOutputStream().write( ByteBuffer.allocate( Long.SIZE / 8 ).putLong( file.length() ).array() );
                    outFile( file , res );
                }
            } catch ( final IOException e ) {
                throw new RuntimeException( e );
            }
        }
    }

    @RequestMapping( "/static/docnext_p/{id}/{path0}/{path1}" )
    public void handleConcat2( @RequestParam( value = "names" , required = false ) final String names , final HttpServletRequest req ,
            final HttpServletResponse res ) {
        if ( names == null ) {
            outFile( new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/docnext_p/".length() ) ) , res );
        } else {
            try {
                final File dir =
                        new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/docnext_p/".length() ) );
                for ( final String name : names.split( "," ) ) {
                    final File file = new File( dir , name );
                    res.getOutputStream().write( ByteBuffer.allocate( Long.SIZE / 8 ).putLong( file.length() ).array() );
                    outFile( file , res );
                }
            } catch ( final IOException e ) {
                throw new RuntimeException( e );
            }
        }
    }

    @RequestMapping( "/static/{id}/{path0}" )
    public void handleStatic1( final HttpServletRequest req , final HttpServletResponse res ) {
        outFile( new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/".length() ) ) , res );
    }

    @RequestMapping( "/static/{id}/{path0}/{path1}" )
    public void handleStatic2( final HttpServletRequest req , final HttpServletResponse res ) {
        outFile( new File( repositoryPathManager.getDocumentRootDirPath() , req.getPathInfo().substring( "/static/".length() ) ) , res );
    }

    private void outFile( final File file , final HttpServletResponse res ) {
        try {
            InputStream in = null;

            try {
                in = FileUtils.openInputStream( file );

                IOUtils.copy( in , res.getOutputStream() );
            } finally {
                IOUtils.closeQuietly( in );
            }
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }
}
