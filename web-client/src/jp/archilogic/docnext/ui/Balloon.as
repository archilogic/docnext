package jp.archilogic.docnext.ui {
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import mx.core.UIComponent;

    public class Balloon extends UIComponent {
        private static const CORNER_RAD : Number = 10;
        private static const MAX_WIDTH : Number = 600;
        private static const TIP_SIZE : Number = 10;

        public function Balloon( text : String ) {
            super();

            var format : TextFormat = new TextFormat();
            format.size = 16;

            _textField = new TextField();
            _textField.x = CORNER_RAD;
            _textField.y = CORNER_RAD;
            _textField.autoSize = TextFieldAutoSize.LEFT;
            _textField.defaultTextFormat = format;
            _textField.text = text;
            addChild( _textField );

            drawBackground();
        }

        private var _parentTip : Point;
        private var _textField : TextField;
        private var _tip : Point;

        public function adjust( parentScale : Number ) : void {
            var scale : Number = 1.0 / parentScale;
            scaleX = scaleY = scale;

            x = _parentTip.x - _tip.x * scale;
            y = _parentTip.y - _tip.y * scale;
        }

        public function set parentTip( value : Point ) : * {
            _parentTip = value;
        }

        public function get text() : String {
            return _textField.text;
        }

        private function drawBackground() : void {
            graphics.clear();

            graphics.beginFill( 0xff8040 );
            graphics.lineStyle( 1 , 0x808080 , 1 , true );
            drawBorder();
            graphics.endFill();

            super.updateDisplayList( unscaledWidth , unscaledHeight );
        }

        private function drawBorder() : void {
            var w : Number = _textField.textWidth + CORNER_RAD * 2;
            var h : Number = _textField.textHeight + CORNER_RAD * 2;

            graphics.moveTo( CORNER_RAD , 0 );

            graphics.lineTo( w - CORNER_RAD , 0 );
            graphics.curveTo( w , 0 , w , CORNER_RAD );

            graphics.lineTo( w , h - CORNER_RAD );
            graphics.curveTo( w , h , w - CORNER_RAD , h );

            graphics.lineTo( w / 2 + TIP_SIZE , h );
            graphics.lineTo( w / 2 , h + TIP_SIZE );
            _tip = new Point( w / 2 , h + TIP_SIZE );
            graphics.lineTo( w / 2 - TIP_SIZE , h );

            graphics.lineTo( CORNER_RAD , h );
            graphics.curveTo( 0 , h , 0 , h - CORNER_RAD );

            graphics.lineTo( 0 , CORNER_RAD );
            graphics.curveTo( 0 , 0 , CORNER_RAD , 0 );
        }
    }
}
