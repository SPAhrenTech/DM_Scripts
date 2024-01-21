//Reads and write Idented data to text file
//line starts with Ident, followed by any numer of tabs, then data
//comments at end of line set off by #
module com.gatan.dm.jemprefs

//
string makePrefEntry(string Ident,string data)
{
	number res=0,found_Ident=0
	string old_data="",trail
	string s,sBefore="",sAfter=""
	return Ident+"\t"+data
}

//Replace nth occurrence with this Ident.
//If nOccur<=0, insert before first matching entry
//If nOccur is greater than # of occurences, make this the last entry.
number writePrefEntry(string sPrefsPath,string sGroup,string sIdent,string sData,number nOccur,number echo)
{
	number res=0,found_Ident=0
	string sOldData="",sTrail
	string s,sBefore="",sAfter=""
	string sLine=sIdent+"\t"+sData
	number hasGroup=0
	if(sGroup!="")
	{
		sLine=sGroup+"\t"+sLine
		hasGroup=1
	}
	number nFound=0
	if(echo)result("Writing data...\n")
	number nfile
	if(doesFileExist(sPrefsPath))
	{
		nfile=openFileForReading(sPrefsPath)
	
		number gotData=0
		while(readFileLine(nFile,0,s))
		{
			number L=len(s)
		
			if(gotData)
			{
				sAfter+=s
				continue
			}
				
			string sGroupP=""
			number gotGroup=0
			
			string sIdentP=""
			number gotIdent=0
			
			number hasTrail=0

			number i=0
			string c
			
			if(hasGroup)
			{
				//Compare Group
				while(i<L)
				{
					c=mid(s,i,1)			
					if(asc(c)==9)//found tab, now look for data
					{
						i++
						gotGroup=1
						break
					}
					sGroupP+=c
					i++
				}
				
				if((!gotGroup)||(sGroupP!=sGroup))
				{
					sBefore+=s
					continue//not the target Group, move to next line
				}			
			}
			
			//Compare Ident
			while(i<L)
			{
				c=mid(s,i,1)
				if(asc(c)==9)//found tab, now look for data
				{
					i++
					gotIdent=1
					break
				}	
				sIdentP+=c
				i++
			}	
		
			if((!gotIdent)||(sIdentP!=sIdent))
			{
				sBefore+=s
				continue//not the target Ident, move to next line
			}			
			
			//Found an occurence
			nFound++
			if(echo)result("found: "+nFound+", occurrence: "+nOccur+"\n")
			if(nFound<nOccur)
			{
				sBefore+=s
				continue
			}
			
			if(nFound>nOccur)
			{
				sAfter+=s
				gotData=1
				continue
			}

			if(nFound==nOccur)
			{
				//Skip over old data
				while(i<L)
				{
					c=mid(s,i,1)
					if(asc(c)==35)//read until #
						break
					i++
				}

				//Read trailing comments
				while(i<L)
				{
					c=mid(s,i,1)
					if((asc(c)!=13)&&(asc(c)!=10))
						sLine+=c//append any other trailing characters
					i++
				}
				gotData=1
			}
			//remove_endchars(trail)
		}
		closeFile(nFile)		//DeleteFile(sPrefsPath)		
	}
	createFile(sPrefsPath)
		
	//Now write
	nfile=openFileForWriting(sPrefsPath)
	writeFile(nFile,sBefore)
	writeFile(nFile,sLine+"\n")
	writeFile(nFile,sAfter)
	closeFile(nFile)
	res=1

	if(echo)result(sLine+"\n")
	return res
}

//
number writePrefEntry(string sPrefsPath,string sGroup,string sIdent,string sData,number echo)
{
	return writePrefEntry(sPrefsPath,sGroup,sIdent,sData,1,echo)
}

//Read the nth occurrence
number readPrefEntry(string sPrefsPath,string sGroup,string sIdent,string &sData,number nOccur,number echo)
{
	number res=0,found_Ident=0
	sData=""
	string sLine=""
	string trail
	if(!doesFileExist(sPrefsPath))return res;
	number nFile=openFileForReading(sPrefsPath)
	number nFound=0
	number hasGroup=(sGroup!="")

	if(echo)result("Reading data...\n")
	while(readFileLine(nFile,0,sLine))
	{
		number L=len(sLine)
		if(L==0)
			continue
		
		//find Group
		string sGroupP=""
		number gotGroup=0

		//find Ident
		string sIdentP=""
		number gotIdent=0
		number i=0

		string c
		
		if(hasGroup)
		{
			//Read Group
			while(i<L)
			{
				c=mid(sLine,i,1)
				if(asc(c)==9)//tab. look for data
				{
					gotGroup=1
					i++
					break
				}
				sGroupP+=c
				i++
			}
			
			if((!gotGroup)||(sGroupP!=sGroup)) continue
			if(echo)result("Group: "+sGroupP+"\n")
		}
		
		//Read Ident
		while(i<L)
		{
			c=mid(sLine,i,1)
			if(asc(c)==9)//tab. look for data
			{
				gotIdent=1
				break
			}
			sIdentP+=c
			i++
		}

		if((!gotIdent)||(sIdentP!=sIdent)) continue

		nFound++
		if(echo)result("found: "+nFound+", occurence: "+nOccur+"\n")
		if(nFound<nOccur)continue
			
		number foundData=0
		while(i<L)
		{
			c=mid(sLine,i,1)
			if(asc(mid(sLine,i,1))!=9)
			{
				foundData=1
				break
			}
			i++
		}
		
		if(!foundData)continue		
		res=1
		while(i<L)
		{
			string c=mid(sLine,i,1)
			if((asc(c)==35)||(asc(c)==9)||(asc(c)==13))
				break
			sData+=c
			i++
		}
		break

	}
	closeFile(nfile)
	if(res)
		if(echo)
			result(sLine)

	return res
}

//Just read the first occurence
number readPrefEntry(string sPrefsPath,string sGroup,string sIdent,string &sData,number echo)
{
	return readPrefEntry(sPrefsPath,sGroup,sIdent,sData,1,echo)
}

//
number getEntryString(string sLine,string &sOut,string sDelim,number index)
{
	number nChar=len(sLine)
	number iPos=0,iIndex=0
	number res=0
	
	sOut=""
	while((iPos<nChar)&&(iIndex<=index))
	{
		string c=mid(sLine,iPos,1)
		iPos++		
		if(iIndex==index)res=1
		if(asc(c)==asc(sDelim))
		{
			iIndex++
			continue
		} 
		if(iIndex==index)
		{
			sOut+=c
		}
	}
	//result("length="+sl+", string="+sout+", number="+num+", npos="+npos+"\n")
	return res
}

//
number getEntryNumber(string s,number &xOut,string sdelim,number index)
{
	string sOut
	number res=getEntryString(s,sOut,sdelim,index)
	xOut=val(sOut)
	return res
}

//
number getEntryTag(string sLine,TagGroup &tagList,string sDelim,number index)
{
	number nChar=len(sLine)
	number iPos=0,iIndex=0
	number res=0
	
	number isString=0
	number firstChar=1
	string sOut=""
	while((iPos<nChar)&&(iIndex<=index))
	{
		string c=mid(sLine,iPos,1)
		number ascc=asc(c)
		iPos++		
		if(iIndex==index)res=1
		if(ascc==asc(sDelim))
		{
			iIndex++
			continue
		} 
		if(iIndex==index)
		{
			if(firstChar)
			{
				if(ascc==asc(" "))
					continue
			}		
			if(ascc==asc("\""))
			{
				if(firstChar)
				{
					isString=1
				}
			}
			else
				sOut+=c
			firstChar=0
		}
	}
	if(res)
	{
		if(isString)
			tagList.tagGroupInsertTagAsString(infinity(),sOut)
		else
			tagList.tagGroupInsertTagAsNumber(infinity(),val(sOut))
	}
	//result("length="+sl+", string="+sout+", number="+num+", npos="+npos+"\n")
	return res
}

//
number writePref(string sPrefsPath,string sGroup,string sIdent,string sData,number nOccur,number echo)
{
	string s
	return writePrefEntry(sPrefsPath,sGroup,sIdent,sData,nOccur,echo)
}

number writePref(string sPrefsPath,string sGroup,string sIdent,number data,string style,number nOccur,number echo)
{
	string s=format(data,style)
	return writePrefEntry(sPrefsPath,sGroup,sIdent,s,nOccur,echo)
}


number writePrefList(string sPrefsPath,string sOwner,string sIdent,TagGroup listTag,number nOccur,number echo)
{
	string s=""
	number nWrite=listTag.tagGroupCountTags()
	number i,first=1
	for(i=0;i<nWrite;++i)
	{	
		number dataType=listTag.tagGroupGetTagType(i,0)	
		string sItem
		listTag.tagGroupGetIndexedTagAsString(i,sItem)
		if(!first)s+=","
		if(dataType==20)//string
			s+="\""+sItem+"\""
		else
			s+=" "+format(val(sItem),"%g")
		first=0
	}
	return writePrefEntry(sPrefsPath,sOwner,sIdent,s,nOccur,echo)
}

number writePref(string sPrefsPath,string sGroup,string sIdent,rgbnumber data,number nOccur,number echo)
{
	TagGroup rgbList=newTagList()
	rgbList.tagGroupInsertTagAsNumber(infinity(),red(data))
	rgbList.tagGroupInsertTagAsNumber(infinity(),green(data))
	rgbList.tagGroupInsertTagAsNumber(infinity(),blue(data))
	return writePrefList(sPrefsPath,sGroup,sIdent,rgbList,nOccur,echo)
}

//
number readPref(string sPrefsPath,string sGroup,string sIdent,string &sData,number nOccur,number echo)
{return readPrefEntry(sPrefsPath,sGroup,sIdent,sData,nOccur,echo);}

number readPref(string sPrefsPath,string sGroup,string sIdent,number &data,number nOccur,number echo)
{
	string s
	number res=readPrefEntry(sPrefsPath,sGroup,sIdent,s,nOccur,echo)
	data=val(s)
	return res
}

number readPrefList(string sPrefsPath,string sOwner,string sIdent,TagGroup &listTag,number nOccur,number echo)
{
	string s
	number res=readPrefEntry(sPrefsPath,sOwner,sIdent,s,nOccur,echo)
	listTag=newTagList()
	number res2=res,nRead=0
	while(res2)
	{	
		string sOut
		res2=getEntryTag(s,listTag,",",nRead)
		nRead++
	}
	return res
}

number readPref(string sPrefsPath,string sGroup,string sIdent,rgbnumber &data,number nOccur,number echo)
{
	TagGroup rgbList
	number res=readPrefList(sPrefsPath,sGroup,sIdent,rgbList,nOccur,echo)
	number r,g,b
	rgbList.tagGroupGetIndexedTagAsNumber(0,r)
	rgbList.tagGroupGetIndexedTagAsNumber(1,g)
	rgbList.tagGroupGetIndexedTagAsNumber(2,b)
	data=rgb(r,g,b)
	return res
}

//First occurence
//
number writePref(string sPrefsPath,string sGroup,string sIdent,number data,string style,number echo)
{return writePref(sPrefsPath,sGroup,sIdent,data,style,1,echo);}

number writePref(string sPrefsPath,string sGroup,string sIdent,string sData,number echo)
{return writePrefEntry(sPrefsPath,sGroup,sIdent,sData,1,echo);}

number writePref(string sPrefsPath,string sGroup,string sIdent,rgbnumber data,number echo)
{return writePref(sPrefsPath,sGroup,sIdent,data,1,echo);}

number writePrefList(string sPrefsPath,string sOwner,string sIdent,TagGroup listTag,number echo)
{return writePrefList(sPrefsPath,sOwner,sIdent,listTag,1,echo);}

//
number readPref(string sPrefsPath,string sGroup,string sIdent,string &sData,number echo)
{return readPref(sPrefsPath,sGroup,sIdent,sData,1,echo);}

number readPref(string sPrefsPath,string sGroup,string sIdent,number &data,number echo)
{return readPref(sPrefsPath,sGroup,sIdent,data,1,echo);}

number readPrefList(string sPrefsPath,string sOwner,string sIdent,TagGroup &listTag,number echo)
{return readPrefList(sPrefsPath,sOwner,sIdent,listTag,1,echo);}

number readPref(string sPrefsPath,string sGroup,string sIdent,rgbnumber &data,number echo)
{return readPref(sPrefsPath,sGroup,sIdent,data,1,echo);}

/*
//
string getJEMPrefsDir(string winOS)
{
	string prefsDir
	if(!StringCompare(winOS,"Windows XP"))
	{
		prefsDir=GetApplicationDirectory("preference",0)
		prefsDir=pathConcatenate(prefsDir,"JEM_files")
	}
	if(!StringCompare(winOS,"Windows 7"))
	{
		prefsDir=GetApplicationDirectory("preference",0)
		prefsDir=pathConcatenate(prefsDir,"JEM_files")
	}
	return prefsDir
}
*/
/*
result("---------\n")
string sDataDir=getApplicationDirectory("preference",0)
string sDataName="JEM_prefs"
string sDataPath=pathConcatenate(sDataDir,sDataName+".txt")

//string sDataPath="C:\ProgramData\Gatan\Prefs\JEM_prefs.txt"
string sGroup="MONTAGE"
string sIdent="Nx"
string sData
number echo=1
number res=readPrefEntry(sDataPath,sGroup,sIdent,sData,1,echo)
result("res: "+res+"\n")
result("data: "+sData+"\n")
*/

/*
string sJEM_prefs_path=GetJEMPrefsPath(getOS(),"JEM_prefs.txt")
string data
readPrefString(sJEM_prefs_path,"example",data,3,1)
readPrefString(sJEM_prefs_path,"example",data,3,1)
data="alt"
writePrefString(sJEM_prefs_path,"example",data,1)
*/