package
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class JPGEncoderWorker extends Sprite
	{
		private var mtw:MessageChannel;
		private var wtm:MessageChannel;
		private var imgBA:ByteArray;
		private var imgBMD:BitmapData;
		private var imgWidth:int;
		private var imgHeight:int;
		private var jpgE:JPEGEncoder;
		
		private var worker:Worker;
		
		public function JPGEncoderWorker()
		{
			worker=Worker.current;
			wtm=worker.getSharedProperty("wtm");
			mtw=worker.getSharedProperty("mtw");
			
			mtw.addEventListener(Event.CHANNEL_MESSAGE, rcv);
		}
		protected function rcv(e:Event):void
		{
			var s:String=mtw.receive();
			if(s=="encode")
			{
				imgBA=worker.getSharedProperty("imgBA");
				imgWidth=worker.getSharedProperty("imgWidth");
				imgHeight=worker.getSharedProperty("imgHeight");
				jpgE=new JPEGEncoder(worker.getSharedProperty("imgQ"));
								
				imgBA.position=0;
				imgBMD=new BitmapData(imgWidth, imgHeight, false); 
				
				imgBA.position=0;
				imgBMD.setPixels(imgBMD.rect, imgBA);
				
				var tempBA:ByteArray=new ByteArray();
				imgBA.clear();
				tempBA=jpgE.encode(imgBMD);
				imgBA.writeBytes(tempBA, 0, tempBA.length);
				wtm.send("0DONE");
			}
		}
	}
}