package jp.archilogic.docnext.helper {
    import __AS3__.vec.Vector;

    public class PageHeadHelper {
        public function PageHeadHelper( singlePages : Array , pages : int ) {
			_pageLength = pages;
			_singlePages = singlePages;
            for ( var page : int = 0 ; page < pages ;  ) {
                _heads.push( page );

                if ( !isSinglePage( page , singlePages ) && page + 1 < pages &&
                    !isSinglePage( page + 1 , singlePages ) ) {
                    _isSingleHead.push( false );
                    page += 2;
                } else {
                    _isSingleHead.push( true );
                    page += 1;
                }
            }
        }
		private var _pageLength:int ;
		private var _singlePages:Array ; 
        private var _heads : Vector.<int> = new Vector.<int>();
        private var _isSingleHead : Vector.<Boolean> = new Vector.<Boolean>();

        public function headToPage( head : int ) : int {
            return _heads[ head ];
        }

        public function isSingleHead( head : int ) : Boolean {
            return _isSingleHead[ head ];
        }
		
		public function isSingleHeadByPage( page : int ) : Boolean {
			return isSinglePage(page, _singlePages);
		}
		
		public function isFore( page : int ) : Boolean {
			var value : Boolean ;
			if(isSingleHeadByPage(page)) {
				value = true;
			}
			else {
				var head : int = pageToHead( page );
				var forePageIndex : int = headToPage( head );
				value = page == forePageIndex ? true : false;
				
				if( forePageIndex != page && (forePageIndex + 1) != page ) {
					throw new ArgumentError("PageHeadHelper.isFore(page:int):Boolean has bug");
				}
					
			}
			return value;
		}
        public function isValidHead( head : int ) : Boolean {
            return head >= 0 && head < _heads.length;
        }

        public function get length() : int {
            return _heads.length;
        }
		
		public function get pageLength() : int {
			return _pageLength;
		}
		
        public function pageToHead( page : int ) : int {
            for ( var head : int = 0 ; head < _heads.length ; head++ ) {
                var headPage : int = _heads[ head ];

                if ( headPage == page ) {
                    return head;
                }

                if ( headPage > page ) {
                    return head - 1;
                }
            }

            return _heads.length - 1;
        }

        private function isSinglePage( page : int , singlePages : Array ) : Boolean {
            for each ( var elem : int in singlePages ) {
                if ( page == elem ) {
                    return true;
                }
            }

            return false;
        }
    }
}