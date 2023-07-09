/*
P. Ahrenkiel-2020
JEM_Dialog is parent class for making dialogs.
The TagGroup dataTags contains tags with data for the various dialog elements.
This is copied by reference from the inherited class.
There is no way to determine which button was pressed after the fact without using
BevelButton, and I don't know how to make those work like standard buttons, so you have to provide
a separate method for every button.
*/
module com.gatan.dm.JEM_Widget
uses com.gatan.dm.ScriptManager

number JEM_Widget_echo=0


class PanelListen
{
	object source
	PanelListen(object self)
	{
		result("PanelListen object "+self.ScriptObjectGetId()+" created.\n"); 
	}

	~PanelListen( object self )
	{
		Result("PanelListen object "+self.ScriptObjectGetId()+" removed.\n");
	}

	object setSource(object self,object o)
	{source=o;return self;}
 

	void onMoveOrSize(object self,number flags,DocumentWindow win)
	{
		//result("window moved\n")
		number wT,wL,wB,wR
		win.windowGetFrameBounds(wT,wL,wB,wR)
		string sName=source.getName()
		//getPanelList().setPanelPosition(sName,wT,wL)
	}
}

//
class AppClosingListen
{
	number selfID
	object source
	AppClosingListen(object self) 
	{
	}
		
	~AppClosingListen( object self )
	{
	}

	void setSelfID(object self,number ID){selfID=ID;}
	void setSource(object self,object src)
	{
		source=src;
	}
	
	void onAppClosing(object self,number flags,object app)
	{
	
		string sName=source.getName()
		getScriptMngr().capturePanel(sName)
	}
	
	void remove(object self)
	{
		applicationRemoveEventListener(selfID)
	}
}


class JEM_Widget:JEM_Dialog
{
	number mode//0: nothing; 1: palette; 2: panel; 3: task
	number wasDisplayed
	object listener
	number listenerID
	image testImg
	string sTitle

	JEM_Widget(object self)
	{
		mode=0
		wasDisplayed=0
		sTitle="widget"
	}

	void setTitle(object self,string s)
	{
		sTitle=s
	}
	
	string getTitle(object self)
	{
		return sTitle
	}

	object addListener(object self)
	{			
		object listener=alloc(AppClosingListen)
		listener.setSource(self)
		string sMessageMap="application_about_to_close:onAppClosing"
		listenerID=applicationAddEventListener(listener,sMessageMap)
		listener.setSelfID(listenerID)
	}

	object removeListener(object self)
	{
	}

	object setMode(object self,number x)
	{
		mode=x
		return self
	}
	
	number getMode(object self)
	{
		return mode
	}
	
	number isPanel(object self)
	{
		return mode
	}
	
	void display(object self)
	{
		self.super.display(self.getTitle())
	}
	
	void close(object self)
	{
		getScriptMngr().capturePanel(self.getName())
		getScriptMngr().setDisplayed(self.getName(),0)						
	}
	
	void refresh(object self)
	{
		if(mode==2)
		{
			getScriptMngr().closePanel(self.getName())
			getScriptMngr().openPanel(self.getName())
		}
		if(mode==3)
		{
			getScriptMngr().unloadTasks()
			getScriptMngr().loadTasks()
		}
	}

	//			
	void helpPressed(object self)
	{	
		string sHelpFilename;self.getData("help filename",sHelpFilename)
		string sPath=getApplicationDirectory("preference",0)
		sPath=pathConcatenate(sPath,"JEM_files")
		sPath=pathConcatenate(sPath,"JEM_HelpFiles")
		sPath=pathConcatenate(sPath,sHelpFileName)
	
		string msg="cmd.exe /c"	// calling the windows command prompt, /c prevents the console from being shown
		msg+="start winword "	// a command-prompt command
//string filepath="C:\\ProgramData\\Gatan\\Prefs\\JEM_files\\JEM_HelpFiles\\test.docx"
		msg+=sPath		// piping output to the text file
		LaunchExternalProcess(msg,10)
	//newScriptWindowFromFile(sPath)
	}
	
	//
	number aboutToCloseDocument(object self,number verify)
	{
		if(mode==2)//panel
		{
			self.close()
			self.write()
		}
	}

	~JEM_Widget(object self)
	{
	}
}

number getWidget(string sName,object &obj)
{
	number res=0
	if(JEM_Widget_echo)result("Looking for panel "+sName+"\n")
	if(getScriptMngr().getPanel(sName,obj))
	{
		if(JEM_Widget_echo)result("Got panel "+sName+"\n")
		res=1;return res
	}
	
	if(JEM_Widget_echo)result("Could not find panel "+sName+"\n")
	if(JEM_Widget_echo)result("Looking for palette "+sName+"\n")
	if(getPalette(sName,obj))
	{
		if(JEM_Widget_echo)result("Got palette "+sName+"\n")
		res=1;return res
	}
	
	if(JEM_Widget_echo)result("Could not find palette "+sName+"\n")
	if(JEM_Widget_echo)result("Looking for task "+sName+"\n")
	if(getScriptMngr().getTask(sName,obj))
	{
		if(JEM_Widget_echo)result("Got task "+sName+"\n")
		res=1;return res
	}
	if(JEM_Widget_echo)result("Could not find task "+sName+"\n")
	return res
}

