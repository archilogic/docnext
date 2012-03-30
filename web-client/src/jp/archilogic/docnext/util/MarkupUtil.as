package jp.archilogic.docnext.util {

    public class MarkupUtil {
        public static function insertAnchor( text : String , blank : Boolean = true ) : String {
            return text.replace( /https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:@&=+$,%#]+/g ,
                                 "<font color='#005add'><u><a href='$&'" + ( blank ? " target='_blank'" : '' ) + ">$&</a></u></font>" );
        }
    }
}
