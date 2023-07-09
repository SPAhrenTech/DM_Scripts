//Calibrate deflectors - P. Ahrenkiel, 2019
module com.gatan.dm.defcalib

uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog
uses com.gatan.dm.jemthread
uses com.gatan.dm.jemprefs
uses com.gatan.dm.smartacq

number DEFCALIB_display=0
number DEFCALIB_online=1
string DEFCALIB_sDeflector="PLA"
number DEFCALIB_showCC=1
string DEFCALIB_sModeExt="MAG"

string DEFCALIB_sGroup="DEFCALIB"
string DEFCALIB_sName="DefCalib"
string DEFCALIB_sTitle="Deflector Calibration"
number DEFCALIB_echo=0
string DEFCALIB_sHelpFilename="DEFCALIB_Help.docx"

string sISBalImageName="ISBAL_bal"

//
class DefCalibMsg:ThreadMsg
{
}

//
interface DefCalibProto
{
	number getImageShiftMAGMode(object self);
	void setImageShiftMAGMode(object self,number x);
	TagGroup getPrefsGroup(object self);
	object getQueue(object self);
	object newMessage(object self,object &m);

	void clearQueue(object self);
	object allocDeflector(object self,string sShortName);
	//string getShortName(object self,string sName);
	number getDefScaleFactor(object self,object def,string sUnits,number lambd,number upix_size,string sMode);
	string getScaleString(object self,string sDefShortName,string sMode);
	string getScaleString(object self,object def,string sMode);
	void begin(object self,number id);
	number endScale(object self,number status);
	number endCalib(object self,number status);
	number endScaleCalib(object self,number status);
	number scale(object self,object src,TagGroup tags,object objs,object def,string sModeExt,number saveResult);
	number calib(object self,object src,TagGroup tags,object objs,object def,string sModeExt,number saveResult,image calDefImg);

}

//
string getSimpleMode()
{
	number mode;string sMode;JEM_getFunctionMode(mode,sMode);
	if(sMode!="DIFF")sMode="MAG"
	return sMode
}


void addColumn(image &img)
{
	number xSize,ySize
	GetSize(img,xSize,ySize)

	string s=GetName(img)
	
	image timg:=RealImage("temp",4,xSize,ySize)
	timg=img
	DeleteImage(img)
				
	img:=RealImage(s,4,xSize+1,ySize)
	img=0
	img[0,0,ySize,xSize]=timg
	DeleteImage(timg)
	SetName(img,s)
}


//
class DefCalibScale:JEM_Widget
{
	void runThread(object self)
	{
		result("---------------\n")
		self.super.begin()
		object owner=self.super.getOwner()

		TagGroup tags
		object objs
		{
			object msg
			if(self.receiveMessage(msg))
			{
				msg.getTags(tags)
				msg.getObjs(objs)
			}
			else return
		}
		object progInfo;if(!getWidget("ProgInfo",progInfo)){self.abort();return;}
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}
		object def;if(!getObj(objs,"deflector",def)){fillObj(objs,"deflector",def=owner.allocDeflector(DEFCALIB_sDeflector).load(),1);}

		string sModeExt;if(!getTag(tags,"extended mode",sModeExt)){sModeExt=DEFCALIB_sModeExt;}

		number online;owner.getData("online",online)	
		TagGroup imgPosList;owner.getData("image position",imgPosList)
		number showCC;owner.getData("show cross correlation",showCC)
		TagGroup ccPosList;owner.getData("cc position",ccPosList)
		number ccRatio;owner.getData("scaling cross correlation ratio",ccRatio)

		//number doProcess;if(!getTag(tags,"process",doProcess)){doProcess=0;fillTag(tags,"process",doProcess,1);}

		//acq.prepForAcquire(camCalib,acqCtrl)
		//acq.checkRefImages(camCalib)
		
		if(self.isOrigin()){}
		object camera;acq.getCamera(camera)		
		number bin
		camera.getBinning(bin,bin)
		number sizeX,sizeY
		camera.getBinnedSize(sizeX,sizeY)
	
		image ccImg:=realImage("cc",4,sizeX,sizeY)
		number x0=sizeX/2,y0=sizeY/2
		number sizeXY=(sizeX**2+sizeY**2)**0.5

		number prevLensOnline;def.getOnline(prevLensOnline)
		def.setOnline(online*prevLensOnline)

		number defX0,defY0
		def.read(defX0,defY0);
		string sDefShortName;def.getShortName(sDefShortName)
		result("scaling "+sDefShortName+"\n")
		result("def: ("+defX0+", "+defY0+")\n")
		//def.set(0,0)
		
		number defX,defY
		
		TagGroup calTag=camCalib.getTags()
		number upixSize;string sUnits
		calTag.TagGroupGetTagAsNumber("Alternative unbinned pixel size",upixSize)
		calTag.TagGroupGetTagAsString("Alternative units",sUnits)
			
		if(sDefShortName=="PLA"){upixSize=1;sUnits="upix";}
		//
		RealImage dDefImg,duPixImg
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		
		image img,img0,acqImg
		number zoom=0.25
		number defRange=16,imax			
		number iDef=0,phase=0,limitFound=0
		number defScale
		number actionKey=progInfo.addProgress("Scaling "+sDefShortName)
		number stepKey=progInfo.addProgress("")
		number imax0
		while(self.super.isAlive())
		{
			number doNext=0	
			if(!self.super.isPaused())
			{					
				if(phase==0)//get reference
				{
					progInfo.setProgress(stepKey,"Getting reference").showProgress()
					def.write(defX0,defY0);	
					if(acq.acquire(acqImg,self,tags,objs,0))
					{				
						img=acqImg.ImageClone()
						ShowImage(img);zoomSize(img,zoom)
						setWindowSize(img,sizeX*zoom,sizeY*zoom)
						setImagePositionWithinWindow(img,0,0)
						number imgX,imgY;
						imgPosList.tagGroupGetIndexedTagAsNumber(0,imgX)
						imgPosList.tagGroupGetIndexedTagAsNumber(1,imgY)
						setWindowPosition(img,imgX,imgY)					

						img0=acqImg.ImageClone()
						iDef=0
						ccImg=CrossCorrelateAnything(img0,img0)
						if(showCC)
						{	showImage(ccImg);ZoomSize(ccImg,zoom);
							setWindowSize(ccImg,sizeX*zoom,sizeY*zoom)
							setImagePositionWithinWindow(ccImg,0,0)
							number ccX,ccY;
							ccPosList.tagGroupGetIndexedTagAsNumber(0,ccX)
							ccPosList.tagGroupGetIndexedTagAsNumber(1,ccY)
							setWindowPosition(ccImg,ccX,ccY)					
						}
						number xm,ym
						imax0=max(ccimg,xm,ym)					
						doNext=1
					}
				}
				
				//
				if(phase==1)
				{
					progInfo.setProgress(stepKey,"Increasing range...").showProgress()
					defX=defX0+defRange;defY=defY0+defRange
					if(!def.validRange(defX,defY))
					{	def.scaleRange(defX,defY);limitFound=1;
						result("out of range\n");}				
					
					string sRes="def: ("+defX+", "+defY+")"
					def.write(defX,defY)
					if(acq.acquire(acqImg,self,tags,objs,0))
					{
						img=acqImg.ImageClone()
						updateImage(img)
						ccImg=crossCorrelateAnything(img,img0)
						if(showCC)updateImage(ccImg)
						number xm,ym
						imax=max(ccImg,xm,ym)
						number dx=bin*(xm-x0),dy=bin*(ym-y0)		
						number dr=(dx**2+dy**2)**0.5
						sRes+=", shift (upix): "+dr+"\n"
						result(sRes)
						if(dr>sizeXY/2){limitFound=1;result("found range\n");}
						if(imax<imax0/ccRatio){limitFound=1;result("low cross correlation\n");}
						
						if(!limitFound)
						{
							if(iDef==0)
							{
								dDefImg:=RealImage("ddef",4,1,2)
								duPixImg:=RealImage("upix",4,1,2)
								//sigImg:=RealImage("sig",4,1,2)
							}
							else
							{
								addColumn(dDefImg)
								addColumn(duPixImg)
								//addColumn(sigImg)
							}
							number sig=1/imax**0.5
							dDefImg[iDef,0]=sig*defRange
							duPixImg[iDef,0]=sig*dr
							defRange*=1.5
							iDef++
						}
					}
					else
					{
						//result("acq error\n");
						self.super.abort()
					}
					if(limitFound)
					{
						if(iDef==0)
							self.super.abort()
						else
						{
							number numer=sum(dDefImg*duPiximg)
							number denom=sum(dDefImg**2)
							defScale=numer/denom*upixSize
							//lensScale=dr*upixSize/defRange
							result("Deflector scale: "+defScale+"\n")
							self.super.kill()
						}
					}
				}
			}
			if(doNext)phase++		
			yield()								
		}
		def.write(defX0,defY0);													

		if(self.super.isViable())
		{
			def.setScale(defScale)
			def.setUnits(sUnits)
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		def.setOnline(prevLensOnline)
		if(isValid(img))
		{
			if(isVisible(img))
			{
				number imgX,imgY;
				getWindowPosition(img,imgX,imgY)					
				imgPosList.tagGroupSetIndexedTagAsNumber(0,imgX)
				imgPosList.tagGroupSetIndexedTagAsNumber(1,imgY)
			}
			deleteImage(img)
		}
		if(isValid(ccImg))
		{
			if(isVisible(ccImg))
			{
				number ccX,ccY;
				getWindowPosition(ccImg,ccX,ccY)					
				ccPosList.tagGroupSetIndexedTagAsNumber(0,ccX)
				ccPosList.tagGroupSetIndexedTagAsNumber(1,ccY)
			}
			deleteImage(ccImg)
		}
		if(self.isOrigin())acqCtrl.endControlScreen();
		progInfo.deleteProgress(actionKey)
		progInfo.deleteProgress(stepKey)
		progInfo.showProgress()

		self.super.end()
	}

	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endScale(1)
	}	
}

//
class DefCalibCalibrate:JEM_Widget
{
	void runThread(object self)
	{
		result("---------------\n")
		self.super.begin()
		object owner=self.super.getOwner()
		
		TagGroup tags
		object objs
		{
			object msg
			if(self.receiveMessage(msg))
			{
				msg.getTags(tags)
				msg.getObjs(objs)
			}
			else return
		}
		object progInfo;if(!getWidget("ProgInfo",progInfo)){self.abort();return;}
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}
		object def;if(!getObj(objs,"deflector",def)){fillObj(objs,"deflector",def=owner.allocDeflector(DEFCALIB_sDeflector),1);}
		string sModeExt;if(!getTag(tags,"extended mode",sModeExt)){sModeExt=DEFCALIB_sModeExt;}

		number calDefImgExists=1;
		image calDefImg;if(!getTag(tags,"calibrated deflection list",calDefImg)){calDefImgExists=0;}
		number echo;owner.getData("echo",echo)	
		number online;owner.getData("online",online)	
		TagGroup imgPosList;owner.getData("image position",imgPosList)
		number showCC;owner.getData("show cross correlation",showCC)
		TagGroup ccPosList;owner.getData("cc position",ccPosList)
			
		//number doProcess;if(!getTag(tags,"process",doProcess)){doProcess=0;fillTag(tags,"process",doProcess,1);}

		//
		if(self.isOrigin()){}
		object camera;acq.getCamera(camera)
		number bin;camera.getBinning(bin,bin)
		number sizeX,sizeY;camera.getBinnedSize(sizeX,sizeY)
		image ccimg:=RealImage("cc",4,sizeX,sizeY)
		number x0=sizeX/2,y0=sizeY/2
		number sizeXY=(sizeX**2+sizeY**2)**0.5

		//def.defineOrigin()
		number prevLensOnline;def.getOnline(prevLensOnline)
		def.setOnline(online*prevLensOnline)

		string sDefShortName;def.getShortName(sDefShortName)
		result("calibrating "+sDefShortName+"\n")
		number defX0,defY0
		def.read(defX0,defY0);
		result("def: ("+defX0+", "+defY0+")\n")
		//the_def.set(0,0)
		
		TagGroup calTag=camCalib.getTags()
		number upixSize;string sUnits
		calTag.tagGroupGetTagAsNumber("Alternative unbinned pixel size",upixSize)
		calTag.tagGroupGetTagAsString("Alternative units",sUnits)
		if(sDefShortName=="PLA"){upixSize=1;sUnits="upix";}
		result("camera scale: "+upixSize+" upix/"+sUnits+"\n")						
		
		number lensScale;def.getScale(lensScale)
		string sLensUnit;def.getUnits(sLensUnit)
		result("lens scale: "+lensScale+" "+sLensUnit+"/lu\n")
		image dDefImg,calibImg

		number nDef,nDim
		image defImg,calImg			

		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		//
		image img,img0,acqImg
		number zoom=0.25
		number iDef=0,phase=0
		number actionKey=progInfo.addProgress("Calibrating "+sDefShortName)
		number stepKey=progInfo.addProgress("")
		while(self.super.isAlive())
		{
			number doNext=0	
			if(!self.super.isPaused())
			{								
				if(phase==0)//get reference and set range
				{
					def.write(defX0,defY0)
					if(calDefImgExists)
					{
						dDefImg=calDefImg/lensScale//lu
					}
					else
					{
						number calRange
						if(lensScale==0)
							calRange=0xFFFF
						else
							calRange=(bin*sizeXY)/6*upixSize/lensScale//lu

						dDefImg:=[12,2]:
							{{0.5,-0.5,0,0,0.5,-0.5,0.5,-0.5,1,-1,0,0},
							{0,0,0.5,-0.5,0.5,0.5,-0.5,-0.5,0,0,1,-1}}
						dDefImg*=calRange
					}
					getSize(dDefImg,nDef,nDim)		
					doNext=1
				}
				
				if(phase==1)//get reference and set range
				{
					progInfo.setProgress(stepKey,"Getting reference")
					progInfo.showProgress()
					if(acq.acquire(acqImg,self,tags,objs,0))
					{
						img:=acqImg.ImageClone()
						showImage(img);zoomSize(img,zoom)
						setWindowSize(img,sizeX*zoom,sizeY*zoom)
						setImagePositionWithinWindow(img,0,0)
						number imgX,imgY;
						imgPosList.tagGroupGetIndexedTagAsNumber(0,imgX)
						imgPosList.tagGroupGetIndexedTagAsNumber(1,imgY)
						setWindowPosition(img,imgX,imgY)					

						img0:=acqImg.ImageClone()
						iDef=0
						if(showCC)
						{	showImage(ccImg);ZoomSize(ccImg,zoom);
							setWindowSize(ccImg,sizeX*zoom,sizeY*zoom)
							setImagePositionWithinWindow(ccImg,0,0)
							number ccX,ccY;
							ccPosList.tagGroupGetIndexedTagAsNumber(0,ccX)
							ccPosList.tagGroupGetIndexedTagAsNumber(1,ccY)
							setWindowPosition(ccImg,ccX,ccY)					
						}
						doNext=1
					}
				}
				
				if(phase==2)
				{
					progInfo.setProgress(stepKey,"Step "+format(iDef+1,"%g")+"/"+format(nDef,"%g"))
					progInfo.showProgress()

					number dDefX=GetPixel(dDefImg,iDef,0),dDefY=GetPixel(dDefImg,iDef,1)
					number defX=dDefX+defX0,defY=dDefY+defY0
					string sRes="def: ("+defX+", "+defY+")"
					if(!def.validRange(defX,defY))
					{
						def.write(defX0,defY0)
						def.scaleRange(defX,defY);
						sRes+=", scaled:("+defX+", "+defY+")"
					}
					def.write(defX,defY)
					image imgp
					if(acq.acquire(acqImg,self,tags,objs,0))				
					{
						img=acqImg.imageClone()
						updateImage(img)
						//camera.acquire(img)
						ccimg=CrossCorrelateAnything(img,img0)
						if(showCC)
						{
							if(ccImg.imageCountImageDisplays()>0)
								updateImage(ccImg)
						}
						number xm,ym
						number imax=max(ccimg,xm,ym)
						number duPixX=bin*(xm-x0),duPixY=bin*(ym-y0)
						if(iDef==0)
						{
							defImg:=RealImage("def",4,1,nDim+1)
							calImg:=RealImage("cal",4,1,nDim)
						}
						else
						{
							addColumn(defImg)
							addColumn(calImg)
						}
						number sig=1/imax**0.5
						defImg[iDef,0]=sig*defX;defImg[iDef,1]=sig*defY;defImg[iDef,2]=sig*1
						calImg[iDef,0]=sig*duPixX*upixSize;calImg[iDef,1]=sig*duPixY*upixSize;
						result(sRes+", shift (upix): ("+duPixX+", "+duPixY+")\n")
						iDef++
						if(iDef>=nDef)doNext=1
					}
					else self.super.abort()							
				}
				
				if(phase==3)
				{	
					def.setEcho(1)
					image calibSubImg:=MatrixMultiply(calImg,rightPseudoInverse(defImg))
					calibImg:=realImage("calib",4,nDim+1,nDim+1)
					calibImg=((icol==irow)?1:0)
					calibImg[0,0,nDim,nDim+1]=calibSubImg				
					def.setCalib(calibImg)
					self.super.kill()
				}
			}
			if(doNext)phase++			
			yield()								
		}
		def.write(defX0,defY0);
		def.setOnline(prevLensOnline)
		if(isValid(img))
		{
			if(isVisible(img))
			{
				number imgX,imgY;
				getWindowPosition(img,imgX,imgY)					
				imgPosList.tagGroupSetIndexedTagAsNumber(0,imgX)
				imgPosList.tagGroupSetIndexedTagAsNumber(1,imgY)
			}
			deleteImage(img)
		}
		if(isValid(ccImg))
		{
			if(isVisible(ccImg))
			{
				number ccX,ccY;
				getWindowPosition(ccImg,ccX,ccY)					
				ccPosList.tagGroupSetIndexedTagAsNumber(0,ccX)
				ccPosList.tagGroupSetIndexedTagAsNumber(1,ccY)
			}
			deleteImage(ccImg)
		}
		if(self.isOrigin()&&(!prevScreen))acqCtrl.endControlScreen();
		progInfo.deleteProgress(actionKey)
		progInfo.deleteProgress(stepKey)
		progInfo.showProgress()
		if(self.super.isViable())
		{
			progInfo.setProgress(stepKey,"Finishing")
			progInfo.showProgress()
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		self.super.end()
	}

	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endCalib(1)
	}
	
}

//
class DefCalibScaleCalibrate:JEM_Widget
{
	void runThread(object self)
	{
		//result("---------------\n")
		self.super.begin()
		object owner=self.super.getOwner()
		
		TagGroup tags
		object objs
		{
			object msg
			if(self.receiveMessage(msg))
			{
				msg.getTags(tags)
				msg.getObjs(objs)
			}
			else return
		}
		object progInfo;if(!getWidget("ProgInfo",progInfo)){self.abort();return;}
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}
		object def;if(!getObj(objs,"deflector",def)){fillObj(objs,"deflector",def=owner.allocDeflector(DEFCALIB_sDeflector),1);}
		string sModeExt;if(!getTag(tags,"extended mode",sModeExt)){sModeExt=DEFCALIB_sModeExt;}
		number calDefImgExists=1;
		image calDefImg;if(!getTag(tags,"calibrated deflection list",calDefImg)){calDefImgExists=0;}
		
		//number useSMARTACQ;source.getData("use SmartAcq",useSMARTACQ)
		TagGroup calTag=camCalib.getTags()
		string sMode;calTag.TagGroupGetTagAsString("Mode",sMode)
	
		if(self.isOrigin()){}
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		number phase=0
		number actionKey=progInfo.addProgress("Scale & Calibrate")
		progInfo.showProgress()
		while(self.super.isAlive())
		{			
			number doNext=0
			if(!self.super.isPaused())
			{					
				if(phase==0)
				{
					if(owner.scale(self,tags,objs,def,sMode,1)){}
					else self.abort()
					doNext=1
				}

				if(phase==1)
				{
					
					if(calDefImgExists)
					{
						if(owner.calib(self,tags,objs,def,sMode,0,null)){}
						else self.abort()
					}
					else
					{
						if(owner.calib(self,tags,objs,def,sMode,0,calDefImg)){}
						else self.abort()
					}
					doNext=1
					self.super.kill()
				}
							
				}			
			if(doNext)phase++
			yield()						
		}
		if(self.isOrigin())acqCtrl.endControlScreen();
		if(self.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		self.super.end()
	}
	
	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endScaleCalib(1)
	}

}


//
class DefCalib:JEM_Widget
{	
	number online
	TagGroup defTag;
	TagGroup defList
	TagGroup defNameList
	
	string sDef,sSmartAcq
	object msg
	object scaleThread,calibThread,scaleCalibThread
	//object MAGCalibMode_dialog
	
//
	string getScaleString(object self,object deflector,string sModeExt)
	{
		string sShortName;deflector.getShortName(sShortName)
		string sUnits;deflector.getUnits(sUnits)
		string sScale="Est. "+sShortName
		if(sModeExt!="")sScale+=" "+sModeExt		
		return sScale+" scale ("+sUnits+"/lu)"
 	}

//
	number readScale(object self,object deflector,string sModeExt)
	{
		string sShortName;deflector.getShortName(sShortName)
		number echo;self.getEcho(echo)
		if(echo)result ("Reading prefs...\n")
		string sScaleString=self.getScaleString(deflector,sModeExt)
		//result(sScaleString+"\n")
		self.addData(sScaleString,1)
		number scale,res=self.readData(sScaleString)
		self.getData(sScaleString,scale)		
		if(res)deflector.setScale(scale)
		return res
	}

	//
	number writeScale(object self,object deflector,string sModeExt)
	{
		string sShortName;deflector.getShortName(sShortName)
		number echo;self.getEcho(echo)
		if(echo)result ("Writing prefs...\n")
		number scale;deflector.getScale(scale)
		string sScaleString=self.getScaleString(deflector,sModeExt)
		self.addData(sScaleString,scale)
		return self.writeData(sScaleString)
	}
	
	//
	number allocDeflector(object self,string sShortName,object &deflector)
	{
		number res=0
		if(sShortName=="CLA1")deflector=alloc(JEM_BeamShift)		
		if(sShortName=="CLA2")deflector=alloc(JEM_BeamTilt)

		if(sShortName=="IS1")deflector=alloc(JEM_ImageShift1)
		if(sShortName=="IS2")deflector=alloc(JEM_ImageShift2)
	
		if(sShortName=="ISBAL1")deflector=alloc(JEM_ImageShiftBal1)
		if(sShortName=="ISBAL2")deflector=alloc(JEM_ImageShiftBal2)
	
		if(sShortName=="PLA")deflector=alloc(JEM_ProjectorDef)

		if(deflector.scriptObjectIsValid())
		{
			number online;self.getData("online",online)
			number echo;self.getEcho(echo)
			deflector.setOnline(online).setEcho(echo).init();	
			res=1
		}
		return res;
	}

	//
	number getDeflectorMode(object self,object deflector,string &sModeExt)
	{
		string sShortName;deflector.getShortName(sShortName)
		number mode;string sMode;JEM_getFunctionMode(mode,sMode);
		sModeExt=sMode
		string sUnits
		
		if(sShortName=="PLA")
			sUnits="upix"
		else
			if(sMode=="DIFF")
				sUnits="mrad"
			else
			{
				sUnits="nm"
				if((sShortName=="IS1")||(sShortName=="IS2")||(sShortName=="ISBAL1")||(sShortName=="ISBAL2"))
				{					
					object dlg=alloc(MAGCALIBMODE).init()
					if(dlg.pose())
					{
						string sMAGCalibMode;dlg.getData("SA position",sMAGCalibMode)
						if(sMAGCalibMode=="SA in")
							sModeExt+=" SA"
					}
				}
				if((sShortName=="CLA2"))
				{					
					sModeExt+=" OA"
				}
			}
		deflector.setUnits(sUnits)
		return 1;
	}
	
	//
	object loadDeflector(object self,string sShortName,object &deflector,string sModeExt)
	{
		number echo;self.getEcho(echo);
		if(echo)result("loading "+sShortName+"\n")
		deflector=null

		if(sShortName=="CLA1")deflector=alloc(JEM_BeamShift).setEcho(echo)			
		if(sShortName=="CLA2")deflector=alloc(JEM_BeamTilt).setEcho(echo)

		if(sShortName=="IS1")deflector=alloc(JEM_ImageShift1).setEcho(echo)
		if(sShortName=="IS2")deflector=alloc(JEM_ImageShift2).setEcho(echo)

		if(sShortName=="ISBAL1")deflector=alloc(JEM_ImageShiftBal1).setEcho(echo)
		if(sShortName=="ISBAL2")deflector=alloc(JEM_ImageShiftBal2).setEcho(echo)
		if(sShortName=="PLA")deflector=alloc(JEM_ProjectorDef).setEcho(echo)

		if(deflector.scriptObjectIsValid())
		{
			if(sShortName=="PLA")
				deflector.setUnits("upix")
			else
				if(sModeExt=="DIFF")
					deflector.setUnits("mrad")
				else
					deflector.setUnits("nm")

			number online;self.getData("online",online);
			deflector.setEcho(echo).setOnline(online)
			if(echo)result("initing "+sShortName+"\n")			
			deflector.init()
		}
		return self
	}
	
	//
	object loadDeflector(object self,string sShortName,object &deflector)
	{
		number mode;string sMode;JEM_getFunctionMode(mode,sMode);//no MAG SA
		return self.loadDeflector(sShortName,deflector,sMode)
	}
	
	object allocDeflector(object self,string sShortName)
	{
		object def
		self.allocDeflector(sShortName,def);if(!def.scriptObjectIsValid())return null			
		return def
	}
	
	//Begin threads
	number beginScale(object self,number priority,number resolve,object src,TagGroup tags,object objs,object def,string sModeExt)
	{			
		if((priority<1)&&(self.isRunning()))return 0
		if(!def.scriptObjectIsValid())
		{
			string s;self.getData("deflector",s)		
			self.allocDeflector(s,def);if(!def.scriptObjectIsValid())return 0			
			if(!self.getDeflectorMode(def,sModeExt))return 0
		}
		fillTag(tags,"extended mode",sModeExt,1)
		fillObj(objs,"deflector",def,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(scaleThread.init(src,self,msg,resolve),priority)
	}

	//
	number beginCalib(object self,number priority,number resolve,object src,TagGroup tags,object objs,object def,string sModeExt,image calDefImg)
	{			
		if((priority<1)&&(self.isRunning()))return 0
		if(!def.scriptObjectIsValid())
		{
			string s;self.getData("deflector",s)		
			self.allocDeflector(s,def);if(!def.scriptObjectIsValid())return 0			
			string sModeExt;if(!self.getDeflectorMode(def,sModeExt))return 0
			if(!self.readScale(def,sModeExt)){OKDialog("Scale not found!");return 0;}
		}
		fillObj(objs,"deflector",def,1)
		fillTag(tags,"extended mode",sModeExt,1)
		if(isValid(calDefImg))fillTag(tags,"deflection list",calDefImg,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(calibThread.init(src,self,msg,resolve),priority)
	}

	//
	number beginScaleCalib(object self,number priority,number resolve,object src,TagGroup tags,object objs,object def,string sModeExt,image calDefImg)
	{			
		if((priority<1)&&(self.isRunning()))return 0
		if(!def.scriptObjectIsValid())
		{
			string s;self.getData("deflector",s)		
			self.allocDeflector(s,def);if(!def.scriptObjectIsValid())return 0			
			if(!self.getDeflectorMode(def,sModeExt))return 0
		}
		fillObj(objs,"deflector",def,1)
		fillTag(tags,"extended mode",sModeExt,1)
		if(isValid(calDefImg))fillTag(tags,"deflection list",calDefImg,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(scaleCalibThread.init(src,self,msg,resolve),priority)
	}

	//
	number endScale(object self,number saveResult)
	{
		TagGroup tags;
		object objs;
		object def
		string sModeExt
		object msg
		number status=scaleThread.receiveMessageOnSignal(msg)
		if(status)
		{
			msg.getTags(tags)
			msg.getObjs(objs)
			getObj(objs,"deflector",def)
			getTag(tags,"extended mode",sModeExt)
			if(saveResult)
				self.writeScale(def,sModeExt)
		}
		return status
	}

	number endCalib(object self,number saveResult)
	{
		TagGroup tags;
		object objs;
		object def
		object msg
		number status=calibThread.receiveMessageOnSignal(msg)
		if(status)
		{
			msg.getTags(tags)
			msg.getObjs(objs)
			getObj(objs,"deflector",def)
			if(saveResult)
				def.saveCalib()
		}
		return status
	}

	number endScaleCalib(object self,number saveResult)
	{
		TagGroup tags;
		object objs;
		object def
		string sModeExt
		object msg
		number status=scaleCalibThread.receiveMessageOnSignal(msg)
		if(status)
		{
			msg.getTags(tags)
			msg.getObjs(objs)
			getObj(objs,"deflector",def)
			getTag(tags,"extended mode",sModeExt)
			if(saveResult)
			{
				self.writeScale(def,sModeExt)
				def.saveCalib()
			}
		}
		return status
	}

	//Do threads
	number scale(object self,object src,TagGroup tags,object objs,object def,string sModeExt,number saveResult)
	{
		number status
		if(status=self.beginScale(1,0,src,tags,objs,def,sModeExt))
			status=self.endScale(saveResult)
		return status
	}

	number calib(object self,object src,TagGroup tags,object objs,object def,string sModeExt,number saveResult,image calDefImg)
	{
		number status
		if(status=self.beginCalib(1,0,src,tags,objs,def,sModeExt,calDefImg))
			status=self.endCalib(saveResult)
		return status
	}

	number scaleCalib(object self,object src,TagGroup tags,object objs,object def,string sModeExt,number saveResult,image calDefImg)
	{
		number status
		if(status=self.beginScaleCalib(1,0,src,tags,objs,def,sModeExt,calDefImg))
			status=self.endScaleCalib(saveResult)
		return status
	}

	//
	void setValues(object self)
	{
		self.setPopup("Deflector")		
	}

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		self.write("DEFCALIB dialog")
	}

	void scalePressed(object self)
	{			
		if(self.isRunning())
			self.stop()
		else
		{
			setTerminate(0)
			self.beginScale(0,1,null,null,null,null,"")
		}

	}

	void calibratePressed(object self)
	{	
		if(self.isRunning())
			self.stop()
		else
		{
			setTerminate(0)
			self.beginCalib(0,1,null,null,null,null,"",null)
		}
	}

	void scaleCalibratePressed(object self)
	{	
		if(self.isRunning())
			self.stop()
		else
		{
			setTerminate(0)
			self.beginScaleCalib(0,1,null,null,null,null,"",null)
		}
	}
//
	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
	
		//
		TagGroup defList=newTagList()
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Beam shift","CLA1"))	
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Beam tilt","CLA2"))
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Image shift 1","IS1"))	
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Image shift 2","IS2"))
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Balanced mag shift","ISBAL1"))	
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Balanced diff shift","ISBAL2"))	
		defList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Projector alignment","PLA"))	
		TagGroup defTag=self.createPopup("deflector","",defList)
		dlgItems.dlgAddElement(defTag).dlgExternalPadding(5,0).dlgAnchor("East")

		//
		TagGroup scaleTag=self.createButton("scale","Scale","scalePressed")
		TagGroup calTag=self.createButton("calibrate","Calibrate","calibratePressed")
		TagGroup scalecalTag=self.createButton("scale and calibrate","Scale/Cal ","scaleCalibratePressed")
		TagGroup helpTag=self.createButton("help","?","helpPressed").dlgExternalPadding(0,5).dlgAnchor("East")
		dlgItems.dlgAddElement(dlgGroupItems(scaleTag,calTag,scalecalTag,helpTag).dlgTableLayout(4,1,0).dlgExternalPadding(0,5)).dlgAnchor("West")
		
		dlgTags.dlgTableLayout(1,3,0)
		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide( "Right" );
		dlgTags.dlgPosition(position);

		self.super.init(dlgTags)
		return self
	}

	number aboutToCloseDocument(object self,number verify)
	{
		self.stop()
		self.write(self.getGroup()+" dialog")
		self.super.aboutToCloseDocument(verify)
	}

	DefCalib(object self)
	{
		self.setGroup(DEFCALIB_sGroup)
		self.setName(DEFCALIB_sName)
		self.setTitle(DEFCALIB_sTitle)
		self.setEcho(DEFCALIB_echo)
		
		online=DEFCALIB_online
		scaleThread=alloc(DefCalibScale).load()
		calibThread=alloc(DefCalibCalibrate).load()
		scaleCalibThread=alloc(DefCalibScaleCalibrate).load()			
		msg=alloc(DefCalibMsg)	
	}
	
	object load(object self)
	{
		self.addData("online",DEFCALIB_online)
		self.addData("show cross correlation",DEFCALIB_showCC)
		self.addData("scaling cross correlation ratio",20)
		self.addData("help filename",DEFCALIB_sHelpFilename)

		TagGroup imgPosList=newTagList()
		imgPosList.tagGroupInsertTagAsNumber(infinity(),20)//X
		imgPosList.tagGroupInsertTagAsNumber(infinity(),20)//Y
		self.addData("image position",imgPosList)

		TagGroup ccPosList=newTagList()
		ccPosList.tagGroupInsertTagAsNumber(infinity(),20)//X
		ccPosList.tagGroupInsertTagAsNumber(infinity(),60)//Y
		self.addData("cc position",ccPosList)
		
		string sDlgGroup=self.getGroup()+" dialog"
		self.addData(sDlgGroup,"deflector",DEFCALIB_sDeflector)
		self.read(sDlgGroup)
	
		return self.super.load()
	}
	
	~DefCalib(object self)
	{
		self.unload()
		self.write(self.getGroup()+" dialog")
	}			
}

void showDefCalib()
{
	if(DEFCALIB_display)
		alloc(DefCalib).load().init().display()
}

showDefCalib()