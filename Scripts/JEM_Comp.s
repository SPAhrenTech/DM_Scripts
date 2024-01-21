//Corrector and composite lenses - P. Ahrenkiel (2020)
//These classes allow one or more lenses to be driven by either one or two input parameters
//The corr matrix is stored in a 3-D image.
module com.gatan.dm.jemcomp
uses com.gatan.dm.jemlib
uses com.gatan.dm.jemlens

//
class JEM_Comp:JEM_Object
{
	object corrList
	number echo
	string sFullName,sShortName

	JEM_Comp(object self)
	{
		corrList=alloc(ObjectList)
		corrList.clearList()
		echo=0
		//self.setName("JEM_Comp")
		sFullName=sShortName=""
	}

	object init(object self,string sN,string sSN)
	{
		sFullName=sN
		sShortName=sSN
		return self
	}
	
	object setFullName(object self,string s)
	{
		sFullName=s
		return self
	}

	object getFullName(object self,string &s)
	{
		s=sFullName
		return self
	}

	object setShortName(object self,string s)
	{
		sShortName=s
		return self
	}

	object getShortName(object self,string &s)
	{
		s=sShortName
		return self
	}

	object addCorr(object self,object o)
	{
		corrList.addObjectToList(o)
		return self
	}

	object getCorr(object self,number i,object &o)
	{
		o=corrList.objectAt(i-1)
		return self
	}
				
	object setCorr(object self,number i,object o)
	{
		object op=corrList.objectAt(i-1)
		op=o
		return self
	}
				
	object getLens(object self,number i,object &o)
	{
		object c=corrList.objectAt(i-1)
		c.getLens(o)
		return self
	}
				
	object setLens(object self,number i,object o)
	{
		object c=corrList.objectAt(i-1)
		c.setLens(o)
		return self
	}
				
//
	object setEcho(object self,number x)
	{
		echo=x
		foreach(object corr;corrList)
			corr.setEcho(x)
		return self
	}

	object getEcho(object self,number &x)
	{
		x=echo
		return self
	}
//
	object setXY(object self,number mX,number mY)
	{
		foreach(object corr;corrList)
		{
			if(echo)
			{
				string sN;corr.getMatrixName(sN)
				result("will set corr "+sN+"\n")
			}
			corr.set(mX,mY)
			if(echo)
			{
				string sN;corr.getMatrixName(sN)
				result("did set corr "+sN+"\n")
			}
		}
		return self
	}
			
//
	object set(object self,number mX,number mY)
	{
		return self.setXY(mX,mY)
	}

//
	object neutralize(object self)
	{
		foreach(object corr;corrList)
			corr.neutralize()
		return self
	}
			
//
	object getCorrList(object self,object &cl)
	{
		cl=corrList
		return self
	}
	//
	object setPolar(object self,number mAmp,number mAng)
	{
		number ang=mAng/180*pi()
		number mX=mAmp*cos(ang),mY=mAmp*sin(ang)
		return self.setXY(mX,mY)
	}
			
	//
	object setPolarTang(object self,number mAmp,number mAng,number tang)
	{
		number ang=mAng/180*pi()
		number mX=mAmp*cos(ang),mY=mAmp*sin(ang)
		number dmX=-tAng*sin(ang),dmY=tAng*cos(ang)
		return self.setXY(mX+dmX,mY+dmY)
	}
			
	object shiftOrigin(object self,number mX,number mY)
	{		
		foreach(object corr;corrList)
			corr.shiftOrigin(mX,mY)
		return self
	}

	object defineOrigin(object self)
	{		
		foreach(object corr;corrList)
			corr.defineOrigin()
		return self
	}

	object clear(object self)
	{
		foreach(object corr;corrList)
			corr.clear()
		return self
	}

//
	object saveCalib(object self)
	{
		foreach(object corr;corrList)
		{
			object lens;corr.getLens(lens)
			if(lens.scriptObjectIsValid())lens.saveCalib()
		}
		return self
	}
	
	object loadCalib(object self)
	{
		foreach(object corr;corrList)
		{
			object lens;corr.getLens(lens)
			if(lens.scriptObjectIsValid())lens.loadCalib()
		}
		return self
	}
			
	object setCalibDir(object self,string sDir)
	{
		foreach(object corr;corrList)
		{
			object lens;corr.getLens(lens)
			if(lens.scriptObjectIsValid())lens.setCalibDir(sDir)
		}
		return self
	}
	
	object setMatrixDir(object self,string sDir)
	{
		foreach(object corr;corrList)
			corr.setMatrixDir(sDir)
		return self
	}
	
	object saveMatrix(object self)
	{
		foreach(object corr;corrList)
			corr.saveMatrix()
		return self
	}
	
	object loadMatrix(object self)
	{
		foreach(object corr;corrList)
			corr.loadMatrix()
		return self
	}	
}

//
class JEM_CompLens:JEM_Comp
{
	object lens

	JEM_CompLens(object self)
	{
		lens=null
		//self.setName("JEM_CompLens")
	}

	object init(object self,string sN,string sSN)
	{
		self.super.init(sN,sSN)
		return self
	}

	object setLens(object self,object o)
	{
		lens=o
		return self
	}
	
	object getLens(object self,object &o)
	{
		o=lens
		return self
	}
						
//
	object getXY(object self,number &mX,number &mY)
	{
		lens.get(mX,mY)
		return self
	}
	
	//
	object getPolar(object self,number &mAmp,number &mAng)
	{
		number mX,mY
		lens.get(mX,mY)
		mAmp=sqrt(mX**2+mY**2)
		if(mAmp>0)
		{
			number cAng=mX/mAmp,sAng=mY/mAmp
			mAng=180/pi()*asincos(sAng,cAng)
		}
		return self
	}

	//
	object read(object self,number &lensX,number &lensY)
	{
		lens.read(lensX,lensY)
	}
	
	//
	object write(object self,number lensX,number lensY)
	{
		lens.write(lensX,lensY)
		number mX,mY
		lens.get(mX,mY)				
		return self.set(mX,mY)
	}

	//
	object setXY(object self,number mX,number mY)
	{
		number echo;self.getEcho(echo)
		lens.set(mX,mY)
		if(echo)result("set lens\n")
		self.super.setXY(mX,mY)
		if(echo)result("set corr lens\n")
		return self
	}
			
	//
	object setPolar(object self,number mAmp,number mAng)
	{
		number ang=mAng/180*pi()
		number mX=mAmp*cos(ang),mY=mAmp*sin(ang)
		return self.setXY(mX,mY)
	}
	
	//
	object neutralize(object self)
	{
		lens.neutralize()
		self.super.neutralize()
		return self
	}
			
	object loadCalib(object self)
	{
		lens.loadCalib()
		self.super.loadCalib()
		return self
	}
			
	object saveCalib(object self)
	{
		lens.saveCalib()
		self.super.saveCalib()
		return self
	}
	
	//This defines the current m-lens setting as its origin.
	//The origin for the s-lenses taken to be their current positions.
	//No proper transformation of the comp matrices is performed.
	object defineOrigin(object self)
	{		
		number mX,mY
		self.getXY(mX,mY)
		self.super.shiftOrigin(mX,mY)		
		lens.defineOrigin()
		self.super.defineOrigin()		
		return self
	}

	//This defines the lens origin as (mX,mY)
	//The origins for the s lenses are taken to be those at (mX,mY)
	//No proper transformation of the comp matrices is performed.
	object defineOrigin(object self,number mX,number mY)
	{		
		self.setXY(mX,mY)
		self.defineOrigin()
		return self
	}

	object clear(object self)
	{
		self.super.clear()
		self.defineOrigin()
		return self
	}

	//This makes the current m lens setting the origin.
	//The origins for the s lenses are taken to be those appropriate for
	//the m lenses using proper transformations of the comp matrices.
	object shiftOrigin(object self)
	{		
		number mX,mY
		self.getXY(mX,mY)
		self.super.shiftOrigin(mX,mY)		
		return self
	}

	//This defines the lens origin as (mX,mY)
	//The origins for the s lenses are taken to be those appropriate for
	//the m lenses using proper transformations of the comp matrices.
	object shiftOrigin(object self,number mX,number mY)
	{		
		self.setXY(mX,mY)
		self.shiftOrigin()
		return self
	}	
}
