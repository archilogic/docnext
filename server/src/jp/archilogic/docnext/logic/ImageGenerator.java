package jp.archilogic.docnext.logic;

import java.io.File;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import jp.archilogic.docnext.bean.PropBean;
import jp.archilogic.docnext.util.ProcUtil;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class ImageGenerator {
    static class PDFInfo {
        int pages;
        int width;
        int height;
    }

    public static final int TEXTURE_SIZE = 512;

    private static final Logger LOGGER = LoggerFactory.getLogger( ImageGenerator.class );

    private static final int PDF_RESOLUTION = 300;

    @Autowired
    private PropBean prop;
    @Autowired
    private ProgressManager progressManager;
    @Autowired
    private RepositoryPathManager repositoryPathManager;

    private void createByResolution( final String pdfPath , final String prefix , final int page , final int resolution ) {
        ProcUtil.doProc(
                String.format( "%s -r %d -f %d -l %d -cropbox %s %s" , prop.pdfToPpm , resolution , page + 1 , page + 1 , pdfPath , prefix ) , true );
    }

    public void createFromImage( final String imagePath , final long id , final int page , final boolean isUseActualSize , final int targetWidth ,
            final int targetHeight , final boolean doCrop , final boolean isWebp ) {
        LOGGER.info( "Begin create from image" );
        final long t = System.currentTimeMillis();

        LOGGER.info( "Proc page: " + page );

        if ( prop.forTexture ) {
            ProcUtil.doProc( String.format( "%s %s %s %d %s %d %d %s %s" , prop.dnconv , imagePath , repositoryPathManager.getImageDirPath( id ) ,
                    page , isUseActualSize ? "true" : "false" , targetWidth , targetHeight , doCrop ? "true" : "false" , isWebp ? "true" : "false" ) );
        }

        progressManager.setCreatedThumbnail( id , page + 1 );

        LOGGER.info( "End create from image. Tooks " + ( System.currentTimeMillis() - t ) + "(ms)" );
    }

    public PDFInfo createFromPDF( final String pdfPath , final long id , final boolean isWebp ) {
        final int N_SKIP = 4;

        final PDFInfo pdf = new PDFInfo();

        // temp pages
        pdf.pages = getPages( pdfPath );

        final String prefix = prop.tmp + Long.toString( id );

        for ( int page = 0 ; page < pdf.pages ; page++ ) {
            createByResolution( pdfPath , prefix , page , PDF_RESOLUTION );
        }

        if ( pdf.pages > N_SKIP * 2 ) {
            pdf.width = Integer.MIN_VALUE;
            pdf.height = Integer.MIN_VALUE;

            for ( int page = N_SKIP ; page < pdf.pages - N_SKIP ; page++ ) {
                final int[] size = getImageSize( getPpmPath( prefix , page ) );

                pdf.width = Math.max( pdf.width , size[ 0 ] );
                pdf.height = Math.max( pdf.height , size[ 1 ] );
            }
        } else {
            final int[] size = getImageSize( getPpmPath( prefix , pdf.pages / 2 ) );

            pdf.width = size[ 0 ];
            pdf.height = size[ 1 ];
        }

        for ( int page = 0 ; page < pdf.pages ; page++ ) {
            createFromImage( getPpmPath( prefix , page ) , id , page , false , pdf.width , pdf.height , page == 0 , isWebp );
        }

        return pdf;
    }

    private int[] getImageSize( final String path ) {
        final String[] sizes = ProcUtil.doProc( String.format( "%s -ping %s" , prop.identify , path ) ).split( " " )[ 2 ].split( "x" );
        return new int[] { Integer.parseInt( sizes[ 0 ] ) , Integer.parseInt( sizes[ 1 ] ) };
    }

    public int getPages( final String pdfPath ) {
        final Matcher matcher =
                Pattern.compile( "Pages: +([0-9]+)" ).matcher( ProcUtil.doProc( String.format( "%s %s" , prop.pdfInfo , pdfPath ) , true ) );

        if ( !matcher.find() ) {
            throw new RuntimeException( "No pages found" );
        }

        return Integer.parseInt( matcher.group( 1 ) );
    }

    private String getPpmPath( final String prefix , final int page ) {
        for ( final String digitFormat : new String[] { "06" , "05" , "04" , "03" , "02" , "" } ) {
            final String path = String.format( "%s-%" + digitFormat + "d.ppm" , prefix , page + 1 );

            if ( new File( path ).exists() ) {
                return path;
            }
        }

        throw new RuntimeException( "Could not find ppm file. (prefix: " + prefix + ", page = " + page + ")" );
    }
}
