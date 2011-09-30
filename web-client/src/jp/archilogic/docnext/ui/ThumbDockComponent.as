package jp.archilogic.docnext.ui
{
	import __AS3__.vec.Vector;
	
	import caurina.transitions.Tweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import jp.archilogic.docnext.helper.OverlayHelper;
	import jp.archilogic.docnext.helper.ResizeHelper;
	import jp.archilogic.docnext.util.DocumentLoadUtil;
	
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.HScrollBar;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ScrollEvent;
	public class ThumbDockComponent extends Canvas
	{
		public function ThumbDockComponent() 
		{
			super();
			this._ui = new ThumbDockComponentUI();
			this._ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            this.addChild( _ui );
            this.addEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
		}
		
		private var _ui : ThumbDockComponentUI ;
		private var _documentComponent : DocumentComponent;
		private var _background : Bitmap; 
		/* public static const THUMB_SIZE : int = 256; */
		public static const THUMB_WIDTH : int = 198
		public static const THUMB_HEIGHT : int= 256;
		private static const PADDING_DOCK : int = 30;
        private static const PADDING_UNFOCUS : int = 50;
        private static const SPAN_BROAD : int = 50;
        private static const SPAN_NARROW : int = 30;
        private static const FOCUSED_WIDTH : int = 400;
		private static const FOCUSED_HEIGHT: int = 512;
		private static const FLANKED_WIDTH : int = 200;
		private static const FLANKED_HEIGHT: int = 256;
		private static const NEIGHBOR_WIDTH: int = 100;
		private static const NEIGHBOR_HEIGHT:int = 256 * .5;
		private static const SHELFED_WIDTH  :int = 60;
		private static const SHELFED_HEIGHT :int = 100;
		private var _focusedThumbs : Vector.<Bitmap> = new Vector.<Bitmap>(5);
		private var _thumbnails : Vector.<ThumbnailComponent> = new Vector.<ThumbnailComponent>();
		private var currentTotalThumb : int;
		private var currentUnfocusedTotalThumb : int ;
		private var _currentIndex : int ;
		private var startIndex : int;
		private var _overlayHelper  : OverlayHelper;
		private var totalPage : int ;
		private var thisHeight : int ;
		private var _pages : Vector.<PageComponent>;
        private var clickedPoint : Point = new Point();
        private var isFocusMode : Boolean = true;
        private var timer : Timer = new Timer(500);
       /*  private var _ratio : Number = 0.3;
        private var _docId : int = 2;  */
        private var _ratio : Number ;
        private var _docId : int ;
        private var _flow : Boolean;
        private var _currentDocPos : int;
        private var isCreated : Boolean = false;
        /* private var direction : int = -1; */
       /*  private var _dtos  : Vector.<DocumentResDto>; */
       /*  private var _infos : Vector.<Object>; */
        public function setBackground ( value : Bitmap) : void
        {
        	this._background = value;
        }
       	public function set documentComponent(d : DocumentComponent ) : void {
			this._documentComponent = d;
		}

        public function set flow(flow : Boolean) : void {
            _flow = flow;
        }

        public function getSelectPage() : int {
            return _thumbnails[_currentIndex].page;
        }
       
		public function addEvents() : void
		{
			this._ui.hScrollbar.addEventListener(ScrollEvent.SCROLL, scrollHandler);
			changeFocusMode(true);
			new ResizeHelper( this , resizeHandler );   
		}
		
		private function addToStageHandler( e : Event ) : void 
		{
			
		}
		private function creationCompleteHandler( e : FlexEvent ) : void 
		{
            _ui.removeEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            new ResizeHelper( this , resizeHandler );   
        }
        private function resizeHandler() : void 
        {
        	if(this.visible == false) return;
        	thisHeight = this.height;
        	this._background.width = this.width;
        	this._background.height = this.height;
        	calculateTotalThumb();
        	resetVisible();
        }
        private function scrollHandler( e : ScrollEvent) : void
        {
        	var target : HScrollBar = e.currentTarget as HScrollBar;
        	_currentIndex = target.scrollPosition;
        	resetStartIndex();
        	resetVisible();
        	if(isFocusMode)
        		initDockAlign();
        	else
	        	initUnFocusedDockAlign();
        }
        private function updateScrollBar() : void
        {
        	this._ui.hScrollbar.scrollPosition = _currentIndex;
        	this._ui.hScrollbar.pageSize = isFocusMode ? currentTotalThumb : currentUnfocusedTotalThumb;
        }
        public function showOff() : void
        {
        	this.visible = false;
        	this._ui.hScrollbar.removeEventListener(ScrollEvent.SCROLL, scrollHandler);
			this._ui.wrapper.removeEventListener(MouseEvent.CLICK, mouseClickHandler);
			this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OVER, unFocusedMouseOverHandler);
			this._ui.wrapper.removeEventListener(MouseEvent.CLICK, showDocumentHandler);
			this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OVER,mouseOverHandler);
			this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			timer.removeEventListener(TimerEvent.TIMER, timerHandler);
			/* new ResizeHelper(this, resizeHandler); */
			/* this._ui.wrapper.removeAllChildren(); */
        }
        public function showUp() : void 
        {
        	var hasChanged : Boolean = false;
        	if(  _docId != _documentComponent.docId &&
        	 	  _currentDocPos != _documentComponent.currentDocPos )
        	{
        		hasChanged = true;
        	}
        	this._pages = _documentComponent.pages;
        	/* _background.alpha = 0.8; */
        	var color : ColorTransform = new ColorTransform(0.5,0.5, 0.5,1,0,0,0,0);
        	_background.transform.colorTransform = color;
        	var wrapper : UIComponent = new UIComponent();
        	wrapper.addChildAt(_background, 0);
        	this._ui.scroller.addChildAt(wrapper, 0); 
        	/* this._ui.wrapper.addChildAt(_background, 0); */
        	/* this._ui.scroller.addChild(_background); */
        	/* this._info = _documentComponent.infos; */
        	_ratio = this._documentComponent.ratio;
        	_docId = this._documentComponent.docId;
        	totalPage = _pages.length;
        	_currentDocPos = this._documentComponent.currentDocPos;
        	_currentIndex = _flow ? totalPage - 1 - _documentComponent.getCurrentHead() * 2 : _documentComponent.getCurrentHead() * 2 ; 
        	
        	this._ui.hScrollbar.setScrollProperties(1,0,totalPage-1);
        	/* this._background = _documentComponent */
        	calculateTotalThumb();
        	/*  temp , should be check if the head or id are changed !!!!!!!*/
        	
        	if(hasChanged || !isCreated) 
        		initChildren();
        	changeFocusMode();
        	resetVisible();
        	initDockAlign();
        	loadThumbs(0, totalPage, null );
        	this.isCreated = true;
        }

        private function initChildren() : void {
            var bitmapData : BitmapData = new BitmapData(SHELFED_WIDTH, SHELFED_HEIGHT, false, 0x334433);
            for(var i:int = 0; i < totalPage ; i++) {
                var thumb : ThumbnailComponent = new ThumbnailComponent();
                var page : int = _flow ? totalPage - i - 1 : i;
                thumb.source = new Bitmap(bitmapData);
                thumb.docId = _docId;
                thumb.page = page;
                thumb.width = SHELFED_WIDTH;
                thumb.height = SHELFED_HEIGHT;
                thumb.x = this.width - 30;
                thumb.y = (this.height -SHELFED_HEIGHT)  * 0.5; 
                thumb.visible = false;
                _thumbnails[i] = thumb;
                this._ui.wrapper.addChild(thumb); 
            }
        }

        private function calculateTotalThumb() : void
        {
        	/* var padding : Number = 30;
        	var padding2 : Number = 30; */
        	//var span : Number = isFocusMode ? SPAN_BROAD : SPAN_NARROW;
        	//var imageW : Number = isFocusMode ? FOCUSED_WIDTH : NEIGHBOR_WIDTH;
        	this.currentTotalThumb = (this.width - PADDING_DOCK*2 - FOCUSED_WIDTH + SPAN_BROAD) / SPAN_BROAD;
        	this.currentUnfocusedTotalThumb = (this.width - PADDING_UNFOCUS*2 - NEIGHBOR_WIDTH + SPAN_NARROW) / SPAN_NARROW;
        }
        private function resetStartIndex() : void
        {
        	var currentTotal : int;
        	var lastIndex : int;
        	
        	if(isFocusMode)
        	{
        		currentTotal = currentTotalThumb;
        		/* var padding : Number = 40; */
        		var nextRelativeCurrentIndex : int = Math.round((clickedPoint.x - PADDING_DOCK - FOCUSED_WIDTH*0.5) / SPAN_BROAD);
        		startIndex = _currentIndex - nextRelativeCurrentIndex;
        		/* if(startIndex + currentTotalThumb-1 < _currentIndex ) _currentIndex = startIndex + currentTotalThumb -1; */
        		if(startIndex > _currentIndex -1 ) 
        			startIndex = _currentIndex - 1;
        		lastIndex = startIndex + currentTotal - 1;
        		
        		if( lastIndex < _currentIndex + 1)
        		{
        			lastIndex = _currentIndex + 1;
        			startIndex = lastIndex -currentTotal + 1;
        		}
        		
        		/* lastIndex = startIndex + currentTotalThumb - 1;
        		if(_currentIndex > lastIndex ) 
        			startIndex = lastIndex +1 - currentTotalThumb; */
        			/* startIndex += _currentIndex  - lastIndex;  */
        		/* if((startIndex+currentTotalThumb) > (totalPage -4))
        			startIndex = totalPage - 4 - currentTotalThumb;  */
        		
        	}
        	else
        	{
        		startIndex = _currentIndex - currentUnfocusedTotalThumb * 0.5;
        		currentTotal = currentUnfocusedTotalThumb;
        	}
        	
        	
        	if(startIndex < 0 ) 
        		startIndex = 0;
        	
        	lastIndex = startIndex + currentTotal - 1;
        	if( lastIndex >= totalPage )
        		startIndex = totalPage  - currentTotal;
        	
        	if(startIndex < 0 ) 
                startIndex = 0;
        	/* if((startIndex + currentTotal) > (totalPage - 1) )
        		startIndex = totalPage - 1 - currentTotal; */
        	/* var limit : int = startIndex+currentTotalThumb  + 5 ;
        	if(limit > totalPage) startIndex = totalPage - limit;  */
        	
        }
        private function resetVisible() : void
        {
        	var total : int = this.currentTotalThumb;
        	var h : int = this.height * 0.5;
        	var w : int = this.width - 30;
        	if(!isFocusMode) total = this.currentUnfocusedTotalThumb;
        	
        	var last : int = startIndex + total-1;
        	for(var i:int = 0; i< totalPage ; i++)
        	{
        		if( i < startIndex )
        		{
        			_thumbnails[i].x = 0;
        			_thumbnails[i].visible = false;
        			_thumbnails[i].y = h;
        		}
        		else if( i > last)
        		{
        			_thumbnails[i].x = w ;
        			_thumbnails[i].visible = false;
        			_thumbnails[i].y = h;
        		}
        		else _thumbnails[i].visible = true;
         	}
        }
       
        private function changeFocusMode( isFocused:Boolean = true) : void
		{
			isFocusMode = isFocused;
			if (isFocused)
			{
				this._ui.wrapper.removeEventListener(MouseEvent.CLICK, mouseClickHandler);
				this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OVER, unFocusedMouseOverHandler);
				this._ui.wrapper.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				this._ui.wrapper.addEventListener(MouseEvent.MOUSE_OUT,mouseOutHandler);
				this._ui.wrapper.addEventListener(MouseEvent.CLICK, showDocumentHandler);
				/* hideThumbs(); */
				/* loadThumbs(0, currentTotalThumb, null );  */
				/* loadThumbs(startIndex, startIndex + currentTotalThumb);  */
				resetStartIndex();
				resetVisible();
			}
			else
			{
				/* Alert.show('unfocus mode' ); */
				this._ui.wrapper.removeEventListener(MouseEvent.CLICK, showDocumentHandler);
				this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OVER,mouseOverHandler);
				this._ui.wrapper.removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				this._ui.wrapper.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				this._ui.wrapper.addEventListener(MouseEvent.MOUSE_OVER, unFocusedMouseOverHandler) ;
				/* hideThumbs(); */
				resetStartIndex(); 
				resetVisible();
				/*  loadThumbs(0, currentUnfocusedTotalThumb, null );  */
				/* loadThumbs(startIndex, startIndex + currentUnfocusedTotalThumb);  */
			}
		}
		private function showDocumentHandler( e : MouseEvent ) : void {
			/* _changeDocumentVisiblityHandler(true); */
			_changeThumbDockVisiblityHandler(false);
		}
		private var _changeThumbDockVisiblityHandler : Function;
		
		public function set changeThumbDockVisiblityHandler( value : Function ) : void {
			this._changeThumbDockVisiblityHandler = value;
		}
		private function mouseClickHandler(e:MouseEvent) : void
		{
			clickedPoint.x = mouseX;
			clickedPoint.y = mouseY;
			var target : ThumbnailComponent = e.target as ThumbnailComponent;
			_currentIndex = _thumbnails.indexOf(target);
			changeFocusMode(true);
			initDockAlign();
		}
		
		private function mouseOverHandler(e:MouseEvent) : void
		{
			timer.removeEventListener(TimerEvent.TIMER, timerHandler);
			timer.reset();
			//init former focusImage source
			 _thumbnails[_currentIndex].resetThumbSource(); 
			var target : ThumbnailComponent = e.target as ThumbnailComponent;
			
			_currentIndex = _thumbnails.indexOf(target);
			
			if( _currentIndex == startIndex && startIndex !=0)
        	{
        		//Alert.show('start  '+ _currentIndex);
        		startIndex--;
        		/* loadThumbs(startIndex, startIndex + 1); */
           	} 
           	var last : int = startIndex+currentTotalThumb-1;
           	if( _currentIndex == last && last < (totalPage-1))
           	{
           		startIndex++;
           		/* loadThumbs(last+1, last+2); */
           	}
           	resetVisible();
			initDockAlign();
		}
		private function mouseOutHandler(e:MouseEvent):void
        {
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
			timer.start();
        	/* var target : ThumbnailComponent = e.target as ThumbnailComponent; */
        	/* isMouseOut = true; */
        } 
		private function timerHandler(e : TimerEvent) :void
		{
			timer.removeEventListener(TimerEvent.TIMER, timerHandler);
			timer.reset();
			_thumbnails[_currentIndex].resetThumbSource(); 
			changeFocusMode(false);
			
			initUnFocusedDockAlign(); 
		}
		private function unFocusedMouseOverHandler(e : MouseEvent ) : void
		{
			var target : ThumbnailComponent = e.target as ThumbnailComponent;
			var index : int = _thumbnails.indexOf(target);
			if(_currentIndex == index ) return;
			_currentIndex = index;
			if( _currentIndex == startIndex && startIndex !=0)
        	{
        		startIndex--;
        		/* loadThumbs(startIndex, startIndex + 1); */
           	} 
           	var last : int = startIndex + currentUnfocusedTotalThumb-1;
           	if( _currentIndex == last && last < (totalPage-1))
           	{
           		startIndex++;
           		/* loadThumbs(last+1, last+2); */
           		/* var end : int = last+ currentUnfocusedTotalThumb;
           		if(end > totalPage) 
           			end = totalPage;
           		loadThumbs(last + 1, end); */
           	}
           	resetVisible();
			initUnFocusedDockAlign();
		}
        private function initUnFocusedDockAlign() : void
        {
        	updateScrollBar();
        	_ui.pageLabel.text = (_currentIndex+1) + ' / ' + totalPage;
        	 var startX :Number = 0.5 * (this.width  - (currentUnfocusedTotalThumb-1) * SPAN_NARROW); 
        	 
        	 //Alert.show(currentUnfocusedTotalThumb + " : " + startIndex);
        	 
        	 for( var i:int = 0 ; i < currentUnfocusedTotalThumb && i + startIndex < totalPage ; i++)
        	 {
        	 	var index : int = i+startIndex;
        		var thumb : ThumbnailComponent = _thumbnails[index];
        		var distWidth : Number = SHELFED_WIDTH;
        		var distHeight:Number = SHELFED_HEIGHT;
        		var offset : int =  - _currentIndex + index;
        		var offsetAbsolute :int = Math.abs(offset);
        		var sign : int = 0;
        		if(offset != 0 ) 
        			sign = offset / offsetAbsolute;
        		else
        		{
        			distWidth=NEIGHBOR_WIDTH;
        			distHeight=NEIGHBOR_HEIGHT;
        		}
        	
        		var padding :Number = 0;
        		padding = 70 * sign;
        		var distX :Number =  startX + i * SPAN_NARROW + padding - distWidth*0.5;
        		var distY : Number = (this.height - distHeight )* 0.5;
				
				Tweener.addTween(thumb, { 	x 		: distX,
        									y 		: distY,
											width  	: distWidth,
											height	: distHeight,
											time : 1
										} );
        	} 
        }
        private function initDockAlign():void
        {
        	updateScrollBar();
        	_ui.pageLabel.text = (_currentIndex+1) + ' / ' + totalPage;
        	var startX :Number = 0.5 * (this.width  - (this.currentTotalThumb -1)* SPAN_BROAD);
        	
        	//Alert.show(currentUnfocusedTotalThumb + " : " + startIndex);
        	
        	for( var i:int = 0 ; i < currentTotalThumb && i + startIndex < totalPage ; i++)
        	{
        		var index : int = i + startIndex;
        		var thumb : ThumbnailComponent = _thumbnails[index];
        		var offset : int =  - this._currentIndex + index;
        		var offsetAbsolute : int = Math.abs(offset);
        		var sign : int = 0;
        		if( offset !=0) sign  = offset / offsetAbsolute;
        		
        		var distWidth : Number = SHELFED_WIDTH;
        		var distHeight : Number = SHELFED_HEIGHT;
        		var padding : Number = 0;
        		/* var completeFunc : Function; */
        		if(offsetAbsolute > 2)
        		{
        			padding = 330 * sign;
        		}
        		else if(offsetAbsolute > 1)
        		{
        			padding = 300 * sign;
        			distWidth = NEIGHBOR_WIDTH;
        			distHeight = NEIGHBOR_HEIGHT;
        		}
        		else if(offsetAbsolute == 1) 
        		{
        			padding = 220 * sign;
        			distWidth = FLANKED_WIDTH;
        			distHeight = FLANKED_HEIGHT;
        		}
        		else
        		{
        			padding = 0;
        			distWidth = FOCUSED_WIDTH;
        			distHeight = FOCUSED_HEIGHT;
        			/* completeFunc = loadFocusedImage; */
        		}
        		var distX : Number = startX + i * SPAN_BROAD - distWidth * 0.5 + padding;
        		var distY : Number = (this.height - distHeight )* 0.5;
        		var obj : Object =  { 		x 		: distX,
        									y		: distY,
											width  	: distWidth,
											height	: distHeight,
											time 	: 1.2
									};
				if(offset == 0)
					obj.onComplete = loadFocusedImage;
					
        		
				/* var numRight : int = currentTotalThumb - _currentIndex - 1; */
				/* var numRight : int = totalPage - _currentIndex - 1;
				var num : int = (_currentIndex > numRight )? _currentIndex : numRight; */
				 this._ui.wrapper.addChildAt(thumb, totalPage-1-offsetAbsolute);   
				Tweener.addTween(thumb, obj);
        	}
        	
        }
       
        private function init(w : int, h : int ) :void
        {
        	
        }
        private function loadNeighborThumb() : void
        {
        	
        }
        
        
        private function loadFocusedImage() : void {
           
            _ui.pageLabel.text +=  ' load...';

           var index : int  = _thumbnails.length - 1 - _currentIndex;
          
			var docId : int = this._documentComponent.docId;
			var imageInfo : Object = this._documentComponent.imageInfo;
			var contentWidth : int = imageInfo.width;
			var contentHeight : int = imageInfo.height;
			var level : int = 0;
			var targetThumb : ThumbnailComponent = _thumbnails[_currentIndex];
            var isUseActual : Boolean = level != imageInfo.maxLevel || !imageInfo.isUseActualSize;
			DocumentLoadUtil.loadPageSource( docId, _thumbnails[_currentIndex].page, level, 
											contentWidth, contentHeight , isUseActual , function(pageSource : BitmapData) : void {
												
				_ui.pageLabel.text += ' load complete';
				
				targetThumb.source = new Bitmap(pageSource); 
			});
        }
        private function loadThumbs(start : int , end : int, next : Function = null) : void {
            // skip index at the mement
			var docId : int = this._documentComponent.docId;
			
            for(var i : int = start; i < end; i++) {
                if(_thumbnails[i] != null && _thumbnails[i].hasThumbSource() ) {
                    _thumbnails[i].visible = true;
                    _thumbnails[i].resetThumbSource();
                    continue;
                }
				DocumentLoadUtil.loadThumb(_thumbnails[i], next);
            }
        }

    }
}






