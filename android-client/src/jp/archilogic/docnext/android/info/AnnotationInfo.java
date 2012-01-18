package jp.archilogic.docnext.android.info;

import java.math.BigDecimal;
import java.util.Map;
import android.graphics.RectF;

public class AnnotationInfo {
    public Map< String , ? > action;
    public String actionName;
    public Integer page;
    public String uri;
    public String target;

    public RectF region;

    @SuppressWarnings({ "unchecked" , "rawtypes" })
    public AnnotationInfo(Map< String , ? > annotation) {
        action = ( Map ) annotation.get( "action" );
        actionName = ( String ) action.get( "action" );

        if ( actionName.equals( "GoToPage" ) ) {
            page = ( ( BigDecimal ) action.get( "page" ) ).intValue();
        } else if ( actionName.equals( "URI" ) ) {
            uri = ( String ) action.get( "uri" );
        } else if ( actionName.equals( "Movie" ) ) {
            target = ( String ) action.get( "target" );
        }

        Map< String , BigDecimal > rectMap = ( Map< String , BigDecimal > ) annotation.get( "region" );

        region = new RectF();
        region.left = ( float ) rectMap.get( "x" ).doubleValue();
        region.top = ( float ) rectMap.get( "y" ).doubleValue();
        region.right = ( float ) ( region.left + rectMap.get( "width" ).doubleValue() );
        region.bottom = ( float ) ( region.top + rectMap.get( "height" ).doubleValue() );
    }
}
