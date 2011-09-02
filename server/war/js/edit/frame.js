var editing = false;
var start = {};
var img = new Image();
var frames = [];

var order = 0;
var page = {
	number: 0,
	next: function() {
		this.number++;
	},
	prev: function() {
		this.number--;
		if (this.number <= -1)
			this.number = 0;
		order = 0;
		draw();
	},
	total: 0
};
var ctx;
var id = 0;

window.addEventListener("load", function() {
	id = readCookie('document_id');
	
	DocumentService.getFrames(id, function(data){
		frames = data;
		loadFrame();
		//can.width = img.width;
		//can.height = img.height;
		//draw();
	});
	
	var can = document.getElementById("frame");
	ctx = document.getElementById("frame").getContext("2d");
	
	can.addEventListener("click", canvasClicked, true);
	//can.addEventListener("mousemove", drawEditing, true);

	drawImage();
}, true);

function drawImage(){
	img.src = "/dispatch/viewer/getPage?documentId=" + id + "&level=0&type=iPhone&px=0&py=0&page=" + page.number;
	img.onload = function(){
		ctx.drawImage(img, 0, 0);
	}
}

function drawFrame(){
	// clear canvas
	ctx.clearRect(0, 0, 8000, 8000);
	ctx.globalCompositeOperation = "darker";
	for (var i = 0; i < frames.length; i++) {
		if (frames[i].page == page.number) {
			ctx.fillStyle = "rgba(255, " + Math.abs(254 - (50 * frames[i].order % 255)) + ", 0, 1)";
			ctx.fillRect(frames[i].x, frames[i].y, frames[i].width, frames[i].height);
			ctx.strokeText(frames[i].order, frames[i].x, frames[i].y);
		}
	}
}

function addFrame(frame){
	if (frame == null)
		frame = {x:200, y:200, width:200, height:200};
	var offset = "top:" + frame.x + "px; left:" + frame.y + "px;";
	var size = "width:" + frame.width + "px;height:" + frame.height + "px;";
	$("#controller").append("<div class='youjo editing' style='position:absolute;" +  size + "opacity:0.2; background-color:red;" + offset + "'></div>");
	$(".youjo").draggable();
	$(".youjo").resizable();
}

function loadFrame(){
	for (var i = 0; i < frames.length; i++) {
		if (frames[i].page == page.number) {
			addFrame(frames[i]);
		}
	}
}

function drawEditing(e) {
	if (editing) {
		ctx.restore();
		ctx.fillStyle = "rgba(255, 0, 0, 1)";

		var org = {
				x: (start.x < e.offsetX ? start.x : e.offsetX),
				y: (start.y < e.offsetY ? start.y : e.offsetY)};

		var width = Math.abs(start.x - e.offsetX);
		var height = Math.abs(start.y - e.offsetY);

		ctx.save();
		ctx.fillRect(org.x, org.y, width, height);
	}
}

function canvasClicked(e) {
	var x = e.offsetX;
	var y = e.offsetY;
	
	if (!editing) {
		start = {x:x, y:y};
		addFrame();
	}
	
	if (editing) {
		var offset = {
				x: (start.x < x ? start.x : x),
				y: (start.y < y ? start.y : y)};
		$(".editinig").offset(offset);

		var width = Math.abs(start.x - x);
		var height = Math.abs(start.y - y);
		$(".editing").width(width);
		$(".editing").height(height);

		//frames[frames.length] = {x:offset.x, y:offset.y, width:width, height:height, page:page.number, order:order++};
	}
	editing = !editing;
	save();
}

function clearPage() {
	for (var i = 0; i < frames.length; i++) {
		if (frames[i].page == page.number) {
			frames.splice(i, 1);
			i--;
		}
	}
	order = 0;
	save();
	draw();
}

function save() {
	DocumentService.setFrames(id, frames, function(){});	
}
