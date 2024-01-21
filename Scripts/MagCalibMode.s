
string MAGCALIBMODE_sGroup="MAGCALIBMODE"
string MAGCALIBMODE_sName="MAGCalibMode"
string MAGCALIBMODE_sTitle="MAG Calibration Mode"
number MAGCALIBMODE_echo=0

//
class MAGCALIBMODE:JEM_Widget
{
	void setValues(object self)
	{
		self.setPopup("SA position")		
	}
		
	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)	
		self.write()	
	}

	object init(object self)
	{

		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		
		tagGroup modeList=NewTagList()
		modeList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("out","SA out"))
		modeList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("in","SA in"))

		tagGroup modeTag=self.createPopup("SA position","Diffraction aperture position",modeList)
		dlgItems.dlgAddElement(modeTag).dlgExternalPadding(5,0).dlgAnchor("East")
		
		dlgTags.dlgTableLayout(1,1,0)
		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.dlgSide( "Right" );
		dlgTags.dlgPosition(position);

		self.super.init(dlgTags)
		return self
	}
	
	MagCalibMode(object self)
	{
		self.setGroup(MAGCALIBMODE_sGroup)
		self.setName(MAGCALIBMODE_sName)
		self.setTitle(MAGCALIBMODE_sTitle)
		self.setEcho(MAGCALIBMODE_echo)
		self.read()
	}

	object load(object self)
	{
		self.addData("SA position","SA out")
		return self.super.load()
	}

	~MagCalibMode(object self)
	{
		self.unload()
	}

}
