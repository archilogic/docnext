/**
*
* 
* 	PageFlip
*
*	----------------------------------------------------------------
*	
*	@notice	PageFlip drawer
*	@author	Foxy
*	@version	1.0
*	@date	2007-01-18
*	
*	Original author :
*	-----------------
*	Didier Brun aka Foxy
*	webmaster@foxaweb.com
*	http://www.foxaweb.com
*
* 	AUTHOR ******************************************************************************
* 
*	authorName : 	Didier Brun - www.foxaweb.com
* 	contribution : 	the original class
* 	date :			2007-01-18
* 
* 	VISIT www.byteArray.org
* 
*
*	LICENSE ******************************************************************************
* 
* 	This class is under RECIPROCAL PUBLIC LICENSE.
* 	http://www.opensource.org/licenses/rpl.php
* 
* 	Please, keep this header and the list of all authors
* 
*
*
*	Nomenclature	
*	------------
*
*    PT(0,0)                                           PT(1,0)
*	  ---------------------------------------------------
*      |  <-------------------PW---------------------->  |
*      | ^ Offset(0,0)  x-->					       |
*      | |						                 |
*      | | y                                             |
*      | | |                                             |
*      | | |                                             |
*      | | V                                             |
*      | |              pPoints[]                        |
*      | |                                               |
*      | |                                               |
*      | |                                               |
*      | |                                          (T3) |
*      | PH                                           ---|
*      | |                                         --- /  
*      | |                                      ---   /   
*      | |                                   ---     /    
*      | |                                ---       /    
*      | |                             ---         /     
*      | |                          ---           /       
*      | |                    PTD  --- cPoints[] /                                           
*      | |                         \            /         
*      | |                          \          /          
*      | |                           \        /           
*      | |                            \      /            
*      | |                             \    /             
*      | V                              \  /             
*      |-------------------------------- \/               
*	PT(0,1)                                           PT(1,1)
*/

package com.foxaweb.pageflip {
	
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.display.Shape;
	
	public class PageFlip {

	
		// ------------------------------------------------
		//
		// ---o public static methods
		//
		// ------------------------------------------------

		/**
		*	Compute and generate a new Flip
		*
		*	@argument ptd:Point		Coords of PTD point (the drag one) relative to the upper-left corner.
		*
		*	@argument pt:Point      The original position of the dragged point. The two possible values for
		*							its x & y components are 0 or 1. pt(0,0) is the upper-left corner, for example,
		*							pt (1,1) is the bottom-right one.
		*
		*	@argument pw:int		Sheet width in pixels.
		*
		*	@argument ph:int      	Sheet height in pixels.
		*
		*	@argument ish:Boolean	If true, horizontal mode is provided. if false, vertical one.
		*
		*	@argument sens:Number	Constraints sensibility. This parametter is a multiplicator for the
		*							constraints values. It's intended to prevent some awefull flickering effects.
		*							Its possible value is ranged between 0.9 and 1.
		*							.9 -> when ptd move is free (drag'n'drop)
		*							1 -> when ptd move is progresive (tween when release).
		*						
		*							At best, you should never swap it from .9 to 1. A progressive incrementation
		*							is better.
		*									
		*							If flickering effects don't disturb you or if your ptd moves is
		*							coded, keep this parametter to 1.
		*
		*  RETURN {}				this method returns an objet which contains : 
		*
		*			cPoints:Array	An array of points which describes the flipped part of the sheet.
		*
		*							NOTE : in case of the ptd point is aligned with its original position or if the height 
		*							of the shape is very small (<1) this array is set to null.
		*
		*			pPoints:Array	An array of points wich describes the fixed part of the sheet.
		*
		*
		*			matrix:Matrix	Transformation matrix for the flipped part of the sheet.
		*
		*			width:Number	Sheet width.
		*		
		*			height:Number	Sheet height.
		*
		*
		*/
	
		public static function computeFlip(ptd:Point,pt:Point,pw:int,ph:int,ish:Boolean,sens:int):Object{

			// useful vars
			var dfx:Number=ptd.x-pw*pt.x;
			var dfy:Number=ptd.y-ph*pt.y;
			var spt:Point=pt.clone();
			var opw:int=pw;
			var oph:int=ph;
		
			// offset corections
			var temp:Number;

			// transform matrix 
			var mat:Matrix=new Matrix();

			if (!ish){
				// size
				temp=pw;
				pw=ph;
				ph=temp;

				// ptd
				temp=ptd.x;
				ptd.x=ptd.y;
				ptd.y=temp;

				// pt
				temp=pt.x;
				spt.x=pt.y;
				spt.y=temp;
			}

			//	pt1 & pt2 are the two fixed points of the sheet. opposed to ptd drag one.
			var pt1:Point=new Point(0,0);
			var pt2:Point=new Point(0,ph);

			// default points array
			// cPoints -> the fliped part
			var cPoints:Array=[null,null,null,null];
			// pPoints -> the fixed part
			var pPoints:Array=[new Point(0,0),new Point(pw,0),null,null,new Point(0,ph)];

			// compute some flip
			flipDrag(ptd,spt,pw,ph);

			// ditstance 
			// it allows you to have a valid position for ptd.
			// the limit is the diagonal of the sheet here
			limitPoint(ptd,pt1,(pw*pw+ph*ph)*sens);
			// the limit is about the opposite fixed point
			limitPoint(ptd,pt2,(pw*pw)*sens);

			// first fliped point
			cPoints[0]=new Point(ptd.x,ptd.y);

			var dy:Number=pt2.y-ptd.y;
			var tot:Number=pw-ptd.x-pt1.x;
			var drx:Number=getDx(dy,tot);

			// fliped angle
			var theta:Number=Math.atan2(dy,drx);
			if (dy==0)theta=0;

			// another fliped angle
			var beta:Number=Math.PI/2-theta;
			var hyp:Number=(pw-cPoints[0].x)/Math.cos(beta);
		
			// vhyp is the hypotenuse of the fliped part
			var vhyp:Number=hyp;
			// if hyp is greater than the height of the sheet or hyp is 
			// negative, the fliped part has 4 points
			// else, it's just a 3 points part (simple corner).
			if (hyp>ph || hyp<0)vhyp=ph;
				
			// second fliped point
			cPoints[1]=new Point(	cPoints[0].x+Math.cos(-beta)*vhyp,
								cPoints[0].y+Math.sin(-beta)*vhyp);

			// last fliped point
			cPoints[3]=new Point(cPoints[0].x+drx,pt2.y);
			
			// if we have a 4 points shape
			if (hyp!=vhyp){
				dy=pt1.y-cPoints[1].y;
				tot=pw-cPoints[1].x;
				drx=getDx(dy,tot);

				// push the before the last point
				cPoints[2]=new Point(cPoints[1].x+drx,pt1.y);	

				// we can now find the fixed points of the sheet
				pPoints[1]=cPoints[2].clone();
				pPoints[2]=cPoints[3].clone();
				pPoints.splice(3,1);
			}else{
				// else we delete the point
				cPoints.splice(2,1);

				// we can now find the fixed points of the sheet
				pPoints[2]=cPoints[1].clone();
				pPoints[3]=cPoints[2].clone();
			}

			// these two polygons are always convex !

			// now we can flip the two arrays
			flipPoints(cPoints,spt,pw,ph);
			flipPoints(pPoints,spt,pw,ph);

			// if !ish (vertical mode)
			// we have to change the points orientation 
			if (!ish){
				oriPoints(cPoints,spt,pw,ph);
				oriPoints(pPoints,spt,pw,ph);
			}

			// flipped part transfrom matrix
			
			var gama:Number=theta;
			
			if (pt.y==0)gama=-gama;
			if (pt.x==0)gama=Math.PI+Math.PI-gama;
			if (!ish)gama=Math.PI-gama;

			mat.a=Math.cos(gama);
			mat.b=Math.sin(gama);
			mat.c=-Math.sin(gama);
			mat.d=Math.cos(gama);

			ordMatrix(mat,spt,opw,oph,ish,cPoints,pPoints,gama,beta);

			// here we fix some mathematical bugs or instabilities
			if (vhyp==0)cPoints=null;
			if (Math.abs(dfx)<1 && Math.abs(dfy)<1)cPoints=null;

			// now we just have to return all the stuff
			return {cPoints:cPoints,pPoints:pPoints,matrix:mat,width:opw,height:oph};
		}

		/**
		*	Draw a sheet using two Bitmap objects
		*
		*	@ocf:Object			computeFlip() returned object
		*	
		*	@argument mc:MovieClip	target
		*	
		*	@bmp0:BitmapData		first page bitmap (left-top aligned)
		*
		*	@bmp1:BitmapData		second page bitmap (left-top aligned)
		*
		*
		*/
		public static function drawBitmapSheet(ocf:Object,mc:Shape,bmp0:BitmapData,bmp1:BitmapData):void{

			// affectations
			var wid:Number=ocf.width;
			var hei:Number=ocf.height;
			var nb:Number;
			var ppts:Array=ocf.pPoints;
			var cpts:Array=ocf.cPoints;


			// draw the fixed part
			mc.graphics.beginBitmapFill(bmp0,new Matrix(),false,true);
			nb=ppts.length;
			mc.graphics.moveTo(ppts[nb-1].x,ppts[nb-1].y);
			while (--nb>=0)mc.graphics.lineTo(ppts[nb].x,ppts[nb].y);
			mc.graphics.endFill();

			// draw the flipped part
			if (cpts==null)return;

			mc.graphics.beginBitmapFill(bmp1,ocf.matrix,false,true);
			nb=cpts.length;
			mc.graphics.moveTo(cpts[nb-1].x,cpts[nb-1].y);
			while (--nb>=0)mc.graphics.lineTo(cpts[nb].x,cpts[nb].y);
			mc.graphics.endFill();

		}

		// ------------------------------------------------
		//
		// ---o private static methods
		//
		// ------------------------------------------------

		/**
		*	orientation correction
		*/
		private static function oriPoints(pts:Array,po:Point,pw:Number,ph:Number):void{
			
			var nb:Number=pts.length;
			var temp:Number;

			while (--nb>=0){
				temp=pts[nb].x;
				pts[nb].x=pts[nb].y;
				pts[nb].y=temp;
			}
		}

		/**
		*	ptdarg correction
		*/
		private static function flipDrag(ptd:Point,po:Point,pw:Number,ph:Number):void{

			// flip y
			if (po.y==0)ptd.y=ph-ptd.y;

			// flip x
			if (po.x==0)ptd.x=pw-ptd.x;

		}

		/**
		*	flip correction
		*/
		private static function flipPoints(pts:Array,po:Point,pw:Number,ph:Number):void{
		
			var nb:Number=pts.length;
			// flip
			if (po.y==0 || po.x==0){
				while (--nb>=0){
					if (po.y==0)pts[nb].y=ph-pts[nb].y;
					if (po.x==0)pts[nb].x=pw-pts[nb].x;
				}
			}
		}

		/**
		*	compute some trigonometry equation
		*
		*	this one is more stable than Math.atan2 for our case
		*/
		private static function getDx(dy:Number,tot:Number):Number{
			return (tot*tot-dy*dy)/(tot*2);
		}

		/**
		*	limit the ptdrag position
		*/
		private static function limitPoint(ptd:Point,pt:Point,dsquare:Number):void{

			var theta:Number;
			var lim:Number;

			var dy:Number=ptd.y-pt.y;
			var dx:Number=ptd.x-pt.x;

			var dis:Number=dx*dx+dy*dy;

			// we save some times using square
			if (dis>dsquare){
				theta=Math.atan2(dy,dx);
				lim=Math.sqrt(dsquare);
				ptd.x=pt.x+Math.cos(theta)*lim;
				ptd.y=pt.y+Math.sin(theta)*lim;
			}
		}

		/**
		*	matric correction
		*
		*/
		private static function ordMatrix(mat:Matrix,spt:Point,opw:Number,oph:Number,ish:Boolean,cPoints:Array,pPoint:Array,gama:Number,beta:Number):void{

			if (spt.x==1 && spt.y==0){
				mat.tx=cPoints[0].x;
				mat.ty=cPoints[0].y;
				if (!ish){
					mat.tx=cPoints[0].x-Math.cos(gama)*opw-Math.cos(-beta)*oph;
					mat.ty=cPoints[0].y-Math.sin(gama)*opw-Math.sin(-beta)*oph;
				}
			}

			if (spt.x==1 && spt.y==1){
				mat.tx=cPoints[0].x+Math.cos(-beta)*oph;
				mat.ty=cPoints[0].y+Math.sin(-beta)*oph;
				if (!ish){
					mat.tx=cPoints[0].x+Math.cos(-beta)*oph;
					mat.ty=cPoints[0].y-Math.sin(-beta)*oph;
				}
			}

			if (spt.x==0 && spt.y==0){
				mat.tx=cPoints[0].x-Math.cos(gama)*opw;
				mat.ty=cPoints[0].y-Math.sin(gama)*opw;
			}

			if (spt.x==0 && spt.y==1){
				mat.tx=cPoints[0].x-Math.cos(gama)*opw-Math.cos(-beta)*oph;
				mat.ty=cPoints[0].y-Math.sin(gama)*opw+Math.sin(-beta)*oph;
				if (!ish){
					mat.tx=cPoints[0].x;
					mat.ty=cPoints[0].y;
				}
			}
		}
	}
}