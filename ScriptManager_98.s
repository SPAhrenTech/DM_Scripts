//ScriptManager - P. Ahrenkiel 2021
//For a clean install, first make sure previous version has been removed,
//using File:Remove Script... Then set SCRIPTMANAGER_display=1 below and
//Execute this script and close this file without saving (or change back to
//SCRIPTMANAGER_display=0 before saving.)
module com.gatan.dm.ScriptManager

number DM_version=2

string SCRIPTMANAGER_sScriptsListName="ScriptFiles.txt"
number SCRIPTMANAGER_display=0
number SCRIPTSMANAGER_echo=0
number SCRIPTSMANAGER_replace=1

number PANELLIST_echo=0
number TECHLIST_echo=0

interface PanelProto
{
	void display(object self);//Defined in widget
	object addListener(object self);
	object removeListener(object self);
	void setPanelPosition(object self,string sName,number wX,number wY);
	string getTitle(object self);
	void setTitle(object self,string sTitle);
	void readScriptList(object self);
}

class PanelObjectList:ObjectList
{	

	PanelObjectList(object self)
	{
	}
	
	~PanelObjectList(object self)
	{
		if(PANELLIST_echo)result("Deconstructing panel list.\n");
		number nPanels=self.sizeOfList()
		result(nPanels+" still in list\n");
		//foreach(object panel;self)
		}
	
	object updateMenu(object self)
	{		
		object menuB=getMenuBar()
		if(!menuB.scriptObjectIsValid())return self
		
		object windowM=findMenuItemByName(menuB,"Window")
		if(!windowM.scriptObjectIsValid())return self
		
		object panelM=findMenuItemByName(windowM,"Panels")
		if(panelM.scriptObjectIsValid())panelM.clearMenuItems()
		if(PANELLIST_echo)result("# of panels: "+self.sizeOfList()+"\n")
		foreach(object panel;self)
		{
			string sName=panel.getName()
			string sTitle=panel.getTitle()
			string sScript="getScriptMngr().togglePanel(\""+sName+"\")\n"
			addScriptToMenu(sScript,sTitle,"Window","Panels",0)
			if(PANELLIST_echo)result("Adding panel "+sName+" to menu.\n")
		}
		return self
	}

	TagGroup getPanelTags(object self,string sName)
	{
		TagGroup itemTag
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Found panel "+sName+"\n");		
				TagGroup globalTag=getPersistentTagGroup()
				TagGroup scriptMngrTag
				if(globalTag.tagGroupDoesTagExist("Script Management"))
					globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)				
				else
				{
					globalTag.tagGroupCreateNewLabeledTag("Script Management")		
					scriptMngrTag=newTagGroup();
					globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag);
				}

				TagGroup panelsTag;
				if(scriptMngrTag.tagGroupDoesTagExist("Panels"))
					scriptMngrTag.tagGroupGetTagAsTagGroup("Panels",panelsTag)	
				else
				{		
					scriptMngrTag.tagGroupCreateNewLabeledTag("Panels")		
					panelsTag=newTagGroup();
					scriptMngrTag.tagGroupSetTagAsTagGroup("Panels",panelsTag)
				}

				//
				TagGroup winPostList
				number wX=20,wY=60
				if(panelsTag.tagGroupDoesTagExist(sName))
					panelsTag.tagGroupGetTagAsTagGroup(sName,itemTag)
				else
				{
					panelsTag.tagGroupCreateNewLabeledTag(sName)
					itemTag=newTagGroup()			
					panelsTag.tagGroupSetTagAsTagGroup(sName,itemTag);
				}
				break
			}
		}
		return itemTag
	}
	
	void setDisplayed(object self,string sName,number disp)
	{
		TagGroup itemTag=self.getPanelTags(sName)
		itemTag.tagGroupSetTagAsNumber("displayed",disp)
	}

	number getDisplayed(object self,string sName)
	{
		TagGroup itemTag=self.getPanelTags(sName)
		number disp;itemTag.tagGroupGetTagAsNumber("displayed",disp)
		return disp
	}
	
	void setPosition(object self,string sName,number wX,number wY)
	{
		TagGroup itemTag=self.getPanelTags(sName)
		TagGroup winPosList=newTagList()
		winPosList.tagGroupInsertTagAsNumber(infinity(),wX)//X
		winPosList.tagGroupInsertTagAsNumber(infinity(),wY)//Y
		itemTag.tagGroupSetTagAsTagGroup("window position",winPosList)
	}

	void getPosition(object self,string sName,number &wX,number &wY)
	{
		TagGroup itemTag=self.getPanelTags(sName)
		TagGroup winPosList
		number disp;itemTag.tagGroupGetTagAsTagGroup("window position",winPosList)
		winPosList.tagGroupGetIndexedTagAsNumber(0,wX)//X
		winPosList.tagGroupGetIndexedTagAsNumber(1,wY)//Y
	}
	
	string getTitle(object self,string sName)
	{
		TagGroup itemTag=self.getPanelTags(sName)
		string sTitle;itemTag.tagGroupGetTagAsString("title",sTitle)
		return sTitle
	}
	//
	void openPanel(object self,string sName)
	{
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Opening panel "+sName+"\n");

				string sTitle=self.getTitle(sName)
				number wX,wY;self.getPosition(sName,wX,wY)
				if(controlDown()){wX=20;wY=60;}

				panel.init().display(sTitle)
				DocumentWindow win=panel.getFrameWindow()
				if(win.windowIsValid())
				{
					win.windowSetFramePosition(wX,wY)
					panel.addListener()
				}
					
				self.setDisplayed(sName,1)
				break
			}
		}
	}
	
	//
	void capturePanel(object self,string sName)
	{
		if(PANELLIST_echo)result("Capturing panel "+sName+"\n")
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Found panel "+sName+"\n");		
				DocumentWindow win=panel.getFrameWindow()
				if(win.windowIsValid())
				{
					number wX,wY;win.windowGetFramePosition(wX,wY)
					self.setPosition(sName,wX,wY)
					if(PANELLIST_echo)
						result("Panel "+sName+" position: "+wX+", "+wY+"\n")					
					self.setDisplayed(sName,1)
				}
				else
					self.setDisplayed(sName,0)						
				break
			}
		}
	}

	//
	void closePanel(object self,string sName)
	{
		if(PANELLIST_echo)result("Closing panel "+sName+"\n")
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Found panel "+sName+"\n");
				self.capturePanel(sName)
				DocumentWindow win=panel.getFrameWindow()
				if(win.windowIsValid())
				{
					panel.removeListener()
					win.windowClose(0)
				}
				self.setDisplayed(sName,0)
				break
			}
		}
	}

	//
	number getPanel(object self,string sName,object &obj)
	{
		if(PANELLIST_echo)result("Getting panel "+sName+"\n")
		number res=0
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Found panel "+sName+"\n");		
				obj=panel
				res=1
				break
			}
		}
		return res
	}
		
	//
	void togglePanel(object self,string sName)
	{
		if(PANELLIST_echo)result("Toggling panel "+sName+"\n")
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{
				number disp=self.getDisplayed(sName)
				if(disp)
					self.closePanel(sName)
				else
					self.openPanel(sName)
			}
		}
	}
	
	number registerPanel(object self,object obj,string sName,string sTitle,number disp)
	{
		obj.setName(sName)
		obj.setTitle(sTitle)
		if(PANELLIST_echo)result("Created panel "+sName+"\n");		
		self.addObjectToList(obj)
		
		TagGroup itemTag=self.getPanelTags(sName)
		
		//Always save new value.
		number id=obj.scriptObjectGetID()
		if(!itemTag.tagGroupDoesTagExist("ID"))
			itemTag.tagGroupCreateNewLabeledTag("ID")
		itemTag.tagGroupSetTagAsNumber("ID",id)

		//Leave previous value if available.
		if(!itemTag.tagGroupDoesTagExist("title"))
		{
			itemTag.tagGroupCreateNewLabeledTag("title")
			itemTag.tagGroupSetTagAsString("title",sTitle)
			if(PANELLIST_echo)result("added title "+sTitle+"\n");		
		}
		
		//Leave previous value if available.
		if(!itemTag.tagGroupDoesTagExist("displayed"))
		{
			itemTag.tagGroupCreateNewLabeledTag("displayed")
			itemTag.tagGroupSetTagAsNumber("displayed",disp)
		}
		
		//Leave previous value if available.
		if(!itemTag.tagGroupDoesTagExist("window position"))
		{
			itemTag.tagGroupCreateNewLabeledTag("window position")
			TagGroup winPosList=newTagList()
			winPosList.tagGroupInsertTagAsNumber(infinity(),20)//X
			winPosList.tagGroupInsertTagAsNumber(infinity(),60)//Y
			itemTag.tagGroupSetTagAsTagGroup("window position",winPosList)
		}		

		if(self.getDisplayed(sName))self.openPanel(sName);
		return id
	}

	number unregisterPanel(object self,string sName)
	{
		foreach(object panel;self)
		{
			if(panel.getName()==sName)
			{	
				if(PANELLIST_echo)result("Found panel "+sName+"\n");		
				self.removeObjectFromList(panel)
				string sTitle=panel.getTitle()
				removeScriptFromMenu(sTitle,"Window","Panels")
				if(PANELLIST_echo)result("Removed script "+sName+"\n");		
				break
			}
		}
	}



	number registerPalette(object self,object obj,string sName,string sTitle,number disp)
	{
		number tok=registerScriptPalette(obj.init(),sName,sTitle)
		number id=obj.scriptObjectGetID()
		TagGroup scriptMngrTag;
		TagGroup globalTag=getPersistentTagGroup()
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)		
		else
		{		
			globalTag.tagGroupCreateNewLabeledTag("Script Management")		
			scriptMngrTag=newTagGroup();
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag)
		}

		TagGroup paletteTag;
		if(scriptMngrTag.tagGroupDoesTagExist("Palettes"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Palettes",paletteTag)		
		else
		{		
			scriptMngrTag.tagGroupCreateNewLabeledTag("Palettes")	
			paletteTag=newTagGroup();
			scriptMngrTag.tagGroupSetTagAsTagGroup("Palettes",paletteTag)
		}

		if(!paletteTag.tagGroupDoesTagExist(sName))
			paletteTag.tagGroupCreateNewLabeledTag(sName);
			
		TagGroup itemTag=newTagGroup();
		if(DM_version==1)
		{
			itemTag.tagGroupCreateNewLabeledTag("Token")
			itemTag.tagGroupSetTagAsNumber("Token",tok)
		}

		itemTag.tagGroupCreateNewLabeledTag("title")
		itemTag.tagGroupSetTagAsString("title",sTitle)

		itemTag.tagGroupCreateNewLabeledTag("ID")
		itemTag.tagGroupSetTagAsNumber("ID",id)

		paletteTag.tagGroupSetTagAsTagGroup(sName,itemTag);

		if(disp)
			openGadgetPanel(sTitle);
		return tok
	}
	
	//
	string listPanels(object self)
	{
		if(PANELLIST_echo)result("Listing panels:\n")
		string s=""
		foreach(object panel;self)
		{
			s+=panel.getName()+"\n"
		}
		return s
	}
}

//
interface TechniqueProto
{
	string getTitle(object self);
	object setMode(object self,number x);
	object load(object self);
	void setValues(object self);
}

class TechniqueList
{

	//This is just used to bridge between the main scope and the local scope
	//of the functions below.
	object taskObj;
	object getTaskObj(object self){return taskObj;}
	object setTaskObj(object self,object obj){return taskObj=obj;}
	
	//
	void loadTasks(object self)
	{
		result("----\n")
		TagGroup scriptMngrTag;
		TagGroup globalTag=getPersistentTagGroup()
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)
		else return

		TagGroup techsTag;
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)		
		else return

		if(scriptMngrTag.tagGroupDoesTagExist("Groups"))
			scriptMngrTag.tagGroupDeleteTagWithLabel("Groups")
		scriptMngrTag.tagGroupCreateNewLabeledTag("Groups")		
		TagGroup groupsTag=newTagGroup()
		scriptMngrTag.tagGroupSetTagAsTagGroup("Groups",groupsTag)		

		number nTechs=techsTag.tagGroupCountTags()
		for(number i=0;i<nTechs;++i)
		{
			string sTechTitle=techsTag.tagGroupGetTagLabel(i)
			TagGroup techTag
			techsTag.tagGroupGetTagAsTagGroup(sTechTitle,techTag)
				
			//skip tech if no tasks
			TagGroup tasksTag
			if(techTag.tagGroupDoesTagExist("Tasks"))
				techTag.tagGroupGetTagAsTagGroup("Tasks",tasksTag)
			else
				continue
			number nTasks=tasksTag.tagGroupCountTags()
			if(nTasks<1)continue

			//get icon
			string sIconPath;techTag.tagGroupGetTagAsString("icon path",sIconPath)
			number sizeXp=75,sizeYp=75
			image iconImg:=rgbImage("icon",4,sizeXp,sizeYp);//
			rgbimage rimg
			number gotImage=0
			if(doesFileExist(sIconPath))
			{
				image img:=openImage(sIconPath)
				number sizeX,sizeY;getSize(img,sizeX,sizeY)
				rimg:=rgbImage("col",3,sizeX,sizeY)

				if((!gotImage)&&img.isRGBDataType(3))
				{
					rImg=rgba(red(img),green(img),blue(img),255)
					gotImage=1
				}
				if((!gotImage)&&img.isRGBDataType(4))
				{
					rImg=img
					gotImage=1
				}

				if(!gotImage)
				{
					number Imax=red(img).max(),Imin=red(img).min()
					
					red(rimg)=Imin+256*(red(img)-Imin)/(Imax-Imin)
					green(rimg)=Imin+256*(red(img)-Imin)/(Imax-Imin)
					blue(rimg)=Imin+256*(red(img)-Imin)/(Imax-Imin)
					gotImage=1
				}
				if(gotImage)
				{
					number xFac=sizeX/sizeXp,yFac=sizeY/sizeYp
					red(iconImg)=red(rImg).warp(xFac*icol,yFac*irow)
					green(iconImg)=green(rImg).warp(xFac*icol,yFac*irow)
					blue(iconImg)=blue(rImg).warp(xFac*icol,yFac*irow)
					alpha(iconImg)=255
				}
			}
			if(!gotImage)
			{
				iconImg=RGBA(icol,irow,iradius,255)
			}
			object tech=createTechnique(sTechTitle,iconImg);
			//add tasks
			TagGroup taskTag
			for(number j=0;j<nTasks;++j)
			{	
				tasksTag.tagGroupGetIndexedTagAsTagGroup(j,taskTag)
				string sClass;taskTag.tagGroupGetTagAsString("class",sClass)
				
				number isPlugin;taskTag.tagGroupGetTagAsNumber("is plug-in",isPlugin)

				if(!isPlugin)
				{
					string sScript="object obj=getScriptMngr().setTaskObj(alloc("+sClass+"));\n"		
					executeScriptString(sScript);
					self.getTaskObj().setMode(3).load().init()//.setValues()
				}
				
				string sTitle;taskTag.tagGroupGetTagAsString("title",sTitle)
				
				number taskID
				if(isPlugin)
					taskID=getWorkflowTaskID(sTitle)
				else
					taskID=registerWorkflowTask(self.gettaskObj(),sTitle)

				number essent;taskTag.tagGroupGetTagAsNumber("essential",essent)
				number disp;taskTag.tagGroupGetTagAsNumber("display",disp)
							
				if(!isPlugin)
				{
					number objID=scriptObjectGetID(self.gettaskObj())
					if(!taskTag.tagGroupDoesTagExist("object ID"))
						taskTag.tagGroupCreateNewLabeledTag("object ID")
					taskTag.tagGroupSetTagAsNumber("object ID",objID)
				}
				
				addWorkflowTask(tech,taskID,essent,disp)

			}

			//Get group for tech
			string sGroup;techTag.tagGroupGetTagAsString("group",sGroup)
			number newGroup=1;
			number groupID
			if(groupsTag.tagGroupDoesTagExist(sGroup))
				groupsTag.tagGroupGetTagAsNumber(sGroup,groupID)
			else
			{
				if(TECHLIST_echo)result("Registering group "+sGroup+"\n")
				groupID=registerTechniqueGroup(sGroup)
				groupsTag.tagGroupSetTagAsNumber(sGroup,groupID)
			}
			addTechniqueToGroup(tech,groupID)
		}
	}

	//
	void unloadTasks(object self)
	{
		TagGroup scriptMngrTag;
		TagGroup globalTag=getPersistentTagGroup()
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)
		else return

		TagGroup techsTag;
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)		
		else return

		if(scriptMngrTag.tagGroupDoesTagExist("Groups"))
		{
			TagGroup groupsTag
			scriptMngrTag.tagGroupGetTagAsTagGroup("Groups",groupsTag)		
			number nGroups=groupsTag.tagGroupCountTags()
			for(number i=0;i<nGroups;++i)
			{
				number groupID;groupsTag.tagGroupGetIndexedTagAsNumber(i,groupID)
				removeTechniqueGroup(groupID)
			}
			scriptMngrTag.tagGroupDeleteTagWithLabel("Groups")
		}

	}


	//
	number getTask(object self,string sName,object &obj)
	{
		if(TECHLIST_echo)result("Getting task "+sName+"\n")
		number res=0

		TagGroup scriptMngrTag;
		TagGroup globalTag=getPersistentTagGroup()
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)
		else return res

		TagGroup techsTag;
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)		
		else return res

		number nTechs=techsTag.tagGroupCountTags()
		for(number i=0;i<nTechs;++i)
		{
			string sTechTitle=techsTag.tagGroupGetTagLabel(i)
			TagGroup techTag
			techsTag.tagGroupGetTagAsTagGroup(sTechTitle,techTag)

			//skip tech if no tasks
			TagGroup tasksTag
			if(techTag.tagGroupDoesTagExist("Tasks"))
				techTag.tagGroupGetTagAsTagGroup("Tasks",tasksTag)
			else
				continue
				
			if(!tasksTag.tagGroupDoesTagExist(sName))
				continue
			
			TagGroup taskTag;tasksTag.tagGroupGetTagAsTagGroup(sName,taskTag)
			
			number objID;taskTag.tagGroupGetTagAsNumber("object ID",objID)
			
			obj=getScriptObjectFromID(objID)
			if(!scriptObjectIsValid(obj))obj=null;
			else res=1;
				
			break;
		}
			
		return res
	}
	//
	void registerTechnique(object self,string sName,string sTitle,string sGroup,string sIconPath)
	{
		if(TECHLIST_echo)result("Registering technique "+sName+"\n");		
		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)				
		else
		{
			globalTag.tagGroupCreateNewLabeledTag("Script Management")		
			scriptMngrTag=newTagGroup();
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag);
		}

		TagGroup techsTag
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
		{
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)	
		}
		else
		{
			scriptMngrTag.tagGroupCreateNewLabeledTag("Techniques")	
			techsTag=newTagGroup()
			scriptMngrTag.tagGroupSetTagAsTagGroup("Techniques",techsTag)	
		}
			
		TagGroup techTag
		if(techsTag.tagGroupDoesTagExist(sName))
			techsTag.tagGroupDeleteTagWithLabel(sName)

		techsTag.tagGroupCreateNewLabeledTag(sName)
		techTag=newTagGroup()
		techsTag.tagGroupSetTagAsTagGroup(sName,techTag)

		techTag.tagGroupCreateNewLabeledTag("title")
		techTag.tagGroupSetTagAsString("title",sTitle)
		if(TECHLIST_echo)result("added title "+sTitle+"\n");		

		techTag.tagGroupCreateNewLabeledTag("icon path")
		techTag.tagGroupSetTagAsString("icon path",sIconPath)
		if(TECHLIST_echo)result("added icon path "+sIconPath+"\n");		

		techTag.tagGroupCreateNewLabeledTag("group")
		techTag.tagGroupSetTagAsString("group",sGroup)
		if(TECHLIST_echo)result("added group "+sGroup+"\n");		
		
	}

	//
	void registerTask(object self,string sName,string sClass,number isPlugin,string sTitle,string sTech,number essent,number disp)
	{
		if(TECHLIST_echo)result("Registering task "+sName+"\n");		
		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)				
		else
		{
			globalTag.tagGroupCreateNewLabeledTag("Script Management")		
			scriptMngrTag=newTagGroup();
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag);
		}

		TagGroup techsTag
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
		{
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)	
		}
				
		TagGroup techTag
		if(!techsTag.tagGroupDoesTagExist(sTech))return
		
		techsTag.tagGroupGetTagAsTagGroup(sTech,techTag)
		TagGroup tasksTag
		if(techTag.tagGroupDoesTagExist("Tasks"))
			techTag.tagGroupGetTagAsTagGroup("Tasks",tasksTag)
		else
		{
			techTag.tagGroupCreateNewLabeledTag("Tasks");
			tasksTag=newTagGroup()
			techTag.tagGroupSetTagAsTagGroup("Tasks",tasksTag)
		}
		if(tasksTag.tagGroupDoesTagExist(sName))
			tasksTag.tagGroupDeleteTagWithLabel(sName)
		
		tasksTag.tagGroupCreateNewLabeledTag(sName)
		TagGroup taskTag=newTagGroup()
		tasksTag.tagGroupSetTagAsTagGroup(sName,taskTag)	
			
		taskTag.tagGroupCreateNewLabeledTag("class")
		taskTag.tagGroupSetTagAsString("class",sClass)

		taskTag.tagGroupCreateNewLabeledTag("is plug-in")
		taskTag.tagGroupSetTagAsNumber("is plug-in",isPlugin)

		taskTag.tagGroupCreateNewLabeledTag("title")
		taskTag.tagGroupSetTagAsString("title",sTitle)
		
		taskTag.tagGroupCreateNewLabeledTag("essential")
		taskTag.tagGroupSetTagAsNumber("essential",essent)
		
		taskTag.tagGroupCreateNewLabeledTag("display")
		taskTag.tagGroupSetTagAsNumber("display",disp)
	}
	
}

class LibInfoDialog:uiFrame
{
	object source
	TagGroup scriptTag
	TagGroup pathTag
	
	LibInfoDialog(object self){}
	
	void nameChanged(object self,TagGroup fieldTag)
	{
		string sName=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("name",sName)
		return
	}
	
	void pathChanged(object self,TagGroup fieldTag)
	{
		string sPath=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("path",sPath)
	}
	
	void setPath(object self)
	{
		string sPath;if(!OpenDialog(sPath))return
		scriptTag.tagGroupSetTagAsString("path",sPath)
		pathTag.dlgValue(sPath)
	}

	object init(object self,object src,TagGroup sTag)
	{
		source=src
		scriptTag=sTag
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Library Info",dlgItems)
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)
		
		TagGroup fieldTag,groupTag
		groupTag=dlgCreateStringField("name",fieldTag,sName,25)		
		fieldTag.dlgIdentifier("name").dlgChangedMethod("nameChanged")
		dlgItems.dlgAddElement(groupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		pathTag=dlgCreateStringField(sPath,50).dlgChangedMethod("pathChanged");
		TagGroup setPathTag=dlgCreatePushButton("Set Path","setPath").dlgIdentifier("set path")
		dlgItems.dlgAddElement(dlgGroupItems(pathTag,setPathTag)).dlgTableLayout(2,1,0).dlgAnchor("West")
		
		dlgTags.dlgTableLayout(1,6,0);
		self.super.init(dlgTags)
		return self
	}
}

//
class MenuItemInfoDialog:uiFrame
{
	object source
	TagGroup scriptTag
	TagGroup pathTag
	
	MenuItemInfoDialog(object self){}
	
	void nameChanged(object self,TagGroup fieldTag)
	{
		string sName=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("name",sName)
		return
	}
	
	void labelChanged(object self,TagGroup fieldTag)
	{
		string sLabel=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("label",sLabel)
		return
	}
	
	void pathChanged(object self,TagGroup fieldTag)
	{
		string sPath=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("path",sPath)
	}
	
	void menuChanged(object self,TagGroup fieldTag)
	{
		string sMenu=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("menu",sMenu)
	}

	void submenuChanged(object self,TagGroup fieldTag)
	{
		string sSubmenu=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("submenu",sSubmenu)
	}

	void setPath(object self)
	{
		string sPath;if(!OpenDialog(sPath))return
		scriptTag.tagGroupSetTagAsString("path",sPath)
		pathTag.dlgValue(sPath)
	}

	object init(object self,object src,TagGroup sTag)
	{
		source=src
		scriptTag=sTag
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Menu Item Info",dlgItems)
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sLabel;scriptTag.tagGroupGetTagAsString("label",sLabel)
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)
		string sMenu;scriptTag.tagGroupGetTagAsString("menu",sMenu)
		string sSubmenu;scriptTag.tagGroupGetTagAsString("submenu",sSubmenu)
		
		TagGroup nameTag,nameGroupTag
		nameGroupTag=dlgCreateStringField("name",nameTag,sName,25)		
		nameTag.dlgChangedMethod("nameChanged")
		dlgItems.dlgAddElement(nameGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup labelTag,labelGroupTag
		labelGroupTag=dlgCreateStringField("label",labelTag,sLabel,25)		
		labelTag.dlgChangedMethod("labelChanged")
		dlgItems.dlgAddElement(labelGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup menuTag,menuGroupTag
		menuGroupTag=dlgCreateStringField("menu",menuTag,sMenu,25)		
		menuTag.dlgChangedMethod("menuChanged")
		dlgItems.dlgAddElement(menuGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup submenuTag,submenuGroupTag
		submenuGroupTag=dlgCreateStringField("optional submenu",submenuTag,sSubmenu,25)		
		submenuTag.dlgChangedMethod("submenuChanged")
		dlgItems.dlgAddElement(submenuGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		pathTag=dlgCreateStringField(sPath,50).dlgChangedMethod("pathChanged");
		TagGroup setPathTag=dlgCreatePushButton("Set Path","setPath").dlgIdentifier("set path")
		dlgItems.dlgAddElement(dlgGroupItems(pathTag,setPathTag)).dlgTableLayout(2,1,0).dlgAnchor("West")
		
		dlgTags.dlgTableLayout(1,7,0);
		self.super.init(dlgTags)
		return self
	}
}

//
class WidgetInfoDialog:uiFrame
{
	object source
	TagGroup scriptTag
	
	WidgetInfoDialog(object self){}
	
	void nameChanged(object self,TagGroup fieldTag)
	{
		string sName=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("name",sName)
		return
	}
	
	void titleChanged(object self,TagGroup fieldTag)
	{
		string sTitle=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("title",sTitle)
		return
	}
	
	void classChanged(object self,TagGroup fieldTag)
	{
		string sClass=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("class",sClass)
		return
	}

	void modeChanged(object self,TagGroup fieldTag)
	{
		number x=fieldTag.dlgGetValue()
		if(x)
			scriptTag.tagGroupSetTagAsString("mode","panel")
		else
			scriptTag.tagGroupSetTagAsString("mode","palette")
		return
	}

	void displayChanged(object self,TagGroup fieldTag)
	{
		number x=fieldTag.dlgGetValue()
		scriptTag.tagGroupSetTagAsNumber("display",x)
		return
	}
	
	object init(object self,object src,TagGroup sTag)
	{
		source=src
		scriptTag=sTag
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Panel Info",dlgItems)
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sClass;scriptTag.tagGroupGetTagAsString("class",sClass)
		string sMode;scriptTag.tagGroupGetTagAsString("mode",sMode)
		number disp;scriptTag.tagGroupGetTagAsNumber("display",disp)
		
		TagGroup nameTag,nameGroupTag
		nameGroupTag=dlgCreateStringField("name",nameTag,sName,25)		
		nameTag.dlgChangedMethod("nameChanged")
		dlgItems.dlgAddElement(nameGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup titleTag,titleGroupTag
		titleGroupTag=dlgCreateStringField("title",titleTag,sTitle,25)		
		titleTag.dlgChangedMethod("titleChanged")
		dlgItems.dlgAddElement(titleGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup classTag,classGroupTag
		classGroupTag=dlgCreateStringField("class",classTag,sClass,25).dlgChangedMethod("classChanged");
		classTag.dlgIdentifier("class").dlgChangedMethod("classChanged")
		dlgItems.dlgAddElement(classGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")
				
		TagGroup modeTag
		modeTag=dlgCreateCheckBox("panel",sMode=="panel").dlgChangedMethod("modeChanged");
		dlgItems.dlgAddElement(modeTag).dlgAnchor("West")//.dlgExternalPadding(0,50)

		TagGroup displayTag
		displayTag=dlgCreateCheckBox("display",disp).dlgChangedMethod("displayChanged");
		dlgItems.dlgAddElement(displayTag).dlgAnchor("West")//.dlgExternalPadding(0,50)

		dlgTags.dlgTableLayout(1,8,0);
		self.super.init(dlgTags)
		return self
	}
}

//
class TechniqueInfoDialog:uiFrame
{
	object source
	TagGroup scriptTag,groupTag,classTag
	TagGroup iconPathTag
	
	TechniqueInfoDialog(object self){}
	
	void nameChanged(object self,TagGroup fieldTag)
	{
		string sName=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("name",sName)
		return
	}
	
	void titleChanged(object self,TagGroup fieldTag)
	{
		string sTitle=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("title",sTitle)
		return
	}
	
	void groupChanged(object self,TagGroup fieldTag)
	{
		string sGroup=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("group",sGroup)
		return
	}
			
	void iconPathChanged(object self,TagGroup fieldTag)
	{
		string sPath=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("path",sPath)
	}
	
	void setIconPath(object self)
	{
		string sPath;if(!openDialog(sPath))return
		scriptTag.tagGroupSetTagAsString("path",sPath)
		iconPathTag.dlgValue(sPath)
	}


	object init(object self,object src,TagGroup sTag)
	{
		source=src
		scriptTag=sTag
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Technique Info",dlgItems)
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sGroup;scriptTag.tagGroupGetTagAsString("group",sGroup)
		string sIconPath;scriptTag.tagGroupGetTagAsString("path",sIconPath)
		
		TagGroup nameTag,nameGroupTag
		nameGroupTag=dlgCreateStringField("name",nameTag,sName,25)		
		nameTag.dlgChangedMethod("nameChanged")
		dlgItems.dlgAddElement(nameGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup titleTag,titleGroupTag
		titleGroupTag=dlgCreateStringField("title",titleTag,sTitle,25)		
		titleTag.dlgChangedMethod("titleChanged")
		dlgItems.dlgAddElement(titleGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup groupTag,groupGroupTag
		groupGroupTag=dlgCreateStringField("group",groupTag,sGroup,25);
		groupTag.dlgIdentifier("group").dlgChangedMethod("groupChanged")
		dlgItems.dlgAddElement(groupGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		iconPathTag=dlgCreateStringField(sIconPath,50).dlgChangedMethod("iconPathChanged");
		TagGroup setIconPathTag=dlgCreatePushButton("Set Path","setIconPath").dlgIdentifier("set icon path")
		dlgItems.dlgAddElement(dlgGroupItems(iconPathTag,setIconPathTag)).dlgTableLayout(2,1,0).dlgAnchor("West")
	
		dlgTags.dlgTableLayout(1,11,0);
		self.super.init(dlgTags)
		return self
	}
}

//
class TaskInfoDialog:uiFrame
{
	object source
	TagGroup scriptTag,groupTag,classTag,iconTag
	TagGroup pathTag
	
	TaskInfoDialog(object self){}
	
	void nameChanged(object self,TagGroup fieldTag)
	{
		string sName=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("name",sName)
		return
	}
	
	void classChanged(object self,TagGroup fieldTag)
	{
		string sClass=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("class",sClass)
		return
	}
	
	void pluginChanged(object self,TagGroup fieldTag)
	{
		number x=fieldTag.dlgGetValue()
		scriptTag.tagGroupSetTagAsNumber("is plug-in",x)
		return
	}
		
	void titleChanged(object self,TagGroup fieldTag)
	{
		string sTitle=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("title",sTitle)
		return
	}
		
	void techniqueChanged(object self,TagGroup fieldTag)
	{
		string sTechnique=fieldTag.dlgGetStringValue()
		scriptTag.tagGroupSetTagAsString("technique",sTechnique)
		return
	}
		
	void essentChanged(object self,TagGroup fieldTag)
	{
		number x=fieldTag.dlgGetValue()
		scriptTag.tagGroupSetTagAsNumber("essential",x)
		return
	}

	void displayChanged(object self,TagGroup fieldTag)
	{
		number x=fieldTag.dlgGetValue()
		scriptTag.tagGroupSetTagAsNumber("display",x)
		return
	}
	
	object init(object self,object src,TagGroup sTag)
	{
		source=src
		scriptTag=sTag
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Task Info",dlgItems)
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sClass;scriptTag.tagGroupGetTagAsString("class",sClass)
		number isPlugin;scriptTag.tagGroupGetTagAsNumber("is plug-in",isPlugin)
		string sTech;scriptTag.tagGroupGetTagAsString("technique",sTech)
		number essent;scriptTag.tagGroupGetTagAsNumber("essential",essent)
		number disp;scriptTag.tagGroupGetTagAsNumber("display",disp)
		
		TagGroup nameTag,nameGroupTag
		nameGroupTag=dlgCreateStringField("name",nameTag,sName,25)		
		nameTag.dlgChangedMethod("nameChanged")
		dlgItems.dlgAddElement(nameGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")
		
		TagGroup classTag,classGroupTag
		classGroupTag=dlgCreateStringField("class",classTag,sClass,25).dlgChangedMethod("classChanged");
		classTag.dlgIdentifier("class").dlgChangedMethod("classChanged")
		dlgItems.dlgAddElement(classGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup pluginTag
		pluginTag=dlgCreateCheckBox("plug in (not a script)",isPlugin).dlgChangedMethod("pluginChanged");
		dlgItems.dlgAddElement(pluginTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup titleTag,titleGroupTag
		titleGroupTag=dlgCreateStringField("title",titleTag,sTitle,25)		
		titleTag.dlgChangedMethod("titleChanged")
		dlgItems.dlgAddElement(titleGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup techTag,techGroupTag
		techGroupTag=dlgCreateStringField("technique",techTag,sTech,25);
		techTag.dlgIdentifier("technique").dlgChangedMethod("techniqueChanged")
		dlgItems.dlgAddElement(techGroupTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup essentTag
		essentTag=dlgCreateCheckBox("essential",essent).dlgChangedMethod("essentChanged");
		dlgItems.dlgAddElement(essentTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		TagGroup displayTag
		displayTag=dlgCreateCheckBox("display",disp).dlgChangedMethod("displayChanged");
		dlgItems.dlgAddElement(displayTag).dlgTableLayout(2,1,0).dlgAnchor("West")

		dlgTags.dlgTableLayout(1,9,0);
		self.super.init(dlgTags)
		return self
	}
}

//
class ScriptManager:object
{
	string sScriptsListName
	TagGroup scriptList

	object utilsInfoDlg
	object libraryInfoDlg
	object menuItemInfoDlg
	object widgetInfoDlg
	object techInfoDlg
	object taskInfoDlg
	object panelList;
	object techList
	
	//
	number getFilenameParts(object self,string sPath,string &sDir,string &sName)
	{
		number nChar=len(sPath)
		string c=""
		sDir="";sName=""
		number found=0
		number i
		for(i=nChar-1;i>0;i--)
		{
			c=mid(sPath,i,1)
			if(c=="\\")
			{
				sDir=left(sPath,i) 
				sName=right(sPath,nChar-i-1)

				found=1
				break
				
			}
		
		}	
		return found
	}

	ScriptManager(object self)
	{
		libraryInfoDlg=alloc(LibInfoDialog)
		menuItemInfoDlg=alloc(MenuItemInfoDialog)
		widgetInfoDlg=alloc(WidgetInfoDialog)
		techInfoDlg=alloc(TechniqueInfoDialog)
		taskInfoDlg=alloc(TaskInfoDialog)
		panelList=alloc(PanelObjectList);
		techList=alloc(TechniqueList)

		if(SCRIPTSMANAGER_echo)result("Constructing script manager.\n");
		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag);		
		else
		{		
			globalTag.tagGroupCreateNewLabeledTag("Script Management")	;	
			scriptMngrTag=newTagGroup();
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag);
		}
		number scriptMngrID;

		if(!scriptMngrTag.tagGroupDoesTagExist("Script Manager ID"))
			scriptMngrTag.tagGroupCreateNewLabeledTag("Script Manager ID")

		scriptMngrTag.tagGroupSetTagAsNumber("Script Manager ID",scriptObjectGetID(self))	
		sScriptsListName=SCRIPTMANAGER_sScriptsListName
		self.readScriptList()
	}
	
	object getPanelList(object self){return panelList;}

	number registerPanel(object self,object obj,string sName,string sTitle,number disp)
	{return panelList.registerPanel(obj,sName,sTitle,disp);}
	
	void openPanel(object self,string sName){panelList.openPanel(sName);}
	void closePanel(object self,string sName){panelList.closePanel(sName);}
	void capturePanel(object self,string sName){panelList.capturePanel(sName);}

	number getPanel(object self,string sName,object &obj)
	{return panelList.getPanel(sName,obj);}
	
	void togglePanel(object self,string sName){panelList.togglePanel(sName);}

	void setDisplayed(object self,string sName,number disp){panelList.setDisplayed(sName,disp);}

	number registerPalette(object self,object obj,string sName,string sTitle,number disp)
	{return panelList.registerPalette(obj,sName,sTitle,disp);}
	
	object setTaskObj(object self,object obj){return techList.setTaskObj(obj);}

	void loadTasks(object self){techList.loadTasks();}
	void unloadTasks(object self){techList.unloadTasks();}

	number getTask(object self,string sName,object &obj)
	{return techList.getTask(sName,obj);}

	number countScripts(object self)
	{
		return scriptList.tagGroupCountTags()
	}
	
	//
	number readEntry(object self,string sLine,string &sEntry,number &pos)
	{	
		sEntry=""
		number i=0,res=0
		number L=len(sLine),length=0
		while(i<L)
		{
			string c=mid(sLine,i,1)
			if(asc(c)==9)//tab
			{
				res=1;i++;
				break
			}
			if(asc(c)==13)//cr
			{
				{res=1;i++;}
				break
			}
			sEntry+=c
			length++
			i++
		}
		pos+=i
		return res
	}

	//
	void readSpecScriptList(object self,string sPath)
	{
		scriptList=newTagList()
		if(doesFileExist(sPath))
		{
			if(SCRIPTSMANAGER_echo)result ("Reading script list...\n")
			number nFile=openFileForReading(sPath)
			string s
			number first=1
			while(readfileline(nFile,0,s))
			{
				number L=len(s)
				if(L==0)
					continue
				
				string sInfo
				number pos=0
				number index
				TagGroup scriptTag=newTagGroup()

				//find name
				if(!self.readEntry(right(s,L-pos),sInfo,pos))continue	
				index=scriptTag.tagGroupCreateNewLabeledTag("name")
				scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)
			
				string sType;if(!self.readEntry(right(s,L-pos),sType,pos))continue
				index=scriptTag.tagGroupCreateNewLabeledTag("type")
				scriptTag.tagGroupSetIndexedTagAsString(index,sType)
		
				//library
				if(sType=="library")
				{
					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("path")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					scriptList.tagGroupInsertTagAsTagGroup(infinity(),scriptTag)				
					continue
				}
							
				if(sType=="menu item")
				{
					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("label")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("path")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("menu")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("submenu")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)
					scriptList.tagGroupInsertTagAsTagGroup(infinity(),scriptTag)
					continue
				}

				//widget
				if(sType=="widget")
				{
					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("title")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("class")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("mode")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("display")
					scriptTag.tagGroupSetIndexedTagAsNumber(index,val(sInfo))

					scriptList.tagGroupInsertTagAsTagGroup(infinity(),scriptTag)
					continue
				}

				//technique
				if(sType=="technique")
				{
					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("title")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("group")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("path")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					scriptList.tagGroupInsertTagAsTagGroup(infinity(),scriptTag)
					continue
				}

				//task
				if(sType=="task")
				{
					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("title")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("class")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("is plug-in")
					scriptTag.tagGroupSetIndexedTagAsNumber(index,val(sInfo))

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("technique")
					scriptTag.tagGroupSetIndexedTagAsString(index,sInfo)

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("essential")
					scriptTag.tagGroupSetIndexedTagAsNumber(index,val(sInfo))

					if(!self.readEntry(right(s,L-pos),sInfo,pos))continue
					index=scriptTag.tagGroupCreateNewLabeledTag("display")//open by default
					scriptTag.tagGroupSetIndexedTagAsNumber(index,val(sInfo))

					scriptList.tagGroupInsertTagAsTagGroup(infinity(),scriptTag)
					continue
				}
			}
			closeFile(nfile)
		}
	}

	//
	void readScriptList(object self)
	{
		string sPrefsDir=getApplicationDirectory("preference",0)
		sPrefsDir=pathconcatenate(sPrefsDir,"JEM_files")
		sPrefsDir=pathconcatenate(sPrefsDir,sScriptsListName)
		self.readSpecScriptList(sPrefsDir)
	}
	
	void writeSpecScriptList(object self,string sPath)
	{
		if(doesFileExist(sPath))
			deleteFile(sPath)
		createFile(sPath)
		number nScripts=scriptList.tagGroupCountTags()

		if(SCRIPTSMANAGER_echo)result ("Writing script list...\n")
		//result("# of scripts: "+nScripts+"\n")
		number nFile=openFileForWriting(sPath)
		number i
		for(i=0;i<nScripts;++i)
		{
			TagGroup scriptTag
			scriptList.tagGroupGetIndexedTagAsTagGroup(i,scriptTag)
			
			string sInfo;number xInfo
			scriptTag.tagGroupGetTagAsString("name",sInfo)
			string s=sInfo

			string sType;scriptTag.tagGroupGetTagAsString("type",sType)
			s+="\t"+sType
			
			if(sType=="library")
			{
				scriptTag.tagGroupGetTagAsString("path",sInfo)
				s+="\t"+sInfo
			}

			if(sType=="menu item")
			{
				scriptTag.tagGroupGetTagAsString("label",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("path",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("menu",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("submenu",sInfo);s+="\t"+sInfo
			}

	
			if(sType=="widget")
			{
				scriptTag.tagGroupGetTagAsString("title",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("class",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("mode",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsNumber("display",xInfo);s+="\t"+format(xInfo,"%6.0f")
			}

			if(sType=="technique")
			{
				scriptTag.tagGroupGetTagAsString("title",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("group",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("path",sInfo);s+="\t"+sInfo
			}

			if(sType=="task")
			{
				scriptTag.tagGroupGetTagAsString("title",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsString("class",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsNumber("is plug-in",xInfo);s+="\t"+format(xInfo,"%6.0f")
				scriptTag.tagGroupGetTagAsString("technique",sInfo);s+="\t"+sInfo
				scriptTag.tagGroupGetTagAsNumber("essential",xInfo);s+="\t"+format(xInfo,"%6.0f")
				scriptTag.tagGroupGetTagAsNumber("display",xInfo);s+="\t"+format(xInfo,"%6.0f")
			}
			s+="\n"
			//result(s)
			writeFile(nFile,s)
		}
		closeFile(nfile)
	}
	
	//
	void writeScriptList(object self)
	{
		string sPrefsDir=getApplicationDirectory("preference",0)
		sPrefsDir=pathconcatenate(sPrefsDir,"JEM_files")
		sPrefsDir=pathconcatenate(sPrefsDir,sScriptsListName)
		self.writeSpecScriptList(sPrefsDir)
	}
	
	void setList(object self,number iSel,TagGroup listTag)
	{
		//set script list
		TagGroup itemList
		listTag.tagGroupGetTagAsTagGroup("Items",itemList)
		itemList.tagGroupDeleteAllTags()
		number nItems=itemList.tagGroupCountTags()
		number nScripts=scriptList.tagGroupCountTags()
		if(iSel<0)iSel=0
		if(iSel>nScripts-1)iSel=nScripts-1
		TagGroup selScriptTag=newTagGroup()
		number i
		for(i=0;i<nScripts;++i)
		{
			TagGroup scriptTag
			scriptList.tagGroupGetIndexedTagAsTagGroup(i,scriptTag)
			string sName;scriptTag.tagGroupGetTagAsString("name",sName)
			string sType;scriptTag.tagGroupGetTagAsString("type",sType)
			string s=sName+"          "+sType
			if(iSel==i)
				selScriptTag.tagGroupCopyTagsFrom(scriptTag.tagGroupClone())
			itemList.dlgAddListItem(s,iSel==i)
		}
		//listTag.TagGroupOpenBrowserWindow(0)
	}

	void setLibraryProperties(object self,TagGroup scriptTag)
	{
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		if(!libraryInfoDlg.init(self,sCopy).pose())return
		scriptTag.tagGroupCopyTagsFrom(sCopy)
		self.writeScriptList()
	}

	void setMenuItemProperties(object self,TagGroup scriptTag)
	{
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		if(!menuItemInfoDlg.init(self,sCopy).pose())return
		scriptTag.tagGroupCopyTagsFrom(sCopy)
	}

	void setWidgetProperties(object self,TagGroup scriptTag)
	{
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		if(!widgetInfoDlg.init(self,sCopy).pose())return
		scriptTag.tagGroupCopyTagsFrom(sCopy)
	}

	void setTechniqueProperties(object self,TagGroup scriptTag)
	{
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		if(!techInfoDlg.init(self,sCopy).pose())return
		scriptTag.tagGroupCopyTagsFrom(sCopy)
	}

	void setTaskProperties(object self,TagGroup scriptTag)
	{
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		if(!taskInfoDlg.init(self,sCopy).pose())return
		scriptTag.tagGroupCopyTagsFrom(sCopy)
	}

	void setProperties(object self,number iSel)
	{
		TagGroup scriptTag
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		string sType;scriptTag.tagGroupGetTagAsString("type",sType)
		if(sType=="library")
			self.setLibraryProperties(scriptTag)
		if(sType=="menu item")
			self.setMenuItemProperties(scriptTag)
		if(sType=="widget")
			self.setWidgetProperties(scriptTag)
		if(sType=="technique")
			self.setTechniqueProperties(scriptTag)
		if(sType=="task")
			self.setTaskProperties(scriptTag)
		self.writeScriptList()
	}
	
	number createLibrary(object self,TagGroup &scriptTag)
	{
		//OpenandSetProgressWindow("prefs file...","","")	
		scriptTag=newTagGroup()
		number index
		index=scriptTag.tagGroupCreateNewLabeledTag("name")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Name")

		index=scriptTag.tagGroupCreateNewLabeledTag("type")
		scriptTag.tagGroupSetIndexedTagAsString(index,"library")

		index=scriptTag.tagGroupCreateNewLabeledTag("path")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")
		return libraryInfoDlg.init(self,scriptTag).pose()
	}

	number createMenuItem(object self,TagGroup &scriptTag)
	{
		//OpenandSetProgressWindow("prefs file...","","")	
		scriptTag=newTagGroup()
		number index
		index=scriptTag.tagGroupCreateNewLabeledTag("name")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Name")

		index=scriptTag.tagGroupCreateNewLabeledTag("label")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Label")

		index=scriptTag.tagGroupCreateNewLabeledTag("type")
		scriptTag.tagGroupSetIndexedTagAsString(index,"menu item")

		index=scriptTag.tagGroupCreateNewLabeledTag("path")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("menu")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("submenu")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		return menuItemInfoDlg.init(self,scriptTag).pose()
	}

	number createWidget(object self,TagGroup &scriptTag)
	{
		string sPath
		//OpenandSetProgressWindow("prefs file...","","")	
		scriptTag=newTagGroup()
		number index
		index=scriptTag.tagGroupCreateNewLabeledTag("name")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Name")

		index=scriptTag.tagGroupCreateNewLabeledTag("title")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Title")

		index=scriptTag.tagGroupCreateNewLabeledTag("type")
		scriptTag.tagGroupSetIndexedTagAsString(index,"widget")

		index=scriptTag.tagGroupCreateNewLabeledTag("class")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("mode")
		scriptTag.tagGroupSetIndexedTagAsString(index,"panel")

		index=scriptTag.tagGroupCreateNewLabeledTag("display")
		scriptTag.tagGroupSetIndexedTagAsNumber(index,1)

		return widgetInfoDlg.init(self,scriptTag).pose()
	}

	number createTechnique(object self,TagGroup &scriptTag)
	{
		string sPath
		//OpenandSetProgressWindow("prefs file...","","")	
		scriptTag=newTagGroup()
		number index
		index=scriptTag.tagGroupCreateNewLabeledTag("name")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Name")

		index=scriptTag.tagGroupCreateNewLabeledTag("title")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Title")

		index=scriptTag.tagGroupCreateNewLabeledTag("type")
		scriptTag.tagGroupSetIndexedTagAsString(index,"technique")

		index=scriptTag.tagGroupCreateNewLabeledTag("group")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("path")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		return techInfoDlg.init(self,scriptTag).pose()
	}

	number createTask(object self,TagGroup &scriptTag)
	{
		string sPath
		//OpenandSetProgressWindow("prefs file...","","")	
		scriptTag=newTagGroup()
		number index
		index=scriptTag.tagGroupCreateNewLabeledTag("name")
		scriptTag.tagGroupSetIndexedTagAsString(index,"Name")

		index=scriptTag.tagGroupCreateNewLabeledTag("type")
		scriptTag.tagGroupSetIndexedTagAsString(index,"task")

		index=scriptTag.tagGroupCreateNewLabeledTag("class")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("is plug-in")
		scriptTag.tagGroupSetIndexedTagAsNumber(index,0)

		index=scriptTag.tagGroupCreateNewLabeledTag("title")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("technique")
		scriptTag.tagGroupSetIndexedTagAsString(index,"")

		index=scriptTag.tagGroupCreateNewLabeledTag("essential")
		scriptTag.tagGroupSetIndexedTagAsNumber(index,1)

		index=scriptTag.tagGroupCreateNewLabeledTag("display")
		scriptTag.tagGroupSetIndexedTagAsNumber(index,1)

		return taskInfoDlg.init(self,scriptTag).pose()
	}

	void insertScript(object self,number iSel,TagGroup scriptTag)
	{
		scriptList.tagGroupAddTagGroupAfter(iSel,scriptTag)
		self.writeScriptList()
	}
	
	void insertLibrary(object self,number iSel)
	{
		TagGroup scriptTag
		if(!self.createLibrary(scriptTag))return
		self.insertScript(iSel,scriptTag)
	}

	void insertMenuItem(object self,number iSel)
	{
		TagGroup scriptTag
		if(!self.createMenuItem(scriptTag))return
		self.insertScript(iSel,scriptTag)
	}
	
	void insertWidget(object self,number iSel)
	{
		TagGroup scriptTag
		if(!self.createWidget(scriptTag))return
		self.insertScript(iSel,scriptTag)
	}

	void insertTechnique(object self,number iSel)
	{
		TagGroup scriptTag
		if(!self.createTechnique(scriptTag))return
		self.insertScript(iSel,scriptTag)
	}
	
	void insertTask(object self,number iSel)
	{
		TagGroup scriptTag
		if(!self.createTask(scriptTag))return
		self.insertScript(iSel,scriptTag)
	}
	
	void remove(object self,number iSel)
	{
		scriptList.tagGroupDeleteTagWithIndex(iSel)
		self.writeScriptList()
	}

	//Something odd about tag strings.
	string fixTagString(object self,string s)
	{
		string sRes=""
		number sLen=len(s)
		for(number i=0;i<sLen;++i)
		{
			number c=asc(mid(s,i,1))	
			sRes+=chr(c)
		}
		return sRes
	}

	void installLibrary(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)
		addScriptFileToMenu(sPath,sName,"","",1)
	}

	void installMenuItem(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sLabel;scriptTag.tagGroupGetTagAsString("label",sLabel)
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)
		string sMenu;scriptTag.tagGroupGetTagAsString("menu",sMenu)
		string sSubmenu;scriptTag.tagGroupGetTagAsString("submenu",sSubmenu)
		addScriptFileToMenu(sPath,sLabel,sMenu,sSubmenu,0)
	}

	void installPalette(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sClass;scriptTag.tagGroupGetTagAsString("class",sClass)
		number disp;scriptTag.tagGroupGetTagAsNumber("display",disp)

		//object dlg=scriptObjectGetClassToken(sClass)
		string sScript=""
		//result("vers: "+DM_version+"\n")

		sScript+="{\n"		
		sScript+="	number tok=getScriptMngr().registerPalette(alloc("+sClass+").setMode(1).load(),"+"\""+sName+"\","+"\""+sTitle+"\","+disp+");\n"	
		sScript+="}\n"			
		
		if(SCRIPTSMANAGER_echo)
		{
			result("---------\n")
			result(sScript)
		}
		addScriptToMenu(sScript,sName,"","",1)
		//openGadgetPanel(sName)
	}


	void installPanel(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName);sName=self.fixTagString(sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle);sTitle=self.fixTagString(sTitle)
		string sClass;scriptTag.tagGroupGetTagAsString("class",sClass);sClass=self.fixTagString(sClass)
		number disp;scriptTag.tagGroupGetTagAsNumber("display",disp)
				
		string sScript=""
		sScript+="{\n"		
		sScript+="	number tok=getScriptMngr().registerPanel(alloc("+sClass+").setMode(2).load(),"+"\""+sName+"\","+"\""+sTitle+"\","+disp+");\n"	
		sScript+="}\n"			

		if(SCRIPTSMANAGER_echo)
		{
			result(sScript)
			result("--------------\n")
		}
		addScriptToMenu(sScript,sName+" Panel","","",1)
	}

	void installWidget(object self,TagGroup scriptTag)
	{
		string sMode;scriptTag.tagGroupGetTagAsString("mode",sMode);sMode=self.fixTagString(sMode)		
		if(sMode=="palette")
			self.installPalette(scriptTag)
		if(sMode=="panel")
			self.installPanel(scriptTag)			
	}

	void installTechnique(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle);sTitle=self.fixTagString(sTitle)
		string sGroup;scriptTag.tagGroupGetTagAsString("group",sGroup)
		string sIconPath;scriptTag.tagGroupGetTagAsString("path",sIconPath)

		string sExtIconPath=""
		number nLen=len(sIconPath)
		for(number i=0;i<nLen;++i)
		{
			string c=mid(sIconPath,i,1)
			sExtIconPath+=mid(sIconPath,i,1)
			if(asc(c)==92)
				sExtIconPath+="\\"
		}
		
		techList.registerTechnique(sName,sTitle,sGroup,sExtIconPath)
	}

	void installTask(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle);sTitle=self.fixTagString(sTitle)
		string sClass;scriptTag.tagGroupGetTagAsString("class",sClass)
		number isPlugin;scriptTag.tagGroupGetTagAsNumber("is plug-in",isPlugin)
		string sTech;scriptTag.tagGroupGetTagAsString("technique",sTech)
		number essent;scriptTag.tagGroupGetTagAsNumber("essential",essent)
		number disp;scriptTag.tagGroupGetTagAsNumber("display",disp)

		//object dlg=scriptObjectGetClassToken(sClass)
		techList.registerTask(sName,sClass,isPlugin,sTitle,sTech,essent,disp)
}
	
	void installOneScript(object self,number iSel)
	{
		TagGroup scriptTag
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		string sType;scriptTag.tagGroupGetTagAsString("type",sType)
		if(sType=="library")
			self.installLibrary(scriptTag)
		if(sType=="menu item")
			self.installMenuItem(scriptTag)
		if(sType=="widget")
			self.installWidget(scriptTag)
		if(sType=="technique")
			self.installTechnique(scriptTag)
		if(sType=="task")
			self.installTask(scriptTag)
	}
	
	void installScript(object self,number iSel)
	{
		techList.unloadTasks()
		removeScriptFromMenu("Load Tasks","","")
		self.installOneScript(iSel)
		addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void installAllScripts(object self)
	{
		techList.unloadTasks()
		removeScriptFromMenu("Load Tasks","","")
		number nScripts=scriptList.tagGroupCountTags()
		number i
		for(i=0;i<nScripts;++i)
			self.installOneScript(i)
		addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void installToScript(object self,number iSel)
	{
		number nScripts=scriptList.tagGroupCountTags()
		number i
		for(i=0;i<iSel;++i)
			self.installOneScript(i)
		addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void uninstallLibrary(object self,TagGroup scriptTag)
	{
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		removeScriptFromMenu(sName,"","")
	}
	
	void uninstallMenuItem(object self,TagGroup scriptTag)
	{
		string sLabel;scriptTag.tagGroupGetTagAsString("label",sLabel)
		string sMenu;scriptTag.tagGroupGetTagAsString("menu",sMenu)
		string sSubmenu;scriptTag.tagGroupGetTagAsString("submenu",sSubmenu)
		removeScriptFromMenu(sLabel,sMenu,sSubmenu)
	}
	
	void uninstallPalette(object self,TagGroup scriptTag)
	{
		string sScript=""
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)

		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)			
		else
		{
			scriptMngrTag=newTagGroup()
			globalTag.tagGroupCreateNewLabeledTag("Script Management")
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag)
		}

		TagGroup paletteTag
		if(scriptMngrTag.tagGroupDoesTagExist("Palettes"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Palettes",paletteTag)			
		else
		{
			paletteTag=newTagGroup()
			scriptMngrTag.tagGroupCreateNewLabeledTag("Palettes")
			scriptMngrTag.tagGroupSetTagAsTagGroup("Palettes",paletteTag)
		}

		TagGroup itemTag
		if(paletteTag.tagGroupGetTagAsTagGroup(sName,itemTag))
		{
			if(DM_version==1)
			{
				number tok;
				if(itemTag.tagGroupGetTagAsNumber("Token",tok))
					sScript+="getScriptMngr().unregisterScriptPalette("+format(tok,"%18.0f")+");\n"
			}
			else
				sScript+="getScriptMngr().unregisterScriptPalette(\""+sTitle+"\");\n"
						
			paletteTag.tagGroupDeleteTagWithLabel(sName)
		}
		closeGadgetPanel(sTitle)
		executeScriptString(sScript)
		removeScriptFromMenu(sName,"","")
	}
	
	void uninstallPanel(object self,TagGroup scriptTag)
	{
		string sScript=""
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)			
		else
		{
			scriptMngrTag=newTagGroup()
			globalTag.tagGroupCreateNewLabeledTag("Script Management")
			globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag)
		}

		TagGroup panelsTag
		if(scriptMngrTag.tagGroupDoesTagExist("Panels"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Panels",panelsTag)			
		else
		{
			panelsTag=newTagGroup()
			scriptMngrTag.tagGroupCreateNewLabeledTag("Panels")
			scriptMngrTag.tagGroupSetTagAsTagGroup("Panels",panelsTag)
		}

		TagGroup itemTag
		if(panelsTag.tagGroupGetTagAsTagGroup(sName,itemTag))
		{
			number id;
			if(itemTag.tagGroupGetTagAsNumber("ID",id))
			{
				object obj=getScriptObjectFromID(id)
				if(obj.scriptObjectIsValid())
				{
					panelList.closePanel(sName)
					panelList.unregisterPanel(sName)
				}
				panelsTag.tagGroupDeleteTagWithLabel(sName)				
			}
		}
		removeScriptFromMenu(sName+" Panel","","")
}
	
	void uninstallWidget(object self,TagGroup scriptTag)
	{
		string sScript=""
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sMode;scriptTag.tagGroupGetTagAsString("mode",sMode)

		if(sMode=="palette")
			self.uninstallPalette(scriptTag)
			
		if(sMode=="panel")
			self.uninstallPanel(scriptTag)
	}
	
	void uninstallTechnique(object self,TagGroup scriptTag)
	{
		string sScript=""
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sGroup;scriptTag.tagGroupGetTagAsString("group",sGroup)

		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)			
		else return

		TagGroup techsTag
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)			
		else return
		
		TagGroup techTag
		if(techsTag.tagGroupGetTagAsTagGroup(sName,techTag))
		{
			string sGroup;techTag.tagGroupGetTagAsString("group",sGroup)
			techsTag.tagGroupDeleteTagWithLabel(sName)
		}	
	}
	
	void uninstallTask(object self,TagGroup scriptTag)
	{
		if(SCRIPTSMANAGER_echo)result("---------------------------\n")

		string sScript=""
		string sName;scriptTag.tagGroupGetTagAsString("name",sName)
		string sTitle;scriptTag.tagGroupGetTagAsString("title",sTitle)
		string sTech;scriptTag.tagGroupGetTagAsString("technique",sTech)

		TagGroup globalTag=getPersistentTagGroup()
		TagGroup scriptMngrTag
		if(globalTag.tagGroupDoesTagExist("Script Management"))
			globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)			
		else return

		TagGroup techsTag
		if(scriptMngrTag.tagGroupDoesTagExist("Techniques"))
			scriptMngrTag.tagGroupGetTagAsTagGroup("Techniques",techsTag)			
		else return

		if(SCRIPTSMANAGER_echo)result("Looking for technique "+sTech+"\n")

		TagGroup techTag
		if(techsTag.tagGroupGetTagAsTagGroup(sTech,techTag))
		{
			if(SCRIPTSMANAGER_echo)result("Found technique "+sTech+"\n")
			TagGroup tasksTag
			if(SCRIPTSMANAGER_echo)result("Looking for tasks\n")
			if(techTag.tagGroupDoesTagExist("Tasks"))
				techTag.tagGroupGetTagAsTagGroup("Tasks",tasksTag)			
			else return
			if(SCRIPTSMANAGER_echo)result("Found tasks\n")

			if(SCRIPTSMANAGER_echo)result("Looking for task "+sName+"\n")
			TagGroup taskTag;
			if(tasksTag.tagGroupGetTagAsTagGroup(sName,taskTag))
			{
				if(SCRIPTSMANAGER_echo)result("Uninstalling task "+sName+"\n")
				tasksTag.tagGroupDeleteTagWithLabel(sName)				
				string sGroup;techTag.tagGroupGetTagAsString("group",sGroup)
			}
		}					
	}
	
	void uninstallOneScript(object self,number iSel)
	{
		TagGroup scriptTag
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		string sType;scriptTag.tagGroupGetTagAsString("type",sType)		
		if(sType=="library")
			self.uninstallLibrary(scriptTag)
		if(sType=="menu item")
			self.uninstallMenuItem(scriptTag)
		if((sType=="widget"))
			self.uninstallWidget(scriptTag)
		if(sType=="technique")
			self.uninstallTechnique(scriptTag)
		if(sType=="task")
			self.uninstallTask(scriptTag)
	}

	void uninstallScript(object self,number iSel)
	{
		removeScriptFromMenu("Load Tasks","","")
		techList.unloadTasks()
		self.uninstallOneScript(iSel)
		self.writeScriptList()
		//addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void uninstallAllScripts(object self)
	{
		removeScriptFromMenu("Load Tasks","","")
		techList.unloadTasks()
		number nScripts=scriptList.tagGroupCountTags()
		number i
		for(i=0;i<nScripts;++i)
			self.uninstallOneScript(nScripts-i-1)
		//addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void uninstallFromScript(object self,number iSel)
	{
		number nScripts=scriptList.tagGroupCountTags()
		number i
		for(i=iSel;i<nScripts;++i)
			self.uninstallOneScript(i)
		addScriptToMenu("getScriptMngr().loadTasks()","Load Tasks","","",1)
		panelList.updateMenu()
	}
	
	void exportSet(object self)
	{
		string sDir=getApplicationDirectory(0,0);
		if(!getDirectoryDialog(sDir))return
		number nScripts=scriptList.tagGroupCountTags()
		TagGroup altScriptList=newTagList()
		number i
		TagGroup scriptTag
		result("Exporting set...\n")
		for(i=0;i<nScripts;++i)
		{
			TagGroup scriptTag;scriptList.tagGroupGetIndexedTagAsTagGroup(i,scriptTag)
			string sName;scriptTag.tagGroupGetTagAsString("name",sName)		
			string sType;scriptTag.tagGroupGetTagAsString("type",sType)
			result(sName+"\t"+sType)
			TagGroup altScriptTag=scriptTag.tagGroupClone()

			if((sType=="technique"))
			{
				string sOldPath;altScriptTag.tagGroupGetTagAsString("path",sOldPath)		
				image img:=openImage(sOldPath)
				
				string sFilename,sOldDir
				if(!self.getFilenameParts(sOldPath,sOldDir,sFilename))continue
				string sNewPath=sDir+sFileName
				if(doesFileExist(sNewPath))
					deleteFile(sNewPath)
				img.saveImage(sNewPath)
				altScriptTag.tagGroupSetTagAsString("path",sNewPath)		
				result(sNewPath+"\n")
				//self.installLibrary(scriptTag)
				//scriptTag.tagGroupSetTagAsString("path",sPath)
			}	
			
			if((sType=="library")||(sType=="menu item"))
			{
				string sOldPath;altScriptTag.tagGroupGetTagAsString("path",sOldPath)		
				number nFile=openFileForReading(sOldPath)
				string sScript,sLine
				while(readFileLine(nFile,sLine))
					sScript+=sLine
				closeFile(nFile)
				
				string sFilename,sOldDir
				if(!self.getFilenameParts(sOldPath,sOldDir,sFilename))continue
				string sNewPath=sDir+sFileName
				if(doesFileExist(sNewPath))
					deleteFile(sNewPath)
				createFile(sNewPath)
				nFile=openFileForWriting(sNewPath)
				writeFile(nFile,sScript)
				closeFile(nFile)
				altScriptTag.tagGroupSetTagAsString("path",sNewPath)		
				result(sNewPath+"\n")
			}
			altScriptList.tagGroupInsertTagAsTagGroup(infinity(),altScriptTag)
		}
		TagGroup dupScriptList=scriptList.tagGroupClone()
		scriptList=altScriptList
		string sPath=pathconcatenate(sDir,sScriptsListName)
		result(sPath+"\n")
		self.writeSpecScriptList(sPath)
		scriptList=dupScriptList
	}

	void importSet(object self)
	{
		string sDir=getApplicationDirectory(0,0);
		if(!getDirectoryDialog(sDir))return
		string sPath=pathconcatenate(sDir,sScriptsListName)
		self.readSpecScriptList(sPath)
		number nScripts=scriptList.tagGroupCountTags()
		TagGroup altScriptList=newTagList()
		number i
		TagGroup scriptTag
		result("Importing set...\n")
		for(i=0;i<nScripts;++i)
		{
			TagGroup scriptTag;scriptList.tagGroupGetIndexedTagAsTagGroup(i,scriptTag)
			string sType;scriptTag.tagGroupGetTagAsString("type",sType)
			//result(sType+"\n")
			TagGroup altScriptTag=scriptTag.tagGroupClone()

			if((sType=="library")||(sType=="menu item")||(sType=="technique"))
			{
				string sOldPath;altScriptTag.tagGroupGetTagAsString("path",sOldPath)						
				string sFilename,sOldDir
				if(!self.getFilenameParts(sOldPath,sOldDir,sFilename))continue
				result(sDir+sFileName+"\n")
				string sNewPath=sDir+sFileName
				altScriptTag.tagGroupSetTagAsString("path",sNewPath)		
				//self.installLibrary(scriptTag)
				//scriptTag.tagGroupSetTagAsString("path",sPath)
			}	
			altScriptList.tagGroupInsertTagAsTagGroup(infinity(),altScriptTag)
		}
		scriptList=altScriptList;
		self.writeScriptList()
	}
	
	void openLibrary(object self,TagGroup scriptTag)
	{
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)		
		newScriptWindowFromFile(sPath)
	}

	void openMenuItem(object self,TagGroup scriptTag)
	{
		string sPath;scriptTag.tagGroupGetTagAsString("path",sPath)		
		newScriptWindowFromFile(sPath)
	}

	void openScript(object self,number iSel)
	{
		TagGroup scriptTag
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		string sType;scriptTag.tagGroupGetTagAsString("type",sType)
		if(sType=="library")
			self.openLibrary(scriptTag)
		if(sType=="menu item")
			self.openMenuItem(scriptTag)
	}

	TagGroup getScriptTag(object self,number iSel)
	{
		TagGroup scriptTag
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		return scriptTag
	}

	number moveUp(object self,number iSel)
	{
		TagGroup scriptTag
		if(iSel==0)return 0
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		scriptList.tagGroupDeleteTagWithIndex(iSel)
		scriptList.tagGroupAddTagGroupBefore(iSel-1,scriptTag)		
		self.writeScriptList()
		return 1
	}

	number moveDown(object self,number iSel)
	{
		TagGroup scriptTag
		number nScripts=scriptList.tagGroupCountTags()
		if(iSel>=nScripts)return 0
		scriptList.tagGroupGetIndexedTagAsTagGroup(iSel,scriptTag)
		TagGroup sCopy=newTagGroup()
		sCopy.tagGroupCopyTagsFrom(scriptTag)
		scriptList.tagGroupDeleteTagWithIndex(iSel)
		scriptList.tagGroupAddTagGroupAfter(iSel,scriptTag)		
		self.writeScriptList()
		return 1
	}
	
	number resetAll(object self)
	{
		number res=OKCancelDialog("Reset all scripts?")
		if(res)
		{
			self.uninstallAllScripts()
			self.installAllScripts()
			OKDialog("Scripts have been reset.")
		}
		return 1
	}	
}

//
object scriptMngr;
{
	TagGroup globalTag=getPersistentTagGroup()
	TagGroup scriptMngrTag
	if(globalTag.tagGroupDoesTagExist("Script Management"))
		globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag);		
	else
	{		
		globalTag.tagGroupCreateNewLabeledTag("Script Management")	;	
		scriptMngrTag=newTagGroup();
		globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag);
	}
	number scriptMngrID;
	number found=1
	if(!scriptMngrTag.tagGroupDoesTagExist("Script Manager ID"))
	{
		found=0
		scriptMngrTag.tagGroupCreateNewLabeledTag("Script Manager ID")
	}

	if(found&&(!SCRIPTSMANAGER_replace))
	{
		scriptMngrTag.tagGroupGetTagAsNumber("Script Manager ID",scriptMngrID)
		scriptMngr=getScriptObjectFromID(scriptMngrID)
		if(!scriptMngr.scriptObjectIsValid())found=0
	}
	else 
		scriptMngr=alloc(ScriptManager)
}
object getScriptMngr(){return scriptMngr;}

object resetScriptMngr()
{
	scriptMngr=alloc(ScriptManager)
}

class ScriptDialog:uiFrame
{
	TagGroup listTag
	number top,left,bottom,right
	//DocumentWindow w
	TagGroup position
	TagGroup actionPopup
	
	number getSelection(object self)
	{
		TagGroup itemList
		listTag.tagGroupGetTagAsTagGroup("Items",itemList)
		number nItems=itemList.tagGroupCountTags()
		number i
		for(i=0;i<nItems;++i)
		{
			TagGroup itemTag
			itemList.tagGroupGetIndexedTagAsTagGroup(i,itemTag)
			number selected;itemTag.tagGroupGetTagAsNumber("Selected",selected)
			if(selected==1)return i
		}
		return -1
	}
	
	void setSelection(object self,number iSel)
	{
		getScriptMngr().setList(iSel,listTag)
		listTag.dlgInvalid(1)
	}
		
	void setActions(object self)
	{
		//set action popup
		number iSel=self.getSelection()
		number isEmpty=0;if(iSel<0)isEmpty=1
		
		TagGroup itemList
		actionPopup.tagGroupGetTagAsTagGroup("Items",itemList)
		itemList.tagGroupDeleteAllTags()
		itemList.dlgAddPopupItemEntry("Actions")			
		itemList.dlgAddPopupItemEntry("Insert Library")			
		itemList.dlgAddPopupItemEntry("Insert Menu Item")			
		itemList.dlgAddPopupItemEntry("Insert Widget")
		itemList.dlgAddPopupItemEntry("Insert Technique")
		itemList.dlgAddPopupItemEntry("Insert Task")

		if(isEmpty)
		{
		}
		else
		{	
			TagGroup scriptTag=getScriptMngr().getScriptTag(iSel)
			string sType;scriptTag.tagGroupGetTagAsString("type",sType)
			actionPopup.dlgAddPopupItemEntry("Remove")
			actionPopup.dlgAddPopupItemEntry("Properties")
			if(sType=="library")
			{
				actionPopup.dlgAddPopupItemEntry("Open Script")
			}
			if(sType=="menu item")
			{
				actionPopup.dlgAddPopupItemEntry("Open Script")
			}
			if(sType=="type")
			{
			}
			if(sType=="task")
			{
			}			
			actionPopup.dlgAddPopupItemEntry("Install")
			actionPopup.dlgAddPopupItemEntry("Install All")
			actionPopup.dlgAddPopupItemEntry("Install To")
			actionPopup.dlgAddPopupItemEntry("Uninstall")
			actionPopup.dlgAddPopupItemEntry("Uninstall All")
			actionPopup.dlgAddPopupItemEntry("Uninstall From")
			actionPopup.dlgAddPopupItemEntry("Export Set")
		}
		actionPopup.dlgAddPopupItemEntry("Import Set")
		if(!isEmpty)
			actionPopup.dlgAddPopupItemEntry("Reset All")

		actionPopup.dlgValue(1)
		actionPopup.dlgInvalid(1)

	}

	void setValues(object self)
	{
		number iSel=self.getSelection()
		self.setSelection(iSel)
		self.setActions()
	}

	void insertScript(object self,TagGroup scriptTag)
	{
		number iSel=self.getSelection()
		getScriptMngr().insertScript(iSel,scriptTag)
		self.setSelection(iSel+1)
	}
	
	void insertLibrary(object self)
	{
		TagGroup scriptTag
		if(!getScriptMngr().createLibrary(scriptTag))return
		self.insertScript(scriptTag)
	}

	void insertMenuItem(object self)
	{
		TagGroup scriptTag
		if(!getScriptMngr().createMenuItem(scriptTag))return
		self.insertScript(scriptTag)
	}
	
	void insertWidget(object self)
	{
		TagGroup scriptTag
		if(!getScriptMngr().createWidget(scriptTag))return
		self.insertScript(scriptTag)
	}

	void insertTechnique(object self)
	{
		TagGroup scriptTag
		if(!getScriptMngr().createTechnique(scriptTag))return
		self.insertScript(scriptTag)
	}

	void insertTask(object self)
	{
		TagGroup scriptTag
		if(!getScriptMngr().createTask(scriptTag))return
		self.insertScript(scriptTag)
	}

	void remove(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().remove(iSel)
		self.setSelection(iSel)
	}

	void setProperties(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().setProperties(iSel)
		self.setSelection(iSel)
	}
	
	void openScript(object self)
	{
		TagGroup scriptTag
		number iSel=self.getSelection()
		getScriptMngr().openScript(iSel)
	}

	void installScript(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().installScript(iSel)
	}

	void installAllScripts(object self)
	{
		getScriptMngr().installAllScripts()
	}
	
	void installToScript(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().installToScript(iSel)
	}
		
	void uninstallScript(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().uninstallScript(iSel)
	}

	void uninstallAllScripts(object self)
	{
		getScriptMngr().uninstallAllScripts()
	}

	void uninstallFromScript(object self)
	{
		number iSel=self.getSelection()
		getScriptMngr().uninstallFromScript(iSel)
	}

	void exportSet(object self)
	{
		getScriptMngr().exportSet()
	}

	void importSet(object self)
	{
		getScriptMngr().importSet()
		self.setValues()
	}

	void moveUp(object self)
	{
		number iSel=self.getSelection()
		if(getScriptMngr().moveUp(iSel))self.setSelection(iSel-1)
	}

	void moveDown(object self)
	{
		number iSel=self.getSelection()
		if(getScriptMngr().moveDown(iSel))self.setSelection(iSel+1)
	}
	
	void resetAll(object self)
	{
		//getScriptMngr().resetAll()
		number res=OKCancelDialog("Reset all scripts?")
		if(res)
		{
			getScriptMngr().uninstallAllScripts()
			resetScriptMngr()
			getScriptMngr().installAllScripts()
			OKDialog("Scripts have been reset.")
		}		
	}

	void actionSelected(object self,TagGroup fieldTag)
	{
		TagGroup itemList,itemTag
		fieldTag.tagGroupGetTagAsTagGroup("Items",itemList)
		number n=fieldTag.dlgGetValue()-1
		itemList.tagGroupGetIndexedTagAsTagGroup(n,itemTag)
		string sAction;itemTag.tagGroupGetTagAsString("Label",sAction)
		if(sAction=="Insert Library")self.insertLibrary()
		if(sAction=="Insert Menu Item")self.insertMenuItem()
		if(sAction=="Insert Widget")self.insertWidget()
		if(sAction=="Insert Technique")self.insertTechnique()
		if(sAction=="Insert Task")self.insertTask()
		if(sAction=="Remove")self.remove()
		if(sAction=="Properties")self.setProperties()
		if(sAction=="Open Script")self.openScript()
		if(sAction=="Install")self.installScript()
		if(sAction=="Install All")self.installAllScripts()
		if(sAction=="Install To")self.installToScript()
		if(sAction=="Uninstall")self.uninstallScript()
		if(sAction=="Uninstall All")self.uninstallAllScripts()
		if(sAction=="Uninstall From")self.uninstallFromScript()
		if(sAction=="Export Set")self.exportSet()
		if(sAction=="Import Set")self.importSet()
		if(sAction=="Reset All")self.resetAll()
		self.setActions()
	}
	
	void listChanged(object self,TagGroup fieldTag)
	{
		self.setActions()
	}
	
	tagGroup newItemTagGroup(object self,string sLabel,string sVal)
	{
		TagGroup itemTag=NewTagGroup()
		
		number index
		index=itemTag.tagGroupCreateNewLabeledTag("Label")
		itemTag.tagGroupSetIndexedTagAsString(index,sLabel)

		index=itemTag.tagGroupCreateNewLabeledTag("Enabled")
		itemTag.tagGroupSetIndexedTagAsNumber(index,1)
		return itemTag
	}
	
	ScriptDialog(object self)
	{
		//getScriptMngr().readScriptList()
	}
	
	object init(object self,number create)
	{	
		TagGroup dlgItems,dlgTags=dlgCreateDialog("Scripts",dlgItems)

		listTag=dlgCreateList("setList",50,30).dlgIdentifier("list").dlgChangedMethod("listChanged")

		dlgItems.dlgAddElement(listTag)
		
		//
		TagGroup itemList
		actionPopup=dlgCreatePopup(itemList).dlgIdentifier("action").dlgChangedMethod("actionSelected")
		itemList.dlgAddPopupItemEntry("Actions",1)			
		itemList.dlgAddPopupItemEntry("Insert Library",1)			
		itemList.dlgAddPopupItemEntry("Insert Menu Item",1)			
		itemList.dlgAddPopupItemEntry("Insert Widget",1)			
		itemList.dlgAddPopupItemEntry("Insert Technique",1)			
		itemList.dlgAddPopupItemEntry("Insert Task",1)			
		itemList.dlgAddPopupItemEntry("Remove",1)			
		itemList.dlgAddPopupItemEntry("Properties",1)			
		itemList.dlgAddPopupItemEntry("Open Script",1)			
		itemList.dlgAddPopupItemEntry("Install",1)			
		itemList.dlgAddPopupItemEntry("Install All",1)			
		itemList.dlgAddPopupItemEntry("Install To",1)			
		itemList.dlgAddPopupItemEntry("Uninstall",1)			
		itemList.dlgAddPopupItemEntry("Uninstall All",1)			
		itemList.dlgAddPopupItemEntry("Uninstall From",1)			
		itemList.dlgAddPopupItemEntry("Export Set",1)			
		itemList.dlgAddPopupItemEntry("Import Set",1)			
		itemList.dlgAddPopupItemEntry("Reset All",1)			
		dlgItems.dlgAddElement(actionPopup)

		//TagGroup insertBeforeTag=dlgCreatePushButton("Insert Before","insertBefore").dlgIdentifier("insert before")

		TagGroup moveUpTag=dlgCreatePushButton("Move Up","moveUp").dlgIdentifier("move up")
		TagGroup moveDownTag=dlgCreatePushButton("Move Down","moveDown").dlgIdentifier("move down")
		//TagGroup resetTag=dlgCreatePushButton("Reset","reset").dlgIdentifier("reset")
		dlgItems.dlgAddElement(dlgGroupItems(moveUpTag,moveDownTag).dlgTableLayout(2,1,0))

		dlgTags.dlgTableLayout(1,4,0);
		position=dlgBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		position=dlgTags.dlgPosition(position);
	
		self.super.init(dlgTags)
		return self
	}

	void AboutToCloseDocument(object self)
	{
		getScriptMngr().writeScriptList()	
	}	
}	

number getPalette(string sName,object &obj)
{
	number res=0
	if(SCRIPTSMANAGER_echo)result("Getting palette "+sName+"\n")
	TagGroup globalTag=getPersistentTagGroup()
	TagGroup scriptMngrTag
	if(globalTag.tagGroupDoesTagExist("Script Management"))
		globalTag.tagGroupGetTagAsTagGroup("Script Management",scriptMngrTag)			
	else
	{
		scriptMngrTag=newTagGroup()
		globalTag.tagGroupCreateNewLabeledTag("Script Management")
		globalTag.tagGroupSetTagAsTagGroup("Script Management",scriptMngrTag)
	}

	TagGroup paletteTag
	if(scriptMngrTag.tagGroupDoesTagExist("Palettes"))
		scriptMngrTag.tagGroupGetTagAsTagGroup("Palettes",paletteTag)			
	else
	{
		paletteTag=newTagGroup()
		scriptMngrTag.tagGroupCreateNewLabeledTag("Palettes")
		scriptMngrTag.tagGroupSetTagAsTagGroup("Palettes",paletteTag)
	}

	TagGroup itemTag;
	if(paletteTag.tagGroupGetTagAsTagGroup(sName,itemTag))
	{
		number id
		if(itemTag.tagGroupGetTagAsNumber("ID",id))
		if(SCRIPTSMANAGER_echo)result("Found palette ID:  "+id+"\n")
		obj=getScriptObjectFromID(id)
		if(getScriptMngr().scriptObjectIsValid())
		{
			res=1
			if(SCRIPTSMANAGER_echo)result("Palette is valid.\n")
		}
		else
		{
			if(SCRIPTSMANAGER_echo)result("Palette is not valid.\n")
		}
	}
	return res
}

if(SCRIPTMANAGER_display)
{	
	object dlg=alloc(ScriptDialog).init(1)
	dlg.display("Scripts")
	dlg.setValues()
}

