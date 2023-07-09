//Montage acquisition on JEOL JEM-2100
//P. Ahrenkiel, 4/30/2019
module com.gatan.dm.jemmontage
uses com.gatan.dm.jemlib
uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog
uses com.gatan.dm.defcalib
uses com.gatan.dm.jemcomp

number MONTAGE_online=1
number MONTAGE_Nx=1
number MONTAGE_Ny=1
number MONTAGE_coarseOverlap=0.1
number MONTAGE_fineOverlap=0.4
number MONTAGE_stitch=1
number MONTAGE_echo=0
string MONTAGE_sDeflector="PLA"
number MONTAGE_MAG_shiftBeam=1//shift beam when in MAG mode
number MONTAGE_MAG_tiltBeam=1//tilt beam when in MAG mode
number MONTAGE_balance=1//balance intensities of images
number MONTAGE_display=0

number MONTAGE_breakOnError=0
string MONTAGE_sGroup="MONTAGE"
string MONTAGE_sName="Montage"
string MONTAGE_sTitle="Montage"
string MONTAGE_sHelpFilename="MONTAGE_Help.docx"

string MONTAGECOARSEALIGN_sSetup="search"

string MONTAGECOARSEALIGN_sGroup="MONTAGECOARSEALIGN"
string MONTAGECOARSEALIGN_sName="MontageCoarseAlign"
string MONTAGECOARSEALIGN_sTitle="Coarse Align Parameters"

string MONTAGEACQUIRE_sGroup="MONTAGEACQUIRE"
string MONTAGEACQUIRE_sName="MontageAcq"
string MONTAGEACQUIRE_sTitle="Montage Parameters"
string sStitchMethod="ramped"

//Prefs
string MONTAGE_sCorrImageName="Montage_corr"

interface MontageProto
{
	void getMontageExtNum(object self,number Nx,number Ny,number f,number &Nxp,number &Nyp);
	image getMontagePoints(object self,number Nx,number Ny,number sizeX,number sizeY,number f);
	image getFrameWeight(object self,number Nx,number Ny,number sizeX,number sizeY,number f,number stitch);
	number endCoarseAlign(object self);
	number endAcquire(object self);
	object getMontageCorr(object self,object &c);
}

//
class MontageMsg:ThreadMsg
{
	image img
	object defCal
		
	object getImg(object self,image &p){p:=img;return self;}
	object setImg(object self,image &p){img:=p;return self;}
	
	object getDefCalib(object self,object &p){p=defCal;return self;}
	object setDefCalib(object self,object &p){defCal=p;return self;}	
}

//
class MontageCoarseAlign:JEM_Widget
{
	number noError
	void setValues(object self)
	{
		self.setPopup("setup")
	}

	MontageCoarseAlign(object self)
	{
		self.setGroup(MONTAGECOARSEALIGN_sGroup)
		self.setName(MONTAGECOARSEALIGN_sName)
		self.setTitle(MONTAGECOARSEALIGN_sTitle)
		self.setEcho(MONTAGE_echo)
	}

	object load(object self)
	{
		self.addData("setup",MONTAGECOARSEALIGN_sSetup)
		return self.super.load()
	}
	
	~MontageCoarseAlign(object self)
	{	
		self.unload()
	}
	
	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		self.write()			
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(MONTAGECOARSEALIGN_sName,dlgItems)
		
//		
		TagGroup setupList=newTagList()
		object acq;if(!getWidget("SmartAcq",acq)){acq=alloc(SmartAcq).load();}		
		acq.appendSetupList(setupList)
		TagGroup coarseSetupTag=self.createPopup("setup","camera setup:",setupList)
		dlgItems.dlgAddElement(coarseSetupTag)
		dlgTags.dlgTableLayout(1,2,0)
	
		self.super.init(dlgTags)
		return self
	}
	
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
		object defCal;if(!getWidget("DefCalib",defCal)){self.abort();return;}
		
		object corr;owner.getMontageCorr(corr)		
		number online;owner.getData("online",online)	
		//number useSMARTACQ;source.getData("use SmartAcq",useSMARTACQ)
		//number doProcess;if(!getTag(tags,"process",doProcess)){doProcess=0;fillTag(tags,"process",doProcess,1);}
		TagGroup calTag=camCalib.getTags()
		string sMode;calTag.TagGroupGetTagAsString("Mode",sMode)

		string sPrevSetup;acq.getData("setup",sPrevSetup)	
		string sCoarseSetup;self.getData("setup",sCoarseSetup)
		acq.setData("setup",sCoarseSetup)
		acq.writeSetup()

		//TagGroup calTag=camCalib.get()
		//calTag.TagGroupOpenBrowserWindow(0)
		corr.defineOrigin()
		object def;corr.getLens(def)
		def.setOnline(online)
		number defX0,defY0;def.read(defX0,defY0)
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		number phase=0
		number actionKey=progInfo.addProgress("Aligning coarse")
		progInfo.showProgress()
		while(self.super.isAlive())
		{			
			number doNext=0
			if(!self.super.isPaused())
			{					
				if(phase==0)
				{
					if(!defCal.scaleCalib(self,tags,objs,def,sMode,1,null))
						self.abort()
					doNext=1
				}
							
				if(phase==1)
				{
					corr.identity().negate()
					corr.setValid(1).saveMatrix()					
					self.super.kill()
				}
			}			
			if(doNext)phase++
			yield()						
		}
		if(self.isOrigin())acqCtrl.endControlScreen();
		def.write(defX0,defY0)
		acq.setData("setup",sPrevSetup)
		acq.writeSetup()
		if(self.isViable())
		{
			//def.set(0,0)
			owner.setData("calibrated",1)
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
			owner.endCoarseAlign()
	}
}


//
//Montage tilt alignment -P. Ahrenkiel, 2020
//Manually align the OA with the beam using tilt
string MONTAGETILTALIGN_sGroup="MONTAGETILTALIGN"
string MONTAGETILTALIGN_sName="MontageTiltAlign"
string MONTAGETILTALIGN_sTitle="Montage Tilt Alignment"
number MONTAGETILTALIGN_echo=0

class MontageTiltAlignMsg:ThreadMsg
{
}

interface MontageTiltAlignProto
{
}

class MontageTiltAlign:JEM_Widget
{
	void setValues(object self)
	{
	}

	MontageTiltAlign(object self)
	{
		self.setGroup(MONTAGETILTALIGN_sGroup)
		self.setName(MONTAGETILTALIGN_sName)
		self.setTitle(MONTAGETILTALIGN_sTitle)
		self.setEcho(MONTAGETILTALIGN_echo)
	}

	object load(object self)
	{
		return self.super.load()
	}

	~MontageTiltAlign(object self)
	{
		self.write()
	}
		
	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		self.write()			
	}

	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val)
		self.setValues();
		self.write()			
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.write()			
		self.setValues();

	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog("",dlgItems)		
		dlgTags.dlgTableLayout(1,1,0)
	
		self.super.init(dlgTags)
		return self
	}
	
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
		object camCalib;if(!getObj(objs,"CameraCal",camCalib))fillObj(objs,"CameraCal",camCalib=alloc(CameraCalib).load(),1);
		object acqCtrl;if(!getWidget("AcqCtrl",acqCtrl)){self.abort();return;}
		object acq;if(!getObj(objs,"SmartAcq",acq)){fillObj(objs,"SmartAcq",acq=alloc(SmartAcq).load(),1);}
		object defCal;if(!getWidget("DefCalib",defCal)){self.abort();return;}
		object montageAcq;if(!getObj(objs,"MontageAcq",montageAcq)){self.kill();self.end();return;}
		
		object corr;owner.getMontageCorr(corr)
		object def;corr.getLens(def)
		number online;owner.getData("online",online)
		def.setOnline(online)
		string sDefName;def.getShortName(sDefName)
		TagGroup calTag=camCalib.getTags()
		number calUpixSize;string sCalUnits
		calTag.TagGroupGetTagAsNumber("Alternative unbinned pixel size",calUpixSize)
		calTag.TagGroupGetTagAsString("Alternative units",sCalUnits)
		number upixSize=calUpixSize;
		string sUnits=sCalUnits
		
		if(sDefName=="PLA"){upixSize=1;sUnits="upix";}

		string sMode;calTag.TagGroupGetTagAsString("Mode",sMode)
		//Check if beam shift on. If so, allocate beam shift lens.
		number MAG_shiftBeam;montageAcq.getData("MAG shift beam",MAG_shiftBeam);
		number doShiftBeam=MAG_shiftBeam&&(sMode!="DIFF")
		object beamShiftLens
		number beamShiftX0,beamShiftY0
		if(doShiftBeam)
		{
			if(alloc(DefCalib).loadDeflector("CLA1",beamShiftLens))
			{
				beamShiftLens.setOnline(online)
				number res;beamShiftLens.loadCalib(res)
				beamShiftLens.defineOrigin()
				beamShiftLens.read(beamShiftX0,beamShiftY0)
			}
		}
		
		//Check if beam tilt on. If so, allocate beam tilt lens.
		number MAG_tiltBeam;montageAcq.getData("MAG tilt beam",MAG_tiltBeam);
		number doTiltBeam=MAG_tiltBeam&&(sMode!="DIFF")
		object beamTiltLens
		number beamTiltX0,beamTiltY0
		if(doTiltBeam)
		{
			if(alloc(DefCalib).loadDeflector("CLA2",beamTiltLens))
			{
				beamTiltLens.setOnline(online)
				number res;beamTiltLens.loadCalib(res)
				beamTiltLens.defineOrigin()
				beamTiltLens.read(beamTiltX0,beamTiltY0)
			}
		}

		number lensX0,lensY0
		def.read(lensX0,lensY0)
		corr.defineOrigin()
	
		object camera;acq.getCamera(camera)
		number bin;camera.getBinning(bin,bin)
		number sizeX,sizeY;camera.getBinnedSize(sizeX,sizeY)
		number uSizeX=bin*sizeX,uSizeY=bin*sizeY
		
		number x0=sizeX/2,y0=sizeY/2
		image img0,resimg
		image ccimg

		//find montage path
		number Nx;montageAcq.getData("Nx",Nx)
		number Ny;montageAcq.getData("Ny",Ny)
		number montSizeX=Nx*sizeX,montSizeY=Ny*sizeY
		number Nxp,Nyp,f=0
		owner.getMontageExtNum(Nx,Ny,f,Nxp,Nyp)

		number nExp=Nxp*Nyp
		result("montage size (pix): "+montSizeX+" x "+montSizeY+"\n")
		result("acquired images: "+Nxp+" x "+Nyp+"\n")
		result("exposures: "+nExp+"\n")

		image pointImg:=owner.getMontagePoints(Nx,Ny,sizeX,sizeY,f)
		image beamTiltImg:=realImage("beamTilt",4,nExp,3)
		image calImageShiftImg:=RealImage("cal image shift",4,nExp,2)
		
		number phase=0,iExp=0
		number ccid=-1
		number scale
		image img
		number actionKey=progInfo.addProgress("Aligning tilt")
		number stepKey=progInfo.addProgress("")
		result("--------------\n")
		while(self.isAlive())
		{	
			number doNext=0
			if(!self.isPaused())
			{
				string sk=format(iExp+1,"%g")
				string smsg="Aligning "+sk+"/"+format(nExp,"%g")
				progInfo.setProgress(stepKey,smsg)
				progInfo.showProgress()

				if(phase==0)
				{
					
					iExp=0
					number pX=trunc(getPixel(pointImg,iExp,0))
					number pY=trunc(getPixel(pointImg,iExp,1))
					number pixShiftX=pX-montSizeX/2,pixShiftY=pY-montSizeY/2
					number imageShiftX=bin*pixShiftX*upixSize,imageShiftY=bin*pixShiftY*upixSize
										
					corr.set(imageShiftX,imageShiftY)
					result("shift: "+imageShiftX+", "+imageShiftY+"\n")

					number calImageShiftX=bin*pixShiftX*calUpixSize,calImageShiftY=bin*pixShiftY*calUpixSize
					calImageShiftImg[iExp,0]=calImageShiftX
					calImageShiftImg[iExp,1]=calImageShiftY
					result("cal shift: "+calImageShiftX+", "+calImageShiftY+"\n")
					if(doShiftBeam)
						beamShiftLens.set(calImageShiftX,calImageShiftY)
					if(doTiltBeam)
						beamTiltLens.set(calImageShiftX,calImageShiftY)
					//result("set (mrad) X: "+phiX+", Y: "+phiY+"\n")
					
					iExp++;doNext=1		
					self.pause();
					acqCtrl.setValues();
				}

				if(phase==1)
				{
					//get tilt lenses after user adjustment
					number x,y;
					if(doTiltBeam)beamTiltLens.read(x,y)
					beamTiltImg[iExp-1,0]=x;beamTiltImg[iExp-1,1]=y;beamTiltImg[iExp-1,2]=1

					progInfo.setProgress(stepKey,"Frame: "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()

					number pX=trunc(getPixel(pointImg,iExp,0))
					number pY=trunc(getPixel(pointImg,iExp,1))
					
					number pixShiftX=pX-montSizeX/2,pixShiftY=pY-montSizeY/2
					number imageShiftX=bin*pixShiftX*upixSize,imageShiftY=bin*pixShiftY*upixSize					
					
					corr.set(imageShiftX,imageShiftY)

					number calImageShiftX=bin*pixShiftX*calUpixSize,calImageShiftY=bin*pixShiftY*calUpixSize
					calImageShiftImg[iExp,0]=calImageShiftX
					calImageShiftImg[iExp,1]=calImageShiftY
					//result("cal shift: "+calImageShiftX+", "+calImageShiftY+"\n")
					if(doShiftBeam)
						beamShiftLens.set(calImageShiftX,calImageShiftY)
					if(doTiltBeam)
						beamTiltLens.set(calImageShiftX,calImageShiftY)

					iExp++			
					if(iExp>=nExp)doNext=1
					self.pause();
					acqCtrl.setValues();
				}
				
				if(phase==2)
				{					
					number x,y;if(doTiltBeam)beamTiltLens.read(x,y)
					beamTiltImg[iExp-1,0]=x;beamTiltImg[iExp-1,1]=y;beamTiltImg[iExp-1,2]=1
					image calibSubImg:=matrixMultiply(calImageShiftImg,rightPseudoInverse(beamTiltImg))
					image calibImg:=realImage("calib",4,2+1,2+1)
					calibImg=((icol==irow)?1:0)
					calibImg[0,0,2,2+1]=calibSubImg	
					//showImage(calImageShiftImg)
					//showImage(beamTiltImg)
					if(doTiltBeam)
					{
						beamTiltLens.setCalib(calibImg)
						beamTiltLens.saveCalib()
					}
					self.super.kill();
				}
			}
			if(doNext)phase++			
			yield()
		}
		def.write(lensX0,lensY0)
		if(doShiftBeam)
			beamShiftLens.write(beamShiftX0,beamShiftY0)
		if(doTiltBeam)
			beamTiltLens.write(beamTiltX0,beamTiltY0)
			
		progInfo.deleteProgress(actionKey)
		progInfo.deleteProgress(stepKey)
		progInfo.showProgress()
		self.proceed();acqCtrl.setValues()
		if(self.super.isViable())
		{
			object msg;self.newMessage(msg)
			self.sendMessage(msg)
		}
		self.super.end()		
	}	
}

//
class MontageAcquire:JEM_Widget
{
	number noError
	void setValues(object self)
	{
		self.setNumber("Nx")
		self.setNumber("Ny")
		self.setNumber("coarse overlap")
		self.setNumber("fine overlap")
		self.setCheckBox("stitch")
		self.setCheckBox("MAG shift beam")
		self.setCheckBox("MAG tilt beam")
		self.setCheckBox("balance intensity")
	}

	MontageAcquire(object self)
	{
		self.setGroup(MONTAGEACQUIRE_sGroup)
		self.setName(MONTAGEACQUIRE_sName)
		self.setTitle(MONTAGEACQUIRE_sTitle)
		self.setEcho(MONTAGE_echo)
	}

	object load(object self)
	{
		self.addData("Nx",MONTAGE_Nx)
		self.addData("Ny",MONTAGE_Ny)
		self.addData("coarse overlap",MONTAGE_coarseOverlap)
		self.addData("fine overlap",MONTAGE_fineOverlap)
		self.addData("stitch",MONTAGE_stitch)
		self.addData("MAG shift beam",MONTAGE_MAG_shiftBeam)
		self.addData("MAG tilt beam",MONTAGE_MAG_tiltBeam)
		self.addData("balance intensity",MONTAGE_balance)
		return self.super.load()
	}

	~MontageAcquire(object self)
	{
		self.super.unload()
	}
		
	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		self.write()			
	}

	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val)
		self.setValues();
		self.write()			
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.setValues();
		self.write()			
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(MONTAGEACQUIRE_sName,dlgItems)
		
//
		tagGroup nX_tag=self.createNumber("Nx","Nx",8,3)//.DLGSide("West").dlgexternalpadding(5,0)
		tagGroup nY_tag=self.createNumber("Ny","Ny",8,3)//.DLGSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(DLGGroupItems(nX_tag,nY_tag).DLGTableLayout(2,1,0).dlgexternalpadding(5,0).DLGAnchor("East"))
		
		tagGroup coarseOverlapTag=self.createNumber("coarse overlap","coarse overlap (0-1)",8,3)
		dlgItems.dlgAddElement(coarseOverlapTag)

		tagGroup fineOverlapTag=self.createNumber("fine overlap","fine overlap (0-1)",8,3)
		dlgItems.dlgAddElement(fineOverlapTag)
		
		tagGroup stitchTag=self.createCheckBox("stitch","stitch")
		dlgItems.dlgAddElement(stitchTag)

		tagGroup MAG_shiftBeamTag=self.createCheckBox("MAG shift beam","shift beam when in MAG mode")
		dlgItems.dlgAddElement(MAG_shiftBeamTag)

		tagGroup MAG_tiltBeamTag=self.createCheckBox("MAG tilt beam","tilt beam when in MAG mode")
		dlgItems.dlgAddElement(MAG_tiltBeamTag)

		tagGroup balanceTag=self.createCheckBox("balance intensity","balance intensity")
		dlgItems.dlgAddElement(balanceTag)

		dlgTags.dlgTableLayout(1,9,0)
	
		self.super.init(dlgTags)
		return self
	}
	
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
		//object defCal;if(!getWidget("DeflectorCal",defCal)){self.abort();return;}

		number fineAlign;if(!getTag(tags,"refine alignment",fineAlign)){fineAlign=0;}
		number saveAlign;if(!getTag(tags,"save alignment",saveAlign)){saveAlign=0;}
		number show;if(!getTag(tags,"show montage",show)){show=1;}
		
		//number doProcess;if(!getTag(tags,"process",doProcess)){doProcess=1;fillTag(tags,"process",doProcess,1);}
		number online;owner.getData("online",online)
		number Nx;self.getData("Nx",Nx);
		number Ny;self.getData("Ny",Ny);
		number f
		if(fineAlign)
			self.getData("fine overlap",f);
		else
			self.getData("coarse overlap",f);		
		
		number stitch;
		//if(fineAlign)stitch=1//temporary. Eventually want to find edges and piece together.
		//else
		self.getData("stitch",stitch);
		//acq.setData("use SmartAcq",useSMARTACQ)
		//acq.prepForAcquire(source,progInfo,camCalib)

		number dtor=pi()/180
		number i,j
		number nPow=1

		object corr;owner.getMontageCorr(corr)
		number isValid;corr.getValid(isValid)
		if(!isValid)
		{
			result("Montage alignment correction is invalid.\n")
			self.abort()
		}
		
		object def;corr.getLens(def)
		def.setOnline(online)
		string sDefName;def.getShortName(sDefName)
		number isDefValid;def.getValid(isDefValid)
		if(!isValid)
		{
			result(sDefName+" calibration is invalid.\n")
			self.abort()
		}
		
		TagGroup calTag=camCalib.getTags()
		number calUpixSize;string sCalUnits
		calTag.TagGroupGetTagAsNumber("Alternative unbinned pixel size",calUpixSize)
		calTag.TagGroupGetTagAsString("Alternative units",sCalUnits)
		number upixSize=calUpixSize;
		string sUnits=sCalUnits
		
		if(sDefName=="PLA"){upixSize=1;sUnits="upix";}

		string sMode;calTag.TagGroupGetTagAsString("Mode",sMode)

		//Check if beam shift on. If so, allocate beam shift lens.
		number MAG_shiftBeam;self.getData("MAG shift beam",MAG_shiftBeam);
		number doShiftBeam=MAG_shiftBeam&&(sMode!="DIFF")
		object beamShiftLens
		number beamShiftX0,beamShiftY0
		if(doShiftBeam)
		{
			if(alloc(DefCalib).loadDeflector("CLA1",beamShiftLens))
			{
				beamShiftLens.setOnline(online)
				number res;beamShiftLens.loadCalib(res)
				beamShiftLens.defineOrigin()
				beamShiftLens.read(beamShiftX0,beamShiftY0)
				beamShiftLens.getValid(isValid)
				if(!isValid)
				{
					result("Beam shift calibration is invalid.\n")
					doShiftBeam=0
				}
			}
		}

		//Check if beam tilt on. If so, allocate beam tilt lens.
		number MAG_tiltBeam;self.getData("MAG tilt beam",MAG_tiltBeam);
		number doTiltBeam=MAG_tiltBeam&&(sMode!="DIFF")
		object beamTiltLens
		number beamTiltX0,beamTiltY0
		if(doTiltBeam)
		{
			if(alloc(DefCalib).loadDeflector("CLA2",beamTiltLens))
			{
				beamTiltLens.setOnline(online)
				number res;beamTiltLens.loadCalib(res)
				beamTiltLens.defineOrigin()
				beamTiltLens.read(beamTiltX0,beamTiltY0)
				beamShiftLens.getValid(isValid)
				if(!isValid)
				{
					result("Beam tilt calibration is invalid.\n")
					doTiltBeam=0
				}
			}
		}

		number doBalanceIntens;self.getData("balance intensity",doBalanceIntens)
		
		number lensX0,lensY0;
		def.read(lensX0,lensY0)
		corr.defineOrigin()
	
		object camera;acq.getCamera(camera)
		number bin;camera.getBinning(bin,bin)
		number sizeX,sizeY;camera.getBinnedSize(sizeX,sizeY)
		number uSizeX=bin*sizeX,uSizeY=bin*sizeY
		
		number x0=sizeX/2,y0=sizeY/2
		image img0,resimg
		image ccimg

		//find montage path
		number montSizeX=Nx*sizeX,montSizeY=Ny*sizeY

		number Nxp,Nyp
		owner.getMontageExtNum(Nx,Ny,f,Nxp,Nyp)

		number nExp=Nxp*Nyp
		if(fineAlign)
		{
			result("montage size (pix): "+montSizeX+" x "+montSizeY+"\n")
			result("acquired images: "+Nxp+" x "+Nyp+"\n")
			result("exposures: "+nExp+"\n")
		}

		image imageShiftImg,corrImageShiftImg
		if(fineAlign&&saveAlign)
		{
			imageShiftImg:=RealImage("image shift",4,nExp,2)
			corrImageShiftImg:=RealImage("corrected image shift",4,nExp,2)
		}
		image pointImg:=owner.getMontagePoints(Nx,Ny,sizeX,sizeY,f)
		
		image montImg,unclippedImg,maskImg,weightImg,unclippedWeightImg
		image subMaskImg,posImg
		//ShowImage(unclippedWeightImg)
		
		image subWeightImg:=owner.getFrameWeight(Nx,Ny,sizeX,sizeY,f,stitch)
		//showImage(subWeightImg)
		
		number phase=0,iExp
		number ccid=-1
		number scale
		image img
		number actionKey=progInfo.addProgress("Acquiring montage")
		number stepKey=progInfo.addProgress("")
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);
		while(self.super.isAlive())
		{
			number doNext=0

			if(!self.super.isPaused())
			{					
				if(phase==0)
				{
					try
					{
						montImg:=RealImage("Montage",4,montSizeX,montSizeY)
						montImg=0

						//oversampled
						unclippedImg:=RealImage("Unclipped",4,montSizeX,montSizeY)
						unclippedImg=0
						//showImage(unclippedImg)
						
						//keep track of what has been sampled
						maskImg:=RealImage("Mask",4,montSizeX,montSizeY)
						maskImg=0
						s//howImage(maskImg)
						
						if(stitch)
						{
							//weights for blending
							weightImg:=RealImage("weight",4,montSizeX,montSizeY)
							weightImg=0
							//showImage(weightImg)

							unclippedWeightImg:=RealImage("unclippedWeight",4,montSizeX,montSizeY)
							unclippedWeightImg=0
							//showImage(unclippedWeightImg)
						}
						if(doBalanceIntens)
						{
							subMaskImg:=realImage("sub mask",4,sizeX,sizeY)
							subMaskImg=0
							//showImage(subMaskImg)

							posImg:=realImage("positioned",4,sizeX,sizeY)
							posImg=0
							//showImage(posImg)
						}
					}
					catch
					{
						throw("Insufficient memory.")
						self.super.abort()
					}
					doNext=1
				}

				
				if(phase==1)//extend pix/def for full montage range
				{	
					if(iExp<=nExp)
					{			
						progInfo.setProgress(stepKey,"Exp: "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
						progInfo.showProgress()

						number pX=trunc(getPixel(pointImg,iExp,0))
						number pY=trunc(getPixel(pointImg,iExp,1))
						
						number pixShiftX=pX-montSizeX/2,pixShiftY=pY-montSizeY/2
						number imageShiftX=bin*pixShiftX*upixSize,imageShiftY=bin*pixShiftY*upixSize
						
						//result("shift: "+imageShiftX+", "+imageShiftY+"\n")
						if(fineAlign&&saveAlign)
						{
							imageShiftImg[iExp,0]=imageShiftX
							imageShiftImg[iExp,1]=imageShiftY
						}					
						corr.set(imageShiftX,imageShiftY)
	
						number calImageShiftX=bin*pixShiftX*calUpixSize,calImageShiftY=bin*pixShiftY*calUpixSize
						//result("cal shift: "+calImageShiftX+", "+calImageShiftY+"\n")
						if(doShiftBeam)
							beamShiftLens.set(calImageShiftX,calImageShiftY)
						if(doTiltBeam)
							beamTiltLens.set(calImageShiftX,calImageShiftY)
					
						number corrImageShiftX,corrImageShiftY
						corr.eval(imageShiftX,imageShiftY,corrImageShiftX,corrImageShiftY)
						
						number prevCorrImageShiftX=corrImageShiftX
						number prevCorrImageShiftY=corrImageShiftY
						//result("apparent=("+apparX+", "+apparY+")\n")
						//result("smartacq? "+useSMARTACQ+"\n")
						if(acq.acquire(img,self,tags,objs,0))
						{					
							number mLeft=pX-sizeX/2,mRight=pX+sizeX/2
							number mTop=pY-sizeY/2,mBottom=pY+sizeY/2

							number pLeft=0,pRight=sizeX
							number pTop=0,pBottom=sizeY

							if(mLeft<0){pLeft-=mLeft;mLeft=0;}
							if(mRight>montSizeX){pRight-=mRight-montSizeX;mRight=montSizeX;}
							if(mTop<0){pTop-=mTop;mTop=0;}
							if(mBottom>montSizeY){pBottom-=mBottom-montSizeY;mBottom=montSizeY;}
							//result("mTop: "+mTop+", mLeft: "+mLeft+", mBottom: "+mBottom+", mRight: "+mRight+"\n")
							//result("pTop: "+pTop+", pLeft: "+pLeft+", pBottom: "+pBottom+", pRight: "+pRight+"\n")
							image pimg=img[pTop,pLeft,pBottom,pRight]
							image mimg=unclippedImg[mTop,mLeft,mBottom,mRight]
							if(iExp==0)
							{
								copyTags(img,montImg)
								imageCopyCalibrationFrom(montImg,img)
								if(show)
								{
									showImage(montImg)
									fitSize(montImg)
									if(getZoom(img)>1)
										zoomSize(montImg,1)
									//disp=montImg.imageGetImageDisplay(0)
								}
							}
							else
							{
								if(fineAlign)
								{
								
									image mmaskImg=maskImg[mTop,mLeft,mBottom,mRight]					
									number meanmImg=sum(mImg*mmaskImg)/sum(mmaskImg)
									mImg=(mmaskImg==0)?meanmImg:mImg

									//if(doesImageExist(ccid))
									if(isValid(ccImg))deleteImage(ccImg)
									//ccImg:=crossCorrelateAnything(pImg,mImg)
									number dX,dY
									ccImg:=getCC_shift(pImg,mImg,4,dX,dY)
									//ShowImage(ccimg)
									//ZoomSize(ccimg,0.25)
									//ccid=getImageID(ccimg)
									number ccSizeX,ccSizeY
									getSize(ccImg,ccSizeX,ccSizeY)

									number ccSizeXY=(ccSizeX**2+ccSizeY**2)**0.5
									if((dX**2+dY**2)**0.5>ccSizeXY)
									{
										dX=0;dY=0
										result("Unable to align images.\n")
										if(MONTAGE_breakOnError)
										{
											showImage(ccimg)
											showImage(pimg)
											showImage(mimg)
											self.super.abort()
											self.abort()
										}										
									}
									//result("dX, dY:"+dY+", "+dY+"\n")
									//dX=0;dY=0
									pX-=trunc(dX);pY-=trunc(dY)
									corrImageShiftX-=bin*dX*upixSize;corrImageShiftY-=bin*dY*upixSize
									
								}
								if(show)
								{
									showImage(montImg)
									//updateImage(montImg)
								}
							}
							
							if(fineAlign)
							{
								result("---------------\n")
								result("Expected shift ("+sUnits+"):("+prevCorrImageShiftX+", "+prevCorrImageShiftY+")\n")
								result("Actual shift ("+sUnits+"): ("+corrImageShiftX+", "+corrImageShiftY+") "+"\n")
							}
							
							if(saveAlign)
							{
								corrImageShiftImg[iExp,0]=corrImageShiftX
								corrImageShiftImg[iExp,1]=corrImageShiftY
							}

							mLeft=pX-sizeX/2;mTop=pY-sizeY/2
							pLeft=0;pTop=0
							if(mLeft<0){pLeft-=mLeft;mLeft=0;}
							if(mTop<0){pTop-=mTop;mTop=0;}
											
							if(doBalanceIntens&&(iExp>0))
							{
								//Find number of overlap pixels
								subMaskImg=warp(maskImg,icol+mLeft-pLeft,irow+mTop-pTop)
								number nOverlapPix=sum(subMaskImg)
								if(isVisible(subMaskImg))updateImage(subMaskImg)
								
								//Find previous average weighted intensity in overlap region
								image subImg:=realImage("sub",4,sizeX,sizeY)
								subImg=warp(montImg,icol+mLeft-pLeft,irow+mTop-pTop)
								number prevImean=sum(subImg)/nOverlapPix

								//Find new average weighted intensity in overlap region
								posImg=subMaskImg*img
								if(isVisible(posImg))updateImage(posImg)

								number newImean=sum(subMaskImg*posImg)/nOverlapPix
								
								number Irat=prevImean/newImean
								//result("intensity ratio: "+Irat+"\n")
								img*=Irat
							}

							unclippedImg=((icol-mLeft+pLeft>=0)&&(icol-mLeft+pLeft<sizeX)\
								&&(irow-mTop+pTop>=0)&&(irow-mTop+pTop<sizeY))?\
								warp(img,icol-mLeft+pLeft,irow-mTop+pTop):unclippedImg

							if(!stitch)
								montImg=(maskImg==0)?unclippedImg:montImg

							maskImg=((icol-mLeft+pLeft>=0)&&(icol-mLeft+pLeft<sizeX)\
								&&(irow-mTop+pTop>=0)&&(irow-mTop+pTop<sizeY))?\
								1:maskImg
							if(isVisible(maskImg))updateImage(maskImg)
								
							if(stitch)
							{															
								weightImg+=((icol-mLeft+pLeft>=0)&&(icol-mLeft+pLeft<sizeX)\
										&&(irow-mTop+pTop>=0)&&(irow-mTop+pTop<sizeY))?\
										warp(subWeightImg,icol-mLeft+pLeft,irow-mTop+pTop):0
								if(isVisible(weightImg))updateImage(weightImg)
								
								unclippedWeightImg+=((icol-mLeft+pLeft>=0)&&(icol-mLeft+pLeft<sizeX)\
										&&(irow-mTop+pTop>=0)&&(irow-mTop+pTop<sizeY))?\
										warp(subWeightImg*img,icol-mLeft+pLeft,irow-mTop+pTop):0
								montImg=(weightImg>0)?unclippedWeightImg/weightImg:0
							}
							
							deleteImage(pimg)
							deleteImage(mimg)
							deleteImage(img)
							
							iExp++
							if(iExp>=nExp)self.super.kill()
						}
					}
				}
			}
			if(doNext)phase++
			yield()						
		}
		def.write(lensX0,lensY0)
		if(doShiftBeam)
			beamShiftLens.write(beamShiftX0,beamShiftY0)
		if(doTiltBeam)
			beamTiltLens.write(beamTiltX0,beamTiltY0)
		if(isValid(img))deleteImage(img)
		if(self.super.isViable())
		{
			if(self.isOrigin()&&show&&isVisible(montImg)){showScaleMarker(montImg);}
			if(fineAlign&&saveAlign&&(nExp>1))
			{
				corr.calc(imageShiftImg,corrImageShiftImg,nPow)
				corr.saveMatrix()				
				result("montage alignment saved\n")
			}
			object msg;self.newMessage(msg)
			msg.setImg(montImg)
			self.sendMessage(msg)
		}
		if(self.isOrigin()){acqCtrl.endControlScreen();}
		else{}
		//result("isn't origin\n")
				
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
			owner.endAcquire()
	}
}

/*
*/
class Montage:JEM_Widget
{
	object coarseAlignThread,tiltAlignThread,acquireThread
	object corr
	object msg
		
	//
	number allocDeflector(object self,object &deflector)
	{
		string sShortName;self.getData("deflector",sShortName)
		
		number res=0
		if(alloc(DefCalib).loadDeflector(sShortName,deflector))
		{
			//deflector.
			deflector.loadCalib(res)
			self.setData("calibrated",res)
			//result("calibrated: "+res+"\n")
		}
		else
			result("failed\n")
		return res;
	}
		
//
	void loadAlign(object self)
	{
		string filePath=""
		string appdir=getApplicationDirectory("preference",0)
		if(!openDialog(filePath))return
		if(MONTAGE_echo)result("Load alignment file: "+filePath+"\n")
		
		image cimg:=OpenImage(filePath)
		corr.setMatrix(cimg)
		corr.saveMatrix()
	}

	void saveAlign(object self)
	{
		string filename
		OpenandSetProgressWindow("Save alignment file...","","")
		if(!saveAsDialog("alignment file:",filename,filename)) return
		if(MONTAGE_echo)result("Save alignment file: "+filename+"\n")
		
		image cimg
		corr.getMatrix(cimg)
		SaveAsGatan(cimg,filename)
	}

	object getMontageCorr(object self,object &c){c=corr;return self;}
	
	number setMontageCorr(object self)
	{									
		object def;
		self.allocDeflector(def)
		number echo;self.getEcho(echo)
		corr=alloc(JEM_CorrLensXY).init("montage lens","lens",def).setEcho(echo)
		corr.setMatrixName(MONTAGE_sCorrImageName)
		return 1
	}

	//
	void getMontageExtNum(object self,number Nx,number Ny,number f,number &Nxp,number &Nyp)
	{
		if((Nx<=1)&&(Ny<=1))
		{
			Nxp=1;Nyp=1
		}
		else
		{
			Nxp=ceil(Nx/(1-f));Nyp=ceil(Ny/(1-f))
		}	
	}

	//
	image getMontagePoints(object self,number Nx,number Ny,number sizeX,number sizeY,number f)
	{
		number montSizeX=Nx*sizeX,montSizeY=Ny*sizeY
		number Nxp,Nyp
		self.getMontageExtNum(Nx,Ny,f,Nxp,Nyp)
		number nExp=Nxp*Nyp
		image pointImg:=RealImage("points",4,nExp,3)
		number ix0=Nx/2,iy0=Ny/2
		number ixp0=(Nxp-1)/2,iyp0=(Nyp-1)/2
		number px0=ix0*sizeX,py0=iy0*sizeY//center of montage (pix)
		number ixp=0,iyp=0
		number np=0
		number px,py
		number sizeXp=(1-f)*sizeX,sizeYp=(1-f)*sizeY
		while(1)
		{
			px=(ixp-ixp0)*sizeXp+ix0*sizeX
			py=(iyp-iyp0)*sizeYp+iy0*sizeY
			number pdist=sqrt((px-px0)**2+(py-py0)**2)

			SetPixel(pointImg,np,0,px)
			SetPixel(pointImg,np,1,py)
			SetPixel(pointImg,np,2,pdist)

			np++	
			ixp++
			if(ixp>=Nxp)
			{
				ixp=0
				iyp++
			
				if(iyp>=Nyp)
					break		
			}
		}

		//Sort by distance from center
		number i,j
		for(i=0;i<nExp;i++)
		{
			number pDistMin=GetPixel(pointImg,i,2)	
			for(j=i+1;j<nExp;j++)
			{
				number pDist=GetPixel(pointImg,j,2)
				if(pDist<pDistMin)
				{
					px=GetPixel(pointImg,j,0)
					py=GetPixel(pointImg,j,1)
				
					SetPixel(pointImg,j,0,GetPixel(pointImg,i,0))
					SetPixel(pointImg,j,1,GetPixel(pointImg,i,1))
					SetPixel(pointImg,j,2,pDistMin)
				
					SetPixel(pointImg,i,0,px)
					SetPixel(pointImg,i,1,py)
					SetPixel(pointImg,i,2,pDist)
				
					pDistMin=pDist			
				}
			}
		}
		return pointImg
	}

	//
	image getFrameWeight(object self,number Nx,number Ny,number sizeX,number sizeY,number f,number stitch)
	{
		number montSizeX=Nx*sizeX,montSizeY=Ny*sizeY
		number Nxp,Nyp
		number fx,fy
		if((Nx<=1)&&(Ny<=1))
		{ fx=1;fy=1;}
		else
		{	fx=(1-f);fy=(1-f);}
		
		Nxp=ceil(Nx/fx);Nyp=ceil(Ny/fy)
		number sizeXp=fx*sizeX,sizeYp=fY*sizeY

		image weightImg:=RealImage("weight",4,sizeX,sizeY)
		weightImg=1
			
		number top,left,bottom,right
		left=0;right=sizeX
		top=0;bottom=sizeY

		number xBound=floor((sizeX-sizeXp)/2)
		number yBound=floor((sizeY-sizeYp)/2)
		
		number fTop,fLeft,fBottom,fRight
		fLeft=left+xBound;fRight=right-xBound
		fTop=top+yBound;fBottom=bottom-yBound

		number dx=1,dy=1
		if(sStitchMethod=="ramped")
		{
			weightImg*=(irow<fTop)?(stitch?((top+irow)/(fTop)):0):1
			weightImg*=(icol<fLeft)?(stitch?((left+icol)/(fLeft)):0):1
			weightImg*=(irow>fBottom)?(stitch?((bottom-irow)/(bottom-fBottom)):0):1
			weightImg*=(icol>fRight)?(stitch?((right-icol)/(right-fRight)):0):1
		}
		
		if(sStitchMethod=="random")
		{
			image randImg:=realImage("random",4,sizeX,sizeY)
			randImg=random();
			weightImg*=(irow<fTop)?(stitch?(randImg<(irow+dy)/(fTop+dy)):0):1
			weightImg*=(icol<fLeft)?(stitch?(randImg<(icol+dx)/(fLeft+dx)):0):1
			weightImg*=(irow>fBottom)?(stitch?(randImg<(sizeY-irow+dy)/(sizeY-fBottom+dy)):0):1
			weightImg*=(icol>fRight)?(stitch?(randImg<(sizeX-icol+dx)/(sizeX-fRight+dx)):0):1
		}
		return weightImg
	}

	void setValues(object self)
	{
		self.setPopup("align action")
		//self.write()
	}
	
	void numberChanged(object self,string sIdent,number val)
	{
		if((sIdent=="Nx")||(sIdent=="Ny"))
			if(val<0)n=0
			
		if(sIdent=="overlap")
		{
			if(val<=0)val=0.0001
			if(val>=1)val=0.9999
		}
		self.super.numberChanged(sIdent,val);
		self.setValues()
	}
			
	//Begin threads
	number beginCoarseAlign(object self,number priority,number resolve,object src,TagGroup tags,object objs)
	{
		if((priority<1)&&(self.isRunning()))return 0
		if(!corr.scriptObjectIsValid())
		{
			OKDialog("Lens not configured!");
			return 0;
		}		
		msg.setTags(tags);msg.setObjs(objs)
		number res=self.begin(coarseAlignThread.init(src,self,msg,resolve),priority)
		return res
	}
	
	number beginTiltAlign(object self,number priority,number resolve,object src,TagGroup tags,object objs)
	{
		if((priority<1)&&(self.isRunning()))return 0
		if(!corr.scriptObjectIsValid())
		{
			OKDialog("Lens not configured!");
			return 0;
		}
		fillObj(objs,"MontageAcq",acquireThread,1)
		msg.setTags(tags);msg.setObjs(objs)
		number res=self.begin(tiltAlignThread.init(src,self,msg,resolve),priority)
		return res

	}
	
	number beginAcquire(object self,number priority,number resolve,object src,TagGroup tags,object objs,number fineAlign,number saveAlign,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		if(!corr.scriptObjectIsValid())
		{
			OKDialog("Lens not configured!");
			return 0;
		}
		number cal;self.getData("calibrated",cal)
		if(!cal)
		{
			OKDialog("Coarse alignment needed!");
			return 0;
		}
		
		fillTag(tags,"refine alignment",fineAlign,1)
		fillTag(tags,"save alignment",saveAlign,1)
		fillTag(tags,"show montage",show,1)
		msg.setTags(tags);msg.setObjs(objs)
		return self.begin(acquireThread.init(src,self,msg,resolve),priority)
	}

	//End threads
	number endCoarseAlign(object self)
	{
		object msg
		number status=coarseAlignThread.receiveMessageOnSignal(msg)
		return status
	}
	
	number endTiltAlign(object self)
	{
		object msg
		number status=tiltAlignThread.receiveMessageOnSignal(msg)
		return status
	}
	
	number endAcquire(object self,image &img)
	{
		object msg
		number status=acquireThread.receiveMessageOnSignal(msg)
		if(status)
			msg.getImg(img)
		return status
	}
	
	number endAcquire(object self)
	{
		image img
		return self.endAcquire(img)
	}
	
	//Do threads
	number coarseAlign(object self,object src,TagGroup tags,object objs)
	{
		number status
		if(status=self.beginCoarseAlign(1,0,src,tags,objs))
			status=self.endCoarseAlign()
		return status
	}

	//Do threads
	number tiltAlign(object self,object src,TagGroup tags,object objs)
	{
		number status
		if(status=self.beginTiltAlign(1,0,src,tags,objs))
			status=self.endTiltAlign()
		return status
	}

	number acquire(object self,image &img,object src,TagGroup tags,object objs,number fineAlign,number saveAlign,number show)
	{
		number status
		if(status=self.beginAcquire(1,0,src,tags,objs,fineAlign,saveAlign,show))
			status=self.endAcquire(img)
		return status
	}

	number fineAlign(object self,image &img,object src,TagGroup tags,object objs,number show)
	{
		return self.acquire(img,src,tags,objs,1,1,show)
	}

	number coarseAcquire(object self,image &img,object src,TagGroup tags,object objs,number show)
	{
		return self.acquire(img,src,tags,objs,0,0,show)
	}
	
	number fineAcquire(object self,image &img,object src,TagGroup tags,object objs,number show)
	{
		return self.acquire(img,src,tags,objs,1,0,show)
	}
	//
	void coarseAlignPressed(object self)
	{
		if(shiftDown())
		{
			coarseAlignThread.init()
			coarseAlignThread.pose()
		}
		else
		{
			if(self.isRunning())self.stop()
			else
			{
				setTerminate(0)
				self.beginCoarseAlign(0,1,null,null,null)
			}
		}
	}

	//
	void tiltAlignPressed(object self)
	{
		if(self.isRunning())self.stop()
		else
		{
			setTerminate(0)
			self.beginTiltAlign(0,1,null,null,null)
		}
	}

//
	void fineAlignPressed(object self)
	{
		setTerminate(0)
		if(shiftDown())
		{
			acquireThread.init()
			acquireThread.pose()
		}
		else
		{
			if(self.isRunning())self.stop()
			else self.beginAcquire(0,1,null,null,null,1,1,1)
		}
	}

//
	void coarseAcquirePressed(object self)
	{
		setTerminate(0)
		if(shiftDown())
		{
			acquireThread.init()
			acquireThread.pose()
		}
		else
		{
			if(self.isRunning())self.stop()
			else self.beginAcquire(0,1,null,null,null,0,0,1)
		}
	}

//
	void fineAcquirePressed(object self)
	{
		setTerminate(0)
		if(optionDown())
		{
			image mimg
			corr.getMatrix(mimg)
			showImage(mimg)
			return			
		}
		if(shiftDown())
		{
			acquireThread.init()
			acquireThread.pose()
		}
		else
		{
			if(self.isRunning())self.stop()
			else self.beginAcquire(0,1,null,null,null,1,0,1)
		}
	}
	
	void loadAlignPressed(object self)
	{
		self.loadAlign()
	}

	void saveAlignPressed(object self)
	{
		self.saveAlign()
	}

	void alignActionSelected(object self)
	{
		string sAction;self.getData("align action",sAction)
		self.setData("align action","")
		if(sAction=="")return
		if(sAction=="coarse align")self.coarseAlignPressed()
		if(sAction=="fine align")self.fineAlignPressed()
		if(sAction=="tilt align")self.tiltAlignPressed()
		if(sAction=="load align")self.loadAlignPressed()
		if(sAction=="save align")self.saveAlignPressed()
		self.setValues()
	}

	void acqActionSelected(object self)
	{
		string sAction;self.getData("acquire action",sAction)
		self.setData("acquire action","")
		if(sAction=="")return
		if(sAction=="coarse acquire")self.coarseAcquirePressed()
		if(sAction=="fine acquire")self.fineAcquirePressed()
		self.setValues()
	}

	
	void popupChanged(object self,string sIdent,tagGroup fieldTag)
	{
		self.super.popupChanged(sIdent,fieldTag)
		if(sIdent=="align action"){self.alignActionSelected();return;}
		if(sIdent=="acquire action"){self.acqActionSelected();return;}
		self.setValues();		
	}

	object init(object self)
	{	
		tagGroup dlgItems,dlgTags=dlgCreateDialog(self.getName(),dlgItems)
		openandSetProgressWindow("","","")	

		//
		TagGroup alignActionList=newTagList()
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Alignment",""))
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Coarse","coarse align"))
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Fine","fine align"))
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Tilt","tilt align"))
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Load","load align"))
		alignActionList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Save","save align"))
		dlgItems.dlgAddElement(self.createPopup("align action",alignActionList)).dlgExternalPadding(5,0).dlgAnchor("West")

		TagGroup coarseAcqTag=self.createButton("coarse acquire","Coarse Acquire","coarseAcquirePressed")
		TagGroup fineAcqTag=self.createButton("fine acquire","Fine Acquire","fineAcquirePressed")
		TagGroup helpTag=self.createButton("help","?","helpPressed").dlgExternalPadding(0,5).dlgAnchor("East")
		dlgItems.dlgAddElement(dlgGroupItems(coarseAcqTag,fineAcqTag,helpTag).dlgTableLayout(3,1,0).dlgExternalPadding(0,5)).dlgAnchor("West")
		
		dlgTags.dlgTableLayout(1,2,0);

		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);

		self.super.init(dlgTags)			
		return self
	}		

	Montage(object self)
	{	
		self.setGroup(MONTAGE_sGroup)
		self.setName(MONTAGE_sName)
		self.setTitle(MONTAGE_sTitle)
		self.setEcho(MONTAGE_echo)		

		coarseAlignThread=alloc(MontageCoarseAlign).load()
		tiltAlignThread=alloc(MontageTiltAlign).load()
		acquireThread=alloc(MontageAcquire).load()
		
		msg=alloc(MontageMsg)
	}
	
	object load(object self)
	{	
		self.addData("online",MONTAGE_online)
		self.addData("deflector","PLA")
		self.addData("calibrated",0)
		self.addData("not saved","align action","")
		self.addData("help filename",MONTAGE_sHelpFilename)

		self.super.load()
		self.setMontageCorr()		
		corr.loadMatrix()

		return self
	}
	
	~Montage(object self)
	{	
		self.unload()
	}
}

void showMontage()
{
	alloc(Montage).load().init().display()
}
if(MONTAGE_display)showMontage()
	
