number DEFWOBBLECONTROL_display=0
number DEFWOBBLER_online=1

string DEFWOBBLER_sGroup="DEFWOBBLER"
string DEFWOBBLER_sName="DefWobbler"
string DEFWOBBLER_sTitle="Deflector Wobbler"
number DEFWOBBLER_echo=0

string DEFWOBBLECONTROL_sGroup="DEFWOBBLECONTROL"
string DEFWOBBLECONTROL_sName="Deflector Wobble Control"
string DEFWOBBLECONTROL_sTitle="Deflector Wobble"

string DEFWOBBLERCONTROL_sDef="CLA2"


interface DefWobblerproto
{
	object show(object self);
}
//Diffraction routines -P. Ahrenkiel, 2019
class DefWobblerMsg:ThreadMsg
{	
}

//
class DefWobbler:JEM_Widget
{	
	object msg
	number willClose
	
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}

		object def;if(!getObj(objs,"deflector",def)){self.kill();self.end();return;}
		self.show();
		DocumentWindow w=self.getFrameWindow()
		number wX,wY
		number needPos=1
		TagGroup winPosList;
		if(self.getData("window position",winPosList))
		{
			number nCoord=winPosList.tagGroupCountTags()
			if(nCoord>1)
			{
				winPosList.tagGroupGetIndexedTagAsNumber(0,wX)
				winPosList.tagGroupGetIndexedTagAsNumber(1,wY)
				w.windowSetFramePosition(wX,wY)
				needPos=0
			}
		}
		if(needPos)
		{
			winPosList=newTagList()
			winPosList.tagGroupInsertTagAsNumber(infinity(),20)//X
			winPosList.tagGroupInsertTagAsNumber(infinity(),60)//Y
			self.setData("window position",winPosList)
		}

		number useCalib;if(!getTag(tags,"use calibration",useCalib))useCalib=0;

		number amp0;owner.getData("amplitude",amp0)
		number angle0;owner.getData("angle (°)",angle0)
		string sSetup;self.getData("setup",sSetup)		

		number freq0;self.getData("frequency (Hz)",freq0)
		number sync0;self.getData("sync camera",sync0)
		number polar0;self.getData("polar",polar0)

		if(self.isOrigin())acqCtrl.beginControlScreen(sync0,acqCtrl.isScreenUp())
		string sPrevSetup;acq.getData("setup",sPrevSetup)
		acq.setData("setup",sSetup)

		number valX0,valY0;
		if(useCalib)def.get(valX0,valY0)
		else def.read(valX0,valY0)
		
		number phasePrev=0,phase0=0
		number tStart=get_tsec()
		string sName;def.getShortName(sName)
		number actionKey=progInfo.addProgress("Wobbling "+sName)
		progInfo.showProgress()
		image dispImg,acqImg
		while(self.super.isAlive())
		{		
			if(!self.super.isPaused())
			{
				number amp;owner.getData("amplitude",amp)
				number angle;owner.getData("angle (°)",angle)

				number freq;self.getData("frequency (Hz)",freq)
				number sync;self.getData("sync camera",sync)
				number polar;self.getData("polar",polar)
				number tNow=get_tsec()
				if((freq!=freq0)||(polar!=polar0))
				{
					phase0=phasePrev;tStart=tNow;freq0=freq;polar0=polar;
				}
				if(sync!=sync0)
				{
					if(sync)
						if(self.isOrigin())acqCtrl.beginControlScreen(1,acqCtrl.isScreenUp());
					else
						if(self.isOrigin()){acqCtrl.endControlScreen();}
					sync0=sync;
				}
				number tElaps=tNow-tStart
				number phase=360*freq*tElaps+phase0
				//while(phase>360)phase-=360;
	
				number val,valX,valY
				if(polar)
				{
					val=phase
					valX=valX0+amp*cos(val*pi()/180)
					valY=valY0+amp*sin(val*pi()/180)
				}
				else
				{
					val=amp*sin(phase*pi()/180)
					valX=valX0+val*cos(angle*pi()/180)
					valY=valY0+val*sin(angle*pi()/180)
				}
				phasePrev=phase
				if(useCalib)def.set(valX,valY)
				else def.write(valX,valY)
				//result("X: "+valX+", Y: "+valY+"\n")
				//If syncing
				if(sync)
				{
					if(acq.acquire(acqImg,self,tags,objs,0))
					{
						dispImg=acqImg
						if(!isVisible(dispImg))
							showImage(dispImg)
						updateImage(dispImg)
					}
					else
						self.super.abort()
				}
			}
			yield()
			Sleep(0.01)
		}
		if(useCalib)def.set(valX0,valY0)
		else def.write(valX0,valY0)
		/*
		*/
		acq.setData("setup",sPrevSetup)
		if(self.isOrigin()){acqCtrl.endControlScreen();}
		if(isValid(dispImg))deleteImage(dispImg)
		if(isValid(acqImg))deleteImage(acqImg)
		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		if(self.isOrigin()){acqCtrl.setValues();}
		if(self.super.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		self.super.end()
		//result("thread ended\n")
	}
	
	void endThread(object self)
	{
		//result("willClose: "+willClose+"\n")
		if(!willClose)self.close()
		self.super.endThread()
	}
	
	object show(object self)
	{		
		string sDlgTitle;self.getData("title",sDlgTitle)	
		self.init().display(sDlgTitle)
		willClose=0
		return self
	}
	
	object close(object self)
	{
		DocumentWindow w=self.getFrameWindow()
		if(windowIsValid(w))
			if(windowIsOpen(w)) w.windowClose(0)
		return self
	}

	void setValues(object self)
	{
		self.setString("setup")	
		self.setNumber("frequency (Hz)")
	}
	
	void popupChanged(object self,string sIdent,tagGroup fieldTag)
	{
		self.super.popupChanged(sIdent,fieldTag)
		self.setValues();		
	}

	//Begin threads
	number beginWobble(object self,number priority,number resolve,object src,TagGroup tags,object objs,object def)
	{
		if((priority<1)&&(self.isRunning()))return 0
		if(!def.scriptObjectIsValid())return 0
		fillObj(objs,"Deflector",def,1)			
		msg.setTags(tags);msg.setObjs(objs)
		setTerminate(0)
		return self.begin(self.init(src,self,msg,resolve),priority)
	}

	number wobble(object self,object source,TagGroup tags,object objs,object def)
	{
		number status
		if(status=self.beginWobble(1,0,source,tags,objs,def))
			status=self.endThread()
		return status
	}

	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)

		TagGroup polarTag=self.createCheckBox("polar","polar").dlgExternalPadding(5,0).dlgSide("East")
		dlgItems.dlgAddElement(polarTag.dlgAnchor("East"))
		
		TagGroup setupList=newTagList()
		object acq;if(!getWidget("SmartAcq",acq)){acq=alloc(SmartAcq).load();}		
		acq.appendSetupList(setupList)
		TagGroup setupTag=self.createPopup("setup","camera setup:",setupList)
		dlgItems.dlgAddElement(setupTag)

		TagGroup freqTag=self.createNumber("frequency (Hz)","Freq. (Hz):",10,2).dlgExternalPadding(5,0).dlgSide("West")
		TagGroup syncTag=self.createCheckBox("sync camera","sync").dlgExternalPadding(5,0).dlgSide("East")
		dlgItems.dlgAddElement(dlgGroupItems(freqTag,syncTag).dlgTableLayout(2,1,0).dlgExternalPadding(5,0).dlgAnchor("East"))
		
		dlgTags.dlgTableLayout(1,4,0);			
		TagGroup position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);
		self.super.init(dlgTags)

		return self
	}	
				
	number aboutToCloseDocument(object self,number verify)
	{
		//result("about to close\n")
		willClose=1

		DocumentWindow w=self.getFrameWindow()
		number wX,wY
		TagGroup winPosList;
		w=self.getFrameWindow()
		w.windowGetFramePosition(wX,wY)
		self.getData("window position",winPosList)
		winPosList.tagGroupSetIndexedTagAsNumber(0,wX)
		winPosList.tagGroupSetIndexedTagAsNumber(1,wY)
		
		self.kill()
		
		//self.close()
		self.write()
		string sDlgGroup;self.getData("dialog group",sDlgGroup)
		self.write(sDlgGroup)
		//result("everything else\n")
	}
	
	DefWobbler(object self)
	{
		self.setGroup(DEFWOBBLER_sGroup)
		self.setName(DEFWOBBLER_sName)
		self.setTitle(DEFWOBBLER_sTitle)
		self.setEcho(DEFWOBBLER_echo)

		msg=alloc(DefWobblerMsg)
	}

	object load(object self)
	{
		self.addData("polar",0)		
		self.addData("setup","search")	
		self.addData("frequency (Hz)",1)		
		self.addData("sync camera",1)		
		self.addData("online",DEFWOBBLER_online)		
	
		TagGroup winPosList=newTagList()
		winPosList.tagGroupInsertTagAsNumber(infinity(),20)//X
		winPosList.tagGroupInsertTagAsNumber(infinity(),60)//Y
		self.addData("window position",winPosList)	
		self.super.load()

		string sDlgGroup=self.getGroup()+" dialog"
		self.addData("not saved","dialog group",sDlgGroup)
		self.addData(sDlgGroup,"angle (°) step",10)
		self.read(sDlgGroup)
		
		return self
	}
	
	~DefWobbler(object self)
	{
		string sDlgGroup;self.getData("dialog group",sDlgGroup)
		self.write(sDlgGroup)
		self.unload()
	}
}

class DefWobbleControl:JEM_Widget
{	
	object msg
	object defWobbleThread	

	number allocDeflector(object self,object &deflector)
	{
		string sShortName;self.getData("deflector",sShortName)		
		if(sShortName=="CLA1")deflector=alloc(JEM_BeamShift)		
		if(sShortName=="CLA2")deflector=alloc(JEM_BeamTilt)

		if(sShortName=="IS1")deflector=alloc(JEM_ImageShift1)
		if(sShortName=="IS2")deflector=alloc(JEM_ImageShift2)
	
		if(sShortName=="ISBAL1")deflector=alloc(JEM_ImageShiftBal1)
		if(sShortName=="ISBAL2")deflector=alloc(JEM_ImageShiftBal2)
	
		if(sShortName=="PLA")deflector=alloc(JEM_ProjectorDef)
		result("here\n")
	
		if(deflector.scriptObjectIsValid())
		{
			number online;self.getData("online",online)
			result("online x: "+online+"\n")
			number echo;self.getData("echo",echo)
			deflector.setOnline(online).setEcho(echo).init();			
		}
		return 1;
	}
	
	void setValues(object self)
	{
		self.setPopup("amplitude")
		self.setNumberLabelStepSel("angle (°)")
		self.write()
	}
	
	void popupChanged(object self,string sIdent,tagGroup fieldTag)
	{
		self.super.popupChanged(sIdent,fieldTag)
		self.setValues();		
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
	}

	void incAnglePressed(object self){self.stepData("angle (°)","",1);self.setValues();}
	void decAnglePressed(object self){self.stepData("angle (°)","",-1);self.setValues();}

	number beginWobble(object self,number priority,number resolve,object src,TagGroup tags,object objs,object def)
	{
		if((priority<1)&&(self.isRunning()))return 0
		fillTag(tags,"use calibration",0,1)
		if(!def.scriptObjectIsValid())
		{		
			string sShortName;self.getData("deflector",sShortName)		
			alloc(DefCalib).load().allocDeflector(sShortName,def)
			if(!def.scriptObjectIsValid())return 0
		}	
		fillObj(objs,"deflector",def,1)	
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(defWobbleThread.init(src,self,msg,resolve),priority)
	}

	number wobble(object self,object source,TagGroup tags,object objs,object def)
	{
		number status
		if(status=self.beginWobble(1,0,source,tags,objs,def))
			status=defWobbleThread.endThread()
		return status
	}

	//
	void ntrlPressed(object self)
	{
		self.setData("angle (°)",0)
		self.setValues() 
	}
	//
	void wobblePressed(object self)
	{
		if(self.isRunning()) self.stop()
		else
		{
			setTerminate(0);self.proceed()
			self.beginWobble(0,1,null,null,null,null)
		}
	}
		//
	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getName(),dlgItems)

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
		dlgItems.dlgAddElement(defTag).dlgExternalPadding(2,0).dlgAnchor("West")

		TagGroup ampList=newTagList()
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0010",16))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0040",64))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0100",256))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0400",1024))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x1000",4096))
		TagGroup ampTag=self.createPopup("amplitude","Amp.:",ampList)
		dlgItems.dlgAddElement(ampTag.dlgExternalPadding(2,0).dlgAnchor("West"))

		TagGroup angleStepList=newTagList()
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0.1",0.1))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0.3",0.3))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1",1))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("3",3))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("10",10))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("30",30))
		angleStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("90",90))
		TagGroup angleTag=self.super.createNumberLabelStepSel("angle (°)","Angle (°):","%7.3g",7,"incAnglePressed","decAnglePressed",angleStepList)
		dlgItems.dlgAddElement(angleTag.dlgExternalPadding(0,0).dlgAnchor("West"))
	
		TagGroup ntrlTag=self.createButton("neutral","NTRL","ntrlPressed")
		TagGroup wobbleTag=self.createButton("wobble","Wobble","wobblePressed")
		dlgItems.dlgAddElement(dlgGroupItems(ntrlTag,wobbleTag).dlgTableLayout(2,1,0)).dlgExternalPadding(2,0).dlgAnchor("West")
		
		dlgTags.dlgTableLayout(1,5,0);			
		TagGroup position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);
		self.super.init(dlgTags)

		return self
	}	

	DefWobbleControl(object self)
	{
		self.setGroup(DEFWOBBLECONTROL_sGroup)
		self.setName(DEFWOBBLECONTROL_sName)
		self.setTitle(DEFWOBBLECONTROL_sTitle)
		self.setEcho(DEFWOBBLER_echo)
		msg=alloc(DefWobblerMsg)
		defWobbleThread=alloc(DefWobbler).load()
		setTerminate(0)
	}
	

	object load(object self)
	{
		self.addData("deflector","CLA2")		
		self.addData("amplitude",256)		
		self.addData("angle (°)",0)		
		self.addData("online",DEFWOBBLER_online)		
		self.super.load()
		
		string sDlgGroup=self.getGroup()+" dialog"
		self.addData("not saved","dialog group",sDlgGroup)		
		self.addData(sDlgGroup,"angle (°) step",10)
		self.read(sDlgGroup)
		
		return self
	}
	
	~DefWobbleControl(object self)
	{
		string sDlgGroup;self.getData("dialog group",sDlgGroup)		
		self.write(sDlgGroup)
		self.super.unload()
	}
	
	//
	number aboutToCloseDocument(object self,number verify)
	{
		self.stop()
	}
}

void showDefWobbleControl()
{
		alloc(DefWobbleControl).load().init().display()
}
if(DEFWOBBLECONTROL_display)showDefWobbleControl()

