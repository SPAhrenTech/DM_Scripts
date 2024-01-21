number PROGRESSINFO_display=0
//number PROGINFO_online=1
number PROGRESSINFO_echo=0
string PROGRESSINFO_sGroup="PROGRESSINFO"
string PROGRESSINFO_sName="ProgInfo"
string PROGRESSINFO_sTitle="Progress Info"

class ProgressInfo:JEM_Widget
{
	TagGroup infoList

	ProgressInfo(object self)
	{
		self.setGroup(PROGRESSINFO_sGroup)		
		self.setEcho(PROGRESSINFO_echo)
		self.setName(PROGRESSINFO_sName)
		self.setTitle(PROGRESSINFO_sTitle)
		infoList=newTagList()
	}
	
	~ProgressInfo(object self)
	{
		self.unload()
	}
	
	object load(object self)
	{
		self.addData("lines",4)
		self.read()
		return self.super.load()
	}
	
	//
	object clearProgress(object self)
	{
		infoList.tagGroupDeleteAllTags()
	}
	
	//
	object deleteProgress(object self,number key)
	{
		number i=0
		while(i<infoList.tagGroupCountTags())
		{
			TagGroup infoTag
			infoList.tagGroupGetIndexedTagAsTagGroup(i,infoTag)
			number keyp
			infoTag.tagGroupGetTagAsNumber("key",keyp)
			if(keyp==key)
			{
				infoList.tagGroupDeleteTagWithIndex(i)
			}
			else
				i++
		}
		return self
	}

	object getProgress(object self,number index,string &sInfo)
	{
		number nInfo=infoList.tagGroupCountTags()
		if(index<nInfo)
		{
			TagGroup infoTag
			infoList.tagGroupGetIndexedTagAsTagGroup(index,infoTag)
			infoTag.tagGroupGetTagAsString("info",sInfo)
			//result(sMsg+"\n")
		}
		return self
	}
	
	//
	number addProgress(object self,string sInfo)
	{
		TagGroup infoTag=newTagGroup()
		number index
		
		number key=getHighResTickCount()
		index=infoTag.tagGroupCreateNewLabeledTag("key")
		infoTag.tagGroupSetIndexedTagAsNumber(index,key)
		
		index=infoTag.tagGroupCreateNewLabeledTag("info")
		infoTag.tagGroupSetIndexedTagAsString(index,sInfo)

		infoList.tagGroupInsertTagAsTagGroup(infinity(),infoTag)
		return key
	}

	//
	object setProgress(object self,number key,string sInfo)
	{
		
		number i=0
		while(i<infoList.tagGroupCountTags())
		{
			TagGroup infoTag
			infoList.TagGroupGetIndexedTagAsTagGroup(i,infoTag)
			number keyp
			infoTag.TagGroupGetTagAsNumber("key",keyp)
			//result("key: "+key+", keyp: "+keyp+"\n")
			if(keyp==key)
			{
				infoTag.tagGroupSetTagAsString("info",sInfo)
				infoList.tagGroupSetIndexedTagAsTagGroup(i,infoTag)
			}
			i++
		}
		return self
	}
	
	//
	number countProgress(object self)
	{
		return infoList.tagGroupCountTags()
	}
	
	object setValues(object self)
	{
		if(!self.getFrameWindow().windowIsValid())return self
		
		//textTag.tagGroupSetTagAsString("Insert","a bunch of words")
		//self.setString("info")
		TagGroup listTag=self.getField("info")
		//listTag.TagGroupOpenBrowserWindow(0)
		TagGroup itemList;
		listTag.tagGroupGetTagAsTagGroup("Items",itemList)
		itemList.tagGroupDeleteAllTags()
		number nItems=itemList.tagGroupCountTags()
		number nInfo=infoList.tagGroupCountTags()
		//infoList.TagGroupOpenBrowserWindow(0)
		number i
		for(i=0;i<nInfo;++i)
		{
			TagGroup infoTag
			infoList.tagGroupGetIndexedTagAsTagGroup(i,infoTag)
			string sInfo;infoTag.tagGroupGetTagAsString("info",sInfo)
			itemList.dlgAddListItem(sInfo,0)
		}
		listTag.dlgInvalid(1)
		return self
	}

	object showProgress(object self)
	{
		self.setValues()
		self.validateView()
		return self
	}
	//

	void linesPressed(object self)
	{
		TagGroup listTag=self.getField("info")
		number h;listTag.tagGroupGetTagAsNumber("Height",h)
		if(getNumber("# of lines:",h,h))
			listTag.tagGroupSetTagAsNumber("Height",h)
		self.setData("lines",h)
		self.write()
		self.refresh()
		//getPanelList().closePanel(self.getName())
		//getPanelList().openPanel(self.getName())
		self.setValues()
	}

	void clearPressed(object self)
	{
		number nInfo=infoList.tagGroupCountTags()
		for(number i=0;i<nInfo;++i)
		{
			number j=nInfo-i-1
			TagGroup infoTag
			infoList.tagGroupGetIndexedTagAsTagGroup(j,infoTag)
			number key;infoTag.tagGroupGetTagAsNumber("key",key)
			self.deleteProgress(key)
		}
		self.setValues()
	}

	void listChanged(object self,TagGroup fieldTag)
	{
	}

	//	
	object init(object self)
	{
		TagGroup dlgItems,dlgTags
		dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		//OpenandSetProgressWindow("","","")	

		//
		TagGroup listTag=self.createList("info",30,3,"","")
		//tagGroup infoTag=self.createTabList("info",1)
		dlgItems.dlgAddElement(listTag.dlgAnchor("West").dlgexternalpadding(5,5))
		number h;self.getData("lines",h)
		listTag.tagGroupSetTagAsNumber("Height",h)
		
		TagGroup linesTag=self.createButton("lines","Lines","linesPressed")	
		TagGroup clearTag=self.createButton("clear","Clear","clearPressed")
		dlgItems.dlgAddElement(dlgGroupItems(linesTag,clearTag).dlgTableLayout(2,1,0).dlgAnchor("West").dlgExternalPadding(5,5))

		dlgTags.dlgTableLayout(1,3,0);

		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.tagGroupSetTagAsString("Width","Medium")
		position.dlgSide( "Right" );
		dlgTags.dlgPosition(position);
	
		self.super.init(dlgTags)
		return self
	}

}	
//
void showProgressInfo()
{
	alloc(ProgressInfo).load().init().display()

}
if(PROGRESSINFO_display)showProgressInfo()

