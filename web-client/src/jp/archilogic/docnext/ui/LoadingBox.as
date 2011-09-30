package jp.archilogic.docnext.ui {
    import mx.containers.Box;
    import mx.controls.Label;

    public class LoadingBox extends Box {
        public function LoadingBox( total : uint ) {
            super();

            _total = total;

            setStyle( 'backgroundColor' , 0xff0000 );

            _label = new Label();
            _label.setStyle( 'color' , 0xffffff );
            addChild( _label );
        }

        private var _label : Label;

        private var _total : uint;

        public function set current( value : uint ) : void {
            _label.text = value + '/' + _total;
        }
    }
}