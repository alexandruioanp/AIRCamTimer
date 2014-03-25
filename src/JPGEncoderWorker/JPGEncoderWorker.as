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
		private var w:int;
		private var h:int;
		private var jpgE:JPEGEncoder;
		
		private var worker:Worker;
		
		private var done:Boolean=false;
		
		private var iniT:int;
		private var finT:int;
		
		public function JPGEncoderWorker()
		{
			worker=Worker.current;
			wtm=worker.getSharedProperty("wtm");
			mtw=worker.getSharedProperty("mtw");
			
			mtw.addEventListener(Event.CHANNEL_MESSAGE, rcv);
			//wtm.send("Worker ready");
		}
		protected function rcv(e:Event):void
		{
			var s:String=mtw.receive();
			done=true;
			if(s=="encode" && done)
			{
				//wtm.send("ENCODING");
				done=false;
				iniT=getTimer();
				imgBA=worker.getSharedProperty("imgBA");
				w=worker.getSharedProperty("imgWidth");
				h=worker.getSharedProperty("imgHeight");
				jpgE=new JPEGEncoder(worker.getSharedProperty("imgQ"));
								
				imgBA.position=0;
				imgBMD=new BitmapData(w, h, false);
				
				imgBA.position=0;
				imgBMD.setPixels(imgBMD.rect, imgBA);
				
				var tempBA:ByteArray=new ByteArray();
				imgBA.clear();
				tempBA=jpgE.encode(imgBMD);
				imgBA.writeBytes(tempBA, 0, tempBA.length);
				finT=getTimer();
				wtm.send("0DONE");
				wtm.send("A"+(finT-iniT).toString());
				done=false;
			}
			else if(s=="encode" && done==false)
			{
				wtm.send("not now");
			}
		}
	}
}