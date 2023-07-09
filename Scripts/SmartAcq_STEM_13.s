//Smart Orius camera acquisition. Phil Ahrenkiel, 2021
//Put SmartAcqRef class definition in useful.
module com.gatan.dm.smartacq
uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog
uses com.gatan.dm.jemthread

//
number SMARTACQSTEM_online=1
number SMARTACQSTEM_useSMARTACQSTEM=1
number SMARTACQSTEM_echo=0
number SMARTACQSTEM_show=1
number SMARTACQSTEM_grabFrame=0

number SMARTACQSTEM_JEOL_index=1//0: BF/DF,1:JEOL,2: HAADF, for grabbing frames
number SMARTACQSTEM_JEOL_active=1
number SMARTACQSTEM_JEOL_byteDepth=2
		
number SMARTACQSTEM_BFDF_index=0
number SMARTACQSTEM_BFDF_active=0
number SMARTACQSTEM_BFDF_byteDepth=2

number SMARTACQSTEM_HAADF_index=2
number SMARTACQSTEM_HAADF_active=1
number SMARTACQSTEM_HAADF_byteDepth=2


number SMARTACQSTEM_imageWidth=256
number SMARTACQSTEM_imageHeight=256
number SMARTACQSTEM_rotation_deg=0
number SMARTACQSTEM_pixelTime_us=2
number SMARTACQSTEM_lineSync=0
number SMARTACQSTEM_nExp=1

number SMARTACQSTEM_display=0

string SMARTACQSTEM_sGroup="SMARTACQSTEM"
string SMARTACQSTEM_sName="SmartAcq_STEM"
string SMARTACQSTEM_sTitle="Smart Acquire STEM"
string SMARTACQSTEM_sHelpFilename="SMARTACQSTEM_Help.docx"

//predef
interface SmartAcq_STEMProto
{
}

class SmartAcq_STEM_msg:ThreadMsg
{
	object imgSet
	
	object getImageSet(object self,object &p){p=imgSet;return self;}	
	object setImageSet(object self,object p){imgSet=p;return self;}
}
//
class SmartAcq_STEM:JEM_Widget
{
	object msg
	
	void runThread(object self)
	{	
		self.super.begin()
		object owner=self.super.getOwner()

		TagGroup tags
		object objs
		object imgSet
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
		number show;if(!getTag(tags,"show",show)){show=SMARTACQSTEM_show;}

		imgSet=alloc(SmartAcq_STEM_ImageSet)
		number online;owner.getData("online",online)

		TagGroup calTag=camCalib.getTags()
		if(self.isOrigin())
		{
		}

		number i,j
	
		//number prevSTEM_paramsID=-1
		number restoreViewWhenDone=0
		if(DSIsAcquisitionActive( ))
		{
			//prevSTEM_paramsID=DSGetActiveParameterID()						
			DSInvokeButton(1)
			//DSStopAcquisition(prevSTEM_paramsID)
			while(DSIsAcquisitionActive()){}
			//if(prevSTEM_paramsID==0)
			restoreViewWhenDone=1
		}

		string sSetup;owner.getData("setup",sSetup)
		TagGroup setupTags;owner.getData(sSetup,setupTags)

		number sizeX;setupTags.tagGroupGetIndexedTagAsNumber(0,sizeX)//exposure time
		number sizeY;setupTags.tagGroupGetIndexedTagAsNumber(1,sizeY)//binning
		number rotDeg;setupTags.tagGroupGetIndexedTagAsNumber(2,rotDeg)//extend range
		number tPixel_us;setupTags.tagGroupGetIndexedTagAsNumber(3,tPixel_us)//acquire frames
		number syncLines;setupTags.tagGroupGetIndexedTagAsNumber(4,syncLines)//quality (0:fast; 1: high)
		number JEOL_active;setupTags.tagGroupGetIndexedTagAsNumber(5,JEOL_active)//proc frames
		number JEOL_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(6,JEOL_byteDepth)//processing mode
		number BFDF_active;setupTags.tagGroupGetIndexedTagAsNumber(7,BFDF_active)//diff streak correction		
		number BFDF_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(8,BFDF_byteDepth)//processing mode
		number HAADF_active;setupTags.tagGroupGetIndexedTagAsNumber(9,HAADF_active)//diff streak correction		
		number HAADF_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(10,HAADF_byteDepth)//processing mode
		number nExp;setupTags.tagGroupGetIndexedTagAsNumber(11,nExp)//
		//result("nExp: "+nExp+"\n")
		number STEM_paramsID=DSCreateParameters(sizeX,sizeY,rotDeg,tPixel_us,syncLines)

		number byteDepth=2 // 2 byte data
		image JEOL_img,JEOL_copyImg
		if(JEOL_active)
		{
			imgSet.getImage(SMARTACQSTEM_JEOL_index,JEOL_img)
			//result("got JEOL img\n")
			if(!isValid(JEOL_img))
				JEOL_img:=integerImage("JEOL",JEOL_byteDepth,0,sizeX,sizeY)
			number JEOL_img_ID=JEOL_img.getImageID() // 0:create new image
			DSSetParametersSignal(STEM_paramsID,SMARTACQSTEM_JEOL_index,JEOL_byteDepth,JEOL_active,JEOL_img_ID)		
		}
		
		image BFDF_img,BFDF_copyImg
		if(BFDF_active)
		{
			imgSet.getImage(SMARTACQSTEM_BFDF_index,BFDF_img)
			if(!isValid(BFDF_img))
				BFDF_img:=integerImage("BF/DF",BFDF_byteDepth,0,sizeX,sizeY)
			number BFDF_img_ID=BFDF_img.getImageID() // 0:create new image
			DSSetParametersSignal(STEM_paramsID,SMARTACQSTEM_BFDF_index,BFDF_byteDepth,BFDF_active,BFDF_img_ID)
		}
		
		image HAADF_img,HAADF_copyImg
		if(HAADF_active)
		{
			imgSet.getImage(SMARTACQSTEM_JEOL_index,HAADF_img)
			if(!isValid(HAADF_img))
				HAADF_img:=integerImage("HAADF",HAADF_byteDepth,0,sizeX,sizeY)
			number HAADF_img_ID=HAADF_img.getImageID() // 0:create new image
			DSSetParametersSignal(STEM_paramsID,SMARTACQSTEM_HAADF_index,HAADF_byteDepth,HAADF_active,HAADF_img_ID)
		}
		
		number prevScreen=acqCtrl.isScreenUp()
		if(self.isOrigin())acqCtrl.beginControlScreen(1,prevScreen);

		number actionKey=progInfo.addProgress("Acquiring...")
		progInfo.showProgress()
	
		number first=1,iExp=0,phase=0					
		while(self.super.isAlive())
		{
			number doNext=0
			if(!self.super.isPaused())
			{						
				if(phase==0)
				{
					DSStartAcquisition(STEM_paramsID,0,0)	
					progInfo.setProgress(actionKey,"Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
					progInfo.showProgress()
					doNext=1
				}
	
				if(phase==1)
				{
					if(DSIsAcquisitionActive()){}
					else
					{
						if(first)
						{					
							if(JEOL_active){JEOL_copyImg:=JEOL_img.imageClone();JEOL_copyImg-=min(JEOL_img);}
							if(BFDF_active){BFDF_copyImg:=BFDF_img.imageClone();BFDF_copyImg-=min(BFDF_img);}
							if(HAADF_active){HAADF_copyImg:=HAADF_img.imageClone();HAADF_copyImg-=min(HAADF_img);}
							first=0							
						}
						else
						{
							if(JEOL_active)JEOL_copyImg+=JEOL_img-min(JEOL_img)
							if(BFDF_active)BFDF_copyImg=BFDF_img-min(BFDF_img)
							if(HAADF_active)HAADF_copyImg=HAADF_img-min(HAADF_img)
						}
						
						if(JEOL_active)JEOL_img=JEOL_copyImg
						if(BFDF_active)BFDF_img=BFDF_copyImg
						if(HAADF_active)HAADF_img=HAADF_copyImg

						iExp++
						if(iExp<nExp)
						{
							DSStartAcquisition(STEM_paramsID,0,0)	
							progInfo.setProgress(actionKey,"Acquiring "+format(iExp+1,"%g")+"/"+format(nExp,"%g"))
							progInfo.showProgress()
						}
						else							
							self.kill()
					}
				}

			}			
	
			if(doNext)phase++
			yield()						
		}								
		//if(DSIsAcquisitionActive())DSStopAcquisition(STEM_paramsID)
		DSStopAcquisition(STEM_paramsID)
		if(self.isOrigin()){acqCtrl.endControlScreen();}

		progInfo.deleteProgress(actionKey)
		progInfo.showProgress()
		//JEM_setShutterPosition(prevShutter)
	
		DSDeleteParameters(STEM_paramsID)
		if(restoreViewWhenDone)DSInvokeButton(1)
		//if(restoreViewWhenDone)DSStartAcquisition(prevSTEM_paramsID,1,0)


		//
		if(self.super.isViable())
		{
			if(JEOL_active)
			{
				if(show)showScaleMarker(JEOL_img)
				imgSet.setImage(SMARTACQSTEM_JEOL_index,JEOL_img)
			}
			if(BFDF_active)
			{
				if(show)showScaleMarker(BFDF_img)
				imgSet.setImage(SMARTACQSTEM_BFDF_index,BFDF_img)
			}
			
			if(HAADF_active)
			{
				if(show)showScaleMarker(HAADF_img)
				imgSet.setImage(SMARTACQSTEM_HAADF_index,HAADF_img)	
			}
		}		

		//DSDialogEnabled(1)
		object msg;self.newMessage(msg)
		msg.setImageSet(imgSet)
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

//
	object readParamsTag(object self,number nParamSet,TagGroup &captureTag)
	{
		captureTag=newTagGroup()
		captureTag.tagGroupCreateNewLabeledTag("Image Width")
		captureTag.tagGroupSetTagAsNumber("Image Width",SMARTACQSTEM_imageWidth)
		
		captureTag.tagGroupCreateNewLabeledTag("Image Height")
		captureTag.tagGroupSetTagAsNumber("Image Height",SMARTACQSTEM_imageHeight)

		captureTag.tagGroupCreateNewLabeledTag("Sample Time")
		captureTag.tagGroupSetTagAsNumber("Sample Time",SMARTACQSTEM_pixelTime_us)

		captureTag.tagGroupCreateNewLabeledTag("Rotation")
		captureTag.tagGroupSetTagAsNumber("Rotation",SMARTACQSTEM_rotation_deg)

		captureTag.tagGroupCreateNewLabeledTag("Synchronize Lines")
		captureTag.tagGroupSetTagAsNumber("Synchronize Lines",SMARTACQSTEM_lineSync)

		captureTag.tagGroupCreateNewLabeledTag("JEOL active")
		captureTag.tagGroupSetTagAsNumber("JEOL active",SMARTACQSTEM_JEOL_active)

		captureTag.tagGroupCreateNewLabeledTag("JEOL byte depth")
		captureTag.tagGroupSetTagAsNumber("JEOL byte depth",2)

		captureTag.tagGroupCreateNewLabeledTag("BF/DF active")
		captureTag.tagGroupSetTagAsNumber("BF/DF active",SMARTACQSTEM_BFDF_active)

		captureTag.tagGroupCreateNewLabeledTag("BF/DF byte depth")
		captureTag.tagGroupSetTagAsNumber("BF/DF byte depth",2)

		captureTag.tagGroupCreateNewLabeledTag("HAADF active")
		captureTag.tagGroupSetTagAsNumber("HAADF active",SMARTACQSTEM_HAADF_active)

		captureTag.tagGroupCreateNewLabeledTag("HAADF byte depth")
		captureTag.tagGroupSetTagAsNumber("HAADF byte depth",2)

		number paramID=nParamSet,found=0
		for(paramID=2;paramID>=0;paramID--)
			if(DSParametersExist(paramID))
			{
				found=1;break
			}

		if(!found)return self

		captureTag.tagGroupSetTagAsNumber("Image Width",DSGetWidth(paramID))
		captureTag.tagGroupSetTagAsNumber("Image Height",DSGetHeight(paramID))
		captureTag.tagGroupSetTagAsNumber("Sample Time",DSGetPixelTime(paramID))
		captureTag.tagGroupSetTagAsNumber("Rotation",DSGetRotation(paramID))
		captureTag.tagGroupSetTagAsNumber("Synchronize Lines",DSGetLineSynch(paramID))
		captureTag.tagGroupSetTagAsNumber("JEOL active",DSGetSignalAcquired(paramID,SMARTACQSTEM_JEOL_index))
		captureTag.tagGroupSetTagAsNumber("BF/DF active",DSGetSignalAcquired(paramID,SMARTACQSTEM_BFDF_index))
		captureTag.tagGroupSetTagAsNumber("HAADF active",DSGetSignalAcquired(paramID,SMARTACQSTEM_HAADF_index))

		return self
	}
	
	object setSetup(object self)
	{				
		//TagGroup captureTag;self.getCaptureTag(captureTag)
		number sizeX;self.getData("image width (pix) (display)",sizeX)
		number sizeY;self.getData("image height (pix) (display)",sizeY)
		number rotDeg;self.getData("rotation (°) (display)",rotDeg)
		number tPixel_us;self.getData("pixel time (us) (display)",tPixel_us)
		number syncLines;self.getData("line sync (display)",syncLines)
		number JEOL_active;self.getData("JEOL active (display)",JEOL_active)
		number BFDF_active;self.getData("BF/DF active (display)",BFDF_active)
		number HAADF_active;self.getData("HAADF active (display)",HAADF_active)
		number JEOL_byteDepth;self.getData("JEOL byte depth (display)",JEOL_byteDepth)
		number BFDF_byteDepth;self.getData("BF/DF byte depth (display)",BFDF_byteDepth)
		number HAADF_byteDepth;self.getData("HAADF byte depth (display)",HAADF_byteDepth)
		number nExp;self.getData("number of exposures (display)",nExp)

		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		setupTags.tagGroupSetIndexedTagAsNumber(0,sizeX)//exposure time
		setupTags.tagGroupSetIndexedTagAsNumber(1,sizeY)//binning
		setupTags.tagGroupSetIndexedTagAsNumber(2,rotDeg)//extend range
		setupTags.tagGroupSetIndexedTagAsNumber(3,tPixel_us)//acquire frames
		setupTags.tagGroupSetIndexedTagAsNumber(4,syncLines)//quality (0:fast; 1: high)
		setupTags.tagGroupSetIndexedTagAsNumber(5,JEOL_active)//proc frames
		setupTags.tagGroupSetIndexedTagAsNumber(6,JEOL_byteDepth)//processing mode
		setupTags.tagGroupSetIndexedTagAsNumber(7,BFDF_active)//processing mode
		setupTags.tagGroupSetIndexedTagAsNumber(8,BFDF_byteDepth)//diff streak correction		
		setupTags.tagGroupSetIndexedTagAsNumber(9,HAADF_active)//diff streak correction		
		setupTags.tagGroupSetIndexedTagAsNumber(10,HAADF_byteDepth)//processing mode
		setupTags.tagGroupSetIndexedTagAsNumber(11,nExp)//processing mode
		return self
	}

	object getSetup(object self)
	{
		string sSetup;self.getData("setup",sSetup)
		TagGroup setupTags;self.getData(sSetup,setupTags)
		
		number sizeX;setupTags.tagGroupGetIndexedTagAsNumber(0,sizeX)//exposure time
		number sizeY;setupTags.tagGroupGetIndexedTagAsNumber(1,sizeY)//binning
		number rotDeg;setupTags.tagGroupGetIndexedTagAsNumber(2,rotDeg)//extend range
		number tPixel_us;setupTags.tagGroupGetIndexedTagAsNumber(3,tPixel_us)//acquire frames
		number syncLines;setupTags.tagGroupGetIndexedTagAsNumber(4,syncLines)//quality (0:fast; 1: high)
		number JEOL_active;setupTags.tagGroupGetIndexedTagAsNumber(5,JEOL_active)//proc frames
		number JEOL_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(6,JEOL_byteDepth)//processing mode
		number BFDF_active;setupTags.tagGroupGetIndexedTagAsNumber(7,BFDF_active)//diff streak correction		
		number BFDF_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(8,BFDF_byteDepth)//processing mode
		number HAADF_active;setupTags.tagGroupGetIndexedTagAsNumber(9,HAADF_active)//diff streak correction		
		number HAADF_byteDepth;setupTags.tagGroupGetIndexedTagAsNumber(10,HAADF_byteDepth)//processing mode
		number nExp;setupTags.tagGroupGetIndexedTagAsNumber(11,nExp)//# of exposures

		self.setData("image width (pix) (display)",sizeX)
		self.setData("image height (pix) (display)",sizeY)
		self.setData("pixel time (us) (display)",tPixel_us)
		self.setData("line sync (display)",syncLines)
		self.setData("rotation (°) (display)",rotDeg)
		self.setData("JEOL active (display)",JEOL_active)
		self.setData("BF/DF active (display)",BFDF_active)
		self.setData("HAADF active (display)",HAADF_active)
		self.setData("JEOL byte depth (display)",JEOL_byteDepth)
		self.setData("BF/DF byte depth (display)",BFDF_byteDepth)
		self.setData("HAADF byte depth (display)",HAADF_byteDepth)
		self.setData("number of exposures (display)",nExp)

		return self
	}

	TagGroup createDefaultSetupTags(object self)
	{
		number sumFrames=0
		number nSumFrames=1
	
		number nSetup=0
		string sSetup;self.getData("setup",sSetup)
		if(sSetup=="view")nSetup=0
		if(sSetup=="record")nSetup=2
		
		TagGroup paramsTag;self.readParamsTag(nSetup,paramsTag)
		number sizeX;paramsTag.tagGroupGetTagAsNumber("Image Width",sizeX)
		number sizeY;paramsTag.tagGroupGetTagAsNumber("Image Height",sizeY)
		number rotDeg;paramsTag.tagGroupGetTagAsNumber("Rotation",rotDeg)//deg
		number tPixel_us;paramsTag.tagGroupGetTagAsNumber("Sample Time",tPixel_us)//us
		number syncLines;paramsTag.tagGroupGetTagAsNumber("Synchronize Lines",syncLines)//bool

		number JEOL_active;paramsTag.tagGroupGetTagAsNumber("JEOL active",JEOL_active)//bool
		number JEOL_byteDepth;paramsTag.tagGroupGetTagAsNumber("JEOL byte depth",JEOL_byteDepth)//

		number BFDF_active;paramsTag.tagGroupGetTagAsNumber("BF/DF active",BFDF_active)//bool
		number BFDF_byteDepth;paramsTag.tagGroupGetTagAsNumber("BF/DF byte depth",BFDF_byteDepth)//

		number HAADF_active;paramsTag.tagGroupGetTagAsNumber("HAADF active",HAADF_active)//bool
		number HAADF_byteDepth;paramsTag.tagGroupGetTagAsNumber("HAADF byte depth",HAADF_byteDepth)//
	
		number nExp;paramsTag.tagGroupGetTagAsNumber("number of exposures (display)",nExp)//

		TagGroup setupTags=newTagList()
		setupTags.tagGroupInsertTagAsNumber(infinity(),sizeX)//pix
		setupTags.tagGroupInsertTagAsNumber(infinity(),sizeY)//pix
		setupTags.tagGroupInsertTagAsNumber(infinity(),rotDeg)//pix
		setupTags.tagGroupInsertTagAsNumber(infinity(),tPixel_us)//pixel time (us)
		setupTags.tagGroupInsertTagAsNumber(infinity(),syncLines)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),JEOL_active)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),JEOL_byteDepth)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),BFDF_active)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),BFDF_byteDepth)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),HAADF_active)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),HAADF_byteDepth)//
		setupTags.tagGroupInsertTagAsNumber(infinity(),nExp)//
		return setupTags
	}
	
	object readSetup(object self)
	{
		self.readParams()
		self.getSetup()
		return self
	}
	
	object writeSetup(object self)
	{
		self.setSetup()
		self.writeParams()
		return self
	}

	number beginAcquire(object self,number priority,number resolve,object src,TagGroup tags,object objs,number show)
	{
		if((priority<1)&&(self.isRunning()))return 0
		msg.setTags(tags);msg.setObjs(objs)
		msg.setImageSet(null)
		return self.begin(self.init(src,self,msg,resolve),priority)
	}
	
	number endAcquire(object self,object &imgSet)
	{	
		//result("ending acq\n")
		object msg
		number status=self.receiveMessageOnSignal(msg)
		if(status)
			msg.getImageSet(imgSet)
		return status
	}

	number endAcquire(object self)
	{
		object imgSet
		return self.endAcquire(imgSet)
	}
		
	number acquire(object self,object &imgSet,object src,TagGroup tags,object objs,number show)
	{
		number status
		fillTag(tags,"signal index",0,0)
		fillTag(tags,"show",show,1)
		if(status=self.beginAcquire(1,0,src,tags,objs,show))
			status=self.endAcquire(imgSet)
		return status
	}

	void acquirePressed(object self)
	{
		setTerminate(0)
		if(self.isRunning())self.kill()
		else self.beginAcquire(0,1,null,null,null,1)
		self.write()
		//result("started acq\n")
	}
		
	void viewPressed(object self)
	{
		DSInvokeButton(1)
	}
		
	void setValues(object self)
	{
		self.setPopup("setup")
		self.setNumber("image width (pix) (display)")
		self.setNumber("image height (pix) (display)")
		self.setNumber("rotation (°) (display)")
		self.setNumber("pixel time (us) (display)")
		self.setNumber("number of exposures (display)")
		self.setCheckBox("line sync (display)")
		self.setCheckBox("JEOL active (display)")
		self.setCheckBox("BF/DF active (display)")
		self.setCheckBox("HAADF active (display)")
		self.setPopup("JEOL byte depth (display)")
		self.setPopup("BF/DF byte depth (display)")
		self.setPopup("HAADF byte depth (display)")
	}

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		if(sIdent=="setup")
		{
			self.getSetup()
		}
		else
		{
			self.setSetup()
		}
		self.setValues()
	}
													
	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val)
		self.setSetup()
		self.setValues()
		//self.write()
	}
	
	void numberChanged(object self,string sIdent,number val)
	{
		number noError=1
		if(sIdent=="number of exposures (display)")
		{
			if(val<1)noError=0
		}
		if(noError) self.super.numberChanged(sIdent,val)
		self.setSetup()
		self.setValues();
		//if(noError) self.write()			
	}

	object appendSetupList(object self,TagGroup &list)
	{
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Search","search"))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Focus","focus"))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Record","record"))
		return self
	}

	object appendSignalList(object self,TagGroup &list)
	{
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("JEOL",1))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("BF/DF",0))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("HAADF",2))
		return self
	}

	object appendByteList(object self,TagGroup &list)
	{
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1 byte",1))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("2 byte",2))
		list.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("4 byte",4))
		return self
	}
//
	object init(object self)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)

		OpenandSetProgressWindow("","","")	

		number n
			
		TagGroup setupList=newTagList()
		self.appendSetupList(setupList)
		TagGroup setupTag=self.createPopup("setup",setupList)

		dlgItems.dlgAddElement(setupTag.dlgexternalpadding(5,0).dlgAnchor("West"))

//
		TagGroup sizeX_tag=self.createNumber("image width (pix) (display)","Width:",8).dlgAnchor("East")
		TagGroup sizeY_tag=self.createNumber("image height (pix) (display)","Height:",8).dlgAnchor("East")
		dlgItems.dlgAddElement(dlgGroupItems(sizeX_tag,sizeY_tag).dlgTableLayout(1,2,0).dlgAnchor("West").dlgexternalpadding(5,0))

		TagGroup rotTag=self.createNumber("rotation (°) (display)","Rotation (°):",8).dlgAnchor("East")
		TagGroup nExpTag=self.createNumber("number of exposures (display)","# of exposures:",5)
		dlgItems.dlgAddElement(dlgGroupItems(rotTag,nExpTag).dlgTableLayout(2,1,0).dlgAnchor("West").dlgexternalpadding(5,0))
		
		//TagGroup rotDegTag=self.createNumber("rotation","Rotation (°):",,8)

		TagGroup tPixelTag=self.createNumber("pixel time (us) (display)","Pixel time (us):",8)
		TagGroup syncTag=self.createCheckBox("line sync (display)","Line sync")
			dlgItems.dlgAddElement(dlgGroupItems(tPixelTag,syncTag).dlgTableLayout(2,1,0).dlgAnchor("West").dlgexternalpadding(5,0))

		TagGroup byteList=newTagList()
		self.appendByteList(byteList)
		
		TagGroup JEOL_tag=self.createCheckBox("JEOL active (display)","JEOL")
		TagGroup JEOL_byteTag=self.createPopup("JEOL byte depth (display)",byteList)
		
		TagGroup BFDF_tag=self.createCheckBox("BF/DF active (display)","BF/DF")
		TagGroup BFDF_byteTag=self.createPopup("BF/DF byte depth (display)",byteList)
		
		TagGroup HAADF_tag=self.createCheckBox("HAADF active (display)","HAADF")
		TagGroup HAADF_byteTag=self.createPopup("HAADF byte depth (display)",byteList)
		
		TagGroup signalsTag=dlgGroupItems(JEOL_tag,BFDF_tag,HAADF_tag).dlgTableLayout(1,3,0).dlgAnchor("West").dlgexternalpadding(5,0)
		TagGroup bytesTag=dlgGroupItems(JEOL_byteTag,BFDF_byteTag,HAADF_byteTag).dlgTableLayout(1,3,0).dlgAnchor("West").dlgexternalpadding(5,0)		
		
		dlgItems.dlgAddElement(dlgGroupItems(signalsTag,bytesTag).dlgTableLayout(2,1,0).dlgAnchor("West").dlgexternalpadding(5,0))
		
				
		//TagGroup specsTag=self.createStringLabel("specs","",50)
		//dlgItems.dlgAddElement(specsTag).dlgInternalPadding(0,5).dlgExternalPadding(5,0).DLGAnchor("East")

		TagGroup viewTag=self.createButton("view","View","viewPressed")	
		TagGroup recordTag=self.createButton("acquire","Acquire","acquirePressed")	
		TagGroup helpTag=self.createButton("help","?","helpPressed")
		dlgItems.dlgAddElement(dlgGroupItems(viewTag,recordTag,helpTag).dlgTableLayout(3,1,0).dlgExternalPadding(0,5).dlgAnchor("West"))

		dlgTags.dlgTableLayout(1,7,0);
		
		TagGroup position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);
			
		self.super.init(dlgTags)
		return self
	}	
				
	//
	SmartAcq_STEM(object self)
	{
		self.setGroup(SMARTACQSTEM_sGroup)
		self.setName(SMARTACQSTEM_sName)
		self.setTitle(SMARTACQSTEM_sTitle)		
		self.setEcho(SMARTACQSTEM_echo)			
				
		msg=alloc(SmartAcq_STEM_msg)
	}

	object load(object self)
	{
		self.addData("online",SMARTACQSTEM_online)
		self.addData("help filename",SMARTACQSTEM_sHelpFilename)
		self.addData("setup","record")
		self.addData("search",newTagList())
		self.addData("focus",newTagList())
		self.addData("record",newTagList())

		//These will be changed by setup
		self.addData("not saved","image width (pix) (display)",SMARTACQSTEM_imageWidth)
		self.addData("not saved","image height (pix) (display)",SMARTACQSTEM_imageHeight)
		self.addData("not saved","rotation (°) (display)",SMARTACQSTEM_rotation_deg)
		self.addData("not saved","pixel time (us) (display)",SMARTACQSTEM_pixelTime_us)
		self.addData("not saved","line sync (display)",SMARTACQSTEM_lineSync)
		self.addData("not saved","number of exposures (display)",SMARTACQSTEM_nExp)
		
		self.addData("not saved","JEOL active (display)",0)
		self.addData("not saved","JEOL byte depth (display)",1)
		
		self.addData("not saved","BF/DF active (display)",0)
		self.addData("not saved","BF/DF byte depth (display)",1)

		self.addData("not saved","HAADF active (display)",0)
		self.addData("not saved","HAADF byte depth (display)",1)
		
						//self.setEcho(1)
		object res=self.super.load()

		self.getSetup()
		//TagGroup tags=self.getTags()
		return res
	}
	
	~SmartAcq_STEM(object self)
	{
		self.unload()
	}
}

void showSmartAcq_STEM()
{
	object obj=alloc(SmartAcq_STEM).load()
	obj.init().display()
	obj.setValues()
}

if(SMARTACQSTEM_display)showSmartAcq_STEM()
