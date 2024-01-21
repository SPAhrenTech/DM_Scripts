//Smart Orius camera acquisition. Phil Ahrenkiel, 2021
//Put SmartAcqRef class definition in useful.
module com.gatan.dm.smartacq
uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog
uses com.gatan.dm.jemthread

number SMARTACQPROC_echo=0
number SMARTACQPROC_nExp=3//Number of exposures to sum/exposure
string SMARTACQPROC_sProcMode="median"//Mode: median or mean
number SMARTACQPROC_useDIFF_streakCorr=1
number SMARTACQPROC_useHighQualityView=1
number SMARTACQPROC_online=1
number SMARTACQPROC_show=1
number SMARTACQPROC_doProcess=1
string SMARTACQPROC_sSetup="Record"
string SMARTACQPROC_sTEM_mode="MAG"

string SMARTACQPROC_sGroup="SMARTACQPROC"
string SMARTACQPROC_sName="SmartAcqProc"
string SMARTACQPROC_sTitle="Process Acquire"

//
number SMARTACQDARKREF_nExp=3

string SMARTACQDARKREF_sGroup="SMARTACQDARKREF"
string SMARTACQDARKREF_sName="SmartAcqDarkRef"
string SMARTACQDARKREF_sTitle="Dark Reference"

//
number SMARTACQGAINREF_nExp=3

string SMARTACQGAINREF_sGroup="SMARTACQGAINREF"
string SMARTACQGAINREF_sName="SmartAcqGainRef"
string SMARTACQGAINREF_sTitle="Gain Reference"

//
string SMARTACQUIRE_sGroup="SMARTACQUIRE"
string SMARTACQUIRE_sName="SmartAcquire"
string SMARTACQUIRE_sTitle="Acquire"

number SMARTACQEXT_maxCounts=2**14-1
number SMARTACQEXT_extFac=10

string SMARTACQUIREEXT_sGroup="SMARTACQUIREEXT"
string SMARTACQUIREEXT_sName="SmartAcquireExt"
string SMARTACQUIREEXT_sTitle="Extended Range"

//
number SMARTACQ_online=1
number SMARTACQ_useSMARTACQ=1
number SMARTACQ_echo=0
number SMARTACQ_show=1
number SMARTACQ_nExp=1
string SMARTACQ_sHelpFilename="SMARTACQ_Help.docx"

number SMARTACQ_useExt=0
number SMARTACQ_display=0

string SMARTACQ_sRefsFolderName="SMARTACQRefs"
string SMARTACQ_sGainRefImgName="SMARTACQGainRef"
string SMARTACQ_sDarkRefImgName="SMARTACQDarkRef"

string SMARTACQ_sGroup="SMARTACQ"
string SMARTACQ_sName="SmartAcq"
string SMARTACQ_sTitle="Smart Acquire"

number SMARTACQ_maxSavedDarkRef=10
number SMARTACQ_maxSavedGainRef=5

//correction bits
//0 - defect
//1 - deiinterlace
//2 - extraction
//4 - bias
//5 - linearization (1)
//6 - linearization (2)
//8 - dark
//9 - gain
//10 - streak

//DM built-in reference uses:
//dark: corr=16. mask=817
//gain: corr=273. mask=817
//Seems to have streak correction off, regardless of user selection
//(and despite mask setting.)
//Also turns linearity off.

//predef
interface SmartAcqProto
{
	TagGroup getSmartAcqTags(object self,image img);
	void readParams(object self);
	void writeParams(object self);
	object getCamera(object self,object &c);
	void getCorrections(object self,number &corr);
	void setCorrections(object self,number corr);
	void applyCorrections(object self,string sTEM_mode);
	void setSize(object self);
	//object getCamera(object self,object &c);
	void getIdleShutterState(object self,number &state);	
	void setIdleShutterState(object self,number state);
	object setBinning(object self,number nBin);
	object getBinning(object self,number &nBin);
	void getInserted(object self,number &inserted);
	void setInserted(object self,number inserted);

	object createImage(object self,image &img,string sName);
	void saveRefImage(object self,image &img,TagGroup currTags,string sName);
	object getImageTags(object self,string sTEM_mode,TagGroup &imgTags);
	object getDarkRefImage(object self,image &img);
	object getGainRefImage(object self,image &img);
	object setDarkRefImage(object self,image img,TagGroup imgTags);
	void setNeedDarkRef(object self,number n);
	number getNeedDarkRef(object self);
	number prepDarkRef(object self,object src,TagGroup tags,object objs,number show);
	void checkRefImages(object self,string sTEM_mode);
	number getProcessed(object self,image &img,object src,TagGroup tags,object objs,number show);
	void endGetProcessed(object self);
	void endAcquire(object self);
	void endAcquireExt(object self);
	void prepForAcquire(object self,string sTEM_mode);
	number acquire(object self,image &img,object src,TagGroup tags,object objs,number show);
	
}

class SmartAcqMsg:ThreadMsg
{
	image img
	
	object getImg(object self,image &p){p:=img;return self;}	
	object setImg(object self,image &p){img:=p;return self;}
}

//Read all of the info from the selected setup,
//but apply to record setting.
class SmartAcqProc:JEM_Widget
{
	object msg
	
	void runThread(object self)
	{
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))
			{fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib),1);}
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		
		number online;if(!getTag(tags,"online",online)){online=SMARTACQPROC_online;}//not used
		number show;if(!getTag(tags,"show processed",show)){show=SMARTACQPROC_show;}
		number doProcess;if(!getTag(tags,"process",doProcess)){doProcess=SMARTACQPROC_doProcess;}
		string sName;if(!getTag(tags,"name",sName)){sName="Processed";}
		string sTEM_mode;if(!getTag(tags,"TEM mode",sTEM_mode)){sTEM_mode=SMARTACQPROC_sTEM_mode;}
		
		number nExp;self.getData("number of exposures",nExp)
		string sProcMode;self.getData("processing mode",sProcMode)		
		number useDIFF_streakCorr;self.getData("use DIFF streak correction",useDIFF_streakCorr)
		
		string sSetup;owner.getData("setup",sSetup)
		TagGroup setupTags;owner.getData(sSetup,setupTags)
		//if(self.isOrigin()){self.prep(sMode);}
		
		//Do all configurations here
		number prevCorr;owner.getCorrections(prevCorr)
		if(self.isOrigin())
		{
			TagGroup calTag=camCalib.getTags()
			calTag.tagGroupGetTagAsString("TEM mode",sTEM_mode)
		}
		owner.applyCorrections(sTEM_mode)
		owner.setSize()
		
		object camera;owner.getCamera(camera)	
		image img;camera.createImageForAcquire(img,sName)
		//self.getCorrections()	
		number sizeX,sizeY;img.getSize(sizeX,sizeY)
		image stackImg
		if(doProcess)
		{
			stackImg:=realImage("raw",4,sizeX,sizeY,nExp)
			stackImg=0;
		}
		else
			nExp=1
		number actionKey=progInfo.addProgress("Processing...")
		progInfo.showProgress()
		number is_closed
		number iExp=0
		while(self.super.isAlive())
		{
			progInfo.setProgress(actionKey,"Processing "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
			progInfo.showProgress()
			try
				camera.acquire(img)
			catch
			{
				setTerminate(1)
				continue
			}
			
			if(doProcess)
				stackImg[0,0,iExp,sizeX,sizeY,iExp+1]=img
			
			iExp++
			if(iExp>=nExp)self.super.kill()

		}
		if(self.super.isViable())
		{
			//for(iExp=0;iExp<nExp;iExp++)
				//result("i: "+iExp+", mean="+mean(stackImg[0,0,iExp,sizeX,sizeY,iExp+1])+"\n")
			//process
			if(doProcess)
			{
				progInfo.setProgress(actionKey,"Processing...")
				progInfo.showProgress()
				if(sProcMode=="median")
				{
					for(iExp=0;iExp<nExp;iExp++)//Sort low to high
					{
						for(number jExp=iExp+1;jExp<nExp;jExp++)
						{
							image temp1Img=stackImg[0,0,iExp,sizeX,sizeY,iExp+1]
							image temp2Img=stackImg[0,0,jExp,sizeX,sizeY,jExp+1]
							stackImg[0,0,iExp,sizeX,sizeY,iExp+1]=(temp1Img<temp2Img)?temp1Img:temp2Img
							stackImg[0,0,jExp,sizeX,sizeY,jExp+1]=!(temp1Img<temp2Img)?temp1Img:temp2Img						
						}
					}
					iExp=trunc(nExp/2)			
					if(iExp==nExp/2)//even
						img=(stackImg[0,0,iExp-1,sizeX,sizeY,iExp]\
							+stackImg[0,0,iExp,sizeX,sizeY,iExp+1])/2
					else//odd
						img=stackImg[0,0,iExp,sizeX,sizeY,iExp+1]
				}
				
				if(sProcMode=="mean")
				{
					img=0;
					for(iExp=0;iExp<nExp;iExp++)
						img+=stackImg[0,0,iExp,sizeX,sizeY,iExp+1]
					img/=nExp
				}
			}
			if(show)
			{
				showImage(img)
			}
			//showImage(stackImg)
			//for(iExp=0;iExp<nExp;iExp++)
				//result("i: "+iExp+", mean="+mean(stackImg[0,0,iExp,sizeX,sizeY,iExp+1])+"\n")
			//showImage(img)
				//result("res, mean="+mean(img)+"\n")
			object msg;self.newMessage(msg)
			msg.setImg(img)
			self.sendMessage(msg)
		}		
		owner.setCorrections(prevCorr)
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		//result("end of get process thread\n")
		self.super.end()

	}
	
	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endGetProcessed()
	}

	void setValues(object self)
	{
		self.setNumber("number of exposures")		
		self.setPopup("processing mode")		
		self.setCheckBox("use DIFF streak correction")		
	}

	void popupChanged(object self,string sIdent,TagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		self.write()
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		
		tagGroup modeList=newTagList()
		modeList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("median","median"))
		modeList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mean","mean"))

		tagGroup modeTag=self.createPopup("processing mode","mode",modeList)
		dlgItems.dlgAddElement(modeTag).dlgexternalpadding(5,0).DLGAnchor("East")
		
		tagGroup nExpTag=self.createNumber("number of exposures","# of exp.",6)
		dlgItems.dlgAddElement(nExpTag).dlgexternalpadding(5,0).DLGAnchor("East")

		tagGroup nStreakTag=self.createCheckBox("use DIFF streak correction","DIFF streak correction")
		dlgItems.dlgAddElement(nStreakTag).dlgexternalpadding(5,0).DLGAnchor("East")

		dlgTags.dlgTableLayout(1,4,0)
		self.super.init(dlgTags)

		return self
	}
	
	SmartAcqProc(object self)
	{
		self.setGroup(SMARTACQPROC_sGroup)
		self.setEcho(SMARTACQPROC_echo)
		self.setName(SMARTACQPROC_sName)
		self.setTitle(SMARTACQPROC_sTitle);		

		msg=alloc(SmartAcqMsg);
	}
	
	object load(object self)
	{
		self.addData("number of exposures",SMARTACQPROC_nExp)
		self.addData("processing mode",SMARTACQPROC_sProcMode)
		self.addData("use DIFF streak correction",SMARTACQPROC_useDIFF_streakCorr)
		return self.super.load()
	}

	~SmartAcqProc(object self)
	{
		self.unload()
	}
		
}

//
class SmartAcqDarkRef:JEM_Widget
{	
	object msg
	void runThread(object self)
	{
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))
			{fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);}
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		number show;if(!getTag(tags,"show",show)){show=SMARTACQ_show;}
	
		string sSetup;owner.getData("setup",sSetup)
		TagGroup setupTags;owner.getData(sSetup,setupTags)
		
		number nExp;self.getData("number of exposures",nExp)
		string sTEM_mode;
		if(self.isOrigin())
		{
			TagGroup calTag=camCalib.getTags()
			calTag.tagGroupGetTagAsString("TEM mode",sTEM_mode)
			fillTag(tags,"TEM mode",sTEM_mode,1)
		}
		getTag(tags,"TEM mode",sTEM_mode)
		
		number actionKey=progInfo.addProgress("Preparing dark ref")
		progInfo.showProgress()
		number phase=0
		image img,darkRefImg
		number first=1,iExp=0
		object camera;owner.getCamera(camera)
		number prevScreen=acqCtrl.isScreenUp()
		//acqCtrl.lowerScreen();

		number prevIdleShutterState;owner.getIdleShutterState(prevIdleShutterState)
		number prevShutter;JEM_getShutterPosition(prevShutter)
		JEM_setShutterPosition(0)
		//camera.setIdleShutterState(1,1)
		while(self.super.isAlive())
		{
			number doNext=0
			if(!self.super.isPaused())
			{					
			
				if(phase==0)
				{
					if(owner.getProcessed(img,self,tags,objs,0))
					{
						if(first)
							darkRefImg=img
						else
							darkRefImg+=img
					}
					else
						self.abort()
					iExp++
					first=0
					if(iExp==nExp)doNext=1					
				}
			
				if(phase==1)
				{
					copyTags(img,darkRefImg)
					darkRefImg/=nExp
					darkRefImg.setName(SMARTACQ_sDarkRefImgName)
					if(show)darkRefImg.showImage()
					tagGroup imgTags;owner.getImageTags(sTEM_mode,imgTags)
					owner.setDarkRefImage(darkRefImg,imgTags)
					//owner.setNeedDarkRef(0)
					self.super.kill()
				}
			}
			if(doNext)phase++
			yield()						
		}
		//if(prevScreen)acqCtrl.raiseScreen();
		//result("restoring shutter\n")
		//JEM_setShutterPosition(0)
		JEM_setShutterPosition(prevShutter)
		owner.setIdleShutterState(prevIdleShutterState)
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		if(self.super.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}		
		self.super.end()
	}
			
	void setValues(object self)
	{
		self.setNumber("number of exposures")		
		self.write()
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Dark Reference",dlgItems)
		
		tagGroup nExpTag=self.createNumber("number of exposures","# of exp.",6)
		dlgItems.dlgAddElement(nExpTag).dlgexternalpadding(5,0).DLGAnchor("East")

		dlgTags.dlgTableLayout(1,2,0)
		self.super.init(dlgTags)

		return self
	}
	
	SmartAcqDarkRef(object self)
	{
		self.setGroup(SMARTACQDARKREF_sGroup)
		self.setName(SMARTACQDARKREF_sName)
		self.setTitle(SMARTACQDARKREF_sTitle)
		self.setEcho(SMARTACQ_echo)
		
		msg=alloc(SmartAcqMsg);
	}

	object load(object self)
	{
		self.addData("number of exposures",SMARTACQDARKREF_nExp)
		return self.super.load()
	}

	~SmartAcqDarkRef(object self)
	{
		self.unload()
	}
}

//
class SmartAcqGainRef:JEM_Widget
{
	object msg
	
	void runThread(object self)
	{
		self.super.begin()
		object owner=self.super.getOwner()
		//object source=self.super.getSource()

		number i,j
	
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))
			{fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);}
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		number show;if(!getTag(tags,"show",show)){show=SMARTACQ_show;}

		number online;if(!getTag(tags,"online",online)){fillTag(tags,"online",SMARTACQ_online,1);}
		string sSetup;owner.getData("setup",sSetup)
		TagGroup setupTags;owner.getData(sSetup,setupTags)
		number nExp;self.getData("number of exposures",nExp)

		TagGroup calTag=camCalib.getTags()
		string sTEM_mode
		number doDiff=1
		//number tExp;camera.getExposure(tExp)
		image gainRefImg,darkRefImg

		//number tExp;
	
		number prevShutterState;JEM_getShutterPosition(prevShutterState)
		number prevIdleShutterState;owner.getIdleShutterState(prevIdleShutterState)

		number prevInserted;owner.getInserted(prevInserted);
		number dtsec_extract=2//How long to extract camera
		owner.setInserted(1);
		if(prevInserted==0)
		{
			number t0=get_tsec()
			while(get_tsec()<t0+dtsec_extract){}
		}

		image img
		number iExp,first
		number phase1=0,phase2=0
		number actionKey=progInfo.addProgress("Preparing gain ref...")
		number stepKey
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		number phase=0;
		while(self.super.isAlive())
		{
			number doNext=0
			if(!self.super.isPaused())
			{					
			
				if(phase==0)
				{
					sTEM_mode="MAG"
					fillTag(tags,"TEM mode",sTEM_mode,1)
					progInfo.setProgress(actionKey,"Preparing "+sTEM_mode+" gain ref...")
					progInfo.showProgress()
					first=1;iExp=0
					doNext=1
				}
							
				if(phase==1)
				{
					stepKey=progInfo.addProgress("Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()
					//acqCtrl.raiseScreen()
					JEM_setShutterPosition(1)
					if(owner.getProcessed(img,self,tags,objs,0))
					{
						if(first)
							gainRefImg=img
						else
							gainRefImg+=img
					}
					else
						self.abort()
					iExp++
					first=0
					if(iExp==nExp)doNext=1					
					progInfo.deleteProgress(stepKey)
					progInfo.showProgress()
				}
				
				if(phase==2)
				{
					gainRefImg/=nExp
					if(owner.prepDarkRef(self,tags,objs,0))
					{
						progInfo.setProgress(actionKey,"Saving "+sTEM_mode+" gain ref...")
						progInfo.showProgress()
						owner.getDarkRefImage(darkRefImg)
						image diffImg=gainRefImg-darkRefImg
						gainRefImg=diffImg/mean(diffImg)
						tagGroup imgTags;owner.getImageTags(sTEM_mode,imgTags)
						owner.saveRefImage(gainRefImg,imgTags,SMARTACQ_sGainRefImgName)
						if(show)gainRefImg.showImage()
						if(!doDiff)self.kill()
					}
					else self.abort()
					doNext=1				
				}
				
				if(phase==3)
				{
					sTEM_mode="DIFF"
					fillTag(tags,"TEM mode",sTEM_mode,1)
					progInfo.setProgress(actionKey,"Preparing "+sTEM_mode+" gain ref...")
					progInfo.showProgress()
					first=1;iExp=0
					doNext=1
				}
				
				if(phase==4)
				{
					stepKey=progInfo.addProgress("Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()
					//acqCtrl.raiseScreen()
					JEM_setShutterPosition(1)
					if(owner.getProcessed(img,self,tags,objs,0))
					{
						if(first)
							gainRefImg=img
						else
							gainRefImg+=img
					}
					else
						self.abort()
					iExp++
					first=0
					if(iExp==nExp)doNext=1					
					progInfo.deleteProgress(stepKey)
					progInfo.showProgress()
				}
					
				if(phase==5)
				{
					gainRefImg/=nExp
					if(owner.prepDarkRef(self,tags,objs,0))
					{
						progInfo.setProgress(actionKey,"Saving "+sTEM_mode+" gain ref...")
						progInfo.showProgress()
						owner.getDarkRefImage(darkRefImg)
						image diffImg=gainRefImg-darkRefImg
						gainRefImg=diffImg/mean(diffImg)
						tagGroup imgTags;owner.getImageTags(sTEM_mode,imgTags)
						imgTags.tagGroupSetTagAsString("TEM mode","DIFF")
						owner.saveRefImage(gainRefImg,imgTags,SMARTACQ_sGainRefImgName)
					}
						else self.abort()
					self.kill()					
				}
			}
			if(doNext)phase++
			yield()						
		}
		//if(!prevScreen)acqCtrl.lowerScreen()
		if(isValid(gainRefImg)){deleteImage(gainRefImg);}
		if(isValid(darkRefImg)){deleteImage(darkRefImg);}
		if(self.super.isOrigin())acqCtrl.endControlScreen();
		//JEM_setShutterPosition(1)
		JEM_setShutterPosition(prevShutterState)
		owner.setIdleShutterState(prevIdleShutterState)
		//JEM_setShutterPosition(prevShutter)
		owner.setInserted(prevInserted);

		//progInfo.deleteProgress(stepKey)
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()

		if(self.super.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		
		self.super.end()
	}
		
	void setValues(object self)
	{
		self.setNumber("number of exposures")		
		self.write()
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		
		tagGroup nExpTag=self.createNumber("number of exposures","# of exp.",6)
		dlgItems.dlgAddElement(nExpTag).dlgexternalpadding(5,0).DLGAnchor("East")

		dlgTags.dlgTableLayout(1,2,0)
		self.super.init(dlgTags)

		return self
	}
	
	SmartAcqGainRef(object self)
	{
		self.setGroup(SMARTACQGAINREF_sGroup)
		self.setName(SMARTACQGAINREF_sName)
		self.setTitle(SMARTACQGAINREF_sTitle)
		self.setEcho(SMARTACQ_echo)
		
		msg=alloc(SmartAcqMsg);
	}

	object load(object self)
	{
		self.addData("number of exposures",SMARTACQGAINREF_nExp)
		return self.super.load()
	}
	
	~SmartAcqGainRef(object self)
	{
		self.unload()
	}
}

//
class SmartAcquire:JEM_Widget
{	
	void runThread(object self)
	{	
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))
			{fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);}
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		number show;if(!getTag(tags,"show",show)){show=SMARTACQ_show;}

		number online;owner.getData("online",online)
		number useQuick;owner.getData("use quick dark reference",useQuick)
		number nExp;self.getData("number of exposures",nExp)

		TagGroup calTag=camCalib.getTags()
		string sTEM_mode;
		if(self.isOrigin())
		{
			calTag.tagGroupGetTagAsString("Mode",sTEM_mode)
			fillTag(tags,"TEM mode",sTEM_mode,1)
		}
		getTag(tags,"TEM mode",sTEM_mode)
		owner.checkRefImages(sTEM_mode)

		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		//Disabled option to use Gatan capture instead.
		//number useSMARTACQ;acqCtrl.getData("use SmartAcq",useSMARTACQ)
		number i,j

		number actionKey=progInfo.addProgress("Acquiring...")
		progInfo.showProgress()

		object camera;owner.getCamera(camera)
		number prevShutter;JEM_getShutterPosition(prevShutter)
		number prevIdleShutterState;owner.getIdleShutterState(prevIdleShutterState)
	
		image img,acqImg
		image darkRefImg,gainRefImg
		number first=1,iExp=0,phase=0					
		while(self.super.isAlive())
		{
			number doNext=0
			if(!self.super.isPaused())
			{						
				if(phase==0)
				{
					if(owner.getNeedDarkRef())
					{
						if(owner.prepDarkRef(self,tags,objs,0)){}
						else self.abort()
					}
					doNext=1
				}

				if(phase==1)
				{
					owner.getDarkRefImage(darkRefImg);
					doNext=1
				}
				

				if(phase==2)
				{
					owner.getGainRefImage(gainRefImg);
					doNext=1
				}
				
				if(phase==3)
				{
					progInfo.setProgress(actionKey,"Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()
					JEM_setShutterPosition(1)
					if(owner.getProcessed(acqImg,self,tags,objs,0)){}
					else self.abort()
						
					iExp++
					if(iExp==nExp)self.super.kill()				
					doNext=1
				}

				if(phase==4)
				{
					progInfo.setProgress(actionKey,"Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()
					if(owner.getProcessed(img,self,tags,objs,0))
						acqImg+=img
					else
						self.abort()
					iExp++
					if(iExp==nExp)self.super.kill()				
				}
			}			
	
			if(doNext)phase++
			yield()						
		}
								
		owner.setIdleShutterState(prevIdleShutterState)
		if(self.isOrigin()){acqCtrl.endControlScreen();}
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		//JEM_setShutterPosition(prevShutter)
	
		//
		if(self.super.isViable())
		{	
			acqImg.setName("Frame");
			TagGroup smartAcqTags=owner.getSmartAcqTags(acqImg)
			
			number tExp,prevExp=0;
			if(!smartAcqTags.tagGroupDoesTagExist("Exposure (s)"))
				smartAcqTags.tagGroupCreateNewLabeledTag("Exposure (s)")					
			smartAcqTags.tagGroupGetTagAsNumber("Exposure (s)",prevExp)
			owner.getExposure(tExp)
			smartAcqTags.tagGroupSetTagAsNumber("Exposure (s)",prevExp+tExp)
	
			number prev_nExp=0
			if(!smartAcqTags.tagGroupDoesTagExist("Number of exposures"))
				smartAcqTags.tagGroupCreateNewLabeledTag("Number of exposures")					
			smartAcqTags.tagGroupGetTagAsNumber("Number of exposures",prevExp)
			smartAcqTags.tagGroupSetTagAsNumber("Number of exposures",prev_nExp+nExp)

			//showImage(gainRefImg)
			//showImage(darkRefImg)
			//showImage(acqImg)
			//Apply reference correc tions
			acqImg-=nExp*darkRefImg
			acqImg/=gainRefImg
				
			if(online)
			{
				number upixSize
				string sUnit
			
				calTag.tagGroupGetTagAsNumber("Unbinned pixel size",upixSize)
				calTag.tagGroupGetTagAsString("Units",sUnit)
				
				number bin;camera.getBinning(bin,bin)
				number pixSize=bin*upixSize
				setScale(acqImg,pixSize,pixSize)
				setUnitString(acqImg,sUnit)
				number mag0,mag1
				string sMode;calTag.tagGroupGetTagAsString("Mode",sMode)
				if(sMode=="DIFF")
				{
					calTag.TagGroupGetTagAsNumber("Indicated camera length (mm)",mag0)
					calTag.TagGroupGetTagAsNumber("Actual camera length (mm)",mag1)
					setNumberNote(acqImg,"Microscope Info:Indicated Magnification",mag0)
					setNumberNote(acqImg,"Microscope Info:Actual Magnification",mag1)
				}
				else
				{
					calTag.tagGroupGetTagAsNumber("Indicated magnification (Kx)",mag0)
					calTag.tagGroupGetTagAsNumber("Actual magnification (Kx)",mag1)
					setNumberNote(acqImg,"Microscope Info:Indicated Magnification",1e3*mag0)
					setNumberNote(acqImg,"Microscope Info:Actual Magnification",1e3*mag1)
				}
			}

			if(show)
			{
				showImage(acqImg)
				if(online)
				{
					imagedisplay imgdisp=acqImg.imagegetimagedisplay(0)
					imgdisp.applydatabar(0)
				}
			}

		}
		object msg;self.newMessage(msg)
		msg.setImg(acqImg)
		self.sendMessage(msg)
		self.super.end()
	}
	
	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endAcquire()
	}

	void setValues(object self)
	{
		self.setNumber("number of exposures")		
		self.write()
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Acquire",dlgItems)
		
		tagGroup nExpTag=self.createNumber("number of exposures","# of exp.",6)
		dlgItems.dlgAddElement(nExpTag).dlgexternalpadding(5,0).DLGAnchor("East")

		dlgTags.dlgTableLayout(1,2,0)
		self.super.init(dlgTags)

		return self
	}
	
	//
	SmartAcquire(object self)
	{
		self.setGroup(SMARTACQUIRE_sGroup)
		self.setName(SMARTACQUIRE_sName)
		self.setTitle(SMARTACQUIRE_sTitle)
		self.setEcho(SMARTACQ_echo)
	}

	object load(object self)
	{
		self.addData("number of exposures",SMARTACQ_nExp)
		return self.super.load()
	}
	
	~SmartAcquire(object self)
	{
		self.unload()
	}
}

//
class SmartAcquireExt:JEM_Widget
{	
	void runThread(object self)
	{	
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))
			{fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);}
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		number show;if(!getTag(tags,"show",show)){show=SMARTACQ_show;}

		number online;owner.getData("online",online)
		number maxCounts;self.getData("maximum counts",maxCounts)
		number extFac;self.getData("extension factor",extFac)

		number prevScreen=acqCtrl.isScreenUp()

		TagGroup calTag=camCalib.getTags()
		string sTEM_mode;calTag.tagGroupGetTagAsString("Mode",sTEM_mode)
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		number useSMARTACQ;acqCtrl.getData("use SmartAcq",useSMARTACQ)

		number i,j

		number actionKey=progInfo.addProgress("Extending...")
		owner.setData("extend range",0)//withhold to avoid nesting
		progInfo.showProgress()

		//number is_closed;camera.getIdleShutterState(1,is_closed)
		//number prevShutter;JEM_getShutterPosition(prevShutter)

		string sSetup;owner.getData("setup",sSetup)
		TagGroup setupTags;owner.getData(sSetup,setupTags)

		number tExpLong;owner.getExposure(tExpLong)
		number tExpShort=tExpLong/extFac;
		image shortImg,longImg,netImg
		//result("ID1: "+procAcq.scriptObjectGetID()+"\n")

		number first=1,iExp=0,phase=0					
		while(self.super.isAlive())
		{
			number doNext=0
			if(!self.super.isPaused())
			{						
				if(phase==0)
				{
					progInfo.setProgress(actionKey,"Extending 1/2")
					progInfo.showProgress()
					owner.setExposure(tExpShort)
					owner.checkRefImages(sTEM_mode)
					if(owner.acquire(shortImg,self,tags,objs,0)){}
					else self.abort()
					doNext=1
				}
				
				if(phase==1)
				{
					progInfo.setProgress(actionKey,"Extending 2/2")
					progInfo.showProgress()
					owner.setExposure(tExpLong)
					owner.checkRefImages(sTEM_mode)
					if(owner.acquire(longImg,self,tags,objs,0)){}
					else self.abort()
					doNext=1
				}

				if(phase==2)
				{
					number longSizeX,longSizeY
					longImg.getSize(longSizeX,longSizeY)

					number shortSizeX,shortSizeY
					shortImg.getSize(shortSizeX,shortSizeY)

					if((longSizeX==shortSizeX)&&(longSizeY==shortSizeY))
					{
						image maskImg=integerImage("mask",1,1,longSizeX,longSizeY)
						maskImg=(longImg>maxCounts)?1:2
						netImg:=realImage("frame",4,longSizeX,longSizeY)
						netImg=(maskImg==1)?extFac*shortImg:longImg
						copyTags(longImg,netImg)
						netImg.imageCopyCalibrationFrom(longImg)
						doNext=1
					}
					else self.abort()
					self.kill()
				}
			}			
			if(doNext)phase++
			yield()						
		}
		
		owner.setData("extend range",1)//restore
		if(self.isOrigin())acqCtrl.endControlScreen();
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		
		//
		if(self.super.isViable())
		{
			TagGroup smartAcqTags=owner.getSmartAcqTags(netImg)
			
			number tExp,prevExp=0;
			if(!smartAcqTags.tagGroupDoesTagExist("Exposure (s)"))
				smartAcqTags.tagGroupCreateNewLabeledTag("Exposure (s)")					
			smartAcqTags.tagGroupGetTagAsNumber("Exposure (s)",prevExp)
			smartAcqTags.tagGroupSetTagAsNumber("Exposure (s)",prevExp+tExpShort)

			if(!smartAcqTags.tagGroupDoesTagExist("Extended range"))
				smartAcqTags.tagGroupCreateNewLabeledTag("Extended range")
					
			if(show)
			{
				showImage(netImg)
				if(online)
				{
					imagedisplay imgdisp=netImg.imagegetimagedisplay(0)
					imgdisp.applydatabar(0)
				}
			}	
		}		
		object msg;self.newMessage(msg)
		msg.setImg(netImg)
		self.sendMessage(msg)
		self.super.end()
	}
	
	//Overrides default
	void endThread(object self)
	{
		object owner=self.super.getOwner()
		if(owner.scriptObjectIsValid())
			owner.endAcquireExt()
	}

	void setValues(object self)
	{
		//self.setNumber("number of exposures")		
		self.write()
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Extended Range",dlgItems)
		
		tagGroup maxCountsTag=self.createNumber("maximum counts","max. counts",8)
		dlgItems.dlgAddElement(maxCountsTag).dlgexternalpadding(5,0).DLGAnchor("East")

		tagGroup extFacTag=self.createNumber("extension factor","ext. factor",6)
		dlgItems.dlgAddElement(extFacTag).dlgexternalpadding(5,0).DLGAnchor("East")

		dlgTags.dlgTableLayout(1,3,0)
		self.super.init(dlgTags)

		return self
	}
	
	SmartAcquireExt(object self)
	{
		self.setGroup(SMARTACQUIREEXT_sGroup)
		self.setName(SMARTACQUIREEXT_sName)
		self.setTitle(SMARTACQUIREEXT_sTitle)
		self.setEcho(SMARTACQ_echo)
	}

	object load(object self)
	{
		self.addData("maximum counts",SMARTACQEXT_maxCounts)
		self.addData("extension factor",SMARTACQEXT_extFac)
		return self.super.load()
	}
	
	~SmartAcquireExt(object self)
	{
		self.unload()
	}
}
//
class SmartAcq:JEM_Widget
{
	object msg
	object getProcessedThread
	object darkRefThread,gainRefThread,acquireThread,acquireExtThread
	object procAcqThread
	number needDarkRef,needGainRef

	image darkRefImg,gainRefImg	
	object savedDarkRefList,savedGainRefList
	
	object camera

	TagGroup getSmartAcqTags(object self,image img)
	{
		TagGroup imgTag=img.imageGetTagGroup()
			
		TagGroup acqTag;
		if(!imgTag.tagGroupDoesTagExist("Acquisition"))
		{
			imgTag.tagGroupCreateNewLabeledTag("Acquisition")
			imgTag.tagGroupSetTagAsTagGroup("Acquisition",newTagGroup())	
		}	
		imgTag.tagGroupGetTagAsTagGroup("Acquisition",acqTag)
		
		TagGroup smartAcqTag;
		if(!acqTag.tagGroupDoesTagExist("Smart Acquire"))
		{
			acqTag.tagGroupCreateNewLabeledTag("Smart Acquire")	
			acqTag.tagGroupSetTagAsTagGroup("Smart Acquire",newTagGroup())	
		}
		acqTag.tagGroupGetTagAsTagGroup("Smart Acquire",smartAcqTag)
		return smartAcqTag
	}
	
//
	void readParams(object self)
	{
		camera.readParams("Imaging","Acquire",SMARTACQPROC_sSetup,0);
	}

	//
	void writeParams(object self)
	{
		camera.writeParams();
	}

	object getSetupTag(object self,TagGroup &setupTag)
	{
		TagGroup globalTag=getPersistentTagGroup()

		number res=0
		TagGroup CM_tag
		if(!globalTag.tagGroupGetTagAsTagGroup("CameraManager",CM_tag))return self
		
		TagGroup configList
		if(!CM_tag.tagGroupGetTagAsTagGroup("CameraConfigurationList",configList))return self
		
		TagGroup configTag
		if(!configList.tagGroupGetIndexedTagAsTagGroup(0,configTag))return self

		TagGroup acqSetsTag
		if(!configTag.tagGroupGetTagAsTagGroup("Acquisition Parameter Sets",acqSetsTag))return self

		TagGroup imagingTag
		if(!acqSetsTag.tagGroupGetTagAsTagGroup("Imaging",imagingTag))return self

		TagGroup acquireTag
		if(!imagingTag.tagGroupGetTagAsTagGroup("Acquire",acquireTag))return self

		acquireTag.tagGroupGetTagAsTagGroup(SMARTACQPROC_sSetup,setupTag)
		return self
	}
	
	object getQuality(object self,number &qual)
	{
		qual=0
		
		object prevParams;
		camera.readParams("Imaging","Acquire",SMARTACQPROC_sSetup,0,prevParams);
		
		self.writeParams()
		TagGroup setupTag;self.getSetupTag(setupTag)
		if(!tagGroupIsValid(setupTag))return self
		
		TagGroup highLevelTag
		if(!setupTag.tagGroupGetTagAsTagGroup("High Level",highLevelTag))return self
		highLevelTag.tagGroupGetTagAsNumber("Quality Level",qual)		
		
		camera.writeParams(prevParams)
		return self
	}
		
	object setQuality(object self,number qual)
	{
		object prevParams;
		camera.readParams("Imaging","Acquire",SMARTACQPROC_sSetup,0,prevParams);
		
		self.writeParams()
		TagGroup setupTag;self.getSetupTag(setupTag)
		if(!tagGroupIsValid(setupTag))return self

		TagGroup highLevelTag
		if(!setupTag.tagGroupGetTagAsTagGroup("High Level",highLevelTag))return self
		highLevelTag.tagGroupSetTagAsNumber("Quality Level",qual)
		self.readParams()

		camera.writeParams(prevParams)
		return self
	}	
	
	object setExposure(object self,number tExp)
	{
		camera.setExposure(tExp)
	}
	
	object getExposure(object self,number &tExp)
	{
		camera.getExposure(tExp)
	}
	
	object setBinning(object self,number nBin)
	{
		camera.setBinning(nBin,nBin)
	}

	object getBinning(object self,number &nBin)
	{
		camera.getBinning(nBin,nBin)
	}
	
	//
	void getCorrections(object self,number &corr)
	{
		number defect_bit=0
		number bias_bit=4
		number linear1_bit=5
		number linear2_bit=6
		number dark_bit=8
		number gain_bit=9
		number streak_bit=10
	
		number mask=\
			1*(2**defect_bit)\
			+1*(2**bias_bit)\
			+1*(2**linear1_bit)\
			+1*(2**linear2_bit)\
			+1*(2**dark_bit)\
			+1*(2**gain_bit)\
			+1*(2**streak_bit)
		
//mask=2**16-1					
		camera.getCorrections(mask,corr)	
		//result("get: mask: "+mask+", corr: "+corr+"\n")
	}

	//
	void setCorrections(object self,number corr)
	{
		number defect_bit=0
		number bias_bit=4
		number linear1_bit=5
		number linear2_bit=6
		number dark_bit=8
		number gain_bit=9
		number streak_bit=10
	
		number mask=\
			1*(2**defect_bit)\
			+1*(2**bias_bit)\
			+1*(2**linear1_bit)\
			+1*(2**linear2_bit)\
			+1*(2**dark_bit)\
			+1*(2**gain_bit)\
			+1*(2**streak_bit)
							
		camera.setCorrections(mask,corr)	
		//result("get: mask: "+mask+", corr: "+corr+"\n")
	}
	//
	void applyCorrections(object self,string sTEM_mode)
	{
		number defect_corr=1,defect_bit=0
		number bias_corr=1,bias_bit=4
		number linear1_corr=1,linear1_bit=5
		number linear2_corr=1,linear2_bit=6
		number dark_corr=0,dark_bit=8
		number gain_corr=0,gain_bit=9
		number streak_corr=0,streak_bit=10
	
		
		if(sTEM_mode=="DIFF")
			self.getData("use DIFF streak correction",streak_corr)
		
		number mask=\
			1*(2**defect_bit)\
			+1*(2**bias_bit)\
			+1*(2**linear1_bit)\
			+1*(2**linear2_bit)\
			+1*(2**dark_bit)\
			+1*(2**gain_bit)\
			+1*(2**streak_bit)
							
		number corr=\
			defect_corr*(2**defect_bit)\
			+bias_corr*(2**bias_bit)\
			+linear1_corr*(2**linear1_bit)\
			+linear2_corr*(2**linear2_bit)\
			+dark_corr*(2**dark_bit)\
			+gain_corr*(2**gain_bit)\
			+streak_corr*(2**streak_bit)
	
		//result("set: mask: "+mask+", corr: "+corr+"\n")
		camera.setCorrections(mask,corr)	
	}
	
	void setSize(object self)
	{
		number sizeX,sizeY
		camera.getSize(sizeX,sizeY)
		
		number bin
		camera.getBinning(bin,bin)
		number binSizeX,binSizeY		
		binSizeX=floor(sizeX/bin)
		binSizeY=floor(sizeY/bin)
		number top,left,bottom,right
		top=0;left=0;bottom=binSizeY;right=binSizeX
		camera.setBinnedArea(top,left,bottom,right)
	}
	
	object getCamera(object self,object &c){c=camera;return self;}

	void getIdleShutterState(object self,number &state){camera.getIdleShutterState(1,state);}	
	void setIdleShutterState(object self,number state){camera.setIdleShutterState(1,state);}
	
	void getInserted(object self,number &inserted){camera.getInserted(inserted);}
	void setInserted(object self,number inserted){camera.setInserted(inserted);}

	object createImage(object self,image &img,string sName)
	{
		camera.createImageForAcquire(img,sName)
		return self
	}
	
//
	number loadRefImage(object self,TagGroup currTags,string sName,image &refImg)
	{
		number n

		string sSetup;currTags.tagGroupGetTagAsString("setup",sSetup)
		string sTEM_mode;currTags.tagGroupGetTagAsString("TEM mode",sTEM_mode)
		
		number qual;currTags.tagGroupGetTagAsNumber("high-quality (slow) view",qual)
		string sQual="_fast";if(qual)sQual="_high"

		number bin;currTags.tagGroupGetTagAsNumber("binning",bin)
		string sBin=""
		if(bin==1)sBin="_bin1"
		if(bin==2)sBin="_bin2"
		if(bin==3)sBin="_bin3"
		if(bin==4)sBin="_bin4"

		string sRefDir=getApplicationDirectory("preference",0)
		sRefDir=pathConcatenate(sRefDir,"JEM_files")
		sRefDir=pathConcatenate(sRefDir,SMARTACQ_sRefsFolderName)
	
		string sFullName=sName+"_"+sTEM_mode
		//sFullName+="_"+sSetup
		sFullName+=sQual
		sFullName+=sBin
		string sFileName,sPath
		//result(sPath+"\n")	
		number res=0
		if(!res)
		{
			sFileName=sFullName+getImageExt()
			sPath=pathConcatenate(sRefDir,sFileName)
			if(doesFileExist(sPath))
			{
				refImg:=newImageFromFile(sPath)
				if(SMARTACQ_echo)result("Loaded "+sPath+"\n")
				res=1
				setName(refImg,sName)
			}
			else
			{
				if(SMARTACQ_echo)result("Failed to load "+sPath+"\n")
			}

		}
		return res
	}

	//
	void saveRefImage(object self,image &img,TagGroup currTags,string sName)
	{
		//string sSetup;currTags.tagGroupGetTagAsString("setup",sSetup)

		string sTEM_mode;currTags.tagGroupGetTagAsString("TEM mode",sTEM_mode)

		number qual;currTags.tagGroupGetTagAsNumber("high-quality (slow) view",qual)
		string sQual="_fast";if(qual)sQual="_high"

		number bin;currTags.tagGroupGetTagAsNumber("binning",bin)
		string sBin=""
		if(bin==1)sBin="_bin1"
		if(bin==2)sBin="_bin2"
		if(bin==3)sBin="_bin3"
		if(bin==4)sBin="_bin4"

		string sRefDir=getApplicationDirectory("preference",0)
		sRefDir=pathConcatenate(sRefDir,"JEM_files")
		sRefDir=pathConcatenate(sRefDir,SMARTACQ_sRefsFolderName)
		string sFullName=sName+"_"+sTEM_mode
		sFullName+=sQual
		//sFullName+="_"+sSetup
		sFullName+=sBin
		
		img.setName(sName)
		sFullName+=getImageExt()
		string sPath=PathConcatenate(sRefDir,sFullName)
		try
		{
			saveAsGatan(img,sPath)
			if(SMARTACQ_echo)result("Saved "+sPath+"\n")
			needGainRef=0
		}
		catch
		{
			if(SMARTACQ_echo)result("Failed to save "+sPath+"\n")
		}
	}
	
	number compareTagGroupString(object self,string sLabel,TagGroup tag0,TagGroup tag1)
	{
		string sItem0,sItem1
		tag0.tagGroupGetTagAsString(sLabel,sItem0)
		tag1.tagGroupGetTagAsString(sLabel,sItem1)
		number res=(sItem0==sItem1)
		//if(!res)result(sLabel+": "+sItem0+", "+sItem1+"\n")
		return res
	}

	number compareTagGroupNumber(object self,string sLabel,TagGroup tag0,TagGroup tag1)
	{
		number item0,item1
		tag0.tagGroupGetTagAsNumber(sLabel,item0)
		tag1.tagGroupGetTagAsNumber(sLabel,item1)
		number res=(item0==item1)
		//result(sLabel+": "+res+"\n")
		return res
	}
	
	number compareDarkRefTags(object self,TagGroup img0Tags,TagGroup img1Tags)
	{
		number res=1
		
		number res0=res*self.compareTagGroupString("setup",img0Tags,img1Tags)
		number res1=self.compareTagGroupString("processing mode",img0Tags,img1Tags)
		number res2=self.compareTagGroupString("TEM mode",img0Tags,img1Tags)		
		number res3=self.compareTagGroupNumber("exposure time (s)",img0Tags,img1Tags)
		number res4=self.compareTagGroupNumber("binning",img0Tags,img1Tags)
		number res5=self.compareTagGroupNumber("use DIFF streak correction",img0Tags,img1Tags)
		number res6=self.compareTagGroupNumber("high-quality (slow) view",img0Tags,img1Tags)		
		//result(res0+", "+res1+", "+res2+", "+res3+", "+res4+", "+res5+", "+res6+"\n")				
		res=res*res1*res2*res3*res4*res5*res6
		return res
	}
	
	number compareGainRefTags(object self,TagGroup img0Tags,TagGroup img1Tags)
	{
		number res=1
		res=res*self.compareTagGroupString("setup",img0Tags,img1Tags)
		//res=res&&self.compareTagGroupString("processing mode",img0Tags,img1Tags)
		res=res*self.compareTagGroupString("TEM mode",img0Tags,img1Tags)		
		res=res*self.compareTagGroupNumber("binning",img0Tags,img1Tags)
		return res
	}
	
	object pushDarkRef(object self,image currDarkRefImg,TagGroup currImgTags)
	{
		object newSavedDarkRef=alloc(SmartAcqRef).init(currDarkRefImg,currImgTags)
		savedDarkRefList.insertObjectIntoList(0,newSavedDarkRef)
		
		number nMaxRef;self.getData("max. saved dark ref",nMaxRef)
		while(savedDarkRefList.sizeOfList()>SMARTACQ_maxSavedDarkRef)
		{
			savedDarkRefList.removeObjectFromList(savedDarkRefList.sizeOfList()-1);
		}
		return self
	}
		
	object pushGainRef(object self,image currGainRefImg,TagGroup currImgTags)
	{		
		object newSavedGainRef=alloc(SmartAcqRef).init(currGainRefImg,currImgTags)
		savedGainRefList.insertObjectIntoList(0,newSavedGainRef)
		
		number nMaxRef;self.getData("max. saved gain ref",nMaxRef)
		while(savedGainRefList.sizeOfList()>nMaxRef)
		{
			savedGainRefList.removeObjectFromList(savedGainRefList.sizeOfList()-1);
		}
		return self
	}
	
	number findDarkRef(object self,TagGroup imgTags)
	{
		number res=0;
		foreach(object savedDarkRef;savedDarkRefList)
		{
			TagGroup savedDarkRefImgTags=savedDarkRef.getTags()
			if(self.compareDarkRefTags(savedDarkRefImgTags,imgTags))
			{
				image tempImg;savedDarkRef.getImage(tempImg);
				if(imageIsValid(tempImg))
				{					
					object newSavedDarkRef0=savedDarkRef;
					savedDarkRefList.removeObjectFromList(savedDarkRef);
					savedDarkRefList.insertObjectIntoList(0,newSavedDarkRef0)
					darkRefImg:=tempImg.imageClone()
					res=1;break;
				}
			}
		}
		//if(res)result("found dark ref\n")
		//else result("can't find dark ref\n")
		return res;
	}
	
	number findGainRef(object self,TagGroup imgTags)
	{
		number res=0;
		
		foreach(object savedGainRef;savedGainRefList)
		{
			TagGroup savedGainRefImgTags=savedGainRef.getTags()
			if(self.compareGainRefTags(savedGainRefImgTags,imgTags))
			{
				image tempImg;savedGainRef.getImage(tempImg);
				if(imageIsValid(tempImg))
				{					
					object newSavedGainRef0=savedGainRef;
					savedGainRefList.removeObjectFromList(savedGainRef);
					savedGainRefList.insertObjectIntoList(0,newSavedGainRef0)
					gainRefImg:=tempImg.imageClone()
					res=1;break;
				}
			}
		}
		
		//if(res)result("found gain ref\n")
		//else result("can't find gain ref\n")
		return res;
	}
	
	//
	object getImageTags(object self,string sTEM_Mode,TagGroup &imgTags)
	{
		string sSetup;self.getData("setup",sSetup)
	
		if(sTEM_Mode!="DIFF")sTEM_Mode="MAG"
			
		string sProcMode;procAcqThread.getData("processing mode",sProcMode);
		number tExp;self.getExposure(tExp)
		number bin;self.getBinning(bin)
		number qual;self.getQuality(qual);
			
		number useDiffStreakCorr;procAcqThread.getData("use DIFF streak correction",useDiffStreakCorr);

		imgTags=newTagGroup()
		imgTags.tagGroupCreateNewLabeledTag("setup")
		imgTags.tagGroupSetTagAsString("setup",sSetup)

		imgTags.tagGroupCreateNewLabeledTag("processing mode")
		imgTags.tagGroupSetTagAsString("processing mode",sProcMode)
		
		imgTags.tagGroupCreateNewLabeledTag("use DIFF streak correction")
		imgTags.tagGroupSetTagAsNumber("use DIFF streak correction",useDiffStreakCorr)
	
		imgTags.tagGroupCreateNewLabeledTag("high-quality (slow) view")
		imgTags.tagGroupSetTagAsNumber("high-quality (slow) view",qual)

		imgTags.tagGroupCreateNewLabeledTag("TEM mode")
		imgTags.tagGroupSetTagAsString("TEM mode",sTEM_mode)

		imgTags.tagGroupCreateNewLabeledTag("exposure time (s)")
		imgTags.tagGroupSetTagAsNumber("exposure time (s)",tExp)

		imgTags.tagGroupCreateNewLabeledTag("binning")
		imgTags.tagGroupSetTagAsNumber("binning",bin)
		return self
	}

	//
	void checkRefImages(object self,string sTEM_Mode)
	{
		//procAcq.getCorrections()
		TagGroup imgTags
		self.getImageTags(sTEM_mode,imgTags)
		//procAcq.getCorrections()

		if(!self.findDarkRef(imgTags))needDarkRef=1
		if(!self.findGainRef(imgTags))needGainRef=1
			
		if(!darkRefImg.imageIsValid())needDarkRef=1		
		if(!gainRefImg.imageIsValid())needGainRef=1

		//if(needDarkRef)result("seems to need dark ref\n")
		if(needGainRef)
		{
			//if(needGainRef)result("seems to need gain ref\n")
			if(self.loadRefImage(imgTags,SMARTACQ_sGainRefImgName,gainRefImg))
			{
				//procAcq.getCorrections()
				self.pushGainRef(gainRefImg,imgTags);
				needGainRef=0
			}
			else
			{
				//result("creating null gain ref\n")
				//object camera;self.getCamera(camera)
				self.setSize()
				camera.createImageForAcquire(gainRefImg,SMARTACQ_sGainRefImgName)
				//showImage(gainRefImg)
				gainRefImg=0
				needGainRef=1
			}

		}
		//result("-------------------\n")
	}

	object getProcAcq(object self){return procAcqThread;}
	
	TagGroup createDefaultSetupTags(object self)
	{
		TagGroup setupTagList=newTagList()
		setupTagList.tagGroupInsertTagAsNumber(infinity(),0.1)//exposure time
		setupTagList.tagGroupInsertTagAsNumber(infinity(),4)//binning
		setupTagList.tagGroupInsertTagAsNumber(infinity(),0)//quality (0:fast; 1: high)
		setupTagList.tagGroupInsertTagAsNumber(infinity(),1)//extend range
		setupTagList.tagGroupInsertTagAsNumber(infinity(),1)//acquire frames
		setupTagList.tagGroupInsertTagAsNumber(infinity(),1)//dark ref frames
		setupTagList.tagGroupInsertTagAsNumber(infinity(),3)//gain ref frames
		setupTagList.tagGroupInsertTagAsNumber(infinity(),1)//processing frames
		setupTagList.tagGroupInsertTagAsString(infinity(),"median")//processing mode
		setupTagList.tagGroupInsertTagAsNumber(infinity(),1)//diff streak correction
		return setupTagList
	}
	
	object getSetup(object self)
	{				
		number tExp;self.getExposure(tExp)
		number bin;self.getBinning(bin)
		number qual;self.getQuality(qual)

		number nDarkRefFrames;darkRefThread.getData("number of exposures",nDarkRefFrames)
		number nGainRefFrames;gainRefThread.getData("number of exposures",nGainRefFrames)
		number extRange;self.getData("extend range",extRange)
		number nProcFrames;procAcqThread.getData("number of exposures",nProcFrames)
		string sProcMode;procAcqThread.getData("processing mode",sProcMode)
		number diffStreakCorr;procAcqThread.getData("use DIFF streak correction",diffStreakCorr)
		number nAcqFrames;acquireThread.getData("number of exposures",nAcqFrames)

		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		number nTags=setupTags.tagGroupCountTags()
		if(nTags<10)setupTags=self.createDefaultSetupTags()
		
		setupTags.tagGroupSetIndexedTagAsNumber(0,tExp)//exposure time
		setupTags.tagGroupSetIndexedTagAsNumber(1,bin)//binning
		setupTags.tagGroupSetIndexedTagAsNumber(2,qual)//quality (0:fast; 1: high)
		setupTags.tagGroupSetIndexedTagAsNumber(3,extRange)//extend range
		setupTags.tagGroupSetIndexedTagAsNumber(4,nAcqFrames)//acquire frames
		setupTags.tagGroupSetIndexedTagAsNumber(5,nDarkRefFrames)//dark ref frames
		setupTags.tagGroupSetIndexedTagAsNumber(6,nGainRefFrames)//gain ref frames
		setupTags.tagGroupSetIndexedTagAsNumber(7,nProcFrames)//proc frames
		setupTags.tagGroupSetIndexedTagAsString(8,sProcMode)//processing mode		
		setupTags.tagGroupSetIndexedTagAsNumber(9,diffStreakCorr)//diff streak correction		
		return self
	}
	
	object setSetup(object self)
	{
		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		
		number tExp;setupTags.tagGroupGetIndexedTagAsNumber(0,tExp)//exposure time
		number bin;setupTags.tagGroupGetIndexedTagAsNumber(1,bin)//binning
		number extRange;setupTags.tagGroupGetIndexedTagAsNumber(3,extRange)//extend range
		number nAcqFrames;setupTags.tagGroupGetIndexedTagAsNumber(4,nAcqFrames)//acquire frames
		number nDarkRefFrames;setupTags.tagGroupGetIndexedTagAsNumber(5,nDarkRefFrames)//dark ref frames
		number nGainRefFrames;setupTags.tagGroupGetIndexedTagAsNumber(6,nGainRefFrames)//gain ref frames
		number qual;setupTags.tagGroupGetIndexedTagAsNumber(2,qual)//quality (0:fast; 1: high)
		number nProcFrames;setupTags.tagGroupGetIndexedTagAsNumber(7,nProcFrames)//proc frames
		string sProcMode;setupTags.tagGroupGetIndexedTagAsString(8,sProcMode)//processing mode
		number diffStreakCorr;setupTags.tagGroupGetIndexedTagAsNumber(9,diffStreakCorr)//diff streak correction		

		self.setExposure(tExp)
		self.setBinning(bin)
		self.setQuality(qual)
		procAcqThread.setData("number of exposures",nProcFrames)
		procAcqThread.setData("processing mode",sProcMode)
		procAcqThread.setData("use DIFF streak correction",diffStreakCorr)
		self.setData("extend range",extRange)
		darkRefThread.setData("number of exposures",nDarkRefFrames)
		gainRefThread.setData("number of exposures",nGainRefFrames)
		acquireThread.setData("number of exposures",nAcqFrames)
		return self
	}
	
	object readSetup(object self)
	{
		self.readParams()
		self.getSetup()
	}
	
	object writeSetup(object self)
	{
		self.setSetup()
		self.writeParams()
	}
	
	number getNeedDarkRef(object self){return needDarkRef;}
	number getNeedGainRef(object self){return needGainRef;}
	void setNeedDarkRef(object self,number n){needDarkRef=n;}
	void setNeedGainRef(object self,number n){needGainRef=n;}
	
	object getDarkRefImage(object self,image &img)
	{
		img:=darkRefImg;
		return self;
	}

	object setDarkRefImage(object self,image img,TagGroup imgTags)
	{
		darkRefImg:=img.imageClone();
		self.pushDarkRef(darkRefImg,imgTags);
		needDarkRef=0;
		//darkRefImgTagList.tagGroupOpenBrowserWindow(0)					
		return self;
	}

	object getGainRefImage(object self,image &img){img:=gainRefImg;return self;}
	
	//Begin threads
	number beginGetProcessed(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"show processed",show,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(procAcqThread.init(src,self,msg,resolve),priority)
	}	

	number beginPrepDarkRef(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"show",show,1)
		msg.setTags(tags);msg.setObjs(objs)			
		return self.begin(darkRefThread.init(src,self,msg,resolve),priority)
	}
		
	number beginPrepGainRef(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{		
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"show",show,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(gainRefThread.init(src,self,msg,resolve),priority)

	}

	number beginAcquire(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"show",show,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(acquireThread.init(src,self,msg,resolve),priority)
	}

	number beginAcquireExt(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"show",show,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(acquireExtThread.init(src,self,msg,resolve),priority)
	}

	//end threads
	number endGetProcessed(object self,image &img)
	{	
		object msg
		number status=procAcqThread.receiveMessageOnSignal(msg)
		if(status)
			msg.getImg(img)
		return status
	}
	
	number endGetProcessed(object self)
	{
		image img
		return self.endGetProcessed(img)
	}
	
	number endAcquire(object self,image &img)
	{	
		object msg
		number status=acquireThread.receiveMessageOnSignal(msg)
		if(status)
			msg.getImg(img)
		return status
	}
	
	number endAcquireExt(object self,image &img)
	{	
		object msg
		number status=acquireExtThread.receiveMessageOnSignal(msg)
		if(status)
			msg.getImg(img)
		return status
	}
	
	number endAcquire(object self)
	{
		image img
		return self.endAcquire(img)
	}
	
	number endAcquireExt(object self)
	{
		image img
		return self.endAcquireExt(img)
	}
	
	//external calls
	number getProcessed(object self,image &img,object src,TagGroup tags,object objs,number show)
	{
		number status		
		if(status=self.beginGetProcessed(1,0,src,tags,objs,show))
			status=self.endGetProcessed(img)
		return status
	}

	number prepDarkRef(object self,object src,TagGroup tags,object objs,number show)
	{	
		fillTag(tags,"show",show,1)
		number status
		if(self.beginPrepDarkRef(1,0,src,tags,objs,show))
			status=darkRefThread.endThread()
		return status
	}
	
	number prepGainRef(object self,object src,TagGroup tags,object objs,number show)
	{
		fillTag(tags,"show",show,1)
		number status
		if(status=self.beginPrepGainRef(1,0,src,tags,objs,show))
			status=gainRefThread.endThread()
		return status
	}

	number acquire(object self,image &img,object src,TagGroup tags,object objs,number show)
	{
		number status
		number useExt;self.getData("extend range",useExt)
		if(useExt)
		{
			if(status=self.beginAcquireExt(1,0,src,tags,objs,show))
				status=self.endAcquireExt(img)
		}
		else
		{
			if(status=self.beginAcquire(1,0,src,tags,objs,show))
				status=self.endAcquire(img)
		}
		return status
	}

	//
	void darkRefPressed(object self)
	{
		setTerminate(0)
		if(shiftDown())
		{
			self.setSetup()
			darkRefThread.init().pose()
			self.getSetup()
			self.write()
			self.setValues()
			return
		}
		self.beginPrepDarkRef(0,1,null,null,null,optionDown())
	}

	//
	void gainRefPressed(object self)
	{				
		setTerminate(0)
		if(shiftDown())
		{
			self.setSetup()
			gainRefThread.init().pose()
			self.getSetup()
			self.write()
			self.setValues()
			return
		}
		self.beginPrepGainRef(0,1,null,null,null,optionDown())
	}

	void acquirePressed(object self)
	{
		setTerminate(0)
		if((!shiftDown())&&optionDown()&&(!controlDown()))
		{
			self.beginGetProcessed(0,1,null,null,null,1)//Needs work
			return
		}
		
		if((!shiftDown())&&(!optionDown())&&controlDown())
		{
			self.readSetup()
			self.setValues()
		}

		if(shiftDown()&&optionDown()&&(!controlDown()))
		{
			self.setSetup()
			procAcqThread.init().pose()
			self.getSetup()
			self.write()
			self.setValues()
			return
		}
		
		if(shiftDown()&&(!optionDown())&&(!controlDown()))
		{
			self.setSetup()
			acquireThread.init().pose()
			self.getSetup()
			self.write()
			self.setValues()
			return
		}
		
		if(shiftDown()&&(!optionDown())&&controlDown())
		{
			self.setSetup()
			acquireExtThread.init().pose()
			self.getSetup()
			self.write()
			self.setValues()
			return
		}

		self.writeSetup()
		//self.setValues()

		//self.readSetup()
		//self.setValues()
		number useExt;self.getData("extend range",useExt)
		if(useExt)
			self.beginAcquireExt(0,1,null,null,null,1)
		else
			self.beginAcquire(0,1,null,null,null,1)
	}
		
	object getSummary(object self)
	{		
		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		number tExp;setupTags.tagGroupGetIndexedTagAsNumber(0,tExp)//exposure time
		number bin;setupTags.tagGroupGetIndexedTagAsNumber(1,bin)//binning
		number qual;setupTags.tagGroupGetIndexedTagAsNumber(2,qual)//
		number nAcqFrames;setupTags.tagGroupGetIndexedTagAsNumber(4,nAcqFrames)//acquire frames
		number nProcFrame;setupTags.tagGroupGetIndexedTagAsNumber(7,nProcFrame)//
		string sProcMode;setupTags.tagGroupGetIndexedTagAsString(8,sProcMode)//
	
		string sSumm=sSetup+": "
		if(nAcqFrames>1)sSumm+=""+nAcqFrames+"x "
		sSumm+=""+tExp+" s; "+bin+"x bin;"

		if(qual)sSumm+=" high"
		else sSumm+=" fast"
		
		sSumm+=";"+nProcFrame+"x proc; "+sProcMode
		self.setData("specs",sSumm)
		return self
	}
	
	void setValues(object self)
	{
		self.getSummary()
		self.setPopup("setup display")
		self.setStringLabel("specs")
		self.setCheckbox("extend range")
	}

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		if(sIdent=="setup display")
		{			
			string sSetupDisp;self.getData("setup display",sSetupDisp)
			if(sSetupDisp=="setup")return
			self.setData("setup display","setup")
			self.setData("setup",sSetupDisp)
			if((!shiftDown())&&(!optionDown())&&controlDown())
				self.writeSetup()
			self.write()
		}
		self.setValues()
	}
													
	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val)
		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		if(sIdent=="extend range")
			setupTags.tagGroupSetIndexedTagAsNumber(3,val)
		self.setValues()
		self.write()
	}
	
	object appendSetupList(object self,TagGroup &list)
	{
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Search","search"))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Focus","focus"))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Record","record"))
		return self
	}
//
	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)

		OpenandSetProgressWindow("","","")	

		number n
			
		TagGroup setupList=newTagList()
		setupList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Setup","setup"))
		self.appendSetupList(setupList)
		TagGroup setupTag=self.createPopup("setup display",setupList)
		
		TagGroup extRangeTag=self.createCheckBox("extend range","Extend")
		dlgItems.dlgAddElement(dlgGroupItems(setupTag,extRangeTag).dlgTableLayout(2,1,0).dlgexternalpadding(5,0).DLGAnchor("East"))

		TagGroup specsTag=self.createStringLabel("specs","",50)
		dlgItems.dlgAddElement(specsTag).dlgInternalPadding(0,5).dlgExternalPadding(5,0).DLGAnchor("East")

		TagGroup acqTag=self.createButton("acquire","Acquire","acquirePressed")
		TagGroup darkTag=self.createButton("prepare dark reference","Dark Ref","darkRefPressed")
		TagGroup gainTag=self.createButton("prepare gain reference","Gain Ref","gainRefPressed")
		TagGroup buttonTags=dlgGroupItems(acqTag,darkTag,gainTag).dlgTableLayout(3,1,0).dlgExternalPadding(0,5).dlgAnchor("West")
	
		TagGroup helpTag=self.createButton("help","?","helpPressed").dlgExternalPadding(0,5).dlgAnchor("East")
		dlgItems.dlgAddElement(dlgGroupItems(buttonTags,helpTag).dlgTableLayout(2,1,0))

		dlgTags.dlgTableLayout(1,4,0);
		
		TagGroup position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);
			
		self.super.init(dlgTags)
		return self
	}	
				
	//
	SmartAcq(object self)
	{
		self.setGroup(SMARTACQ_sGroup)
		self.setName(SMARTACQ_sName)
		self.setTitle(SMARTACQ_sTitle)		
		self.setEcho(SMARTACQ_echo)			

		darkRefThread=alloc(SmartAcqDarkRef).load()
		gainRefThread=alloc(SmartAcqGainRef).load()
		acquireThread=alloc(SmartAcquire).load()
		acquireExtThread=alloc(SmartAcquireExt).load()
		procAcqThread=alloc(SmartAcqProc).load()
		
		camera=alloc(GatanCamera)
		camera.setOnline(SMARTACQPROC_online)
		camera.getCurrent()
		self.readParams()
		
		msg=alloc(SmartAcqMsg)
	}	

	object load(object self)
	{
		self.addData("online",SMARTACQ_online)
		self.addData("help filename",SMARTACQ_sHelpFilename)
		self.addData("setup","record")
		self.addData("extend range",SMARTACQ_useExt)
		self.addData("search",newTagList())
		self.addData("focus",newTagList())
		self.addData("record",newTagList())
		self.addData("not saved","specs","")
		self.addData("not saved","setup display","setup")

		self.addData("max. saved dark ref",SMARTACQ_maxSavedDarkRef)
		self.addData("max. saved gain ref",SMARTACQ_maxSavedGainRef)
	
		savedDarkRefList=alloc(ObjectList)
		savedGainRefList=alloc(ObjectList)
		
		//self.setEcho(1)
		object res=self.super.load()
		string sSetup;self.getData("setup",sSetup)
		if(sSetup=="setup")self.setData("setup","record")

		self.getSummary()
		//self.writeSetupTags()
		//self.setValues()
		//self.getTags().tagGroupOpenBrowserWindow(0)
		return res
	}
	
	~SmartAcq(object self)
	{
		self.unload()
	}

/*
	//
	number aboutToCloseDocument(object self,number verify)
	{
		result("close\n")
		self.close()
		self.write()
	}
	*/
}

void showSmartAcq()
{
	object obj=alloc(SmartAcq).load()
	obj.init().display()
	obj.setValues()
}

if(SMARTACQ_display)showSmartAcq()
