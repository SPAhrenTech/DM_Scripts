//Corrector and composite lenses - P. Ahrenkiel (2020)
//These classes allow one or more lenses to be driven by either one or two input parameters
//The corr matrix is stored in a 3-D image.
module com.gatan.dm.jemcomp
uses com.gatan.dm.jemlib
uses com.gatan.dm.jemlens

//temp prototype
image matrixPseudoInverse(image rImg,number tol);

//
interface JEM_CorrProto
{
	object setValid(object self,number isValid);
}

class JEM_Corr:JEM_Optic
{
	string sMatrixDir
	image matrixImg
	number powLimFlag//Avoids singularity at origin
	number harmFlag//Fourier series in angle
	number rangeSVD//SVD cutoff ratio
	number useSVD//
	number nmDim
	
	JEM_Corr(object self)
	{
		sMatrixDir=getApplicationDirectory("preference",0)
		sMatrixDir=pathConcatenate(sMatrixDir,"JEM_files")
		sMatrixDir=pathConcatenate(sMatrixDir,"Calibration_files")
		//self.setName("JEM_Corr")
		harmFlag=0
		rangeSVD=1e4
		useSVD=0
	}
	
	object init(object self,string sN,string sSN,number nsDim)
	{
		self.super.init(sN,sSN,nsDim)
		if(matrixImg.imageIsValid())
			deleteImage(matrixImg)
		matrixImg:=realImage(sSN+"_matrix",4,2,2,nsDim)
		matrixImg=0
		self.setValid(1)
		powLimFlag=1;harmFlag=0
		return self
	}

	object getValid(object self,number &isValid)
	{
		isValid=0
		TagGroup imgTag=matrixImg.imageGetTagGroup()
		if(imgTag.tagGroupDoesTagExist("valid"))
			imgTag.tagGroupGetTagAsNumber("valid",isValid)
		return self;
	}
	
	object setValid(object self,number isValid)
	{
		TagGroup imgTag=matrixImg.imageGetTagGroup()
		if(imgTag.tagGroupDoesTagExist("valid"))
			imgTag.tagGroupDeleteTagWithLabel("valid")
		imgTag.tagGroupCreateNewLabeledTag("valid");
		imgTag.tagGroupSetTagAsNumber("valid",isValid)
		return self;
	}
		
	object setPowLim(object self,number f){powLimFlag=f;}
	object getPowLim(object self,number &f){f=powLimFlag;}
	
	object setHarmonic(object self,number f){harmFlag=f;}
	object getHarmonic(object self,number &f){f=harmFlag;}
	
	object setUseSVD(object self,number x){useSVD=X;}
	object getUseSVD(object self,number &x){s=useSVD;}

	object setRangeSVD(object self,number x){rangeSVD=X;}
	object getRangeSVD(object self,number &x){s=rangeSVD;}
	
	object makeCoefList(object self,number nPow)
	{
		if(!matrixImg.imageIsValid())return self
		number i,j,k,l
		number nCoef=0//=(nPow+1)*(nPow+2)/2
		TagGroup coefList=newTagList()
		for(j=0;j<=nPow;j++)
			for(i=0;i<=nPow;i++)
			{
				if(powLimFlag)
					if(i+j>nPow)continue
					
				if(harmFlag)
				{
					if((j>0)&&(i>1))continue
					if((j>0)&&(trunc(j/2)==j/2))continue
				}
				TagGroup pairList=newTagList()
				pairList.tagGroupInsertTagAsNumber(infinity(),i)
				pairList.tagGroupInsertTagAsNumber(infinity(),j)
				coefList.tagGroupInsertTagAsTagGroup(infinity(),pairList)
				nCoef++
			}

		image coefImg:=RealImage("coeff",4,nCoef,2)//expansion of mImg
		k=0
		for(k=0;k<nCoef;k++)
		{
			TagGroup pairList
			coefList.tagGroupGetIndexedTagAsTagGroup(k,pairList)
			pairList.tagGroupGetIndexedTagAsNumber(0,i)
			pairList.tagGroupGetIndexedTagAsNumber(1,j)
			coefImg[k,0]=i;coefImg[k,1]=j
		}
		TagGroup imgTag=matrixImg.imageGetTagGroup()
		if(imgTag.tagGroupDoesTagExist("nCoef"))
			imgTag.tagGroupDeleteTagWithLabel("nCoef")
		imgTag.tagGroupCreateNewLabeledTag("nCoef");		
		imgTag.tagGroupSetTagAsNumber("nCoef",nCoef)

		if(imgTag.tagGroupDoesTagExist("coef"))
			imgTag.tagGroupDeleteTagWithLabel("coef")
		imgTag.tagGroupCreateNewLabeledTag("coef");
		imgTag.tagGroupSetTagAsArray("coef",coefImg)
		return self
	}
	
	//Calculate the corrector matrix based on calibration data
	object calc(object self,image mImg,image sImg,number nPow)
	{
		//mImg contains the master lens values
		//sImg contains the slave lens values
		//nPow is the maximum exponent in the expansion
		
		number nmCalib//number of master calibration points
		number nmDim//number of master lens dimensions
		GetSize(mImg,nmCalib,nmDim)

		number nsCalib//number of slave calibration points
		number nsDim//number of slave lens dimensions
		GetSize(simg,nscalib,nsDim)
		number echo;self.getEcho(echo)
		if(nsCalib!=nmCalib)
		{
			if(echo)result("Calibration error.\n")
			return null
		}
		number i,j,k,l

		string sMatrixName="matrix"
		if(matrixImg.imageIsValid())sMatrixName=matrixImg.getName()
		matrixImg:=realImage(sMatrixName,4,nPow+1,nPow+1,nsDim)
		self.makeCoefList(nPow)		
		
		TagGroup imgTag=matrixImg.imageGetTagGroup()
		number nCoef;imgTag.tagGroupGetTagAsNumber("nCoef",nCoef)
		image coefImg:=realImage("coef",4,nCoef,2)
		imgTag.tagGroupGetTagAsArray("coef",coefImg)
		if(echo)result("coefficients: "+nCoef+"\n")

		number xyRange=mImg.meanSquare()

		image rImg:=RealImage("rimg",4,nmCalib,nCoef)//expansion of mImg
		for(l=0;l<nmCalib;l++)
		{
			number mX=getPixel(mImg,l,0)
			number mY=getPixel(mImg,l,1)
		
			for(k=0;k<nCoef;k++)
			{
				i=coefImg.getPixel(k,0)
				j=coefImg.getPixel(k,1)
				number mFacX=1,mFacY=1
				if(i>0)
					mFacX=(mX/xyRange)**i
				if(j>0)
					mFacY=(mY/xyRange)**j
				rImg[l,k]=mFacX*mFacY
			}
		}
		//showImage(rImg)
		image irImg		
		if(harmFlag)
			irImg:=rightPseudoInverse(rImg)
		else
		{
			if(useSVD)
				irImg:=pseudoInverse(rImg,rangeSVD)//uses SVD
			else
				irImg:=rightPseudoInverse(rImg)
		}
		image matrix1DImg:=matrixMultiply(sImg,irImg)//one master dim per slave dim version
		image rirImg=matrixMultiply(rImg,irImg)
		self.setValid(!matrixIsSingular(rirImg))
		
		//redo scaling
		for(k=0;k<nCoef;k++)
		{
			i=coefImg.getPixel(k,0)
			j=coefImg.getPixel(k,1)
			number mFacX=1,mFacY=1
			if(i>0)
				mFacX=(xyRange)**i
			if(j>0)
				mFacY=(xyRange)**j
			matrix1DImg[k,0]/=mFacX*mFacY
			matrix1DImg[k,1]/=mFacX*mFacY
		}

		//change to two master dim per slave dim
		matrixImg=0
		for(k=0;k<nCoef;k++)
		{
			i=coefImg.getPixel(k,0)
			j=coefImg.getPixel(k,1)

			for(l=0;l<nsDim;l++)
				matrixImg[i,j,l]=matrix1DImg[k,l]
		}
		return self
	}

	object setMatrix(object self,image mImg)
	{		
		if(mImg.imageIsValid())
			matrixImg:=mImg.imageClone()
		return self
	}

	object getMatrix(object self,image &mImg)
	{
		if(matrixImg.imageIsValid())
		mImg:=matrixImg.imageClone()
		return self
	}

	image getMatrix(object self)
	{
		return matrixImg
	}
			
	object setMatrixName(object self,string s)
	{
		if(matrixImg.imageIsValid())
			matrixImg.setName(s)
		return self
	}

	object getMatrixName(object self,string &s)
	{
		if(matrixImg.imageIsValid())
			s=matrixImg.getName()
		return self
	}
			
	object setMatrixDir(object self,string s)
	{
		sMatrixDir=s
		return self
	}

	object getMatrixDir(object self,string &s)
	{
		s=sMatrixDir
		return self
	}
			
	object saveMatrix(object self)
	{
		if(!matrixImg.imageIsValid())return self
		string sMatrixName=matrixImg.getName()
		string sPath=pathConcatenate(sMatrixDir,sMatrixName+getImageExt())
		number echo;self.getEcho(echo)
		if(doesFileExist(sPath))
		{
			deleteFile(sPath)
			if(echo)result("File "+sPath+" exists: deleting\n")
		}
		try
		{
			saveAsGatan(matrixImg,sPath)
			if(echo)result(sPath+" saved.\n")			
		}
		catch
			if(echo)result("Could not save "+sPath+"\n")
		return self
	}
	
	object loadMatrix(object self)
	{
		string sMatrixName=matrixImg.getName()
		string sPath=pathConcatenate(sMatrixDir,sMatrixName+getImageExt())
		number echo;self.getEcho(echo)
		if(doesFileExist(sPath))
		{			
			try
			{
				image mImg:=openImage(sPath)
				if(echo)result("Opened "+sPath+"\n")
				matrixImg:=mImg.imageClone()
			}
			catch
				if(echo)result("Could not open "+sPath+"\n")
		}
		else
		{
			if(echo)result(sPath+" not found.\n")
			self.saveMatrix()
		}
		return self
	}
	
	object clear(object self)
	{
		number echo;self.getEcho(echo)
		if(!matrixImg.imageIsValid()) return self
		if(echo)result("clearing\n")
		matrixImg=0
		return self
	}

	//Evaluate the compensator (slave) lens settings for a particular master lens setting
	object eval(object self,number mX,number mY,image &sImg)
	{
		number echo;self.getEcho(echo)
		if(!matrixImg.imageIsValid())return self
		string sName;matrixImg.getName(sName)
		if(echo)result("evaluating "+sName+"\n")
		number nPow=matrixImg.imageGetDimensionSize(0)-1
		number nsDim=matrixImg.imageGetDimensionSize(2)
		if(echo)result("limit power: "+powLimFlag+"\n")
		if(echo)result("harmonics only: "+harmFlag+"\n")
		//change to one master dim per slave dim
		//number nCoef=0//=(nPow+1)*(nPow+2)/2
		TagGroup imgTag=matrixImg.imageGetTagGroup()
		if(!(imgTag.tagGroupDoesTagExist("nCoef")&&imgTag.tagGroupDoesTagExist("coefList")))
			self.makeCoefList(nPow)
		
		number nCoef;imgTag.tagGroupGetTagAsNumber("nCoef",nCoef)
		image coefImg:=realImage("coef",4,nCoef,2)
		imgTag.tagGroupGetTagAsArray("coef",coefImg)
		
		number i,j,k,l
		if(echo)result("coefficients: "+nCoef+"\n")
		if(echo)result("sDim: "+nsDim+"\n")
		if(echo)result("nPow: "+nPow+"\n")
		image matrix1DImg:=RealImage("matrix1D",4,nCoef,nsDim)
		matrix1DImg=0
		for(k=0;k<nCoef;k++)
		{
			i=coefImg.getPixel(k,0)
			j=coefImg.getPixel(k,1)

			for(l=0;l<nsDim;l++)
				matrix1DImg[k,l]=matrixImg[i,j,l]
		}
		if(echo)result("made 1D\n")
		image rImg:=RealImage("rimg",4,1,nCoef)
		for(k=0;k<nCoef;k++)
		{
			i=coefImg.getPixel(k,0)
			j=coefImg.getPixel(k,1)

			number mFacX=1,mFacY=1
			if(i>0)
				mFacX=mX**i
			if(j>0)
				mFacY=mY**j
			rImg[0,k]=mFacX*mFacY
		}
		
		if(echo)result("got factors\n")		
		try
			sImg:=matrixMultiply(matrix1DImg,rImg)
		catch
		{
			showImage(matrix1DImg)
			showImage(rImg)
		}
		if(echo)result("got eval result\n")
		return self
	}

	//This sets the s lens coords when the m lens is at (0,0) to be
	//those contained in sImg   
	object defineOrigin(object self,image sImg)
	{
		if(!matrixImg.imageIsValid()) return self
		number nsDim=matrixImg.imageGetDimensionSize(2)	
		for(number i=0;i<nsDim;++i)
			matrixImg[0,0,i]=sImg[0,i]
		return self
	}

	//This sets the s lens coords when the m lens is at (0,0) to be
	//those when the m lens is at (mX,mY)   
	object defineOrigin(object self,number mX,number mY)
	{
		image simg
		self.eval(mX,mY,sImg)
		if(!doesImageExist(getImageID(sImg))) return self
		return self.defineOrigin(sImg)
	}

	//Shift the compensator (slave) lens settings for a shift in master setting
	//The specified master value will become the origin for the
	//calbrated lens setting
	object shiftOrigin(object self,number mdX,number mdY)
	{
		if(!matrixImg.imageIsValid()) return self
		number nPow=matrixImg.imageGetDimensionSize(0)-1
		number nsDim=matrixImg.imageGetDimensionSize(2)
		image mpImg:=RealImage("shifted matrix",4,nPow+1,nPow+1,nsDim)
		mpImg=matrixImg

		number i,j,k,l,m
		for(m=0;m<nsDim;m++)
			for(j=0;j<=nPow;j++)
				for(i=0;i<=nPow;i++)		
				{
					number c=0
					for(l=j;l<=nPow;l++)
						for(k=i;k<=nPow;k++)		
						{
							number xFac=1,yFac=1
							if(k-i>0)
								xFac=mdX**(k-i)
							if(l-j>0)
								yFac=mdY**(l-j)
							number dc=choose(k,i)*xFac*choose(l,j)*yFac*GetPixel(mpImg,k,l,m)							
							c+=dc
						}
					matrixImg[i,j,m]=c
				}
		return self
	}	

	//
	object negate(object self)
	{
		matrixImg*=-1
		return self
	}	
}

class JEM_CorrLens:JEM_Corr
{
	object lens

	JEM_CorrLens(object self)
	{
		lens=null
	}
	
	object init(object self,string sFullName,string sShortName,object lensp)
	{
		lens=lensp
		number nsDim;lens.getDim(nsDim)
		self.super.init(sFullName,sShortName,nsDim)
		return self
	}

	object getValid(object self,number &isValid)
	{
		number isValid1=0
		if(lens.scriptObjectIsValid())lens.getValid(isValid1)
		number echo;self.getEcho(echo)
		if(echo){if(!isValid1)result("lens is invalid.\n");}
		number isValid2
		self.super.getValid(isValid2)
		if(echo){if(!isValid2)result("object is invalid.\n");}
		isValid=isValid1&&isValid2
		return self;
	}
	
	number isLens(object self)
	{
		return 0;
	}
	
	object setLens(object self,object o)
	{
		if(lens.scriptObjectIsValid())
			if(lens.isLens())lens=o
		return self
	}

	object getLens(object self,object &o)
	{
		if(lens.scriptObjectIsValid())lens.getLens(o)
		return self
	}
	
	object setNextLens(object self,object o)
	{		
		lens=o
		return self
	}
	
	object getNextLens(object self,object &o)
	{
		o=lens
		return self
	}
	
	object setOnline(object self,number n)
	{
		if(lens.scriptObjectIsValid())lens.setOnline(n)
		return self
	}
	
	object getOnline(object self,number &n)
	{
		if(lens.scriptObjectIsValid())lens.getOnline(n)
		return self
	}

	object setCalibName(object self,string s)
	{
		if(lens.scriptObjectIsValid())lens.setCalibName(s)
		return self
	}
	
	object setCalibDir(object self,string s)
	{
		if(lens.scriptObjectIsValid())lens.setCalibDir(s)
		return self
	}

	object getCalibDir(object self,string &s)
	{
		if(lens.scriptObjectIsValid())lens.getCalibDir(s)
		return self
	}


	object loadCalib(object self,number &res)
	{
		if(lens.scriptObjectIsValid())lens.loadCalib(res)
		return self
	}

	object loadCalib(object self)
	{
		if(lens.scriptObjectIsValid())lens.loadCalib()
		return self
	}

	object saveCalib(object self)
	{
		if(lens.scriptObjectIsValid())lens.saveCalib()
		return self
	}

	object setCalib(object self,image cImg)
	{
		if(lens.scriptObjectIsValid())lens.setCalib(cImg)
		return self
	}
	
	object getCalib(object self,image &cImg)
	{
		if(lens.scriptObjectIsValid())lens.getCalib(cImg)
		return self
	}
	
	object clearCalib(object self)
	{
		if(lens.scriptObjectIsValid())lens.clearCalib()
		return self
	}
	
	object setUnits(object self,string s)
	{
		if(lens.scriptObjectIsValid())lens.setUnits(s)
		return self
	}

	object getUnits(object self,string &s)
	{
		if(lens.scriptObjectIsValid())lens.getUnits(s)
		return self
	}

	object setScale(object self,number x)
	{
		if(lens.scriptObjectIsValid())lens.setScale(x)
		return self
	}
	
	object getScale(object self,number &x)
	{
		if(lens.scriptObjectIsValid())lens.getScale(x)
		return self
	}

	object setEcho(object self,number echo)
	{
		self.super.setEcho(echo)
		if(lens.scriptObjectIsValid())lens.setEcho(echo)
		return self
	}
	
	object neutralize(object self)
	{
		if(lens.scriptObjectIsValid())lens.neutralize()
		return self
	}

	object clear(object self)
	{	
		self.super.clear()
		if(lens.scriptObjectIsValid())lens.defineOrigin()
		return self
	}
	
	object saveMatrix(object self)
	{
		self.super.saveMatrix()
		if(lens.scriptObjectIsValid())lens.saveMatrix()
		return self
	}

	object loadMatrix(object self)
	{
		self.super.loadMatrix()
		if(lens.scriptObjectIsValid())lens.loadMatrix()
		return self
	}

	//
	object defineOrigin(object self,image sImg)
	{		
		self.super.defineOrigin(sImg)
		//if(lens.scriptObjectIsValid())lens.defineOrigin(sImg)
		return self
	}
	
	object set(object self,image sImg)
	{
		if(lens.scriptObjectIsValid())lens.set(sImg)
		return self
	}	
}

//This class drives a 1-D lens by two input parameters
class JEM_CorrLensX:JEM_CorrLens
{
	object init(object self,string sN,string sSN,object lens)
	{
		number nsDim;lens.getDim(nsDim)
		if(nsDim!=1)return self
		return self.super.init(sN,sSN,lens)
	}

	object defineOrigin(object self)
	{
		object lens;self.super.getLens(lens)
		number sX;lens.get(sX)
		image sImg:=[1,1]:{{sX}}
		self.super.defineOrigin(sImg)
		return self
	}

	object identity(object self)
	{
		image matImg;self.super.getMatrix(matImg)
		if(!matImg.imageIsValid()) return self
		matImg=0
		matImg[1,0,0]=1
		self.super.setMatrix(matImg)
		return self
	}

	//
	object eval(object self,number mX,number mY,number &s)
	{
		image sImg
		self.super.eval(mX,mY,sImg)
		if(!sImg.imageIsValid()) return self
		s=GetPixel(sImg,0,0)
		return self
	}
	
	//
	object set(object self,number mX,number mY)
	{
		number sX
		self.eval(mX,mY,sX)
		image sImg:=[1,2]:{{sX},{1}}
		return self.super.set(sImg)
	}
}

//This class drives a 2-D lens by two input parameters
class JEM_CorrLensXY:JEM_CorrLens
{
	object init(object self,string sN,string sSN,object lens)
	{
		number nsDim;lens.getDim(nsDim)
		if(nsDim!=2)return self
		return self.super.init(sN,sSN,lens)
	}

	object defineOrigin(object self)
	{
		object lens;self.super.getLens(lens)
		number sX,sY;lens.get(sX,sY)
		image sImg:=[1,2]:{{sX},{sY}}
		self.super.defineOrigin(sImg)
		return self
	}

	object identity(object self)
	{
		image matImg;self.super.getMatrix(matImg)
		if(!matImg.imageIsValid()) return self
		matImg=0
		matImg[1,0,0]=1
		matImg[0,1,1]=1
		self.super.setMatrix(matImg)
		return self
	}

	//
	object eval(object self,number mX,number mY,number &sX,number &sY)
	{
		image sImg
		self.super.eval(mX,mY,sImg)	
		if(!sImg.imageIsValid()) return self
		sX=GetPixel(sImg,0,0)
		sY=GetPixel(sImg,0,1)
		return self
	}
	
	//
	object set(object self,number mX,number mY)
	{
		number sX,sY
		self.eval(mX,mY,sX,sY)
		image sImg:=[1,3]:{{sX},{sY},{1}}
		return self.super.set(sImg)
	}
}
