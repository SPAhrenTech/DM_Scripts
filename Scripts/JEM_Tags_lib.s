module com.gatan.dm.jemtags

//
number setGlobalGroupTag(string sGroup,string sLabel,tagGroup &groupTag)
{
	TagGroup globalTag=getPersistentTagGroup()

	number res=0
	number groupIndex
	if(!globalTag.tagGroupDoesTagExist(sGroup))
	{
		groupIndex=globalTag.tagGroupCreateNewLabeledTag(sGroup)
		globalTag.tagGroupSetTagAsTagGroup(sGroup,NewTagGroup())
	}
	
	globalTag.tagGroupGetTagAsTagGroup(sGroup,groupTag)
	if(!groupTag.tagGroupDoesTagExist(sLabel))
	{
		number tagIndex=groupTag.tagGroupCreateNewLabeledTag(sLabel)
	}
	res=1
	return res
}


number getGlobalGroupTag(string sGroup,string sLabel,tagGroup &groupTag)
{
	TagGroup globalTag=GetPersistentTagGroup()

	number res=0
	number n=0
	if(globalTag.tagGroupDoesTagExist(sGroup))
	{	
		globalTag.tagGroupGetTagAsTagGroup(sGroup,groupTag)
		if(groupTag.tagGroupDoesTagExist(sLabel))
			res=1
	}
	return res
}

//
number setGlobalData(string sGroup,string sLabel,number n)
{
	number res=0
	TagGroup groupTag
	if(res=setGlobalGroupTag(sGroup,sLabel,groupTag))
		groupTag.tagGroupSetTagAsNumber(sLabel,n)
	return res
}

number getGlobalData(string sGroup,string sLabel,number &n)
{
	number res=0
	TagGroup groupTag
	if(res=getGlobalGroupTag(sGroup,sLabel,groupTag))
		groupTag.TagGroupGetTagAsNumber(sLabel,n)
	return res
}

//
number setGlobalData(string sGroup,string sLabel,string s)
{
	number res=0
	TagGroup groupTag
	if(res=setGlobalGroupTag(sGroup,sLabel,groupTag))
		groupTag.tagGroupSetTagAsString(sLabel,s)
	return res
}

number getGlobalData(string sGroup,string sLabel,string &s)
{
	number res=0
	TagGroup groupTag
	if(res=getGlobalGroupTag(sGroup,sLabel,groupTag))
		groupTag.TagGroupGetTagAsString(sLabel,s)
	return res
}

//Control screen
void setControlScreen(number n)
{
	setGlobalData("SDSMT","control screen",n)
}

number getControlScreen()
{
	number n=0
	getGlobalData("SDSMT","control screen",n)
	return n
}

//Use SmartAcq
void setUseSmartAcq(number n)
{
	setGlobalData("SDSMT","use SmartAcq",n)
}

number getUseSmartAcq()
{
	number n=0
	getGlobalData("SDSMT","use SmartAcq",n)
	return n
}

//Proceed
void setPaused(number paused)
{
	setGlobalData("SDSMT","Paused",paused)
}

number getPaused()
{
	number paused=0
	getGlobalData("SDSMT","Paused",paused)
	return paused
}

void togglePaused()
{
	number paused=1-getPaused()
	setPaused(paused)
}

//Terminate
void setTerminate(number terminate)
{
	setGlobalData("SDSMT","Terminate",terminate)
}

number getTerminate()
{
	number terminate=0
	getGlobalData("SDSMT","Terminate",terminate)
	return terminate
}

//Operating system
void setOS(string sWinOS)
{
	setGlobalData("SDSMT","Operating System",sWinOS)
}

string getOS()
{
	string sWinOS="Windows 7"
	getGlobalData("SDSMT","Operating System",sWinOS)
	return sWinOS
}

//DM version
void setVers(string sDMversion)
{
	setGlobalData("SDSMT","DM Version",sDMversion)
}

string getVers()
{
	string sDMversion="2"
	getGlobalData("SDSMT","DM Version",sDMversion)
	return sDMversion
}

//
string getImageExt()
{
	string sExt
	if(!StringCompare(getVers(),"1"))
		sExt=".dm3"
	else
		sExt=".dm4"
	return sExt
}