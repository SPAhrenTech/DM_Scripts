//Camera Calibration"
number CAMERACALIB_online=1
number CAMERACALIB_echo=0
number CAMERACALIB_doDisplay=0
string CAMERACALIB_MAGname="MAG_table"
string CAMERACALIB_DIFFname="DIFF_table"

string CAMERACALIB_sGroup="CAMERACALIB"
string CAMERACALIB_sName="CameraCalib"

interface CameraCalibProto
{
}

//
class CameraCalib:JEM_Object
{
	TagGroup tag
	
	number getEntry(object self,TagGroup calTable,number magVal)
	{
		number nCal=calTable.TagGroupCountTags()
		number magSmall=0,magBig=1e12
		number facSmall=0,facBig=1e12
		number noSmall=1,noBig=1
		number i
		for(i=0;i<nCal;++i)
		{
			TagGroup val_tag
			calTable.tagGroupGetIndexedTagAsTagGroup(i,val_tag)
			number mag,fac
			val_tag.tagGroupGetTagAsNumber("ref",mag)
			val_tag.tagGroupGetTagAsNumber("fac",fac)
			if((mag<=magVal)&&(mag>magSmall))
			{
				magSmall=mag
				facSmall=fac
				noSmall=0
			}

			if((mag>magVal)&&(mag<magBig))
			{
				magBig=mag
				facBig=fac
				noBig=0
			}
		}
		number fac
		if(nosmall)fac=facBig
		if(noBig)fac=facSmall
		if((!noSmall)&&(!noBig))
			fac=((magBig-magVal)*facSmall+(magVal-magSmall)*facBig)/(magBig-magSmall)
		return fac
	}

	void readMagFac(object self,string sFilename,number refVal,number &fac)
	{
		string sPath=getApplicationDirectory("preference",0)
		sPath=pathConcatenate(sPath,"JEM_files")
		sPath=pathConcatenate(sPath,"Calibration_files")
		sPath=pathConcatenate(sPath,sFilename+".txt")
		number echo=CAMERACALIB_echo
		TagGroup tg=newTagList()
		if(echo)result ("Reading table...\n")
		number nfile=openFileForReading(sPath)
		string s
		number first=1
		while(readFileLine(nfile,0,s))
		{	
			if(first){first=0;continue;}
			number ref;getEntryNumber(s,ref,",",0)
			number fac;getEntryNumber(s,fac,",",1)
			TagGroup val_tag=NewTagGroup()
			
			number index
			index=val_tag.tagGroupCreateNewLabeledTag("ref")
			val_tag.tagGroupSetIndexedTagAsNumber(index,ref)

			index=val_tag.tagGroupCreateNewLabeledTag("fac")
			val_tag.tagGroupSetIndexedTagAsNumber(index,fac)
			
			tg.tagGroupInsertTagAsTagGroup(infinity(),val_tag)
		}
		closeFile(nfile)
		//tg.TagGroupOpenBrowserWindow(0)
		fac=self.getEntry(tg,refVal)
	}
	
	//nm or µm (MAG) or 1/nm (DIFF) per upix
	object getCalInfo(object self,string &sMode,number &EKeV,number &mag_or_L,string &sUnit)
	{
		number mode;JEM_getFunctionMode(mode,sMode);
		string sString;JEM_getMagValue(mag_or_L,sUnit,sString)			
		number EeV;JEM_getHTValue(EeV)
		EKeV=EeV/1000
		return self
	}
		
	//Generates  taggroup with calibration info
	object collect(object self)
	{
		tag.TagGroupDeleteAllTags()

		string sMode,sMagUnit;
		number EKeV,mag_or_L
		self.getCalInfo(sMode,EKeV,mag_or_L,sMagUnit);

		number index
		index=tag.tagGroupCreateNewLabeledTag("E (KeV)")
		tag.TagGroupSetIndexedTagAsNumber(index,EKeV)		

		index=tag.tagGroupCreateNewLabeledTag("Mode")
		tag.tagGroupSetIndexedTagAsString(index,sMode)
			
		number Pum=9,Pmm=Pum/1000
		number upixSize,altUpixSize
		string sUnits,sAltUnits
		if(sMode=="DIFF")
		{
			number lambd_nm=get_wvln(EKeV)
			number L0_mm=mag_or_L
			number camconst0_nm_mm=lambd_nm*L0_mm
			number diff_fac=1.467
			self.readMagFac(CAMERACALIB_DIFFname,camconst0_nm_mm,diff_fac)
			number camconst1_nm_mm=diff_fac*camconst0_nm_mm
			upixSize=Pmm/camconst1_nm_mm
			sUnits="1/nm"

			altUpixSize=1e3*Pmm*lambd_nm/camconst1_nm_mm//mrad
			sAltUnits="mrad"

			index=tag.TagGroupCreateNewLabeledTag("Indicated camera length (mm)")
			tag.TagGroupSetIndexedTagAsNumber(index,L0_mm)

			index=tag.TagGroupCreateNewLabeledTag("Actual camera length (mm)")
			tag.TagGroupSetIndexedTagAsNumber(index,diff_fac*L0_mm)

			index=tag.TagGroupCreateNewLabeledTag("Scale factor")
			tag.TagGroupSetIndexedTagAsNumber(index,diff_fac)

			index=tag.TagGroupCreateNewLabeledTag("Actual camera constant (nm.mm)")
			tag.TagGroupSetIndexedTagAsNumber(index,camconst1_nm_mm)
		}
		else
		{
			number M0_Kx=mag_or_L/1000
			number mag_fac=1.393
			self.readMagFac(CAMERACALIB_MAGname,M0_Kx,mag_fac)
			number M1_Kx=mag_fac*M0_Kx

			altUpixSize=Pum/M1_Kx//nm
			sAltUnits="nm"


			if(M0_Kx<15)
			{
				upixSize=altUpixSize/1000//µm
				sUnits="µm"
			}
			else
			{
				upixSize=altUpixSize//nm
				sUnits="nm"
			}

			index=tag.TagGroupCreateNewLabeledTag("Indicated magnification (Kx)")
			tag.TagGroupSetIndexedTagAsNumber(index,M0_Kx)

			index=tag.TagGroupCreateNewLabeledTag("Actual magnification (Kx)")
			tag.TagGroupSetIndexedTagAsNumber(index,M1_Kx)

			index=tag.TagGroupCreateNewLabeledTag("Scale factor")
			tag.TagGroupSetIndexedTagAsNumber(index,mag_fac)
		}

		//nm or µm (MAG), 1/nm (DIFF)
		index=tag.TagGroupCreateNewLabeledTag("Unbinned pixel size")
		tag.TagGroupSetIndexedTagAsNumber(index,upixSize)

		index=tag.TagGroupCreateNewLabeledTag("Units")
		tag.TagGroupSetIndexedTagAsString(index,sUnits)

		//nm (MAG), mrad(DIFF)
		index=tag.TagGroupCreateNewLabeledTag("Alternative unbinned pixel size")
		tag.TagGroupSetIndexedTagAsNumber(index,altUpixSize)

		index=tag.TagGroupCreateNewLabeledTag("Alternative units")
		tag.TagGroupSetIndexedTagAsString(index,sAltUnits)

		return self
	}

	CameraCalib(object self)
	{
		self.setGroup(CAMERACALIB_sGroup)
		self.setName(CAMERACALIB_sName);
		tag=newTagGroup();
		self.collect();
	}

	//Generates  taggroup with calibration info
	TagGroup getTags(object self)
	{
		return tag.tagGroupClone()
	}
}


//external
void CameraCalib_getUpixSize(number &upixSize,string &sUnit)
{
	TagGroup calTag=alloc(CAMERACALIB).getTags()
	calTag.tagGroupGetTagAsNumber("Unbinned pixel size",upixSize)
	calTag.tagGroupGetTagAsString("Units",sUnit)	
}

void CameraCalib_getCal(TagGroup &calTag)
{
	calTag=alloc(CAMERACALIB).getTags()
}
