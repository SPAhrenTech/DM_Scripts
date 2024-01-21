//Loading/saving Alignment for JEOL JEM-2100
module com.gatan.dm.jemalignfiles
uses com.gatan.dm.jemlib
uses com.gatan.dm.jemprefs
uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog

number JEMALIGNFILES_doDisplay=0
string JEMALIGNFILES_dlgTitle="Alignment"
number JEMALIGNFILES_online=1
number JEMALIGNFILES_echo=0

class JEM_AlignFiles:JEM_Dialog
{
	object makeDataSet(object self)
	{
		object dataSet=alloc(JEM_Data)
		dataSet.setGroup("")//Owner will be omitted in alignment file
		dataSet.addData("Gun1X",0)
		dataSet.addData("Gun1Y",0)
		dataSet.addData("Gun2X",0)
		dataSet.addData("Gun2Y",0)
		dataSet.addData("CLA1X",0)
		dataSet.addData("CLA1Y",0)
		dataSet.addData("CLA2X",0)
		dataSet.addData("CLA2Y",0)
		dataSet.addData("IS1X",0)
		dataSet.addData("IS1Y",0)
		dataSet.addData("IS2X",0)
		dataSet.addData("IS2Y",0)
		dataSet.addData("PLAX",0)
		dataSet.addData("PLAY",0)
		dataSet.addData("ShiftBalX",0)
		dataSet.addData("ShiftBalY",0)
		dataSet.addData("TiltBalX",0)
		dataSet.addData("TiltBalY",0)
		dataSet.addData("AngleBalX",0)
		dataSet.addData("AngleBalY",0)
		dataSet.addData("CondStigX",0)
		dataSet.addData("CondStigY",0)
		dataSet.addData("ObjStigX",0)
		dataSet.addData("ObjStigY",0)
		dataSet.addData("IntStigX",0)
		dataSet.addData("IntStigY",0)
		return dataSet
	}
	
	//
	object load(object self,string sAlignPath)
	{
		//Get prefs file (input)
		openandSetProgressWindow("align file...","","")	
		object dataSet=self.makeDataSet() 
		dataSet.setPath(sAlignPath)
		dataSet.setEcho(JEMALIGNFILES_echo)
		dataSet.read()

		number n,nX,nY
		self.getData("load Gun1",n)
		if(n)
		{	
			dataSet.getData("Gun1X",nX)
			dataSet.getData("Gun1Y",nY)
			JEM_setGunA1(nX,nY)
		}

		self.getData("load Gun2",n)
		if(n)
		{
			dataSet.getData("Gun2X",nX)
			dataSet.getData("Gun2Y",nY)
			JEM_setGunA2(nX,nY)
		}

		self.getData("load CLA1",n)
		if(n)
		{
			dataSet.getData("CLA1X",nX)
			dataSet.getData("CLA1Y",nY)
			JEM_setCLA1(nX,nY)
		}

		self.getData("load CLA2",n)
		if(n)
		{
			dataSet.getData("CLA2X",nX)
			dataSet.getData("CLA2Y",nY)
			JEM_setCLA2(nX,nY)
		}

		self.getData("load IS1",n)
		if(n)
		{
			dataSet.getData("IS1X",nX)
			dataSet.getData("IS1Y",nY)
			JEM_setIS1(nX,nY)
		}

		self.getData("load IS2",n)
		if(n)
		{
			dataSet.getData("IS2X",nX)
			dataSet.getData("IS2Y",nY)
			JEM_setIS2(nX,nY)
		}

		self.getData("load PLA",n)
		if(n)
		{
			dataSet.getData("PLAX",nX)
			dataSet.getData("PLAY",nY)
			JEM_setPLA(nX,nY)
		}

		self.getData("load ShiftBal",n)
		if(n)
		{
			dataSet.getData("ShiftBalX",nX)
			dataSet.getData("ShiftBalY",nY)
			JEM_setShifBal(nX,nY)
		}

		self.getData("load TiltBal",n)
		if(n)
		{
			dataSet.getData("TiltBalX",nX)
			dataSet.getData("TiltBalY",nY)
			JEM_setTiltBal(nX,nY)
		}

		self.getData("load AngleBal",n)
		if(n)
		{
			dataSet.getData("AngleBalX",nX)
			dataSet.getData("AngleBalY",nY)
			JEM_setAngBal(nX,nY)
		}

		self.getData("load CondStig",n)
		if(n)
		{
			dataSet.getData("CondStigX",nX)
			dataSet.getData("CondStigY",nY)
			JEM_setCLs(nX,nY)
		}
			
		self.getData("load ObjStig",n)
		if(n)
		{
			dataSet.getData("ObjStigX",nX)
			dataSet.getData("ObjStigY",nY)
			JEM_setOLs(nX,nY)
		}

		self.getData("load IntStig",n)
		if(n)
		{
			dataSet.getData("IntStigX",nX)
			dataSet.getData("IntStigY",nY)
			JEM_setILs(nX,nY)
		}
		OpenandSetProgressWindow("","","")	
		if(JEMALIGNFILES_echo)result("alignment loaded\n")
		return self
	}

	//
	object save(object self,string sAlignPath)
	{
		if(doesFileExist(sAlignPath))
			deletefile(sAlignPath)
		createFile(sAlignPath)
		//number nfile=OpenFileForReadingAndWriting(sAlign_path)

		object dataSet=self.makeDataSet() 
		dataSet.setPath(sAlignPath)

		number nX,nY
		JEM_getGunA1(nX,nY)
		dataSet.setData("Gun1X",nX)
		dataSet.setData("Gun1Y",nY)
					
		JEM_getGunA2(nX,nY)
		dataSet.setData("Gun2X",nX)
		dataSet.setData("Gun2Y",nY)
			
		JEM_getCLA1(nX,nY)
		dataSet.setData("CLA1X",nX)
		dataSet.setData("CLA1Y",nY)
			
		JEM_getCLA2(nX,nY)
		dataSet.setData("CLA2X",nX)
		dataSet.setData("CLA2Y",nY)

		JEM_getIS1(nX,nY)
		dataSet.setData("IS1X",nX)
		dataSet.setData("IS1Y",nY)

		JEM_getIS2(nX,nY)
		dataSet.setData("IS2X",nX)
		dataSet.setData("IS2Y",nY)

		JEM_getPLA(nX,nY)
		dataSet.setData("PLAX",nX)
		dataSet.setData("PLAY",nY)

		JEM_getShifBal(nX,nY)
		dataSet.setData("ShiftBalX",nX)
		dataSet.setData("ShiftBalY",nY)

		JEM_getTiltBal(nX,nY)
		dataSet.setData("TiltBalX",nX)
		dataSet.setData("TiltBalY",nY)

		JEM_getAngBal(nX,nY)
		dataSet.setData("AngleBalX",nX)
		dataSet.setData("AngleBalY",nY)

		JEM_getCLs(nX,nY)
		dataSet.setData("CondStigX",nX)
		dataSet.setData("CondStigY",nY)

		JEM_getOLs(nX,nY)
		dataSet.setData("ObjStigX",nX)
		dataSet.setData("ObjStigY",nY)

		JEM_getILs(nX,nY)
		dataSet.setData("IntStigX",nX)
		dataSet.setData("IntStigY",nY)
		
		dataSet.setEcho(JEMALIGNFILES_echo)
		dataSet.write()
		openandSetProgressWindow("","","")	
		if(JEMALIGNFILES_echo)result("alignment saved\n")
		
		return self
	}
	
	void setValues(object self)
	{
		number n
		self.setCheckBox("load Gun1");
		self.setCheckBox("load Gun2");
		self.setCheckBox("load CLA1");
		self.setCheckBox("load CLA2");
		self.setCheckBox("load IS1");
		self.setCheckBox("load IS2");
		self.setCheckBox("load PLA");
		self.setCheckBox("load ShiftBal");
		self.setCheckBox("load TiltBal");
		self.setCheckBox("load AngleBal");
		self.setCheckBox("load CondStig");
		self.setCheckBox("load ObjStig");
		self.setCheckBox("load IntStig");
		self.write()
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(JEMALIGNFILES_dlgTitle,dlgItems)
		openandSetProgressWindow("","","")	

		dlgItems.dlgAddElement(self.createCheckBox("load Gun1","Gun1").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load Gun2","Gun2").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load CLA1","CLA1").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load CLA2","CLA2").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load IS1","IS1").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load IS2","IS2").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load PLA","PLA").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load ShiftBal","ShiftBal").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load TiltBal","TiltBal").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load AngleBal","AngleBal").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load CondStig","CondStig").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load ObjStig","ObjStig").DLGSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("load IntStig","IntStig").DLGSide("West"))
	
		dlgTags.dlgTableLayout(1,13,0)
		self.super.init(dlgTags)
		return self
	}
	
	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val);
		self.setValues()
	}		

	JEM_AlignFiles(object self)
	{
		self.setGroup("ALIGNMENT")
		self.addData("load Gun1",1)
		self.addData("load Gun2",1)
		self.addData("load CLA1",1)
		self.addData("load CLA2",1)
		self.addData("load IS1",1)
		self.addData("load IS2",1)
		self.addData("load PLA",1)
		self.addData("load ShiftBal",1)
		self.addData("load TiltBal",1)
		self.addData("load AngleBal",1)
		self.addData("load CondStig",1)
		self.addData("load ObjStig",1)
		self.addData("load IntStig",1)
		self.setEcho(JEMALIGNFILES_echo)
		self.read()
		self.write()//Needed if called modal to enter data into prefs

		//self.setName("JEM_AlignFiles")
	}
	
	number aboutToCloseDocument(object self,number verify)
	{
		self.write()
	}
}

if(JEMALIGNFILES_doDisplay)
	alloc(JEM_AlignFiles).init().pose()