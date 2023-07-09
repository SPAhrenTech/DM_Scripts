//Lens Wobbler -P. Ahrenkiel, 2020
number LENSWOBBLER_online=1
number LENSWOBBLER_echo=0
number LENSWOBBLER_display=0

string LENSWOBBLER_sGroup="LENSWOBBLER"
string LENSWOBBLER_sName="LensWobbler"
string LENSWOBBLER_sTitle="Lens Wobbler"
string LENSWOBBLER_sLens="OLf"

class LensWobblerMsg:ThreadMsg
{
}

interface LensWobblerProto
{
	object allocLens(object self,string sShortName);
}

//
class LensWobbler:JEM_Widget
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
		object camCalib;if(!getObj(objs,"CameraCalib",camCalib))fillObj(objs,"CameraCalib",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		//object procAcq;if(!getObj(objs,"ProcessAcq",procAcq))fillObj(objs,"ProcessAcq",procAcq=alloc(ProcessAcq).load(),1);
		//object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}
	
		object lens;if(!getObj(objs,"lens",lens)){fillObj(objs,"lens",lens=owner.allocLens(LENSWOBBLER_sLens),1);}

		number val0;lens.read(val0)	
		number prevScreen=acqCtrl.isScreenUp()
		//if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);

		//acq.prepForAcquire(procAcq,camCalib)
		number freq0;owner.getData("frequency (Hz)",freq0)		

		number phasePrev=0,phase0=0
		number tStart=get_tsec()
		string sName;lens.getShortName(sName)
		number actionKey=progInfo.addProgress("Wobbling "+sName)
		progInfo.showProgress()
		//self.kill()
		//number iter=0
		while(self.super.isAlive())
		{		
			if(!self.super.isPaused())
			{
				number amp;owner.getData("amplitude",amp)
				number freq;owner.getData("frequency (Hz)",freq)
				number tNow=get_tsec()
				if(freq!=freq0)
				{
					phase0=phasePrev;tStart=tNow;freq0=freq
				}
				number tElaps=tNow-tStart
				number phase=360*freq*tElaps+phase0;
				//while(phase>360)phase-=360;
				number val=val0+amp*sin(phase*pi()/180)
				phasePrev=phase
				//result("val: "+val+"\n")
				lens.write(val)
				//image acqImg
				//acq.acquire(acqImg,self,tags,objs,0,0)
			}
			yield()
			sleep(0.1)//Apparently needed to allow interrupt
			//iter++
			//if(iter>100){result("done\n");self.kill();}
		}

		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		lens.set(val0)
		if(self.super.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		self.super.end()
	}

	object msg	
	
	//
	number allocLens(object self,string sShortName,object &lens)
	{
		if(sShortName=="CL3")lens=alloc(JEM_Brightness)		
		if(sShortName=="OLf")lens=alloc(JEM_ObjectiveFine)
		if(sShortName=="OLc")lens=alloc(JEM_ObjectiveCoarse)
		if(sShortName=="IL1")lens=alloc(JEM_IntermediateLens1)
		if(sShortName=="PL")lens=alloc(JEM_ProjectorLens)

		if(lens.scriptObjectIsValid())
		{
			number online;self.getData("online",online)
			number echo;self.getData("echo",echo)
			lens.setOnline(online).setEcho(echo).init();			
		}
		result(sShortName+"\n")
		return 1;
	}
	
	//
	object allocLens(object self,string sShortName)
	{
		object lens
		self.allocLens(sShortName)
		return lens;
	}

	void setValues(object self)
	{
		self.setPopup("amplitude")
		self.setNumber("frequency (Hz)")
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

	//Begin threads
	number beginWobble(object self,number priority,number resolve,object src,TagGroup tags,object objs,object lens)
	{
		if((priority<1)&&(self.isRunning()))return 0
		if(!lens.scriptObjectIsValid())
		{
			string s;self.getData("lens",s)		
			self.allocLens(s,lens);if(!lens.scriptObjectIsValid())return 0			
		}
		fillObj(objs,"lens",lens,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(self.init(src,self,msg,resolve),priority)
	}

	//Do threads
	number wobble(object self,object src,TagGroup tags,object objs,object lens)
	{
		number status
		if(status=self.beginWobble(1,0,src,tags,objs,lens))
			status=self.endThread()
		return status
	}
	//
	void wobblePressed(object self)
	{
		if(self.isRunning())
			self.stop()
		else
		{
			setTerminate(0)
			self.beginWobble(0,1,null,null,null,null)
		}
	}		
	
	//
	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)

		//
		TagGroup lensList=newTagList()
		lensList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Brightness","CL3"))	
		lensList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Objective (fine)","OLf"))	
		lensList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Objectives (coarse)","OLc"))	
		lensList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Intermediate 1","IL1"))
		lensList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Projector","PL"))
		TagGroup lensTag=self.createPopup("lens","",lensList)
		dlgItems.dlgAddElement(lensTag).dlgExternalPadding(5,0).dlgAnchor("East")

		TagGroup ampList=newTagList()
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0010",16))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0040",64))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0100",256))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x0400",1024))
		ampList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("0x1000",4096))
		TagGroup ampTag=self.createPopup("amplitude","Amp (lens units)",ampList)
		dlgItems.dlgAddElement(ampTag.dlgExternalPadding(5,0).dlgAnchor("West"))

		TagGroup freqTag=self.createNumber("frequency (Hz)","Freq. (Hz):",8,2).dlgExternalPadding(5,0).dlgSide("West")
		TagGroup wobbleTag=self.createButton("wobble","Wobble","wobblePressed")
		dlgItems.dlgAddElement(dlgGroupItems(freqTag,wobbleTag).dlgTableLayout(2,1,0).dlgExternalPadding(5,0).dlgAnchor("West"))
		
		dlgTags.dlgTableLayout(1,4,0);			
		TagGroup position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);
		self.super.init(dlgTags)

		openandSetProgressWindow("","","")	
			
		return self
	}	
				
	number aboutToCloseDocument(object self,number verify)
	{
		self.stop()
		self.super.aboutToCloseDocument(verify)
	}
	
	LensWobbler(object self)
	{
		self.setGroup(LENSWOBBLER_sGroup)
		self.setName(LENSWOBBLER_sName)
		self.setTitle(LENSWOBBLER_sTitle)
		self.setEcho(LENSWOBBLER_echo)
		
		//wobbleThread=alloc(LensWobble).load()
		msg=alloc(LensWobblerMsg)		
	}
	
	object load(object self)
	{
		self.addData("lens","CL3")		
		self.addData("amplitude",256)		
		self.addData("frequency (Hz)",1)		
		self.addData("online",LENSWOBBLER_online)	
		return self.super.load()
	}
	
	~LensWobbler(object self)
	{
		self.unload()
	}
}

void showLensWobbler()
{
	alloc(LensWobbler).load().init().display()
}

if(LENSWOBBLER_display)showLensWobbler()
