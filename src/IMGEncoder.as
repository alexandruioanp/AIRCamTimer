package
{	
	import com.adobe.images.JPGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	
	public class IMGEncoder extends Sprite
	{
		private var mtw:MessageChannel;
		private var wtm:MessageChannel;
		private var imgBA:ByteArray;
		private var imgBMD:BitmapData;
		private var w:int;
		private var h:int;
		private var jpgE:JPGEncoder;
		private var imgF:File;
		
		private var worker:Worker;
		
		public function IMGEncoder()
		{
			trace("worker created");
			worker=Worker.current;
			wtm=worker.getSharedProperty("wtm") as MessageChannel;
			mtw=worker.getSharedProperty("mtw") as MessageChannel;
			
			mtw.addEventListener(Event.CHANNEL_MESSAGE, rcv);
			wtm.send("test");
		}
		protected function rcv(e:Event):void
		{
			trace("LALALAL");
			var s:String=mtw.receive();
			trace(s);
			if(s=="encode")
			{
				wtm.send("roger");
				trace("ENCODING");
				imgBA=worker.getSharedProperty("imgBA");
				w=worker.getSharedProperty("imgWidth");
				h=worker.getSharedProperty("imgHeight");
				//jpgE=new JPEGEncoder(worker.getSharedProperty("imgQ"));
				
				imgBA.position=0;
				imgBMD=new BitmapData(w, h, false);
				imgBMD.setPixels(imgBMD.rect, imgBA);
				jpgE.encode(imgBMD);
				save();
			}
		}
		private function save():void
		{
			imgF=new File(worker.getSharedProperty("path")+worker.getSharedProperty("fname")+".jpg");
			trace(imgF.url);
		}
	}
}