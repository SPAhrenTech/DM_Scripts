//
module com.gatan.dm.jemthread

class ThreadMsg:object
{
	TagGroup threadTags
	object threadObjs
	
	object getTags(object self,TagGroup &p){p=threadTags;return self;}
	object setTags(object self,TagGroup &p){threadTags=p;return self;}	
	
	object getObjs(object self,object &p){p=threadObjs;return self;}
	object setObjs(object self,object &p){threadObjs=p;return self;}	

	ThreadMsg(object self)
	{
	}
}

interface JEM_ThreadProto
{
	void endThread(object self,object t);
	number end(object self,object t);
}

//
class JEM_Thread:JEM_Object
{	
	number viable,alive,resolve
	object origin,owner
	number running
	object mq,msg,sig
	number readyForKey

	JEM_Thread(object self)
	{
		mq=newMessageQueue()
		sig=newSignal(0)
		viable=alive=1
		readyForKey=1
		origin=null
		owner=null
		running=0
	}
	
	object setQueue(object self,object q){mq=q;return self;}
	object getQueue(object self,object &q){q=mq;return self;}

	void clearQueue(object self)
	{
		while(1)
		{
			object resMsg=mq.waitOnMessage(0,null)
			if(resMsg.scriptObjectIsValid())
			{}
			else
				break;
		}
	}

	object setMessage(object self,object m)
	{
		msg=m.scriptObjectClone();
		return self;
	}

	object newMessage(object self,object &m)
	{
		m=msg.scriptObjectClone();
		return self;
	}
	
	object newMessage(object self)
	{
		object m;self.newMessage(m)
		return m;
	}

	object sendMessage(object self,object m)
	{
		self.clearQueue()
		mq.postMessage(m)
		return self
	}
		
	number receiveMessage(object self,object &m,number tMax)
	{
		number tStart=get_tsec()
		number tWait=0
		number res=0
		while(get_tsec()-tStart<tMax)
		{
			m=mq.waitOnMessage(0.01,null)
			if(m.scriptObjectIsValid())
			{res=1;break;}			
		}
		self.clearQueue()					
		return res
	}

	number receiveMessage(object self,object &m)
	{
		return self.receiveMessage(m,infinity())
	}

	number receiveMessageOnSignal(object self,object &m)
	{		
		sig.waitOnSignal(infinity(),null)
		sig.resetSignal()
		number id=self.scriptObjectGetID()
		//result("thread: "+id+", is viable: "+viable+"\n")
		if(viable)
			while(1)
			{
				m=mq.waitOnMessage(1,null)
				if(m.scriptObjectIsValid()){break;}
				else
					if(getTerminate()){viable=0;break;}
					
			}
		self.clearQueue()					
		return viable
	}

	object init(object self,object s,object o,object m,number r)
	{
		self.clearQueue()		
		sig.resetSignal()
		resolve=r;
		viable=1;
		alive=1
		readyForKey=1
		origin=s
		owner=o
		msg=m.scriptObjectClone();
		self.sendMessage(msg)
		return self
	}		
	
	object begin(object self)
	{
		running=1;
		return self
	}

	//
	number endThread(object self)
	{
		object msg
		number status=self.receiveMessageOnSignal(msg)
		//number id=self.scriptObjectGetID()
		return status
	}
	
	object end(object self)
	{
		alive=0
		running=0
		owner.end(self)
		sig.setSignal()
		if(resolve)
			self.endThread()//status not used
		return self
	}
	
	object pause(object self)
	{
		setPaused(1)
		return self
	}
		
	object proceed(object self)
	{
		setPaused(0)
		return self
	}

	object kill(object self)
	{
		alive=0
		return self
	}

	object abort(object self)
	{
		viable=0
		alive=0
		return self
	}
	number isPaused(object self){return getPaused();}
	number isViable(object self){return viable;}
	number isRunning(object self){return running;}
	number isAlive(object self)
	{
		if(getTerminate())self.abort()		
		if(origin.scriptObjectIsValid())
			if(!origin.isAlive())alive=0
		return alive
	}
	
	void setOrigin(object self,object o){origin=o;}
	object getOrigin(object self){return origin;}

	void setOwner(object self,object o){owner=o;}
	object getOwner(object self){return owner;}
	
	number isOrigin(object self){return !origin.scriptObjectIsValid();}

	number pose(object self)
	{
		string sGroup;self.getGroup(sGroup)
		object dataCopy=alloc(JEM_Data).setGroup(sGroup)
		dataCopy.copyData(self,sGroup)
		number res=self.super.pose()
		if(!res)self.copyData(dataCopy,sGroup)		
		return res
	}
	

}
