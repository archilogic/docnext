package jp.archilogic.docnext.logic;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.DoubleBuffer;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import jp.archilogic.docnext.dto.Region;
import jp.archilogic.docnext.dto.TOCElem;
import jp.archilogic.docnext.logic.PDFAnnotationParser.PageAnnotationInfo;
import jp.archilogic.docnext.type.BindingType;
import jp.archilogic.docnext.type.DocumentType;
import jp.archilogic.docnext.type.FlowDirectionType;
import jp.archilogic.docnext.util.CustomJSON;
import net.arnx.jsonic.JSON;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.google.common.collect.Lists;

@Component
public class PersistManager {
    public static class ImageJson {
        public int width;
        public int height;
        public int maxLevel;
        @Deprecated
        public int actualWidth;
        public boolean isUseActualSize;
        public int maxNumberOfLevel;
        public boolean isWebp;
        public boolean hasAnnotation = true;

        // for JSONIC
        public ImageJson() {
        }

        public ImageJson( final int width , final int height , final int maxLevel , final int actualWidth , final boolean isUseActualSize ,
                final boolean isWebp ) {
            this.width = width;
            this.height = height;
            this.maxLevel = maxLevel;
            this.actualWidth = actualWidth;
            this.isUseActualSize = isUseActualSize;
            maxNumberOfLevel = 3;
            this.isWebp = isWebp;
        }
    }

    public static class InfoJson {
        public long id;
        public List< DocumentType > types;
        public int pages;
        public List< Integer > singlePages;
        public List< TOCElem > toc;
        public String title;
        public String publisher;
        // This parameters should be here?
        public BindingType binding;
        public FlowDirectionType flow;
        public int version = 1;

        // public Long[] ids; // for multiple documents

        // for JSONIC
        public InfoJson() {
        }

        public InfoJson( final long id , final List< DocumentType > types ) {
            this.id = id;
            this.types = types;
            pages = -1;
            singlePages = Lists.newArrayList();
            toc = Lists.newArrayList();
            title = "NO TITLE";
            publisher = "NO PUBLISHER";
            binding = BindingType.RIGHT;
            flow = FlowDirectionType.TO_LEFT;
        }

        public InfoJson( final long id , final List< DocumentType > types , final int pages , final List< Integer > singlePages ,
                final List< TOCElem > toc , final String title , final String publisher , final BindingType binding , final FlowDirectionType flow ) {
            this.id = id;
            this.types = types;
            this.pages = pages;
            this.singlePages = singlePages;
            this.toc = toc;
            this.title = title;
            this.publisher = publisher;
            this.binding = binding;
            this.flow = flow;
        }
    }

    public static class TextJson {
        public List< String > fonts;

        // for JSONIC
        public TextJson() {
        }
    }

    @Autowired
    private RepositoryPathManager repositoryPathManager;

    private void pack( final String src , final String dst ) {
        try {
            final ZipOutputStream zos = new ZipOutputStream( FileUtils.openOutputStream( new File( dst ) ) );
            packHelper( zos , new File[] { new File( src ) } , src.length() );
            IOUtils.closeQuietly( zos );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private void packHelper( final ZipOutputStream zos , final File[] files , final int prefixLen ) throws IOException {
        for ( final File f : files ) {
            if ( f.isDirectory() ) {
                packHelper( zos , f.listFiles() , prefixLen );
            } else {
                zos.putNextEntry( new ZipEntry( f.getPath().substring( prefixLen ).replace( '\\' , '/' ) ) );

                final InputStream is = new BufferedInputStream( FileUtils.openInputStream( f ) );
                for ( final byte[] buf = new byte[ 1024 ] ; ; ) {
                    final int len = is.read( buf );

                    if ( len < 0 ) {
                        break;
                    }

                    zos.write( buf , 0 , len );
                }
                IOUtils.closeQuietly( is );

                zos.closeEntry();
            }
        }
    }

    public void packImageTextIndex( final long id , final String src ) {
        pack( src , repositoryPathManager.getImageTextIndexPath( id ) );
    }

    public ImageJson readImageJson( final long id ) {
        return readJson( repositoryPathManager.getImageJsonPath( id ) , ImageJson.class );
    }

    public InfoJson readInfoJson( final long id ) {
        return readJson( repositoryPathManager.getInfoJsonPath( id ) , InfoJson.class );
    }

    private < T > T readJson( final String path , final Class< T > clazz ) {
        try {
            JSON.prototype = CustomJSON.class;

            return JSON.decode( FileUtils.readFileToString( new File( path ) ) , clazz );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public void writeImageAnnotationJson( final long id , final int page , final List< PageAnnotationInfo > annotation ) {
        writeJson( repositoryPathManager.getImageAnnotationPath( id , page ) , annotation );
    }

    public void writeImageInfoJson( final long id , final ImageJson json ) {
        writeJson( repositoryPathManager.getImageJsonPath( id ) , json );
    }

    public void writeImageTextRegions( final long id , final int page , final List< Region > regions ) {
        final int SIZEOF_DOUBLE = 8;
        final int N_REGION_FIELDS = 4;

        try {
            final ByteBuffer buffer = ByteBuffer.allocate( regions.size() * N_REGION_FIELDS * SIZEOF_DOUBLE );
            buffer.order( ByteOrder.LITTLE_ENDIAN );

            final DoubleBuffer db = buffer.asDoubleBuffer();
            for ( final Region region : regions ) {
                db.put( region.x );
                db.put( region.y );
                db.put( region.width );
                db.put( region.height );
            }

            FileUtils.writeByteArrayToFile( new File( repositoryPathManager.getImageTextRegionsPath( id , page ) ) , buffer.array() );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public void writeInfoJson( final long id , final InfoJson json ) {
        writeJson( repositoryPathManager.getInfoJsonPath( id ) , json );
    }

    private void writeJson( final String path , final Object json ) {
        try {
            JSON.prototype = CustomJSON.class;

            FileUtils.writeStringToFile( new File( path ) , JSON.encode( json ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }
}
