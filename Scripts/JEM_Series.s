//Series-Set Script
//Sets the defaults for Series
//Press 'enter' to begin.
//TODO: finish custom ref code
//Uninstall instructions are shown on the Results window.
module com.gatan.dm.jemseries
uses com.gatan.dm.jemlib
uses com.gatan.dm.jemtags
uses com.gatan.dm.jemobject
uses com.gatan.dm.jemdialog

number JEM_SERIES_display=0
number JEM_SERIES_echo=0
string JEM_SERIES_sCurrVersion="v213"
number JEM_SERIES_online=1


string JEM_SERIES_sGroup="JEM_SERIES"
string JEM_SERIES_sName="Series"
string JEM_SERIES_sTitle="Series"

//
number returnno
string returnname,returnstring

class JEM_Series:JEM_Widget
{
	string getDocsDir(object self)
	{
		string sDocsDir="C:"
		if(!stringCompare(getOS(),"Windows XP"))
			sDocsDir=pathConcatenate(sDocsDir,"Documents and Settings")
		else
			sDocsDir=pathConcatenate(sDocsDir,"Users")
		getVers()
		return sDocsDir
	}
	
	string getUserDir(object self)
	{
		string sDocsDir=self.getDocsDir()
		string sUserName;self.getData("user",sUserName)
		string sUserDir=pathConcatenate(sDocsDir,sUserName)
		return sUserDir
	}
	
	object makeUserDataSet(object self)
	{
		object dataSet=alloc(JEM_Data)
		dataSet.setGroup("")//Owner will be omitted in user data file
		dataSet.addData("sample","sample")
		dataSet.addData("series","A")
		dataSet.addData("next exposure",0)
		dataSet.addData("destination path",self.getUserDir())
		dataSet.addData("max TIFF size (MB)",16)
		dataSet.addData("TIFF format",1)		
		dataSet.addData("Gatan format",1)	
		dataSet.addData("TIFF grayscale",0)		
		dataSet.addData("show scale marker",1)
		dataSet.addData("autosave",1)
		dataSet.addData("use custom ref",0)
		dataSet.addData("digits",3)
		dataSet.addData("add mag",1)

		return dataSet
	}
	
	void writeUserPrefs(object self)
	{
		string sUserDir=self.getUserDir()		
		string sUserPrefsPath=pathConcatenate(sUserDir,"seriesdata.txt")	
		if(doesFileExist(sUserPrefsPath))
			deleteFile(sUserPrefsPath)
		
		object dataSet=self.makeUserDataSet()
		dataSet.setPath(sUserPrefsPath)
		dataSet.setEcho(JEM_SERIES_echo)
		dataSet.copyData("",self,"user")
	
		number nPrefs=createFileForWriting(sUserPrefsPath)
		writeFile(nPrefs,JEM_SERIES_sCurrVersion+"\n")
		closeFile(nPrefs)

		dataSet.write()
		closeFile(nPrefs)
	}

	void readUserPrefs(object self)
	{
		string sUserDir=self.getUserDir()		
		string sUserPrefsPath=pathConcatenate(sUserDir,"seriesdata.txt")
		if(!doesFileExist(sUserPrefsPath))
			self.writeUserPrefs()
		number nPrefs=openFileForReading(sUserPrefsPath)

		string sVersion;readFileLine(nPrefs,0,sVersion);remove_endchars(sVersion)
		string s
		if(sVersion==JEM_SERIES_sCurrVersion)
		{
			object dataSet=self.makeUserDataSet()
			dataSet.setPath(sUserPrefsPath)
			dataSet.setEcho(JEM_SERIES_echo)
			dataSet.copyData("",self,"user")
			dataSet.read()	
			self.copyData("user",dataSet,"")
		}
		else
		{
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("sample",s)
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("series",s)
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("next exposure",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("destination path",s)
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("max TIFF size (MB)",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("TIFF format",val(s))		
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("Gatan format",val(s))	
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("TIFF grayscale",val(s))		
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("show scale marker",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("autosave",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("use custom ref",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("digits",val(s))
			readFileLine(nPrefs,0,s);remove_endchars(s);self.setData("add mag",val(s))
		}
		closeFile(nPrefs)
	}
	
	//
	void resetExposure(object self)
	{
		self.setData("next exposure",0)
	}

	//
	number incrementExposure(object self)
	{
		number nExp;self.getData("next exposure",nExp)
		nExp++
		self.setData("next exposure",nExp)
		return 1
	}

	//
	void setUser(object self)
	{
		self.readUserPrefs()
	}

	//
	void setSample(object self)
	{
		self.resetExposure()
		self.setData("series","A")
	}

	//
	void setSeries(object self)
	{
		self.resetExposure()
	}

	void setDestPath(object self)
	{
		string sDestPath;self.getData("destination path",sDestPath)
		if(!doesDirectoryExist(sDestPath))sDestPath=self.getUserDir()
		self.setData("destination path",sDestPath)
	}

	//
	string makeExposureString(object self,number nExp)
	{
		number nExpp=nExp
		if(nExp<0)nExpp=trunc(abs(nExp))

		string s=""
		if(nExp<0)
			s="-"
		
		s+=""+nExpp
		return s
	}

	//
	string getImageName(object self,image img)
	{
		
		string sSample;self.getData("sample",sSample)
		string sName=sSample
		
		string sSeries;self.getData("series",sSeries)
		if(sSeries!="")sName+="_"+sSeries

		number nExp;self.getData("next exposure",nExp)
		sName+="_"+self.makeExposureString(nExp)

		number num
		string s

		number addMag;self.getData("add mag",addMag)
		number indMag
		if(addMag&&getNumberNote(img,"Microscope Info:Indicated Magnification",indMag))
		{

			string sIllMode
			if(getStringNote(img,"Microscope Info:Illumination Mode",sIllMode))
			{
				if((!stringCompare(sIllMode,"TEM"))\
					||(!stringCompare(sIllMode,"NBD"))\
					||(!stringCompare(sIllMode,"CBD")))
				{
					string sImagMode
					if(getStringNote(img,"Microscope Info:Imaging Mode",sImagMode))
					{
						if((!stringCompare(sImagMode,"MAG1"))\
							||(!stringCompare(sImagMode,"MAG2"))\
							||(!stringCompare(sImagMode,"LowMAG")))
						{					
							if(indMag<1000)
								sName+="_"+format(indMag,"%g")+"x"
							else
								sName+="_"+format(indMag/1000,"%g")+"Kx"
						}
		
						if(!StringCompare(sImagMode,"DIFF"))
						{
							sName+="_"+indMag/10
							sName+="cm"
						}
					}
				}
				
				if(!StringCompare(sIllMode,"STEM"))
				{	
					string sImagMode
					if(getStringNote(img,"Microscope Info:Imaging Mode",sImagMode))
					{
						if((!stringCompare(sImagMode,"MAG"))\
						||(!stringCompare(sImagMode,"AMAG"))\
						||(!stringCompare(sImagMode,"LMAG"))\
						||(!stringCompare(sImagMode,"UUDIFF")))
						{					
							if(!stringCompare(sImagMode,"UUDIFF"))//DM thinks mag is cam length
							{
								number camLen
								getNumberNote(img,"Microscope Info:STEM Camera Length",camLen)
								indMag=camLen/10
							}
							if(indMag<1000)
								sName+="_"+format(indMag,"%g")+"x"
							else
								sName+="_"+format(indMag/1000,"%g")+"Kx"
						}
		
					}
				}
			}
		}
		return sName
	}

	//Write Image Area
	void writeImageArea(object self,number nlog,image img,string label)
	{
		number xsize,ysize
		getSize(img,xsize,ysize)
		writeFile(nlog,label+" Image Area (Pixels): "+xsize+" x "+ysize+"\n")	
	}

	//Write Pixel Size
	void writePixelSize(object self,number nlog,image img,string label)
	{
		number num
		string s=GetUnitString(img)
		if(len(s)>0)
		{
			number xpix_size,ypix_size
			GetScale(img,xpix_size,ypix_size)
			num=(xpix_size+ypix_size)/2
			WriteFile(nlog,label+" Image Pixel Size ("+s+"): "+num+"\n")	
		}
	}

	//
	void writeImageData(object self,string sPath,image img)
	{
		number nLog=openFileForReadingAndWriting(sPath)
		number logSize=getFileSize(nLog)
		string sOut=readFile(nLog,logSize)//move to EOF

		number num
		string s

		writeFile(nlog,"-----------------------\n")

		//Date
		if(getStringNote(img,"DataBar:Acquisition Date",s))
			writeFile(nlog,"Acquisition Date: "+s+"\n")		

		//Time
		if(getStringNote(img,"DataBar:Acquisition Time",s))
			writeFile(nlog,"Acquisition Time: "+s+"\n")		

		//
		number indMag
		if(getNumberNote(img,"Microscope Info:Indicated Magnification",indMag))
		{
			string sIllMode
			if(getStringNote(img,"Microscope Info:Illumination Mode",sIllMode))
			{
				if((sIllMode=="TEM")||(sIllMode=="NBD")||(sIllMode=="CBD"))
				{						
					string sImagMode
					if(getStringNote(img,"Microscope Info:Imaging Mode",sImagMode))
					{
						writeFile(nlog,"Mode: "+sImagMode+"\n")
						if((!stringCompare(sImagMode,"MAG1"))\
							||(!stringCompare(sImagMode,"MAG2"))\
							||(!stringCompare(sImagMode,"LowMAG")))
						{				
							if(indMag<1000)
								writeFile(nlog,"Magnification (x): "+format(indMag,"%g")+"\n")
							else
								writeFile(nlog,"Magnification (Kx): "+format(indMag/1000,"%g")+"\n")
						}
		
						if(!stringCompare(sImagMode,"DIFF"))		
						{	
							writeFile(nlog,"Camera Length (cm): "+format(indMag/10,"%g")+"\n")
						}
					}
				}
				if(sIllMode=="STEM")
				{						
					string sImagMode
					if(GetStringNote(img,"Microscope Info:Imaging Mode",sImagMode))
					{
						writeFile(nlog,"Mode: "+sImagMode+"\n")
						if((sImagMode=="MAG")||(sImagMode=="AMAG")||(sImagMode=="LMAG")||(sImagMode=="UUDIFF"))//
						{
							if(!stringCompare(sImagMode,"UUDIFF"))//DM thinks cag is cam length
							{
								number camLen
								getNumberNote(img,"Microscope Info:STEM Camera Length",camLen)
								indMag=camLen/10
							}
							if(indMag<1000)
								writeFile(nlog,"Magnification (x): "+format(indMag,"%g")+"\n")
							else
								writeFile(nlog,"Magnification (Kx): "+format(indMag/1000,"%g")+"\n")
						
						}
					}

					number channel
					if(getNumberNote(img,"DigiScan:Channel",channel))
					{
						if(channel==0)
							writeFile(nlog,"Channel: Gatan\n")
						if(channel==1)
							writeFile(nlog,"Channel: JEOL\n")
					}
				}
			}
		}

		//Voltage
		if(getNumberNote(img,"Microscope Info:Voltage",num))
			writeFile(nLog,"Voltage (V): "+num+"\n")			

		//Camera Type
		if(getStringNote(img,"Microscope Info:Calibration:Current Device Name",s))
			writeFile(nLog,"Camera Type: "+s+"\n")
	
		//Active Size
		if(getStringNote(img,"Acquisition:Device:Active Size (pixels)",s))
			writeFile(nLog,"Active Size (Pixels): "+s+"\n")
		
		//CCD Pixel Size
		if(getStringNote(img,"Acquisition:Frame:CCD:Pixel Size (um)",s))
			writeFile(nLog,"CCD Pixel Size (um): "+s+"\n")
			
		//Exposure Time
		//if(getNumberNote(img,"Acquisition:Frame:Sequence:Exposure Time (ns)",num))
			//writeFile(nLog,"Exposure Time (s): "+num/1e9+"\n")
		if(getNumberNote(img,"Acquisition:Smart Acquire:Exposure (s)",num))
			writeFile(nLog,"Exposure Time (s): "+num+"\n")

		if(getNumberNote(img,"Acquisition:Smart Acquire:Extended range",num))
			writeFile(nLog,"Extended range: "+1+"\n")

		/*Image Data*/
		//Image Name	
		writeFile(nLog,"Image Name: "+GetName(img)+"\n")
	
		//Image Area
		self.writeImageArea(nLog,img,"Original")

		//Image Pixel Size
		self.writePixelSize(nLog,img,"Original")

		s=imageGetDescriptionText(img)
		if(stringCompare(s,""))
			writeFile(nLog,"Description: "+s+"\n")
		closeFile(nLog)
	}

	//
	string changeExt(object self,string sOldName,string sNewExt)
	{
		number ls=len(sOldName),maxExtLen=3
	
		number iEnd=ls-maxExtLen-1,i
		if(iEnd<0)iEnd=0

		string sNameRoot=sOldName		
		for(i=ls-1;i>=iEnd;i--)
		{
			string c=mid(sOldName,i,1)
			if(asc(c)==asc("."))
			{
				sNameRoot=left(sOldName,i)			
				break
			}
		}
		//result("old: "+sOldName+", root: "+sNameRoot+"\n")
		return sNameRoot+"."+sNewExt
	}

	void logAndSaveImage(object self,image img,number force)
	{
		number saveAny=1
		//Open log file
		string sLogDir;self.getData("destination path",sLogDir)
		if(!doesDirectoryExist(sLogDir))
		{
			OKDialog("Set series info first!")
			break
		}

		string sSample;self.getData("sample",sSample)
		string sSeries;self.getData("series",sSeries)
		string sLogPath=pathConcatenate(sLogDir,sSample+"_"+sSeries+"_log.txt")
		number nLog
		if(!DoesFileExist(sLogPath))
		{
			nLog=createFileForWriting(sLogPath)
			writeFile(nLog,"Sample: "+sSample+"\n")
			writeFile(nLog,"Series: "+sSeries+"\n\n")
			closeFile(nLog)		
		}

		//
		string s
		number isLogged=getStringNote(img,"Logged",s)
		string sParamSet
		getStringNote(img,"Acquisition:Parameters:Parameter Set Name",sParamSet)
		number isRecord=!stringCompare(sParamSet,"Record")

		string sSTEM_recorded
		getStringNote(img,"DigiScan:Recorded",sSTEM_recorded)
		number isDigiScan=!stringCompare(sSTEM_recorded,"true")
		
		number err=0	
		number showScale;self.getData("show scale marker",showScale)
		if(showScale)showScaleMarker(img)

		//Set name
		string sOldFileName=getName(img)
		string sFileName="Frame"
		string sFilePathAndName=pathConcatenate(sLogDir,sFileName)
		if((force||(!isLogged))&&(isRecord||isDigiScan||saveAny))
		{
			sFileName=self.getImageName(img)
			setName(img,sFileName)
			sFilePathAndName=pathConcatenate(sLogDir,getName(img))
		}
		else
			err=-1//
		
		//save as DM3
		number formatGatan;self.getData("Gatan format",formatGatan)
		if((!err)&&formatGatan)
		{
			string sFileNameAndExt=sFileName+getImageExt()
			sFilePathAndName=pathConcatenate(sLogDir,sFileNameAndExt)
			if(doesFileExist(sFilePathAndName))
			{
				//result("name2 "+filepathandname+"\n")
				if(force)
					saveAsGatan(img,sFilePathAndName)
				else
				{
					setName(img,sOldFileName)
					err=1
				}
			}
			else
				saveAsGatan(img,sFilePathAndName)	
		}

		//save as TIFF
		number formatTIFF;self.getData("TIFF format",formatTIFF)
		if((!err)&&formatTIFF)
		{
			string sFileNameAndExt=sFileName+".tif"
			sFilePathAndName=pathConcatenate(sLogDir,sFileNameAndExt)
			number nExp;self.getData("next exposure",nExp)
			number nExpTemp=nExp//added to fix DM glitch

			number grayscaleTIFF;self.getData("TIFF grayscale",grayscaleTIFF)
			number maxTIFF_sizeMB;self.getData("max TIFF size (MB)",maxTIFF_sizeMB)
			if(doesFileExist(sFilePathAndName))
			{
				if(force)
					saveTIFFDisplay(img,sFilePathAndName,grayscaleTIFF,maxTIFF_sizeMB)
				else
					err=3
			}
			else
			{
				if(!saveTIFFDisplay(img,sFilePathAndName,grayscaleTIFF,maxTIFF_sizeMB))
					err=4
		
			}
			nExp=nExpTemp
		}
		
		//Log
		//result("error:"+err+"\n")
		if(!err)
		{
			self.writeImageData(sLogPath,img)		
			setStringNote(img,"Logged","yes")
			cleanImage(img)
			self.incrementExposure()
		}
		if(err>0)
		{
			result("Error "+err+"\n")
			OKDialog("An error occurred saving:\n"+sFileName)
		}

		self.writeUserPrefs()
	}
	
	//
	void startAcquire(object self)
	{
		number prevShutterState
		object camera=CM_GetCurrentCamera();
		camera.CM_GetIdleShutterState(0,prevShutterState)
		object params=CM_GetCameraAcquisitionParameterSet(camera,"Imaging","Acquire","Record",0)
		image img:=camera.CM_AcquireImage(params)
		camera.CM_SetIdleShutterState(0,prevShutterState)
		showImage(img)			
		
		number showScale;self.getData("show scale marker",showScale)
		if(showScale)showScaleMarker(img)
		
		number autosave;self.getData("autosave",autosave)
		if(autosave)
			self.logAndSaveImage(img,1)
	}	

	//
	TagGroup makeUserList(object self)
	{
		string sDocsDir=self.getDocsDir()

		TagGroup dirTag=getFilesInDirectory(sDocsDir,2)
		number nFiles=dirTag.tagGroupCountTags()
		TagGroup userList=newTagList()
		
		number i
		for(i=0;i<nFiles;i++)
		{
			TagGroup userTag;dirTag.tagGroupGetIndexedTagAsTagGroup(i,userTag)
			string s;userTag.tagGroupGetTagAsString("Name",s)
			if((s!="Default")&&(s!="Default User")&&(s!="Public"))
				userList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup(s,s))
		}
		return userList 
	}
	
	void setValues(object self)
	{

		//user_tag.DLGValue(usernum+1)
		self.setPopup("user")
		self.setString("sample")
		self.setString("series")
		self.setNumber("next exposure")
		self.setString("destination path")
		self.setNumber("next exposure")
		self.setNumber("max TIFF size (MB)")
		self.setCheckBox("Gatan format")
		self.setCheckBox("TIFF format")
		self.setCheckBox("TIFF grayscale")
		self.setCheckBox("show scale marker")
		self.setCheckBox("add mag")

	}
	
	void getValues(object self)
	{
	}

		//
	void logAndSave(object self)
	{
		image img
		if(!GetFrontImage(img))return
		self.logAndSaveImage(img,optionDown())
		self.setValues()

	}

	//
	void logAndSaveAll(object self)
	{
		//loop through images
		number nImgDocs=countImageDocuments()
		number nPos // note position 0 is foremost

		number force=optionDown()
		for(nPos=0;nPos<nImgDocs;nPos++)
		{
			imagedocument imgDoc=getImageDocument(nPos)
			image img:=imageDocumentGetImage(imgDoc,0)
			self.logAndSaveImage(img,force)
			self.setValues()
		}	
	}

	//
	void closeAll(object self)
	{
		//result("-------\n")
		number nPos // note position 0 is foremost
		number force=optionDown()
		//if(!force)
			//force=OKCancelDialog("Close all recorded images?")

		number actualPos=0
		number nImgDocs=countImageDocuments()
		for(nPos=0;npos<nImgDocs;nPos++)
		{
			//result("-------\n")
			imagedocument imgDoc=getImageDocument(actualPos)
			image img:=imageDocumentGetImage(imgDoc,0)

			string sFileName=getName(img)
			//result("name: "+filename+"\n")
			string s

			number isLogged=getStringNote(img,"Logged",s)
			number isRecord=0
			if(getStringNote(img,"Microscope Info:Illumination Mode",s))
			{
				if((s=="TEM")||(s=="NBD")||(s=="CBD"))
				{	
					getStringNote(img,"Acquisition:Parameters:Parameter Set Name",s)
					isRecord=(s=="Record")
				}
				if(s=="STEM")
				{
					getStringNote(img,"DigiScan:Recorded",s)
					isRecord=(s=="true")
				}
			}
			
			if(isRecord)
			{
				if(isLogged)
				{
					cleanImage(img)
					deleteImage(img)
				}
				else
				{
					if(force)
					{
						cleanImage(img)
						deleteImage(img)
					}
					else
					{
						OKDialog("A recorded image has not been logged!"\
							+"\n"+sFileName\
							+"\n(Hold 'Alt' to force close without logging.)")
						if(optionDown())
						{
							cleanImage(img)
							deleteImage(img)
						}
						else
							actualPos+=1								
					}
				}
			}
			else
				actualPos+=1
		}
	}	
	

	void selectDestPath(object self)
	{
		string sDestPath;self.getData("destination path",sDestPath)
		number res=doesDirectoryExist(sDestPath)
		if(!doesDirectoryExist(sDestPath))sDestPath=self.getUserDir()
		if(stringCompare(getOS(),"Windows7"))
			setApplicationDirectory("current",0,sDestPath)
		if(getDirectoryDialog(sDestPath))
			self.setData("destination path",sDestPath)
		self.setDestPath()
		self.getData("destination path",sDestPath)
		setApplicationDirectory("open_save",0,sDestPath)
		self.writeUserPrefs()
		self.setValues()
	}

	void numberChanged(object self,string sIdent,number val)
	{
		self.super.numberChanged(sIdent,val)
		self.writeUserPrefs()
		self.setValues()
	}

	void stringChanged(object self,string sIdent,string sVal)
	{
		self.super.stringChanged(sIdent,sVal);
		if(sIdent=="sample")
			self.setSample()
		
		if(sIdent=="series")
			self.setSeries()
			
		if(sIdent=="destination path")
			self.setDestPath()
			
		self.writeUserPrefs()
		self.setValues()
	}
	
	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{
		self.super.popupChanged(sIdent,itemTag)
		//if(sIdent=="user")
			//self.setUser()
		self.write()
		self.readUserPrefs()
		self.setValues()
	}

	void boxChecked(object self,string sIdent,number val)
	{
		self.super.boxChecked(sIdent,val)
		self.writeUserPrefs()
		self.setValues()
	}

	void acquire(object self)
	{
		self.startAcquire()
		self.setValues()
	}
	
	object init(object self)
	{
		tagGroup dlgItems,dlgTags=dlgCreateDialog(self.getName(),dlgItems)

		//add items
		TagGroup userList=self.makeUserList()
		TagGroup userNameTag=self.createPopup("user","User Name:",userList,"Top").dlgAnchor("West").dlgExternalPadding(5,5)
		dlgItems.dlgAddElement(userNameTag)
		
		dlgItems.dlgAddElement(self.createString("sample","Sample:",20,"Top").dlgAnchor("West").dlgExternalPadding(5,0))
		dlgItems.dlgAddElement(self.createString("series","Series:",20,"Top").dlgAnchor("West").dlgExternalPadding(5,0))
		dlgItems.dlgAddElement(self.createNumber("next exposure","Next Exp. #:",20,"Top").dlgAnchor("West").dlgExternalPadding(5,0))
		dlgItems.dlgAddElement(self.createNumber("max TIFF size (MB)","TIFF Max. Size (MB):",20,"Top").dlgAnchor("West").dlgExternalPadding(5,0))

		TagGroup formatDM_tag
		if(getVers()=="1")formatDM_tag=self.createCheckBox("Gatan format","Gatan .dm3")
		else formatDM_tag=self.createCheckBox("Gatan format","Gatan .dm4")
		TagGroup formatTIFF_tag=self.createCheckBox("TIFF format","8-bit .tif ")
		TagGroup formatTIFF_grayTag=self.createCheckBox("TIFF grayscale","Grayscale").dlgSide("West")
		TagGroup formatTIFF_scaleTag=self.createCheckBox("show scale marker","Marker")
		//TagGroup autoSaveTag=self.createCheckBox("autosave","Autosave").dlgSide("West")
		TagGroup addMagTag=self.createCheckBox("add mag","Add mag")

		TagGroup group1Tag=dlgGroupItems(formatDM_tag,formatTIFF_Tag).dlgTableLayout(1,3,0)
		TagGroup group2Tag=dlgGroupItems(formatTIFF_graytag,formatTIFF_scaleTag,addMagTag).dlgTableLayout(1,3,0)
		//TagGroup group3Tag=dlgGroupItems(autoSaveTag,addMagTag).dlgTableLayout(2,1,0)
		dlgItems.dlgAddElement(dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0)).dlgAnchor("West").dlgExternalPadding(5,0);

		dlgItems.dlgAddElement(self.createButton("set destination path","Set Destination Path","selectDestPath").dlgAnchor("West").dlgExternalPadding(5,0))
		dlgItems.dlgAddElement(self.createString("destination path","",32).dlgAnchor("West").dlgExternalPadding(5,0))

		TagGroup logSaveTag=self.createButton("log and save","Log/Save","logAndSave")
		TagGroup logSaveAllTag=self.createButton("log and save all","Log/Save All","logAndSaveAll")
		TagGroup action1Tag=dlgGroupItems(logSaveTag,logSaveAllTag).dlgTableLayout(2,1,0).dlgExternalPadding(5,0).dlgAnchor("West")
		dlgItems.dlgAddElement(action1Tag)
	
		TagGroup closeAllTag=self.createButton("close all","Close All","closeAll")
		TagGroup acquireTag=self.createButton("start acquire","Acq/Log/Save","acquire").dlgExternalPadding(5,0)
		TagGroup action2Tag=dlgGroupItems(closeAllTag,acquireTag).dlgTableLayout(2,1,0).dlgExternalPadding(5,0).dlgAnchor("West")
		dlgItems.dlgAddElement(action2Tag)

		dlgTags.dlgTableLayout(1,12,0);

		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);

		self.super.init(dlgTags)			
		return self
	}

	JEM_Series(object self)
	{
		OpenandSetProgressWindow("","","")	

		self.setGroup(JEM_SERIES_sGroup)
		self.setEcho(JEM_SERIES_echo)
		
		self.setName(JEM_SERIES_sName)
	}
	
	object load(object self)
	{
		string sUserName=SpGetUsername()
		
		self.addData("online",JEM_SERIES_online)
		self.addData("user",sUserName)		
		self.addData("user","sample","sample")
		self.addData("user","series","A")
		self.addData("user","next exposure",0)
		self.addData("user","destination path",self.getUserDir())
		self.addData("user","max TIFF size (MB)",16)
		self.addData("user","TIFF format",1)		
		self.addData("user","Gatan format",1)	
		self.addData("user","TIFF grayscale",0)		
		self.addData("user","show scale marker",1)
		self.addData("user","autosave",1)
		self.addData("user","use custom ref",0)
		self.addData("user","digits",3)
		self.addData("user","add mag",1)
						
		self.super.load()
		self.setData("user",sUserName)//Need to retain current user, not previous
		self.readUserPrefs()
		return self
	}

	~JEM_Series(object self)
	{
		self.unload()
	}
}

//
void showSeries()
{
	alloc(JEM_Series).load().init().display()
}

if(JEM_SERIES_display)showSeries()
