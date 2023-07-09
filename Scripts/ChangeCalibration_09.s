//change calibration
number CHANGECALIBRATION_display=0
string CHANGECALIBRATION_sGroup="CHANGECALIBRATION"
string CHANGECALIBRATION_sName="ChangeCalibration"
string CHANGECALIBRATION_sTitle="Change Calibration"
number CHANGECALIBRATION_echo=0

string CHANGECALIBRATION_sDlgTitle="Calibration"

//
class ChangeCalibration:JEM_Widget
{
	//number prevLineLen
	//string sPrevUnits
	ChangeCalibration(object self)
	{
		self.setGroup(CHANGECALIBRATION_sGroup)
		self.setName(CHANGECALIBRATION_sName)
		self.setTitle(CHANGECALIBRATION_sTitle)
	}
	
	object load(object self)
	{
		self.addData("units","nm")
		self.addData("length (pix)",100)
		self.addData("length",100)
		self.addData("line selected",0)
		self.addData("previous units","")
		self.addData("scale",1)
		return self.super.load()
	}

	~ChangeCalibration(object self)
	{
	}
		
	void setValues(object self)
	{
		number isLineAnnot;self.getData("line selected",isLineAnnot)
		if(isLineAnnot)self.setNumber("length")		
		self.setPopup("units")		
	}

	void unitsChanged(object self)
	{
		string sPrevUnits,sUnits
		self.getData("previous units",sPrevUnits)
		self.getData("units",sUnits)
		number scaleXY;self.getData("scale",scaleXY)
		
		number isLineAnnot;self.getData("line selected",isLineAnnot)
		number lineLen;self.getData("length",lineLen)		

		number oldFac=1,fac=1
		number change=0
		if((sPrevUnits=="Å")||(sPrevUnits=="nm")||(sPrevUnits=="µm"))
		{
			if(sPrevUnits=="Å")oldFac=10
			if(sPrevUnits=="nm")oldFac=1
			if(sPrevUnits=="µm")oldFac=0.001
			
			if(sUnits=="Å"){fac=10;change=1;}
			if(sUnits=="nm"){fac=1;change=1;}
			if(sUnits=="µm"){fac=0.001;change=1;}
			
			change=1		
			if(isLineAnnot)self.setNumber("length")
		}
		
		if((sPrevUnits=="1/Å")||(sPrevUnits=="1/nm")||(sPrevUnits=="1/µm")||(sPrevUnits=="mrad"))
		{
			if(sPrevUnits=="1/Å")oldFac=0.1
			if(sPrevUnits=="1/nm")oldFac=1
			if(sPrevUnits=="1/µm")oldFac=10000
			if(sPrevUnits=="mrad")
			{
				tagGroup tags=self.getTags()//.TagGroupOpenBrowserWindow(0)
				tagGroup data
				number E_KeV,k
				if(self.getData("E (KeV)",E_KeV))
				{
					k=1/get_wvln(E_KeV)					
					oldFac=1000/k
				}
			}

			if(sUnits=="1/Å"){fac=0.1;change=1;}
			if(sUnits=="1/nm"){fac=1;change=1;}
			if(sUnits=="1/µm"){fac=1000;change=1;}
			if(sUnits=="mrad")
			{
				number E_KeV,k
				if(self.getData("E (KeV)",E_KeV))
				{
					k=1/get_wvln(E_KeV)
					fac=1000/k
				change=1;
				}
			}
		}
		result("--------------\n")
		if(change)
		{
			if(isLineAnnot)
			{
				lineLen*=fac/oldFac			
				self.setData("length",lineLen)
				result(lineLen+" "+sUnits+"\n")
			}
			self.setData("scale",scaleXY*fac/oldFac)
			self.setData("units",sUnits)
			self.setValues()

			result(fac+", "+oldFac+", ")
			result(sUnits+", "+sPrevUnits+"\n")
		}
		//sPrevUnits=sUnits
	}
	
	
	void numberChanged(object self,string sIdent,number val)
	{
		if(sIdent=="length")
		{
			number lineLenPix;self.getData("length (pix)",lineLenPix)
			number scaleXY=val/lineLenPix
			self.setData("scale",scaleXY)
			self.super.numberChanged(sIdent,val)
			self.setValues();
		}
	}

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		
		if(sIdent=="units")
		{
			string sPrevUnits
			self.getData("units",sPrevUnits)
			self.setData("previous units",sPrevUnits)
			self.super.popupChanged(sIdent,itemTag)
			self.unitsChanged()
			
		}
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		
		number isLineAnnot;self.getData("line selected",isLineAnnot)
		string sPrevUnits;self.getData("previous units",sPrevUnits)
		self.setData("units",sPrevUnits)
		if(isLineAnnot)
		{
			number lineLen;self.getData("length",lineLen)
			tagGroup lenTag=self.createNumber("length","Length",12,4)
			dlgItems.dlgAddElement(lenTag).dlgExternalPadding(5,0).dlgAnchor("East")
		}
		
		tagGroup unitsList=newTagList()
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Å","Å"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("nm","nm"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("µm","µm"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1/Å","1/Å"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1/nm","1/nm"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1/µm","1/µm"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mrad","mrad"))
		unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("pix","pix"))
		//unitsList.TagGroupOpenBrowserWindow(0)

		number iSel=0
		number nAnn=unitsList.tagGroupCountTags()
		number foundUnits=0
		
		number i
		for(i=0;i<nAnn;i++)
		{
			tagGroup tag
			unitsList.tagGroupGetIndexedTagAsTagGroup(i,tag)
			string sUnits;tag.tagGroupGetTagAsString("Value",sUnits)
			if(sUnits==sPrevUnits){foundUnits=1;iSel=i;break;}
		
		}
			
		if(!foundUnits)
		{
			unitsList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup(sPrevUnits,sPrevUnits))
		}

		tagGroup unitsTag=self.createPopup("units","Units",unitsList)

		dlgItems.dlgAddElement(unitsTag).dlgExternalPadding(5,0).dlgAnchor("East")
		dlgTags.dlgTableLayout(1,2,0)
		self.super.init(dlgTags)

		return self
	}
}

void showChangeCalibration()
{
	image img
	if(!GetFrontImage(img))
	{
		OKDialog("You must have an image on which to operate!")
		exit(0)
	}

	object changeCal=alloc(ChangeCalibration).load()

	//scale
	number scaleX,scaleY
	getScale(img,scaleX,scaleY)
	number scaleXY=(scaleX+scaleY)/2
	changeCal.setData("scale",scaleXY)

	string sUnits
	sUnits=getUnitString(img)
	if(sUnits=="")sUnits="pix"
	changeCal.setData("previous units",sUnits)

	//line annotation
	number i=0,annID
	number islineAnnot=0
	while((i<CountAnnotations(img))&&(!islineAnnot))
	{
		annID=GetNthAnnotationID(img,i)
		if(AnnotationType(img,annID)==2)
			if(IsAnnotationSelected(img,annID))
				islineAnnot=1	
		i=i+1
	}
		
	changeCal.setData("line selected",islineAnnot)
	if(islineAnnot)
	{
		number sx,sy,ex,ey
		getAnnotationRect(img,annID,sx,sy,ex,ey)
		number lineLenPix=((sx-ex)**2+(sy-ey)**2)**0.5//pix
		changeCal.setData("length (pix)",lineLenPix)
		changeCal.setData("length",lineLenPix*scaleXY)
	}

	changeCal.init()
	number E_eV
	if(getNumberNote(img,"Microscope Info:Voltage",E_eV))
		changeCal.addData("temp","E (KeV)",E_eV/1000)
		
	if(changeCal.pose())
	{
		changeCal.getData("units",sUnits)
		changeCal.getData("scale",scaleXY)
		
		setScale(img,scaleXY,scaleXY)
		setUnitString(img,sUnits)
	}
}

if(CHANGECALIBRATION_display)showChangeCalibration()
