/*
P. Ahrenkiel-2019
JEMObject is a parent class for making objects that handle one or more threads.
These objects typically have an associated dialog from which the threads
can be accessed through the GUI.
*/
module com.gatan.dm.jemobject
uses com.gatan.dm.jem_data

//predef
interface JEM_Object_proto
{
	void setOwner(object self,object o);
}

class JEM_Object:JEM_Data
{
	number origin
	TagGroup threadList
	string sName
	JEM_Object(object self)
	{
		threadList=newTagList();
		sName="object"
	}
	
	void setName(object self,string s)
	{
		sName=s
	}
	
	string getName(object self)
	{
		return sName
	}

	number countThreads(object self)
	{
		return threadList.tagGroupCountTags()
	}
	
	number getThreadID(object self,number order,number &id)
	{
		number nThreads=self.countThreads()		
		if(nThreads>0)
			threadList.tagGroupGetIndexedTagAsNumber(order,id)		
		return nThreads>0
	}
	
	number begin(object self,object t,number priority)
	{
		t.setOwner(self)		
		number doStart=0
		number id=t.scriptObjectGetID()
		if(priority>0)
		{
			threadList.tagGroupInsertTagAsNumber(priority,id)
			doStart=1
		}
		else
		{
			if(self.countThreads()<1)
			{
				threadList.tagGroupInsertTagAsNumber(infinity(),id)
				doStart=1
			}
		}
		if(doStart)t.startThread()
		return doStart
	}
	
	number end(object self,object t)
	{
		number tID=t.scriptObjectGetID()
		number nThread=self.countThreads()
		number iThread
		for(iThread=0;iThread<nThread;iThread++)
		{
			number tpID;threadList.tagGroupGetIndexedTagAsNumber(iThread,tpID)
			if(tID==tpID)
			{
				//result("deleting thread: "+tID+"\n")
				threadList.tagGroupDeleteTagWithIndex(iThread)
				return 1
			}
		}
		return 0
	}
	
	number isRunning(object self)
	{
		number res=0
		number nThread=self.countThreads()
		number iThread
		for(iThread=0;iThread<nThread;iThread++)
		{
			number id;
			threadList.tagGroupGetIndexedTagAsNumber(iThread,id)
			object t=getScriptObjectFromID(id)
			if(t.scriptObjectIsValid())
				res=res||t.isRunning()
		}
		return res
	}

	void stop(object self){setTerminate(1);}
	void pause(object self){setPaused(1);}
	void togglePause(object self){setPaused(1-getPaused());}	
	void proceed(object self){setPaused(0);}
	
	TagGroup getThreadList(object self){return threadList;}
}
