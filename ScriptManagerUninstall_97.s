//ScriptManagerUninstaller - P. Ahrenkiel 2021

//First remove all relevant scripts (including ScriptManager)
//using File:Remove Script... 
//Then run this script.


void uninstallScriptManager()
{
	TagGroup globalTag=getPersistentTagGroup()
	TagGroup scriptMngrTag
	if(globalTag.tagGroupDoesTagExist("Script Management"))
		globalTag.tagGroupDeleteTagWithLabel("Script Management")			
}

uninstallScriptManager()
	
	

