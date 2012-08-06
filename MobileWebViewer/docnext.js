/*** const variable ***/
var ERROR_BROKEN_FILE = 'ファイルの一部に不具合がありました。ネットワークが繋がる環境で再起動をしてください。';
var ERROR_BROKEN_JSON = 'info.jsonに不具合がありました。'; 
var ERROR_ABORT = 'ファイルの一部に不具合がありました。ネットワークが繋がる環境で再起動をしてください。';
var ERROR_INVALID_TYPE = 'イメージコンテンツではありません。';
var ERROR_FORBIDDEN = 'このコンテンツに対する閲覧権限がありません。';
var CONFIRM_RETRY = 'ダウンロード中にネットワークエラーが発生しました。ダウンロードを再開してもよろしいですか？\n';
var ERROR_GOTO_PAGE = '遷移先ページに不具合がありました。';

var host = "localhost:8888";
var FOR_PC = false;

/*** Utilities ***/
var $ = function( id ) {
    return document.getElementById( id );
};

var min = Math.min;
var max = Math.max;

var osVersion = '';
var isMakeCanvas = true;

/*** Local?Provider ***/
var LocalProvider = function() {

    this.getText = function( xmlHttp , isAsync ) {
        if ( isAsync && xmlHttp.readyState != 4 ) {
            return null;
        }

        if ( xmlHttp.readyState == 4 && xmlHttp.status == 200 ) {
            return xmlHttp.responseText;
        } else {
            if ( !errorFlag ) {
                errorFlag = true;
                window.alert(ERROR_BROKEN_FILE);
            }
            throw new Error( '' );
        }
    };


    this.getData = function( url , auth , async ) {
        var isAsync = async != undefined;
        var xmlHttp = new XMLHttpRequest();

        if ( isAsync ) {
            var lp = this;
            xmlHttp.onreadystatechange = function() {
                var res = lp.getText( xmlHttp , isAsync );
                if ( res != null ) {
                    async( res );
                }
            };
        }

	xmlHttp.open( "GET" , url , isAsync );

        if ( auth != undefined ) {
            xmlHttp.setRequestHeader( "Authorization", "Basic " + auth );
        }

	console.log("url : " + url);

        xmlHttp.send( null );

        return this.getText( xmlHttp , isAsync );
    };

    this.getJson = function( responseText ) {
        if (responseText[0] != '<') {
            try {
                return JSON.parse(responseText);
            } catch(err) {
                if ( !errorFlag ) {
                    errorFlag = true
                    alert(ERROR_BROKEN_JSON);
                }
                throw new Error( '' )
            }
        } else {
            if ( !errorFlag ) {
                errorFlag = true;
                window.alert(ERROR_BROKEN_JSON);
            }
            throw new Error( '' );
        }
    };

    this.getJsonInfo = function( url ) {
        return this.getJson( this.getData( url ) );
    };

    this.loadAnnotation = function( state, page ) {
        var url = state.baseUrl + '/image/' + page + '.anno.json';
        var resp = function( responseText ) {
            if (responseText[0] != '<') {
                state.annotations[page] = JSON.parse(responseText);
            } else {
                if ( !errorFlag ) {
                    errorFlag = true;
                    window.alert(ERROR_BROKEN_JSON);
                }
                throw new Error( '' );
            }
        };
        this.getData( url , undefined , resp );
    };

    this.getInfo = function( url ) {
        return this.getJsonInfo( url + "info.json" );
    };

    this.getImageInfo = function( url ) {
        return this.getJsonInfo( url + "image/image.json" );
    };

    this.getSpreadFirstPages = function( singlePages , pages ) {
        var ret = new Array();
        for( var i = 0 ; i < pages ; i++ ) {
            if( !singlePages.contains( i ) && ( i == 0 || !ret.contains( i - 1 ) ) && i != pages - 1 ) {
                ret.push( i );
            }
        }
        return ret;
    };
};

var VERSION_NAME = "1.5";

var osVersion;
var osVersion2;
var docnextUA;
var jumpUrl = "";
var shelfUrl = jumpUrl;

var TEXTURE_SIZE = 512;
var EPS = 0.01;

// temporal
var FORCE_LEVEL = 1;

var errorFlag = false;

var Matrix = function() {
    this.scale = 0;
    this.tx = 0;
    this.ty = 0;
    this.state;

    this.adjust = function( screen , pageSize ) {
        var p = ( _state.isDoublePage ) ? 2 : 1;
        this.tx = min( max( this.tx , screen.width - pageSize.width * this.scale * p ) , 0 );
        this.ty = min( max( this.ty , screen.height - pageSize.height * this.scale ) , 0 );
    };

    this.copy = function( that ) {
        this.scale = that.scale;
        this.tx = that.tx;
        this.ty = that.ty;

        return this;
    };

    this.i = function( src , dst , value ) {
        return src + ( dst - src ) * value;
    };

    this.interpolate = function( src , dst , value ) {
        this.scale = this.i( src.scale , dst.scale , value );
        this.tx = this.i( src.tx , dst.tx , value );
        this.ty = this.i( src.ty , dst.ty , value );
    };

    this.length = function( length ) {
        return length * this.scale;
    };

    this.set = function( scale , tx , ty ) {
        this.scale = scale;
        this.tx = tx;
        this.ty = ty;
    };

    this.x = function( x ) {
        return x * this.scale + this.tx;
    };

    this.y = function( y ) {
        return y * this.scale + this.ty;
    };
};

var Cleanup = function() {
    this.isIn = false;
    this.src = new Matrix();
    this.dst = new Matrix();
    this.shouldAdjust = false;
    this.start = 0;
    this.duration = 0;

    this.calc = function( mat , screen , pageSize ) {
        if ( mat.tx > EPS || mat.ty > EPS || mat.tx < screen.width - pageSize.width * mat.scale - EPS || mat.ty < screen.height - pageSize.height * mat.scale - EPS ) {
            this.isIn = true;
            this.src.copy( mat );
            this.dst.copy( mat );
            this.dst.adjust( screen , pageSize );
            this.shouldAdjust = false;
            this.start = new Date().getTime();
            this.duration = 200;
        }
    };

    this.calcDoubleTap = function( mat , pos , pad , screen , minScale , maxScale ) {
        var dstScale = NaN;

        if ( mat.scale < maxScale ) {
            dstScale = min( 2 * mat.scale , maxScale );
        } else {
            dstScale = minScale;
        }

        this.isIn = true;
        this.src.copy( mat );
        this.dst.set( dstScale , dstScale / mat.scale * ( mat.tx - ( pos.x - pad.x ) ) + screen.width / 2 , dstScale / mat.scale * ( mat.ty - ( pos.y - pad.y ) ) + screen.height / 2 );
        this.shouldAdjust = true;
        this.start = new Date().getTime();
        this.duration = 250;
    };

    this.update = function( mat , screen , pageSize ) {
        var elapsed = ( new Date().getTime() - this.start ) / this.duration;
                
        var willFinish = false;
                
        if ( elapsed > 1 ) {
            elapsed = 1;
            willFinish = true;
        }
                
        var val = 1 - Math.pow( 1 - elapsed , 3 );
                
        mat.interpolate( this.src , this.dst , val );

        if ( this.shouldAdjust ) {
            mat.adjust( screen , pageSize );
        }
                
        if ( willFinish ) {
            this.isIn = false;
        }
    };
};

/*** state ***/
var State = function( w , h ) {
    this.textures = [];
    this.annotations = [];
    
    this.initTextures = function() {
        var texturesCount = this.isDoublePage ? 2 : 3;
        for ( var delta = 0 ; delta < this.pages; delta++ ) {
            this.textures[ delta ] = [];

            for ( var level = 0 ; level <= this.maxLevel ; level++ ) {
                this.textures[ delta ][ level ] = [];

                var isUseActual = this.maxLevel == this.image.maxLevel && this.image.isUseActualSize;
                var ny , nx;
                if ( level != this.maxLevel || !isUseActual ) {
                    var width = TEXTURE_SIZE;
                    var height = this.image.height * width / this.image.width;
                    var factor = Math.pow( 2 , level );
                    nx = Math.floor( ( width * factor - 1 ) / TEXTURE_SIZE ) + 1;
                    ny = Math.floor( ( height * factor - 1 ) / TEXTURE_SIZE ) + 1;
                } else {
                   nx = Math.floor( ( this.image.width - 1 ) / TEXTURE_SIZE ) + 1;
                   ny = Math.floor( ( this.image.height - 1 ) / TEXTURE_SIZE ) + 1;
                }

                for ( var py = 0 ; py < ny ; py++ ) {
                    this.textures[ delta ][ level ][ py ] = [];

                    for ( var px = 0 ; px < nx ; px++) {
                        this.textures[ delta ][ level ][ py ][ px ] = 0;
                    }
                }
            }
        }
    };

    this.screen = { width: w , height: h };
    this.matrix = new Matrix();
    this.isInTouch = false;
    this.cleanup = new Cleanup();
    this.minScale = 0;
    this.maxScale = 0;
    this.id;
    this.baseUrl;
    this.doc;
    this.image;
    this.page = 0;
    this.pages;
    this.spreadFirstPages;
    this.minLevel = 0;
    this.maxLevel = 0;
    this.pageSize = { width: 0, height: 0 };
    this.isDoublePage = false;
    this.cancelLoading = false;
    this.cancelPage = 0;
    this.directory = "";
    this.blinkStart = 0;

    this.doubleTap = function( pos ) {
        this.cleanup.calcDoubleTap( this.matrix , pos , this.padding() , this.screen , this.minScale , this.maxScale );
    };

    this.padding = function( page ) {
        return { x: max( this.screen.width - this.matrix.scale * this.pageSize.width * (this.isDoublePage ? 2 : 1) , 0 ) / 2 , y: max( this.screen.height - this.matrix.scale * this.pageSize.height , 0 ) / 2 };
    };

    this.update = function() {
        if ( !this.isInTouch ) {
            if ( !this.cleanup.isIn ) {
                this.cleanup.calc( this.matrix , this.screen , this.pageSize );
            }
            
            if ( this.cleanup.isIn ) {
                this.cleanup.update( this.matrix , this.screen , this.pageSize );
            }
        } else {
            this.cleanup.isIn = false;
        }
    };

    this.initScale = function() {
        if ( Device.isLandscape() && !Device.isIPad() ) {
            this.minScale = this.screen.width / this.pageSize.width;
	} else {
            this.minScale = min( this.screen.width / this.pageSize.width , this.screen.height / this.pageSize.height);
        }
        this.maxScale = max(1, this.minScale);

        this.matrix.scale = this.minScale;
    };

    this.isCleanup = function() {
        return this.cleanup.isIn;
    };

    this.initLevel = function(imageInfo) {
        var util = new ImageLevelUtil();
        this.minLevel = util.getMinLevel(this.screen, imageInfo.maxLevel);
        this.maxLevel = util.getMaxLevel(this.minLevel, imageInfo.maxLevel, imageInfo.maxNumberOfLevel);
    };

    this.initPageSize = function(imageInfo) {
        this.pageSize.width = this.minLevel != this.image.maxLevel || !this.image.isUseActualSize ? ( TEXTURE_SIZE * Math.pow( 2 , this.minLevel ) ) : this.image.width;
        this.pageSize.height = this.image.height * this.pageSize.width / this.image.width;

        /*if (imageInfo.isUseActualSize) {
            this.pageSize.height = TEXTURE_SIZE * Math.pow(2, this.minLevel);
            this.pageSize.width = this.pageSize.height * imageInfo.width / imageInfo.height;
        } else {
            this.pageSize.width = TEXTURE_SIZE * Math.pow(2, this.minLevel);
            this.pageSize.height = this.pageSize.width * (imageInfo.height / imageInfo.width);
        }*/
    };

    this.clearTextures = function( page , y , x ) {
        if (page < 0 || page >= this.pages) {
            return;
        }

	for ( var level = 0 ; level <= this.maxLevel ; level++ ) {
            var ny = this.textures[ 0 ][ level ].length;
            var nx = this.textures[ 0 ][ level ][ 0 ].length;
            for ( var py = 0 ; py < ny ; py++ ) {
                for ( var px = 0 ; px < nx ; px++) {
                    delete this.textures[ page ][ level ][ py ][ px ];
                }
            }
        }
    };
    
    this.initAnnotation = function () {
        this.blinkStart = new Date();
    }

    this.nextPage = function() {
        this.initAnnotation();
        var pageWidth = this.matrix.length( this.pageSize.width );
        var p = ( this.isDoublePage ) ? 2 : 1;

        if ( !( this.page + p < this.pages ) ) {
            return;
        }
        var level = this.minLevel;
	var ny = this.textures[ 0 ][ level ].length;
	var nx = this.textures[ 0 ][ level ][ 0 ].length;

        if ( this.isDoublePage ) {
            if ( this.doc.singlePages.contains( this.page ) ) {
                this.page += 1;
            } else {
                this.page += p;
            }
            loadAndNext( this , this.page  , this.minLevel , 0 , 0 , ny , nx );
            loadAndNext( this , this.page + 1, this.minLevel , 0 , 0 , ny , nx );
            loadAndNext( this , this.page + 2 , this.minLevel , 0 , 0 , ny , nx );
            loadAndNext( this , this.page + 3, this.minLevel , 0 , 0 , ny , nx );
            this.matrix.tx -= this.matrix.length(this.pageSize.width*p) * this.xsign;
        } else {
            this.page++;
            this.clearTextures( this.page - 2 );
            loadAndNext( this , this.page + 1 , this.minLevel , 0 , 0 , ny , nx );
            this.matrix.tx -= this.matrix.length(this.pageSize.width ) * this.xsign;
        }
        this.cleanup.isIn = false;
        //this.matrix.ty = 0;
    };

    this.prevPage = function() {
        this.initAnnotation();
        var pageWidth = this.matrix.length( this.pageSize.width );
        var p = ( this.isDoublePage && this.page - 2 >= 0 ) ? 2 : 1;

        if ( !( this.page > 0 ) ) {
            return;
        }
        var level = this.minLevel;
	var ny = this.textures[ 0 ][ level ].length;
	var nx = this.textures[ 0 ][ level ][ 0 ].length;

        if ( this.isDoublePage ) {
            if ( this.doc.singlePages.contains( this.page - 1 ) ) {
                this.page -= 1;
            } else {
                this.page -= p;
            }
            loadAndNext( this , this.page + 1 , this.minLevel , 0 , 0 , ny , nx );
            loadAndNext( this , this.page , this.minLevel , 0 , 0 , ny , nx );
            this.matrix.tx += this.matrix.length( this.pageSize.width * 2 ) * this.xsign;
        } else {
            this.page--;
            this.clearTextures( this.page + 2 );
            loadAndNext( this , this.page - 1 , this.minLevel , 0 , 0 , ny , nx );
            this.matrix.tx += this.matrix.length( this.pageSize.width ) * this.xsign;
        }
        this.cleanup.isIn = false;
        //this.matrix.ty = min( 0, this.screen.height - this.matrix.length(this.pageSize.height ) );
    };

    this.gotoPage = function(page) {
	if ( isNaN( page ) || page < 0 || page >= this.textures.length ) {
            return;
        }
        this.initAnnotation();
        this.page = page;
        var level = this.minLevel;
	var ny = this.textures[ 0 ][ level ].length;
	var nx = this.textures[ 0 ][ level ][ 0 ].length;

        loadAndNext( this , this.page - 1 , level , 0 , 0 , ny , nx );
        loadAndNext( this , this.page     , level , 0 , 0 , ny , nx );
        loadAndNext( this , this.page + 1 , level , 0 , 0 , ny , nx );
    };

    this.getLevel = function() {
        //return 1; if maxLevel is 0 , bad status;
        for ( var level = this.minLevel ; level < this.maxLevel ; level++ ) {
            if ( this.matrix.scale < Math.pow( 2 , level - this.minLevel - 1 ) ) {
		return 1;
                return level;
            }
        }
        return this.maxLevel;
    };
};

/*** loading ***/
var loadAndNext = function( state , page , level , py , px , ny , nx ) {

    if (page < 0 || page >= state.pages || Math.abs(page - state.page) > 3 ) {
        return;
    }

    if (level == state.minLevel && py == 0 && px == 0) {
        if (state.image.hasAnnotation) {
            (new LocalProvider).loadAnnotation(state, page);
        }
    }

    if ( px >= nx ) {
        loadAndNext( state , page , level , py + 1 , 0 , ny , nx );
        return;
    }
    if ( py >= ny ) {
	if ( ++level <= state.maxLevel ) {
            ny = state.textures[ 0 ][ level ].length;
	    nx = state.textures[ 0 ][ level ][ 0 ].length;

            loadAndNext( state , page , level , 0 , 0 , ny , nx );
        }
        return;
    }
    if ( level > state.maxLevel ) {
        return;
    }
    if ( page >= state.pages ) {
        state.textures[ page ][ level ][ py ][ px ] = null;
        loadAndNext( state , page , level , py , px + 1 , ny , nx );
        return;
    }

    var img = document.createElement( 'img' );

    img.onload = function() {
        state.textures[ page ][ level ][ py ][ px ] = img;

        loadAndNext( state , page , level , py , px + 1 , ny , nx );
    };

    img.onerror = function() {
        if ( !errorFlag ) {
            errorFlag = true;
            if ( window.confirm(CONFIRM_RETRY) ) {
                errorFlag = false;
                loadAndNext( state , page , level , py , px , ny , nx );
            }
        }
    };

    var url = state.baseUrl + 'image/texture-' + page + '-' + level + '-' + px + '-' + py + '.jpg';

    img.src = url;
};

var blinkAlpha = 0.5;

var drawRegion = function( ctx , state ) {
    var draw = function( annotation , x ) {
        var n = new Date() - state.blinkStart;
        var t = Math.floor( n / 1000);
        ctx.fillStyle = "rgba(77 , 77 , 88 , " + (t % 2 ? 0.0 : 0.5) + ")";
        if ( n > 3500 ) {
            ctx.fillStyle = "rgba(0 , 0 , 0 , 0)";
        }

        var region = annotation.region;
        region.pageX = state.padding( 2 ).x + region.x * state.pageSize.width * state.matrix.scale + state.matrix.tx;
        region.pageX += x;
        region.pageWidth = region.width * state.pageSize.width * state.matrix.scale;
        region.pageY = region.y * state.pageSize.height * state.matrix.scale + state.matrix.ty; 
        region.pageHeight = region.height * state.pageSize.height * state.matrix.scale;

        ctx.fillRect(region.pageX, region.pageY, region.pageWidth, region.pageHeight);
    };

    var doubleDraw = function( page , x ) {
	if (state.annotations[page] == undefined) {
            return;
        }

        for ( var i = 0 ; i < state.annotations[page].length ; i++ ) {
            draw( state.annotations[ page ][ i ] , x );
        }
    };

    if ( state.isDoublePage ) {
        var page = state.page;
	var marginL = margin( state , state.page + 1 , 1 );
        var marginR = margin( state , state.page - 1 , -1 );
        var pageWidth = state.matrix.length( state.pageSize.width ) * state.xsign;
	var distance = pageWidth * 2 + 30 * state.matrix.scale * state.xsign;

        // prev
        if ( state.doc.singlePages.contains( state.page - 1 ) ) {
            doubleDraw( state.page - 1 , pageWidth / 2 + distance );                   
        } else {
            doubleDraw( state.page - 1 , distance );
        }

        if ( state.doc.singlePages.contains( page ) ) {
            doubleDraw( page , pageWidth / 2 );
            page++;
        } else {
            doubleDraw( page , pageWidth + marginR );
            page++;
            doubleDraw( page , 0 );
            page++;
        }
                
        // next
        if ( state.doc.singlePages.contains( page ) ) {
            doubleDraw( page , pageWidth / 2　- pageWidth * 2 );
            page++;
        } else {
            doubleDraw( page , pageWidth - distance );
            page++;
        }
    } else {
        for (var delta = -1; delta <= 1; delta++) {
            var page = state.page + delta;

            if (state.annotations[page] == undefined) {
                continue;
            }

	    var distance = delta == 0 ? 0 : margin( state , state.page + delta , delta );

            for ( var i = 0 ; i < state.annotations[page].length ; i++ ) {
                draw( state.annotations[ page ][ i ] , -1 * ( delta * state.pageSize.width * state.matrix.scale * state.xsign ) + distance );
            }
        }
    }		
};

Array.prototype.contains = function( value ) {
    for( var i in this ) {
        if( this[ i ] === value ) {
            return true;
        }
    }
    return false;
};

var margin = function( state , page , deltaPage ) {

    if ( state.isDoublePage || deltaPage == 0 ) {
        return 0;
    }

    var L2R = state.direction == "L2R";

    var xSign = L2R ? 1 : -1;
    var deltaX = 0;

    var marginLeft = 0;
    var marginRight = 0;

    var PAGE_MARGIN = 30;

    if ( state.spreadFirstPages.contains( page ) ) {
        if ( L2R ) {
            marginLeft = PAGE_MARGIN;
        } else {
            marginRight = PAGE_MARGIN;
        }
    } else if ( page - 1 >= 0 && state.spreadFirstPages.contains( page - 1 ) ) {
        if ( L2R ) {
            marginRight = PAGE_MARGIN;
        } else {
            marginLeft = PAGE_MARGIN;
        }
    } else {
        marginLeft = marginRight = PAGE_MARGIN;
    }
    
    if ( ( deltaPage == 1 ) == L2R ) {
        deltaX += state.matrix.length( marginLeft ) * xSign * deltaPage;
    } else {
        deltaX += state.matrix.length( marginRight ) * xSign * deltaPage;
    }
    return deltaX;
};

var drawTexture = function( ctx , state ) {
    var pad = state.isDoublePage ? state.padding(2) : state.padding(1);
    var y = state.matrix.y( 0 );

    var marginL = margin( state , state.page + 1 , 1 );
    var marginR = margin( state , state.page - 1 , -1 );

    level = state.getLevel();

    var factor;
    if ( level != state.image.maxLevel || !state.image.isUseActualSize ) {
        factor = Math.pow( 2 , level - state.minLevel );
    } else {
        factor = level != state.minLevel ? state.image.width / ( TEXTURE_SIZE * Math.pow( 2 , state.minLevel ) ) : 1;
    }

    for ( var py = 0 ; py < state.textures[ 0 ][ level ].length ; py++ ) {
        var srcHeight = py < state.textures[ 0 ][ level ].length - 1 ? TEXTURE_SIZE : ( state.image.height - TEXTURE_SIZE * py ) * state.pageSize.height / state.image.height;

        if ( !( py < state.textures[ 0 ][ level ].length - 1 ) ) {
            if ( level != state.image.maxLevel || !state.image.isUseActualSize ) {
                srcHeight = state.image.height * state.textures[ 0 ][ level ][ py ].length * TEXTURE_SIZE / state.image.width - TEXTURE_SIZE * py;
            } else {
                srcHeight = TEXTURE_SIZE;
            }
        }

        if (Device.isIOS4()) {
            srcHeight = TEXTURE_SIZE;
        }

        var dstHeight = state.matrix.length( srcHeight ) / factor;
        var x = state.matrix.x( 0 ) + pad.x;
        if ( state.direction == "L2R" && state.isDoublePage ) {
            x += state.matrix.length( state.pageSize.width );
        }

        for ( var px = 0 ; px < state.textures[ 0 ][ level ][ py ].length ; px++ ) {
            // TODO
            var srcWidth = TEXTURE_SIZE ;
            if (px < state.textures[0][ level ][py].length - 1) {
                srcWidth = TEXTURE_SIZE;
            } else {
                if ( level != state.image.maxLevel || !state.image.isUseActualSize ) {
                    srcWidth = TEXTURE_SIZE;
                } else {
                    srcWidth = state.image.width - TEXTURE_SIZE * px;
                }
            }

            var dstWidth = state.matrix.length( srcWidth ) / factor;
            var pageWidth = state.matrix.length( state.pageSize.width );
            var pg = state.page;

            if ( state.isDoublePage ) {

                var draw = function( page , x ) {
                    ctx.drawImage( state.textures[ page ][ level ][ py ][ px ] , 0 , 0 , srcWidth , srcHeight , Math.ceil( x ) , Math.ceil( y ) , Math.ceil( dstWidth ) , Math.ceil( dstHeight ) );
                }

                var pageWidth = state.matrix.length( state.pageSize.width );
                pageWidth *= state.xsign;

                // prev
                var distance = pageWidth * 2 + 30 * state.matrix.scale * state.xsign;

                if ( state.doc.singlePages.contains(state.page - 1)) {
                    if ( state.textures[ ( state.page - 1 ) ] && state.textures[ ( state.page - 1 ) ][ level ][ py ][ px ] ) {
                        draw( state.page - 1 , x + pageWidth / 2 + distance );
                    }
                } else {
                    if ( state.textures[ ( state.page - 1 ) ] && state.textures[ ( state.page - 1 ) ][ level ][ py ][ px ] ) {
                        draw( state.page - 1 , x + distance );
                    }
                    if ( state.textures[ ( state.page - 2 ) ] && state.textures[ ( state.page - 2 ) ][ level ][ py ][ px ] ) {
                        draw( state.page - 2 , x + distance + pageWidth + marginR );
                    }           
                }
                
                if ( state.doc.singlePages.contains( pg )) {
                    if ( state.textures[ pg ] && state.textures[ pg ][ level ][ py ][ px ] ) {
                        draw( pg , x + pageWidth / 2 );
                        pg++;
                    }
                } else {
                    if ( state.textures[ pg ] && state.textures[ pg ][ level ][ py ][ px ] ) {
                        draw( pg , x + pageWidth + marginR );
                        pg++;
                    }
                    if ( state.textures[ pg ] && state.textures[ pg ][ level ][ py ][ px ] ) {
                        draw( pg , x );
                        pg++;
                    }               
                }
                
                // next
                var distance = pageWidth * 2 + 30 * state.matrix.scale * state.xsign;
                if ( state.doc.singlePages.contains( pg )) {
                    if ( state.textures[ pg ] && state.textures[ pg ][ level ][ py ][ px ] ) {
                        draw( pg ,  x  + pageWidth / 2　- pageWidth * 2 );
                        pg++;
                    }
                } else {

                    if ( state.textures[ ( pg ) ] && state.textures[ ( pg ) ][ level ][ py ][ px ] ) {
                        draw( pg ,  x  + pageWidth - distance );
                        pg++;
                    }
                    if ( state.textures[ ( pg ) ] && state.textures[ ( pg ) ][ level ][ py ][ px ] ) {
                        draw( pg ,  x  - distance );
                        pg++;
                    }             
                }

            } else {
                //var marginL = margin( state , state.page + 1 , 1 );
                //var marginR = margin( state , state.page - 1 , -1 );

                var draw = function( page , x , y) {
                    var image = state.textures[ page ][ level ][ py ][ px ];
                    var dx = Math.ceil( x );
                    var dy = Math.ceil( y );
                    var dw = Math.ceil( dstWidth );
                    var dh = Math.ceil( dstHeight );
                    if (Device.isIOS4() && ( srcWidth != image.width || srcHeight != image.height ) ) {
                        var canvas = document.createElement('canvas');
                        canvas.width = srcWidth;
                        canvas.height = srcHeight;
                        var context = canvas.getContext('2d');
                        context.drawImage( image , 0, 0 );
                        ctx.drawImage( canvas , 0 , 0 , srcWidth , srcHeight , dx , dy , dw , dh );
                    } else {
                        ctx.drawImage( image , 0 , 0 , srcWidth , srcHeight , dx, dy, dw, dh );
                    }
                }

                for ( var delta = -1 ; delta <= 1 ; delta++ ) {
                    var target = state.page + delta;
                    if ( target >= 0 && target < state.pages && state.textures[ target ][ level ][ py ][ px ] ) {
                        var margin_ = margin( state , target , delta ); 

                        draw( target , x - state.xsign * pageWidth * delta + margin_ , y );
                    }
                }
            }

            x += dstWidth;
        }

        y += dstHeight;
    }
};

var render = function( ctx , state ) {
    ctx.clearRect( 0 , 0 , $('canvas').width , $('canvas').height );

    if ( isMakeCanvas ) {
        return;
    }

    drawTexture( ctx , state );
    drawRegion( ctx, state );
    updateDebugArea( state );
};

/*** event handler ***/
var registerEventListener = function( state ) {
    var onTouchBegin = function() {
        state.isInTouch = true;
    };
    
    var onTouchEnd = function() {
        state.isInTouch = false;
    };
    
    var onDrag = function( delta ) {
        var EPS = 0.1;
        var page = state.page > 0 ? state.page : 0;

        level = state.getLevel();

        var factor;
        if ( level != state.image.maxLevel || !state.image.isUseActualSize ) {
            factor = Math.pow( 2 , level - state.minLevel );
        } else {
            factor = level != state.minLevel ? state.image.width / ( TEXTURE_SIZE * Math.pow( 2 , state.minLevel ) ) : 1;
        }

        var pageWidth = state.matrix.length( TEXTURE_SIZE ) * state.textures[ page ][ level ][ 0 ].length;
        var pageHeight = state.matrix.length( TEXTURE_SIZE ) * ( state.textures[ page ][ level ].length - 1 ) + state.matrix.length( state.pageSize.height - TEXTURE_SIZE * ( state.textures[ page ][ level ].length - 1 ) );

        //TODO can move
        if ( state.screen.width + EPS >= pageWidth && !true ) {
            delta.x = 0;
        }
        if ( state.screen.height + EPS >= pageHeight ) {
            delta.y = 0;
        }

        state.matrix.tx += delta.x;
        state.matrix.ty += delta.y;
    };

    var onTap = function( pos ) {

        level = state.getLevel();

        var THREASHOLD = 4;
        var page = state.page > 0 ? state.page : 0;
        var pageWidth = state.matrix.length( TEXTURE_SIZE ) * state.textures[ page % state.textures.length ][ level ].length;
        var x = pos.x - state.matrix.tx;
        var w = state.screen.width / THREASHOLD;
        var dx = x < w ? -1 : x > pageWidth * state.matrix.scale - w ? 1 : 0;
        var delta = dx * -1;
        var p = state.isDoublePage ? 2 : 1;
        if (pos.x < state.screen.width / 4) {
            if ( state.direction == "L2R" ) {
                if ( state.page > 0 ) {
                    state.prevPage();
                }
            } else {
                if ( state.page + p < state.pages ) {
                    state.nextPage();
                }
            }
          } else if (pos.x > state.screen.width / 4 * 3) {
            if ( state.direction == "L2R" ) {
                if ( state.page + p < state.pages ) {
                    state.nextPage();
                }
            } else {
                if ( state.page > 0 ) {
                    state.prevPage();            
                }
            }
        } else {
        }
    };

    var switchMenu = function() {
        if (FOR_PC) {
            return;
        }
        var style = $('topbar').style;
        var display = style.display;
        
        if (display != 'none') {
            style.display = 'none';
        } else if (pos.y < state.screen.height / 4 && display  != 'block') {
            style.display  = 'block';
        } 
    };

    var pos = {};
    var originalTrans = {};
    var originalScale;
    var pinchCenter = { x:0, y:0 };
    var isInTouch = false;
    var isDrag = false;
    var prevClickTime = 0;
    var tapTimer;

    var down = function( e ) {
        e.preventDefault();
        scrollTo(0, 0);

        onTouchBegin();

        pos = { x: e.pageX , y: e.pageY };
        if ( e.touches != null ) {
            pos = { x: e.touches[0].pageX , y: e.touches[0].pageY };
        }
        isInTouch = true;
        isDrag = false;

    };

    var action = function() {
        var inRegion = function(region, delta) {
            var x = pos.x;
            var y = pos.y;

            region.pageX = state.padding().x + region.x * state.pageSize.width * state.matrix.scale + state.matrix.tx + state.pageSize.width * state.matrix.scale * delta;
            region.pageWidth = region.width * state.pageSize.width * state.matrix.scale;
            region.pageY = region.y * state.pageSize.height * state.matrix.scale + state.matrix.ty; 
            region.pageHeight = region.height * state.pageSize.height * state.matrix.scale;

            if (x >= region.pageX &&
                x <= region.pageX + region.pageWidth &&
                y >= region.pageY &&
                y <= region.pageY + region.pageHeight ) {
                return true;
            }
            return false;
        };

        for (var delta = 0; delta <= (state.isDoublePage ? 1 : 0); delta++) {
            var page;
            if (state.isDoublePage) {
                page = state.page + 1 - delta;
            } else {
                page = state.page;
            }
            if (state.annotations[page] == undefined) {
                continue;
            }
            for (var i = 0; i < state.annotations[page].length; i++) {
                var annotation = state.annotations[page][i];

                if (!inRegion(annotation.region, delta)) {
                    continue;
                }

                switch (annotation.action.action) {
                case "URI":
                    window.location = annotation.action.uri;
                    break;
                case "GoToPage":
                    var gotopage = parseInt( annotation.action.page , 10 );
                    if (gotopage >= state.pages || isNaN(gotopage)) {
                        window.alert(ERROR_GOTO_PAGE);
                    } else {
                        state.gotoPage( gotopage );
                    }
                    break;
                case "Movie":
                    window.location = annotation.action.target;
                    break;
                }

                return true;
            }
        }
    };
    
    var up = function(e) {
        isInTouch = false;

        onTouchEnd();

        clearTimeout( tapTimer );
        var interval = new Date().getTime() - prevClickTime;
        if (interval < 500 && !isDrag) {
            state.doubleTap( pos );
        } else if( isDrag ) {
            var p = state.isDoublePage ? 2 : 1;
            var pageWidth = state.matrix.length( state.pageSize.width ) * p;
            var L2R = state.direction == "L2R";

            if ( state.matrix.tx > state.screen.width / 8 ) {
                if ( L2R ) {
                    state.matrix.tx = 0;
                    state.prevPage();
                } else {
                    state.nextPage();
                }
            } else if ( state.matrix.tx < 0 && 
                ( (pageWidth <= state.screen.width && state.matrix.tx * (-1) > state.screen.width / 8)
             || (pageWidth > state.screen.width && state.matrix.tx * (-1) > pageWidth - state.screen.width + state.screen.width / 8) ) ) {
                if ( L2R ) {
                    state.nextPage();
                } else {
                    state.prevPage();
                }
            }
        } else {
            tapTimer = setTimeout( function(){ 
                    if (!action()) {
                        switchMenu();
                        onTap( pos );
                    }
                } , 500 );
        }

        prevClickTime = prevClickTime == 0 && !isDrag ? new Date().getTime() : 0;
    };
    
    var move = function( e ) {
        if (Device.isIOS4()) {
            var middle = function(a , b) {
                return Math.abs(a - b) / 2 + min(a, b);
            }
            if (e.touches != undefined && e.touches.length == 2) {
                pinchCenter = { x: middle(e.touches[0].pageX, e.touches[1].pageX),
                    y: middle(e.touches[0].pageY, e.touches[1].pageY) };
            }
        }

        // prevent scrolling
        e.preventDefault();

        if ( isInTouch ) {            
            if ( e.touches == null ) {
                 e.touches = [ { pageX: e.pageX , pageY: e.pageY } ];
            }
            onDrag( { x: e.touches[0].pageX - pos.x , y: e.touches[0].pageY - pos.y } );
            pos = { x: e.touches[0].pageX , y: e.touches[0].pageY };


            isDrag = true;
        }
    };

    var originalPadding;

    var gestureStart = function(e) {
        e.preventDefault();
        originalScale = state.matrix.scale;
        originalPadding = {x:state.padding().x};
        originalTrans = {x:state.matrix.tx, y:state.matrix.ty};
    };

    var gestureChange = function(e) {
        e.preventDefault();
        var matrix = state.matrix;
        var screen = state.screen;

        var scale = e.scale;
        if (e.scale * originalScale > state.maxScale) {
            scale = state.maxScale / originalScale;
        }
        if (e.scale * originalScale < state.minScale) {
            scale = state.minScale / originalScale;
        }

        var x = e.pageX;
        var y = e.pageY;
        if (Device.isIOS4()) {
            var x = pinchCenter.x;
            var y = pinchCenter.y;
        }
        matrix.tx = scale * (originalTrans.x - x + originalPadding.x) + x - state.padding().x;
        matrix.ty = scale * (originalTrans.y - y) + y;
        matrix.scale = scale * originalScale;
    };

    var gestureEnd = function(e) {
    };

    var rotate = function(e) {
        if ( Device.isIPad() && Device.isLandscape() ) {
            state.isDoublePage = true;
        } else {
            state.isDoublePage = false;
        }

        state.initScale();

        state.cleanup.isIn = false;

        resizeIcon();
        //resize();
	makeScreenFull(state);
    };

    var canvas = $('canvas');

    // for PC
    canvas.addEventListener( 'mousedown' , down );
    canvas.addEventListener( 'mousemove' , move );
    canvas.addEventListener( 'mouseup' , up );
    // for iOS
    canvas.addEventListener( 'touchstart' , down );
    canvas.addEventListener( 'touchmove' , move );
    canvas.addEventListener( 'touchend' , up );

    canvas.addEventListener('gesturestart', gestureStart);
    canvas.addEventListener('gesturechange', gestureChange);
    canvas.addEventListener('gestureend', gestureEnd);
    canvas.addEventListener('orientationchange', rotate);
    var resize = function() {
        //makeScreenFull(state);
    };
    canvas.addEventListener('resize', resize);

    var topbar = $('topbar');
    
    topbar.addEventListener('mouseup', up);
};

var params = {};

var retrieveParameters = function() {
    var query = window.location.search.substring(1);
    var parameters = query.split('&');
    for (var i = 0; i < parameters.length; i++) {
        var pos = parameters[i].indexOf('=');
        if (pos > 0) {
            var name = parameters[i].substring(0, pos);
            var value = parameters[i].substring(pos + 1);

            params[name] = value;
        }
    }
};

var ImageLevelUtil = function() {
    this.getMaxLevel = function(minLevel, imageMaxLevel, imageMaxNumberOfLevel) {
        return minLevel + this.getNumberOfLevel(minLevel, imageMaxLevel, imageMaxNumberOfLevel) - 1;
    };

    this.getMinLevel = function(screen, imageMaxLevel) {
        return min(max(Math.ceil(Math.log(this.getShortSide(screen) / TEXTURE_SIZE) / Math.log(2)), 0),
                imageMaxLevel);
    };

    this.getNumberOfLevel = function(minLevel, imageMaxLevel, imageMaxNumberOfLevel) {
        var limit = imageMaxNumberOfLevel > 0 ? imageMaxNumberOfLevel : 3;

        return min(imageMaxLevel - minLevel + 1, limit);
    };

    this.getShortSide = function(screen) {
        return min(screen.width, screen.height);
    };
};

var portraitScreen = null;
var landscapeScreen = null;

var makeScreenFull = function(state) {
    var canvas = $('canvas');

    isMakeCanvas = true;

    canvas.height = 1000;

    setTimeout( function() {

        window.scrollTo( 0 , 1 );
    
        setTimeout( function() {
            if (canvas.width != window.innerWidth || canvas.height != window.innerHeight) {
                canvas.width = window.innerWidth;
                canvas.height = window.innerHeight;
            }

	    isMakeCanvas = false;

            if (state != null && (state.screen.width != canvas.width || state.screen.height != canvas.height)) {
                state.screen = { width : canvas.width , height : canvas.height };
                state.initPageSize();
                state.initScale();
                state.cleanup.isIn = false;
                state.update();
            }

	    setTimeout( function() {
                window.scrollTo( 0 , 1 );
	    } , 2000 );
        }, 100 );

    }, 100 );
};

var updateDebugArea = function(state) {
    var updateElement = function(id, text) {
        var debug = document.getElementsByClassName('debug')[0];
        var ul = debug.getElementsByTagName('ul')[0];
        if ($(id) == null) {
            var dt = document.createElement('dt');
            dt.textContent = id;
            ul.appendChild(dt);

            var dd = document.createElement('dd');
            dd.id = id;
            ul.appendChild(dd);
        }

        $(id).textContent = text;
    }

    updateElement('window_width', window.innerWidth);
    updateElement('window_height', window.innerHeight);
    updateElement('canvas_width', $('canvas').width);
    updateElement('canvas_height', $('canvas').height);
    updateElement('screenWidth', state.screen.width);
    updateElement('screenHeight', state.screen.height);
};

var showDebugArea = function() {
    var div = document.getElementsByClassName('debug')[0];
    div.style.display = 'block';
};

var resizeIcon = function() {
    var bar = document.getElementById('topbar');
    var imgs = bar.getElementsByTagName('img');
    var as = bar.getElementsByTagName('a');
    var width; // icon width in pixel
    var fontSize; // fontSize width in pixel
    var widthInMM = 5.34; // icon width in mm
    var fontSizeInMM = 1.5; // font height in mm

    if (Device.isIPad()) {
        var iPadWidthInMM = Device.isPortrait() ? 147.0 : 197.0;
        var windowWidthInPixel = window.innerWidth;
        var ratio = windowWidthInPixel / iPadWidthInMM; 
        width = ratio * widthInMM * 1.5;
        fontSize = ratio * fontSizeInMM * 1.5;
    } else {
        var iPhoneWidthInMM = Device.isPortrait() ? 49.8 : 74.8;
        var windowWidthInPixel = window.innerWidth;
        var ratio = windowWidthInPixel / iPhoneWidthInMM; 
        width = ratio * widthInMM;
        fontSize = ratio * fontSizeInMM;
    }

    for (var i = 0; i < imgs.length; i++) {
        imgs[i].width = width;
    }


    for (var i = 0; i < as.length; i++) {
        as[i].style.setProperty('font-size', Math.round(fontSize) + 'px', 'important');
    }
}

var Device = new function() {
    this.isIPad  = function() {
        return /iPad/.test(navigator.userAgent);
    };
    this.isIPhone = function() {
        return /iPhone/.test(navigator.userAgent);
    };
    this.isIPod = function() {
        return /iPod/.test(navigator.userAgent);
    };
    this.isPC = function() {
        return !this.isIPad() && !this.isIPhone() && !this.isIPod();
    };

    this.isIOS = function() {
        return this.isIPad() || this.isIPhone() || this.isIPod();
    };

    this.isIOS4 = function() {
        return this.isIOS() && osVersion < '5.0';
    }

    this.isPortrait = function() {
        return !this.isLandscape();
    };
    this.isLandscape = function() {
        return Math.abs(window.orientation) == 90;
    }
}

function shelf(){
    if ( window.confirm( 'ビューアを終了いたしますか？' ) ) {
        if ( shelfUrl == "" ) {
            window.close();
            return;
        }
        document.location.href = shelfUrl;
    }
};

function menuClose(){
    if ( window.confirm( 'ビューアを終了いたしますか？' ) ) {
        document.location.href = jumpUrl == shelfUrl ? "javascript:window.close();" : shelfUrl;
    }
};

window.onload = function() {
    var userAgent = navigator.userAgent;

    osVersion = userAgent.replace( /.*(iPhone|CPU) ?OS ?([\d_]+).*/g, "$2" ).replace( /_/g , ".");
    osVersion2 = osVersion.replace( /^(\d\.\d).*$/ , "$1");
    docnextUA = "DocNext/" + VERSION_NAME + " iPhone" + osVersion2 + "(iPhone)";

    resizeIcon();

    if (!FOR_PC) {
        if ( Device.isPC() ) {
            document.location = jumpUrl;
            return;
        } else {
            navigator.userAgent.match( /((iPhone)|(CPU)) OS (\w+){1,3}/g);
            var osVer = ( RegExp.$4.replace( /_/g, '' ) + '00' ).slice( 0, 3 );
            if ( osVer < 400 ) {
                //document.location = jumpUrl;
                return;
            }
        }
    }
    retrieveParameters();

    init();

    if (params.returnURL != undefined ) {
        shelfUrl = decodeURI(params.returnURL);
    }
};

var tickId;

var init = function() {
    var c = $( 'canvas' );

    var ctx = c.getContext( '2d' );
    
    var state = new State( c.width , c.height );

    _state = state;
    if ( Device.isIPad() && Device.isLandscape() ){
        state.isDoublePage = true;
    } else {
        state.isDoublePage = false;
    }

    if (params.page != undefined) {
        state.page = Number(params.page);
    }

    if (params.id != undefined) {
        state.id = params.id;
        state.baseUrl = "http://" + host + "/dispatch/static/" + state.id + "/";
    }

    registerEventListener( state );

    var tick = function() {
        state.update();
        render( ctx , state );
    };

    var lp = new LocalProvider();

    state.doc = lp.getInfo( state.baseUrl );
    var IMAGE = 0;
    if (state.doc.types[0] != IMAGE) {
        if (!errorFlag) {
            errorFlag = true;
            alert(ERROR_INVALID_TYPE);
        }
        throw new Error( '' );
    }
    state.direction = state.doc.binding == 'left' ? 'L2R' : 'R2L';
    state.xsign = state.direction == "R2L" ? 1 : -1;
    state.image = lp.getImageInfo( state.baseUrl );
    state.pages = state.doc.pages;
    state.spreadFirstPages = lp.getSpreadFirstPages( state.doc.singlePages , state.pages );    
    state.initLevel( state.image );
    state.initPageSize( state.image );
    state.initScale();
    state.initTextures();

    tickId = setInterval( tick , 33 );

    var level = state.minLevel;
    var ny = state.textures[ 0 ][ level ].length;
    var nx = state.textures[ 0 ][ level ][ 0 ].length;

    if ( state.isDoublePage ) {
        loadAndNext( state , state.page , state.minLevel , 0 , 0 , ny , nx );
        loadAndNext( state , state.page + 1 , state.minLevel , 0 , 0 , ny , nx );
        loadAndNext( state , state.page + 2, state.minLevel , 0 , 0 , ny , nx );
        loadAndNext( state , state.page + 3 , state.minLevel , 0 , 0 , ny , nx );  
    } else {
        loadAndNext( state , state.page - 1 , state.minLevel , 0 , 0 , ny , nx );
        loadAndNext( state , state.page , state.minLevel , 0 , 0 , ny , nx );
        loadAndNext( state , state.page + 1 , state.minLevel , 0 , 0 , ny , nx );
    }
    state.initAnnotation();
    //setTimeout( function() {
        makeScreenFull( state );
    //}, 100 );
};

var errorFlag = false;

window.onerror = function ( msg , url , l ) {
    if ( !errorFlag ) {
        errorFlag = true;
        window.alert( msg );
        window.alert(ERROR_ABORT);

        clearTimeout(tickId);
    }
};
