package jp.archilogic.docnext.ui
{
	import mx.containers.Canvas;
	
	public class Restriction extends Canvas
	{
		public function Restriction()
		{
			super();
			
			ui = new RestrictionUI();
			addChild( ui );
		}
		
		private var ui : RestrictionUI;
	}
}