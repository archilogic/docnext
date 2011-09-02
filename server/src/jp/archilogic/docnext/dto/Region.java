package jp.archilogic.docnext.dto;
public class Region {
    public double x;
    public double y;
    public double width;
    public double height;

    public Region( double x , double y , double width , double height ) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    @Override
    public String toString() {
        return String.format( "Region[%f,%f,%f,%f]" , x , y , width , height );
    }
}
