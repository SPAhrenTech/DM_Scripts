//Allows users to store/restore exposure times
string EXPOSURE_sGroup="EXPOSURE"
string EXPOSURE_sName="Exposure"
string EXPOSURE_sTitle="Exposure"
number EXPOSURE_echo=0
number EXPOSURE_display=0

//
class Exposure:JEM_Widget
{	
	number online	

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		number tExp
		self.getData("exposure time (s)",tExp)
		if(tExp>0)
		{
			object camera=CM_GetCurrentCamera();
			object cameraParams=CM_GetCameraAcquisitionParameterSet(camera,"Imaging","Acquire","Record",0)
			CM_SetExposure(cameraParams,tExp)
			CM_SaveCameraAcquisitionParameterSet(camera,cameraParams);
			//result("setting: "+tExp+"\n")
		}
		self.setData("exposure time (s)",-1)
		self.setPopup("exposure time (s)")
	}
													
	//
	Exposure(object self)
	{
		self.setGroup(EXPOSURE_sGroup)
		self.setName(EXPOSURE_sName)
		self.setTitle(EXPOSURE_sTitle)
		self.setEcho(EXPOSURE_echo)		
	}	

	//
	object load(object self)
	{
		self.addData("exposure time list (s)",newTagGroup())
		self.addData("not saved","exposure time (s)",-1)
		return self.super.load()
	}	

	~Exposure(object self)
	{
		self.super.unload()
	}	

	//
	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)	
	
		TagGroup popupList=newTagList()
		popupList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Exposure (s)",-1))

		TagGroup expList;self.getData("exposure time list (s)",expList)
		number nExp=expList.tagGroupCountTags()
		number i
		for(i=0;i<nExp;i++)
		{
			number tExp;expList.tagGroupGetIndexedTagAsNumber(i,tExp)
			popupList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup(format(tExp,"%1g"),tExp))
		}
		TagGroup expPopup=self.createPopup("exposure time (s)",popupList).dlgSide("West").dlgExternalPadding(15,0)

		dlgItems.dlgAddElement(expPopup)	
		dlgTags.dlgTableLayout(2,1,0)
		
		self.super.init(dlgTags)
		return self
	}
}

void showExposure()
{
	alloc(Exposure).load().init().display()
}	

if(EXPOSURE_display)showExposure()


