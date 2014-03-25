/*
The MIT License (MIT)

Copyright (c) 2014 Alexandru Ioan Pop
aip.messages@yahoo.co.uk

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
*/
package
{
	import com.bit101.components.List;
	import com.bit101.components.ListItem;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;
	import flash.display.NativeWindowType;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.describeType;
	import flash.utils.getTimer;
	
	[SWF(backgroundColor="0xFFFFFF", width="250", height="90", frameRate="60")]
	
	public class AIRCamTimer extends Sprite
	{
		//Asset Embeds
		[Embed(source="assets/camB.jpg")]
		private var B1:Class;
		private var camB:Bitmap=new B1();
		
		[Embed(source="assets/optB.jpg")]
		private var B2:Class;
		private var optB:Bitmap=new B2();
		
		[Embed(source="assets/conB.jpg")]
		private var B3:Class;
		private var conB:Bitmap=new B3();
		
		[Embed(source="assets/okB.jpg")]
		private var B4:Class;
		private var okB:Bitmap=new B4();
		
		[Embed(source="assets/startB.jpg")]
		private var B5:Class;
		private var stB:Bitmap=new B5();
		
		[Embed(source="assets/stopB.jpg")]
		private var B6:Class;
		private var stpB:Bitmap=new B6();
		
		[Embed(source="assets/disabled.png")]
		private var B7:Class;
		private var disB:Bitmap=new B7();
		
		[Embed(source="assets/JPGEncoderWorker.swf", mimeType="application/octet-stream")]
		private static var workerClass:Class;
		private var workerBytes:ByteArray=new workerClass();
		
		//Window stuff
		private var cameraWindow:NativeWindow;
		private var cameraWindowOptions:NativeWindowInitOptions=new NativeWindowInitOptions();
		private var optionsWindow:NativeWindow;
		private var cCenterWindow:NativeWindow=stage.nativeWindow;
		private var optionsWindowOptions:NativeWindowInitOptions=new NativeWindowInitOptions();
		private var ownedWindows:Array=new Array();
		
		private var cam:Camera;
		private var vd:Video;
		private var svd:StageVideo;
		
		private var hTF:TextField=new TextField();
		private var wTF:TextField=new TextField();
		private var fpsTF:TextField=new TextField();
		private var qTF:TextField=new TextField();
		private var textFormat:TextFormat=new TextFormat();;
		private var textFormat2:TextFormat=new TextFormat();
		private var noCamTF:TextField=new TextField();
		private var expl1:TextField=new TextField();
		private var dirTF:TextField=new TextField();
		private var timerTF:TextField=new TextField();
		private var intervalTF:TextField=new TextField();
		
		private var camW:int, camH:int, camFPS:int, imgQ:int;
		
		private var imgFile:File=new File();
		private var nativeFile:File;
		private var fileStream:FileStream;
		
		private var dt:Date;
		private var updt:Timer=new Timer(1000);
		
		private var worker:Worker;
		private var wtm:MessageChannel; //workerToMain
		private var mtw:MessageChannel; //mainToWorker
		
		private var imgBA:ByteArray=new ByteArray();
		private var bmpd:BitmapData;
		private var img:Bitmap;
		
		private var fname:String=new String();
		
		private var svA:Boolean; //StageVideo available?
		
		private var directory:String;
		
		private var photoTimer:Timer=new Timer(5000);
		
		private var dirSel:Boolean=false;
		
		private var capInt:int; //time interval between pictures
		private var startX:int; //initial window coordinates
		private var startY:int;
		
		private var camSB:SimpleButton=new SimpleButton(camB, camB, camB, camB);
		private var optSB:SimpleButton=new SimpleButton(optB, optB, optB, optB);
		private var conSB:SimpleButton=new SimpleButton(conB, conB, conB, conB);
		private var okSB:SimpleButton=new SimpleButton(okB, okB, okB, okB);
		private var staSB:SimpleButton=new SimpleButton(stB, stB, stB, stB);
		private var stpSB:SimpleButton=new SimpleButton(stpB, stpB, stpB, stpB);
		
		private var disabled:Sprite=new Sprite(); //disabled overlay on the Start button
		
		private var iniT:int;
		
		private var selectedCam:int=0;
		private var currentCam:int=-1;
		
		private var camList:List;
		
		public function AIRCamTimer()
		{
			camW=320; camH=240; camFPS=15; imgQ=100;

			textFormat.align=TextFormatAlign.JUSTIFY; textFormat.size=25;
			textFormat2.align=TextFormatAlign.JUSTIFY; textFormat2.size=15;
			
			startX=355; startY=200; //main window initial position
			
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, setStageVideo, false, 0, true);
			setAllWindows();			//initialize the windows
			work(); 					//initialize the worker
			setCam(selectedCam);					//initialize camera
			updt.addEventListener(TimerEvent.TIMER, refFileName);
			updt.start();
			photoTimer.addEventListener(TimerEvent.TIMER, tick);
			fileStream=new FileStream();
			
			//temporary
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyD);
		}
		private function tick(e:TimerEvent):void
		{
			capture();
		}
		private function setStageVideo(e:StageVideoAvailabilityEvent):void
		{
			if(e.availability==StageVideoAvailability.AVAILABLE) svA=true;
			else svA=false;
			refreshCameraWindow();
		}
		private function work():void
		{
			worker=WorkerDomain.current.createWorker(workerBytes);
			
			mtw=Worker.current.createMessageChannel(worker);
			wtm=worker.createMessageChannel(Worker.current);
			
			worker.setSharedProperty("wtm", wtm);
			worker.setSharedProperty("mtw", mtw);
			imgBA.shareable=true;
			worker.setSharedProperty("imgBA", imgBA);
			
			worker.addEventListener(Event.WORKER_STATE, ifRunning);
			wtm.addEventListener(Event.CHANNEL_MESSAGE, rcv);
			
			worker.start();
		}
		private function ifRunning(e:Event):void
		{
			if(worker.state==WorkerState.RUNNING) mtw.send("initialize");
		}
		private function rcv(e:Event):void
		{
			var s:String=wtm.receive();
			trace("d:"+s);
			if(s=="0DONE")
			{
				if(dirSel)
				{
					imgFile.url=directory+"/"+fname+".jpg";
					nativeFile=new File(imgFile.nativePath);
					//fileStream=new FileStream();
					fileStream.open(nativeFile, FileMode.WRITE);
					var ba2:ByteArray=new ByteArray();
					ba2=imgBA;
					//fileStream.writeBytes(imgBA, 0, imgBA.length);
					fileStream.writeBytes(ba2, 0, ba2.length);
					fileStream.close();
				}
			}
		}
		private function keyD(e:KeyboardEvent):void
		{
			if(e.keyCode==32)
			{
				if (cam) capture();
			}
		}
		private function capture():void
		{
			imgBA.clear();
			
			bmpd=new BitmapData(cam.width, cam.height);
			cam.drawToBitmapData(bmpd);
			bmpd.copyPixelsToByteArray(bmpd.rect, imgBA);
					
			worker.setSharedProperty("imgWidth", cam.width);
			worker.setSharedProperty("imgHeight", cam.height);
			worker.setSharedProperty("imgQ", imgQ);
				
			mtw.send("encode");
		}

		
		private function refFileName(e:TimerEvent):void
		{
			if(dirSel && cam && capInt) disabled.visible=false;
			
			var y:int;
			var mo:int;
			var d:int;
			var h:int;
			var m:int;
			var s:int;
			
			fname=new String();
			dt=new Date();
			y=dt.fullYear; mo=dt.month+1; d=dt.date; h=dt.hours; m=dt.minutes; s=dt.seconds;
			fname=fname+y.toString();
			if(mo<10) fname+="0";
			fname+=mo.toString();
			if(d<10) fname+="0";
			fname+=d.toString();
			if(h<10) fname+="0";
			fname+=h.toString();
			if(m<10) fname+="0";
			fname+=m.toString();
			if(s<10) fname+="0";
			fname+=s.toString();
		}
		private function setCam(value:int):void
		{
			if(value>=0 && value<=Camera.names.length)
			{
				cam=Camera.getCamera(value.toString());
				if(cam)
				{
					cam.setMode(camW, camH, camFPS);
					cam.setQuality(0, 100);
					refreshCameraWindow();
					wTF.text=cam.width.toString(); hTF.text=cam.height.toString(); fpsTF.text=cam.fps.toString();
				}
			}
		}
		private function refreshCameraWindow():void
		{
			if(cam)
			{
				if(!svA)
				{
					vd=new Video(cam.width, cam.height);
					vd.attachCamera(cam);
					cameraWindow.stage.addChild(vd);
				}
				else
				{
					if(vd) cameraWindow.stage.removeChild(vd), vd.attachCamera(null), vd=null;
					svd=cameraWindow.stage.stageVideos[1];
					svd.attachCamera(cam);
					svd.addEventListener(StageVideoEvent.RENDER_STATE, svdResize, false, 0, false);
				}
				cameraWindow.width=cam.width;
				cameraWindow.height=cam.height;
			}
		}
		private function svdResize(e:StageVideoEvent):void
		{
			svd.viewPort=new Rectangle(0, 0, cam.width, cam.height);
		}
		private function setAllWindows():void
		{
			setControlCenter();
			setOptionsWindow();
			setCameraWindow();
			ownedWindows.push(cameraWindow);
			ownedWindows.push(optionsWindow);
		}
		private function setControlCenter():void
		{
			cCenterWindow.alwaysInFront=true;
			cCenterWindow.title="AIRCamTimer";
			cCenterWindow.addEventListener(Event.CLOSE, closeAll);
			cCenterWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, dispChange);
			cCenterWindow.stage.nativeWindow.x=startX;
			cCenterWindow.stage.nativeWindow.y=startY;
			
			//Button stuff
			camSB.x=camSB.y=10;
			optSB.x=camSB.x+camSB.width+10; optSB.y=10;
			stpSB.x=staSB.x=optSB.x+optSB.width+10; stpSB.y=staSB.y=10;
			camSB.addEventListener(MouseEvent.CLICK, camWInvoked);
			optSB.addEventListener(MouseEvent.CLICK, optWInvoked);
			staSB.addEventListener(MouseEvent.CLICK, startCapture);
			stpSB.addEventListener(MouseEvent.CLICK, stopCapture);
			cCenterWindow.stage.addChild(camSB);
			cCenterWindow.stage.addChild(optSB);
			cCenterWindow.stage.addChild(stpSB);
			cCenterWindow.stage.addChild(staSB);
			//
			disabled.addChild(disB);
			cCenterWindow.stage.addChild(disabled);
			disabled.x=staSB.x; disabled.y=staSB.y; disabled.alpha=0.6;
		}
		
		private function stopCapture(e:MouseEvent):void
		{
			photoTimer.stop();
			stpSB.visible=false;
			staSB.visible=true;
		}
		
		private function startCapture(e:MouseEvent):void
		{
			if(!photoTimer.running && dirSel) photoTimer.start();
			staSB.visible=false;
			stpSB.visible=true;
		}
		private function dispChange(e:NativeWindowDisplayStateEvent):void
		{
			var camSt:Boolean, opSt:Boolean;
			if(e.beforeDisplayState=="normal" && e.afterDisplayState=="minimized")
			{
				camSt=cameraWindow.visible; opSt=optionsWindow.visible;
			}
			if(e.beforeDisplayState=="minimized" && e.afterDisplayState=="normal")
			{
				cameraWindow.visible = camSt; optionsWindow.visible = opSt;
			}
		}
		private function setCameraWindow():void
		{
			cameraWindowOptions.type=NativeWindowType.UTILITY;
			cameraWindowOptions.resizable=false;
			cameraWindowOptions.renderMode=NativeWindowRenderMode.DIRECT;
			cameraWindow=new NativeWindow(cameraWindowOptions);
			cameraWindow.title="Camera Feed";
			cameraWindow.activate();
			cameraWindow.visible=false;
			cameraWindow.addEventListener(Event.CLOSING, windowClosing);
			cameraWindow.stage.scaleMode=StageScaleMode.NO_SCALE;
			cameraWindow.stage.align=StageAlign.TOP_LEFT;
			noCamTF.defaultTextFormat=textFormat; noCamTF.text="No camera selected";
			noCamTF.autoSize=TextFieldAutoSize.LEFT;
			cameraWindow.stage.stageWidth=noCamTF.width; cameraWindow.stage.stageHeight=noCamTF.textHeight;
			cameraWindow.stage.addChild(noCamTF);
		}
		private function setOptionsWindow():void
		{
			optionsWindowOptions.type=NativeWindowType.UTILITY;
			optionsWindowOptions.resizable=false;
			optionsWindow=new NativeWindow(optionsWindowOptions);
			optionsWindow.title="Options";
			optionsWindow.width=300;
			optionsWindow.height=430;
			optionsWindow.activate();
			optionsWindow.stage.scaleMode=StageScaleMode.NO_SCALE;
			optionsWindow.stage.align=StageAlign.TOP_LEFT;
			optionsWindow.visible=false;
			optionsWindow.maxSize=optionsWindow.minSize=new Point(optionsWindow.width, optionsWindow.height); 
			optionsWindow.addEventListener(Event.CLOSING, windowClosing);
			//Moar buttons
			optionsWindow.stage.addChild(conSB);
			conSB.x=5;
			conSB.y=optionsWindow.stage.stageHeight-conSB.height-5;
			conSB.addEventListener(MouseEvent.CLICK, detectCams);
			
			optionsWindow.stage.addChild(okSB);
			okSB.x=optionsWindow.stage.stageWidth-okSB.width-5; okSB.y=conSB.y;
			okSB.addEventListener(MouseEvent.CLICK, applyOptions);
			//TextFields
			
			intervalTF.defaultTextFormat=textFormat; intervalTF.restrict="0-9."; intervalTF.maxChars=5;
			intervalTF.text="interval";
			
			wTF.defaultTextFormat=textFormat; wTF.restrict="0-9"; wTF.maxChars=5;
			hTF.defaultTextFormat=textFormat; hTF.restrict="0-9"; hTF.maxChars=5;
			fpsTF.defaultTextFormat=textFormat; fpsTF.restrict="0-9"; fpsTF.maxChars=5;
			qTF.defaultTextFormat=textFormat; qTF.restrict="0-9"; qTF.maxChars=5;
			expl1.defaultTextFormat=textFormat2; expl1.multiline=true; expl1.width=optionsWindow.stage.stageWidth-10;
			
			expl1.text="Input the desired width, height, FPS of the stream and the quality of the saved image" +
				", then hit OK. The" +
				" application will try to set it to the closest supported specification. This may" +
				" not always work as expected. Select a camera from the list and hit the CONnect button"+
				", which also reconnects to the camera if previously selected. If no cameras are detected "+
				"check the connection and restart the application.";
						
			wTF.addEventListener(MouseEvent.CLICK, clickedTF);
			hTF.addEventListener(MouseEvent.CLICK, clickedTF);
			fpsTF.addEventListener(MouseEvent.CLICK, clickedTF);
			qTF.addEventListener(MouseEvent.CLICK, clickedTF);
			intervalTF.addEventListener(MouseEvent.CLICK, clickedTF);
			
			wTF.type=TextFieldType.INPUT;
			wTF.text="123456"; wTF.height=wTF.textHeight; wTF.width=wTF.textWidth; 
			wTF.x=optionsWindow.stage.stageWidth/5-wTF.width/2; wTF.y=5; wTF.text=camW.toString();
			
			hTF.type=TextFieldType.INPUT;
			hTF.text="123456"; hTF.height=hTF.textHeight; hTF.width=hTF.textWidth; 
			hTF.x=optionsWindow.stage.stageWidth*2/5-hTF.width/2; hTF.y=5; hTF.text=camH.toString();
			
			fpsTF.type=TextFieldType.INPUT;
			fpsTF.text="123456"; fpsTF.height=fpsTF.textHeight; fpsTF.width=fpsTF.textWidth;
			fpsTF.x=optionsWindow.stage.stageWidth*3/5-fpsTF.width/2; fpsTF.y=5; fpsTF.text=camFPS.toString();
			
			qTF.type=TextFieldType.INPUT;
			qTF.text="123456"; qTF.height=qTF.textHeight; qTF.width=qTF.textWidth;
			qTF.x=optionsWindow.stage.stageWidth*4/5-qTF.width/2; qTF.y=5; qTF.text=imgQ.toString();
			qTF.maxChars=3;
			
			expl1.height+=90; expl1.x=5; expl1.y=wTF.height+wTF.y+5; expl1.wordWrap=true; expl1.selectable=false;
			expl1.height=expl1.textHeight+5;
			
			dirTF.defaultTextFormat=textFormat2; dirTF.text="Click to select where to save the images.";
			dirTF.x=5; dirTF.y=expl1.y+expl1.textHeight+5; dirTF.selectable=false;
			dirTF.width=optionsWindow.stage.stageWidth-10; optionsWindow.stage.addEventListener(MouseEvent.CLICK, browseForDir);
			dirTF.height=dirTF.textHeight+3;
			
			intervalTF.type=TextFieldType.INPUT;
			intervalTF.type=TextFieldType.INPUT;
			intervalTF.text="interval"; intervalTF.height=intervalTF.textHeight; intervalTF.width=intervalTF.textWidth+10;
			intervalTF.x=dirTF.x; intervalTF.y=dirTF.y+dirTF.height;
			intervalTF.addEventListener(FocusEvent.FOCUS_OUT, unfocusedInterval);

			optionsWindow.stage.addChild(wTF);
			optionsWindow.stage.addChild(hTF);
			optionsWindow.stage.addChild(fpsTF);
			optionsWindow.stage.addChild(qTF);
			optionsWindow.stage.addChild(dirTF);
			optionsWindow.stage.addChild(expl1);
			optionsWindow.stage.addChild(intervalTF);
			//
			rebuildCamList();
		}
		private function rebuildCamList():void
		{
			if(Camera.names.length>0)
			{
				camList = new List(optionsWindow.stage, 5, intervalTF.y + intervalTF.height + 5, Camera.names);
				noCamTF.visible=false;
			}
			else
			{
				camList = new List(optionsWindow.stage, 5, intervalTF.y + intervalTF.height + 10, ["No cameras detected"]);
			}
			camList.addEventListener(Event.SELECT, choseCam);
			camList.alternateRows=true;
			camList.autoHideScrollBar=true;
			camList.width=optionsWindow.width-17;
			camList.height=optionsWindow.stage.stageHeight-camList.y-10-conB.height;
		}
		private function choseCam(e:Event):void
		{
			currentCam=selectedCam;
			selectedCam=camList.selectedIndex;
		}
		private function unfocusedInterval(e:FocusEvent):void
		{
			if(intervalTF.text.charAt(intervalTF.text.length-1)!='s') intervalTF.appendText(" s");
		}
		private function browseForDir(e:MouseEvent):void
		{
			if(e.target==dirTF)
			{
				imgFile.browseForDirectory("Select a directory...");
				imgFile.addEventListener(Event.SELECT, selectedDir);
			}
		}
		private function selectedDir(e:Event):void
		{
			var auxi:int, auxs:String;
		//
		//	testTimer.start();
			dirSel=true;
			directory=imgFile.url;
			dirTF.text=imgFile.url; dirTF.text=dirTF.text.substr(8);
			dirTF.text=dirTF.text.replace(/%20/g, " ");
			if(dirTF.textWidth>dirTF.width)
			{
				auxi=dirTF.text.lastIndexOf("/");
				auxs=dirTF.text.substr(auxi);
				dirTF.text=dirTF.text.slice(0, 3);
				dirTF.text=dirTF.text.concat("...");
				dirTF.text=dirTF.text.concat(auxs);
			}
		}
		private function applyOptions(e:MouseEvent):void
		{
			camW=int(wTF.text);
			camH=int(hTF.text);
			camFPS=int(fpsTF.text);
			imgQ=int(qTF.text);
			capInt=int(intervalTF.text.slice(0, intervalTF.text.search("s")));
			if(imgQ>100)
			{
				imgQ=100; qTF.text="100";
			}
			if(cam && (camW!=cam.width || camH!=cam.height || camFPS!=cam.fps || currentCam!=selectedCam)) setCam(selectedCam);
			if(capInt!=photoTimer.delay/1000) resetTimer();
			optionsWindow.visible=false;
		}
		private function resetTimer():void
		{
			if(photoTimer.running) photoTimer.stop();
			photoTimer.delay=capInt*1000;
			stopCapture(new MouseEvent(MouseEvent.MOUSE_DOWN));
		}
		private function detectCams(e:MouseEvent):void
		{
		//	rebuildCamList();
			setCam(selectedCam);
		}
		private function clickedTF(e:MouseEvent):void
		{
			(e.target as TextField).setSelection(0, (e.target as TextField).length);
		}
		private function windowClosing(e:Event):void
		{
			e.target.visible=false;
			e.preventDefault();
			if(e.target==optionsWindow && cam)
			{
				wTF.text=cam.width.toString(); hTF.text=cam.height.toString(); fpsTF.text=cam.fps.toString();
				qTF.text=cam.quality.toString();
			}
		}
		private function camWInvoked(e:MouseEvent):void
		{
			if(cameraWindow.visible)
			{
				cameraWindow.visible=false;
			}
			else
			{
				cameraWindow.visible=true;
				cameraWindow.orderToFront();
			}
		}
		private function optWInvoked(e:MouseEvent):void
		{
			if(optionsWindow.visible)
			{
				optionsWindow.visible=false;
			}
			else
			{
				optionsWindow.visible=true;
				optionsWindow.orderToFront();
			}	
		}
		private function closeAll(e:Event):void
		{
			var n:int=ownedWindows.length;
			var i:int;
			
			for(i=0; i<n; i++)
				ownedWindows[i].close();
		}
	}
}