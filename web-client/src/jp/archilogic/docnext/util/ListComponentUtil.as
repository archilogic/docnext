package jp.archilogic.docnext.util {
    import mx.controls.ComboBox;

    public class ListComponentUtil {
        public static function setComboBoxFromProperty( comboBox : ComboBox , key : Object , value : Object ) : void {
            for each ( var item : Object in comboBox.dataProvider ) {
                if ( item[ key ] == value ) {
                    comboBox.selectedItem = item;
                    break;
                }
            }
        }

        public static function setComboBoxFromValue( comboBox : ComboBox , value : Object ) : void {
            setComboBoxFromProperty( comboBox , 'value' , value );
        }
    }
}