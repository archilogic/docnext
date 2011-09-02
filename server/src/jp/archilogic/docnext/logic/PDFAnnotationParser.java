package jp.archilogic.docnext.logic;

import java.io.IOException;
import java.util.List;

import jp.archilogic.docnext.dto.Region;
import jp.archilogic.docnext.exception.EncryptedPDFException;
import jp.archilogic.docnext.exception.MalformedPDFException;

import org.apache.pdfbox.exceptions.COSVisitorException;
import org.apache.pdfbox.exceptions.CryptographyException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.encryption.BadSecurityHandlerException;
import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDAction;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDActionGoTo;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDActionURI;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotation;
import org.apache.pdfbox.pdmodel.interactive.annotation.PDAnnotationLink;
import org.apache.pdfbox.pdmodel.interactive.documentnavigation.destination.PDDestination;
import org.apache.pdfbox.pdmodel.interactive.documentnavigation.destination.PDNamedDestination;
import org.apache.pdfbox.pdmodel.interactive.documentnavigation.destination.PDPageDestination;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.google.common.collect.Lists;

@Component
public class PDFAnnotationParser {
    interface Action {
    }

    class GoToPageAction implements Action {
        public String action = "GoToPage";
        public int page;

        GoToPageAction( final int page ) {
            this.page = page;
        }
    }

    class PageAnnotationInfo {
        public Region region;
        public Action action;

        public PageAnnotationInfo( final Region region , final Action action ) {
            this.region = region;
            this.action = action;
        }
    }

    class URIAction implements Action {
        public String action = "URI";
        public String uri;

        URIAction( final String uri ) {
            this.uri = uri;
        }
    }

    private static final Logger LOGGER = LoggerFactory.getLogger( PDFAnnotationParser.class );

    public void checkCanParse( final String src ) throws MalformedPDFException , EncryptedPDFException {
        try {
            final PDDocument document = PDDocument.load( src );

            if ( document.isEncrypted() ) {
                document.openProtection( new StandardDecryptionMaterial( null ) );
            }
        } catch ( final IOException e ) {
            throw new MalformedPDFException( e );
        } catch ( final BadSecurityHandlerException e ) {
            throw new RuntimeException( e );
        } catch ( final CryptographyException e ) {
            throw new EncryptedPDFException();
        }
    }

    public void clean( final String src , final String dst ) {
        try {
            final PDDocument document = PDDocument.load( src );

            if ( document.isEncrypted() ) {
                document.openProtection( new StandardDecryptionMaterial( null ) );
                document.setAllSecurityToBeRemoved( true );
            }

            final List< ? > allPages = document.getDocumentCatalog().getAllPages();
            for ( int i = 0 ; i < allPages.size() ; i++ ) {
                final PDPage page = ( PDPage ) allPages.get( i );

                page.setAnnotations( Lists.newArrayList() );
            }

            document.save( dst );
            document.close();
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } catch ( final COSVisitorException e ) {
            throw new RuntimeException( e );
        } catch ( final BadSecurityHandlerException e ) {
            throw new RuntimeException( e );
        } catch ( final CryptographyException e ) {
            throw new RuntimeException( e );
        }
    }

    private Region convertToRegion( final PDAnnotation anno , final PDPage page ) {
        final PDRectangle rect = anno.getRectangle();
        final PDRectangle crop = page.findCropBox();
        final PDRectangle media = page.findMediaBox();

        final PDRectangle container = crop.getWidth() < media.getWidth() ? crop : media;

        final float w = container.getWidth();
        final float h = container.getHeight();

        return new Region( ( rect.getLowerLeftX() - container.getLowerLeftX() ) / w , ( h - ( rect.getUpperRightY() - container.getLowerLeftY() ) )
                / h , rect.getWidth() / w , rect.getHeight() / h );
    }

    @SuppressWarnings( "unchecked" )
    private List< PageAnnotationInfo > getAnnotations( final PDPage page ) throws IOException {
        final List< PageAnnotationInfo > ret = Lists.newArrayList();

        for ( final PDAnnotation anno : ( List< PDAnnotation > ) page.getAnnotations() ) {
            if ( anno instanceof PDAnnotationLink ) {
                final PDAction action = ( ( PDAnnotationLink ) anno ).getAction();

                if ( action instanceof PDActionGoTo ) {
                    final PDDestination dest = ( ( PDActionGoTo ) action ).getDestination();

                    if ( dest instanceof PDNamedDestination ) {
                        LOGGER.info( "PDNamedDestination is not supported" );
                    } else if ( dest instanceof PDPageDestination ) {
                        ret.add( new PageAnnotationInfo( convertToRegion( anno , page ) , new GoToPageAction( ( ( PDPageDestination ) dest )
                                .findPageNumber() ) ) );
                    } else {
                        LOGGER.info( "Unsupported PDDestination: " + nsGetClassName( dest ) );
                    }
                } else if ( action instanceof PDActionURI ) {
                    ret.add( new PageAnnotationInfo( convertToRegion( anno , page ) , new URIAction( ( ( PDActionURI ) action ).getURI() ) ) );
                } else {
                    LOGGER.info( "Unsupported PDActionGoto: " + nsGetClassName( action ) );
                }
            } else {
                LOGGER.info( "Unsupported PDAnnotation: " + nsGetClassName( anno ) );
            }
        }

        return ret;
    }

    private String nsGetClassName( final Object object ) {
        return object != null ? object.getClass().toString() : "(null)";
    }

    public List< List< PageAnnotationInfo >> parse( final String src ) {
        try {
            final PDDocument document = PDDocument.load( src );
            if ( document.isEncrypted() ) {
                document.openProtection( new StandardDecryptionMaterial( null ) );
            }

            final List< List< PageAnnotationInfo >> ret = Lists.newArrayList();

            final List< ? > allPages = document.getDocumentCatalog().getAllPages();
            for ( int i = 0 ; i < allPages.size() ; i++ ) {
                ret.add( getAnnotations( ( PDPage ) allPages.get( i ) ) );
            }

            document.close();

            return ret;
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } catch ( final BadSecurityHandlerException e ) {
            throw new RuntimeException( e );
        } catch ( final CryptographyException e ) {
            throw new RuntimeException( e );
        }
    }
}
