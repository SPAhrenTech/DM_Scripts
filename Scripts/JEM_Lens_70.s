module com.gatan.dm.jemlens
uses com.gatan.dm.jemlib

//
interface JEM_LensProto
{
	object setValid(object self,number isValid);
}

//
class JEM_Optic:JEM_Object
{
	string sFullName,sShortName
	number nDim
	number echo

	JEM_Optic(object self)
	{
		self.setName("")		
		sFullName=sShortName=""
		nDim=0
		echo=0
	}
	
	object init(object self,string sN,string sSN,number nsDim)
	{
		sFullName=sN
		sShortName=sSN
		nDim=nsDim
	}
	
	object setEcho(object self,number echop)
	{
		echo=echop
		return self
	}

	object getEcho(object self,number &echop)
	{
		echop=echo
		return self
	}
	
	object getDim(object self,number &n)
	{
		n=nDim
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
	
	object neutralize(object self)
	{
		return self
	}

	object loadMatrix(object self)
	{
		return self
	}

	object saveMatrix(object self)
	{
		return self
	}
	
	object getLens(object self,object &o)
	{
		o=self
		return self
	}
	
	object getNextLens(object self,object &o)
	{
		o=null
		return self
	}

	number isLens(object self)
	{
		return 1;
	}
	object setLens(object self,object o)
	{
		return self
	}

}

//
class JEM_Lens:JEM_Optic
{
	number online
	string sCalibDir
	image calibImg
	number scale
	string sUnits

	JEM_Lens(object self)
	{
		online=0
		self.setName("JEM_Lens")		
		scale=1
		sCalibDir=getApplicationDirectory("preference",0)
		sCalibDir=pathConcatenate(sCalibDir,"JEM_files")
		sCalibDir=pathConcatenate(sCalibDir,"Calibration_files")
	}
	
	object init(object self,string sN,string sSN,number nsDim)
	{
		self.super.init(sN,sSN,nsDim)
		if(!calibImg.imageIsValid())
		{
			calibImg:=RealImage(sSN+"_calib",4,nsDim+1,nsDim+1)
			calibImg=(icol==irow)?1:0
			self.setValid(1)
		}
		return self
	}		

	object getValid(object self,number &isValid)
	{
		isValid=0
		TagGroup imgTag=calibImg.imageGetTagGroup()
		if(imgTag.tagGroupDoesTagExist("valid"))
			imgTag.tagGroupGetTagAsNumber("valid",isValid)
		return self;
	}
	
	object setValid(object self,number isValid)
	{
		TagGroup imgTag=calibImg.imageGetTagGroup()
		if(imgTag.tagGroupDoesTagExist("valid"))
			imgTag.tagGroupDeleteTagWithLabel("valid")
		imgTag.tagGroupCreateNewLabeledTag("valid");		
		imgTag.tagGroupSetTagAsNumber("valid",isValid)
		return self;
	}
	
	object setOnline(object self,number x)
	{
		online=x
		return self
	}

	object getOnline(object self,number &x)
	{
		x=online
		return self
	}

	object setCalibName(object self,string s)
	{
		if(calibImg.imageIsValid())
			calibImg.setName(s)
		return self
	}

	object getCalibName(object self,string &s)
	{
		if(calibImg.imageIsValid())
			s=calibImg.getName()
		return self
	}

	object setCalibDir(object self,string s)
	{
		sCalibDir=s
		return self
	}

	object getCalibDir(object self,string &s)
	{
		s=sCalibDir
		return self
	}

	object setUnits(object self,string s)
	{
		sUnits=s
		return self
	}

	object getUnits(object self,string &s)
	{
		s=sUnits
		return self
	}

	object setScale(object self,number x)
	{
		scale=x
		return self
	}

	object getScale(object self,number &x)
	{
		x=scale
		return self
	}

	object clearCalib(object self)
	{
		calibImg=(icol==irow)?1:0
		return self
	}

	object setCalib(object self,image cImg)
	{
		number sizeX,sizeY;getSize(cimg,sizeX,sizeY)
		number nDim;self.getDim(nDim)
		number echo;self.getEcho(echo)
		if((sizeX!=nDim+1)||(sizeY!=nDim+1))
		{
			if(echo)result("Calibration error.\n")
			return self
		}
		if(MatrixIsSingular(cImg))
		{
			if(echo)result("Calibration error.\n")
			return self
		}
		calibImg=cImg.imageClone()
		self.setValid(1)
		return self
	}

	object getCalib(object self,image &cImg)
	{
		cImg=calibImg.imageClone()
		return self
	}

	object saveCalib(object self)
	{
		if(!calibImg.imageIsValid())return self
		string sCalibName=calibImg.getName()
		string sPath=pathconcatenate(sCalibDir,sCalibName+getImageExt())
		number echo;self.getEcho(echo)
		if(doesFileExist(sPath))
		{
			deleteFile(sPath)
			if(echo)result("File "+sPath+" exists: deleting\n")
		}
		try
		{
			saveAsGatan(calibImg,sPath)
			if(echo)result("Saving "+sPath+"\n")
		}
		catch
			if(echo)result("Could not save "+sPath+"\n")
		return self
	}
	
	object loadCalib(object self,number &res)
	{
		res=0
		number didLoad=0
		string sCalibName=calibImg.getName()
		string sPath=pathconcatenate(sCalibDir,sCalibName+getImageExt())
		number echo;self.getEcho(echo)
		number nDim;self.getDim(nDim)
		if(doesFileExist(sPath))
		{
			try
			{
				image cImg:=openImage(sPath)
				if(echo)result("Opened "+sPath+"\n")

				number nX,nY;getSize(cImg,nX,nY)
				if((nX!=nDim+1)||(nY!=nDim+1))
				{
					if(echo)result("Calibration error.\n")
					return self
				}
				if(MatrixIsSingular(cImg))
				{
					if(echo)result("Calibration error.\n")
					return self
				}

				calibImg:=cImg.imageClone()
				res=1
				self.setValid(1)
				
			}
			catch
				if(echo)result("Could not open "+sPath+"\n")
		}	
		else
		{
			if(echo)result(sPath+" not found.\n")
			self.saveCalib()
		}
		return self
	}

	object loadCalib(object self)
	{
		number res
		return self.loadCalib(res)
	}

	object defineOrigin(object self,image sImg)
	{
		number nDim;self.getDim(nDim)
		image calSubImg=-matrixMultiply(calibImg[0,0,nDim,nDim],sImg)
		calibImg[0,nDim,nDim,nDim+1]=calSubImg
		return self
	}

}

class JEM_LensBal:JEM_Lens
{
	image balImg,defImg
	image coordImg
	string sBalDir
	
	object init(object self,string sFullName,string sShortName)
	{
		self.super.init(sFullName,sShortName,2)
		balImg:=realImage(sShortName+"_bal",4,4,4)
		
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupCreateNewLabeledTag("mix angle (°)");
		balTag.tagGroupSetTagAsNumber("mix angle (°)",0);

		balTag.tagGroupCreateNewLabeledTag("axis angle (°)");
		balTag.tagGroupSetTagAsNumber("axis angle (°)",0);

		balImg=(icol==irow)?1:0

		defImg:=realImage(sShortName+"_def",4,4,4)
		defImg=(icol==irow)?1:0

		sBalDir=getApplicationDirectory("preference",0)
		return self
	}
		
	object setBalName(object self,string s)
	{
		if(balImg.imageIsValid())balImg.setName(s)
		return self
	}

	object getBalName(object self,string &s)
	{
		if(balImg.imageIsValid())s=balImg.getName()
		return self
	}

	object setBalDir(object self,string s)
	{
		sBalDir=s
		return self
	}

	object getBalDir(object self,string &s)
	{
		s=sBalDir
		return self
	}

	object clearBal(object self)
	{
		balImg=(icol==irow)?1:0
		
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupSetTagAsNumber("mix angle (°)",0);
		balTag.tagGroupSetTagAsNumber("axis angle (°)",0);
		return self
	}

	object setBal(object self,image bImg)
	{
		number sizeX,sizeY;getSize(bimg,sizeX,sizeY)		
		number nDim;self.super.getDim(nDim)
		number echo;self.super.getEcho(echo)
		if((sizeX!=2*nDim)||(sizeY!=2*nDim))
		{
			result("size: "+sizeX+", "+sizeY+"\n")
			result("dim: "+nDim+"\n")
			if(echo)result("Balancing error.\n")
		}
		else
		{
			if(echo)result("Setting image.\n")
			balImg=bImg
			copyTags(bImg,balImg)

			TagGroup balTag=balImg.imageGetTagGroup()
			if(!balTag.tagGroupDoesTagExist("mix angle (°)"))
			{
				balTag.tagGroupCreateNewLabeledTag("mix angle (°)");
				balTag.tagGroupSetTagAsNumber("mix angle (°)",0);
			}

			if(!balTag.tagGroupDoesTagExist("axis angle (°)"))
			{
				balTag.tagGroupCreateNewLabeledTag("axis angle (°)");
				balTag.tagGroupSetTagAsNumber("axis angle (°)",0);
			}
		}
		return self
	}

	object getBal(object self,image &bImg)
	{
		bImg:=balImg.imageClone()
		return self
	}

	object getDef(object self,image &dImg)
	{
		dImg:=defImg.imageClone()
		return self
	}

	object setCoord(object self,image cImg)
	{
		coordImg:=cImg.imageClone()
		return self
	}

	object getCoord(object self,image &cImg)
	{
		cImg:=coordImg.ImageClone()
		return self
	}

	object saveBal(object self)
	{
		if(!balImg.imageIsValid())return self
		string sBalName=balImg.getName()
		string sPath=pathconcatenate(sBalDir,sBalName+getImageExt())
		number echo;self.getEcho(echo)
		if(doesFileExist(sPath))
		{
			deleteFile(sPath)
			if(echo)result("File "+sPath+" exists: deleting\n")
		}
		try
		{
			saveAsGatan(balImg,sPath)
			if(echo)result("Saving "+sPath+"\n")
		}
		catch
			if(echo)result("Could not save "+sPath+"\n")
		return self
	}
	
	object evalDef(object self)
	{
		TagGroup balTag=balImg.imageGetTagGroup()
		number mixAng;balTag.tagGroupGetTagAsNumber("mix angle (°)",mixAng);
		number axisAng;balTag.tagGroupGetTagAsNumber("axis angle (°)",axisAng);
		number cMix=cos(mixAng*pi()/180),sMix=sin(mixAng*pi()/180)
		number cAxis=cos(axisAng*pi()/180),sAxis=sin(axisAng*pi()/180)
		
		image mixImg:=[4,4]:{	{cMix,0,-sMix,0},
								{0,cMix,0,-sMix},
								{sMix,0,cMix,0},
								{0,sMix,0,cMix}	}

		image axisImg:=[4,4]:{	{cMix,0,-sMix,0},
								{0,cMix,0,-sMix},
								{sMix,0,cMix,0},
								{0,sMix,0,cMix}	}
								
		defImg=matrixMultiply(mixImg,axisImg)
		
	}
	
	object loadBal(object self,number &res)
	{
		res=0
		number didLoad=0
		string sBalName=balImg.getName()
		string sPath=pathconcatenate(sBalDir,sBalName+getImageExt())
		number echo;self.getEcho(echo)		
		if(echo)result("Loading "+sPath+"\n")
		if(doesFileExist(sPath))
		{
			try
			{
				image tImg:=openImage(sPath)
				if(echo)result("Opened "+sPath+"\n")
				number nX,nY;getSize(tImg,nX,nY)
				number nDim;self.super.getDim(nDim)
				if((nX!=2*nDim)||(nY!=2*nDim))
				{
					if(echo)result("Balancing error.\n")
				}
				else
				{
					balImg:=tImg.imageClone()
					copyTags(tImg,balImg)
					res=1
				}
				tImg.cleanImage()
				tImg.closeImage()
				TagGroup balTag=balImg.imageGetTagGroup()
	
				if(!balTag.tagGroupDoesTagExist("mix angle (°)"))
				{
					balTag.tagGroupCreateNewLabeledTag("mix angle (°)");
					balTag.tagGroupSetTagAsNumber("mix angle (°)",0);
				}

				if(!balTag.tagGroupDoesTagExist("axis angle (°)"))
				{
					balTag.tagGroupCreateNewLabeledTag("axis angle (°)");
					balTag.tagGroupSetTagAsNumber("axis angle (°)",0);
				}
				self.evalDef()
				
			}
			catch
				if(echo)result("Could not open "+sPath+"\n")
		}	
		else
		{
			if(echo)result(sPath+" not found.\n")
			self.saveCalib()
		}
		return self
	}

	object loadBal(object self)
	{
		number res
		return self.loadBal(res)
	}

	object defineOrigin(object self,image lensImg)
	{
		return self.super.defineOrigin(lensImg);
	}
	
	object getMixAngle(object self,number &mixAng)
	{
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupGetTagAsNumber("mix angle (°)",mixAng);
		return self	
	}
	
	object getAxisAngle(object self,number &axisAng)
	{
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupGetTagAsNumber("axis angle (°)",axisAng);
		return self	
	}
	
	object setMixAngle(object self,number mixAng)
	{
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupSetTagAsNumber("mix angle (°)",mixAng);
		self.evalDef()
		return self	
	}
	
	object setAxisAngle(object self,number axisAng)
	{
		TagGroup balTag=balImg.imageGetTagGroup()
		balTag.tagGroupSetTagAsNumber("axis angle (°)",axisAng);
		self.evalDef()
		return self	
	}

}

//
class JEM_LensX:JEM_Lens
{
	object init(object self,string sName,string sShortName)
	{
		return self.super.init(sName,sShortName,1)
	}
	
	//override this
	object read(object self,number &lens)
	{
		return self
	}

	//override this
	object write(object self,number lens)
	{
		return self
	}

	object neutralize(object self)
	{
		self.write(0)
		return self
	}

	object defineOrigin(object self)
	{
		number lensX
		self.read(lensX)
		image lensImg:=[1,1]:{{lensX}}
		self.super.defineOrigin(lensImg)
		return self
	}

	object get(object self,number &x)
	{
		number lens	
		self.read(lens)
		image lensImg:=[1,2]:{{lens},{1}}
		image cImg;self.super.getCalib(cImg)	
		image xImg:=matrixMultiply(cImg,lensImg)//calib unit
		x=GetPixel(xImg,0,0)
		return self
	}

	object set(object self,number x)
	{
		image xImg:=[1,2]:{{x},{1}}
		image cImg;self.super.getCalib(cImg)
		image cImgL:=matrixInverse(cImg)
		image lensImg:=matrixMultiply(cImgL,xImg)//lens unit
		number lens=GetPixel(lensImg,0,0)
		self.write(lens)
		return self
	}

	object set(object self,image lensImg)
	{
		number x
		x=GetPixel(lensImg,0,0)
		return self.set(x)
	}
	
	number validRange(object self,number x)
	{
		number res=1
		if((x<0x0000)||(x>0xFFFF))res=0
		return res
	}
	
	object scaleRange(object self,number &x,number &y)
	{
		number x0;self.read(x0)
		number dX=x-x0
		if(x0+dX>0xFFFF)
		{
			number rat=(0xFFFF-x0)/(x-x0)
			dX*=rat;
		}
		if(x0+dX<0x0000)
		{
			number rat=(0x0000-x0)/(x-x0)
			dX*=rat
		}
		x=x0+dX
	}

}

class JEM_LensXY:JEM_Lens
{
	object init(object self,string sName,string sShortName)
	{return self.super.init(sName,sShortName,2);}
	
	//override this
	object read(object self,number &lensX,number &lensY)
	{
		return self
	}

	//override this
	object write(object self,number lensX,number lensY)
	{
		return self
	}

	object neutralize(object self)
	{
		self.write(0,0)
		return self
	}

	object defineOrigin(object self)
	{
//		string sN;self.getShortName(sN)
//		result("define origin: "+sN+"\n")
		number lensX,lensY
		self.read(lensX,lensY)
		image lensImg:=[1,2]:{{lensX},{lensY}}
		self.super.defineOrigin(lensImg)
		return self
	}

	object get(object self,number &x,number &y)
	{
		number lensX,lensY	
		self.read(lensX,lensY)
		image lensImg:=[1,3]:{{lensX},{lensY},{1}}
		image cImg;self.super.getCalib(cImg)
		image xyImg:=MatrixMultiply(cImg,lensImg)//lens unit
		x=GetPixel(xyImg,0,0);y=GetPixel(xyImg,0,1)
		return self
	}

	object set(object self,number x,number y)
	{
		image xyImg:=[1,3]:{{x},{y},{1}}		
		image cImg;self.super.getCalib(cImg)
		image cImgL:=MatrixInverse(cImg)
		image lensImg:=MatrixMultiply(cImgL,xyImg)//lens unit
		number lensX=GetPixel(lensImg,0,0),lensY=GetPixel(lensImg,0,1)
		self.write(lensX,lensY)
		return self
	}
	
	object set(object self,image coordImg)
	{
		number x,y
		x=GetPixel(coordImg,0,0)
		y=GetPixel(coordImg,0,1)
		return self.set(x,y)
	}

	//
	object setPolar(object self,number mAmp,number mAng)
	{
		number ang=mAng/180*pi()
		number mX=mAmp*cos(ang),mY=mAmp*sin(ang)
		return self.set(mX,mY)
	}

	number validRange(object self,number x,number y)
	{
		number res=1
		if((x<0x0000)||(x>0xFFFF))res=0
		if((y<0x0000)||(y>0xFFFF))res=0
		return res
	}

	object scaleRange(object self,number &x,number &y)
	{
		number x0,y0;self.read(x0,y0)
		number dX=x-x0,dY=y-y0
		if(x0+dX>0xFFFF)
		{
			number rat=(0xFFFF-x0)/(x-x0)
			dX*=rat;dY*=rat
		}
		if(y0+dY>0xFFFF)
		{
			number rat=(0xFFFF-y0)/(y-y0)
			dX*=rat;dY*=rat
		}
		if(x0+dX<0x0000)
		{
			number rat=(0x0000-x0)/(x-x0)
			dX*=rat;dY*=rat
		}
		if(y0+dY<0x0000)
		{
			number rat=(0x0000-y0)/(y-y0)
			dX*=rat;dY*=rat
		}
		x=x0+dX;y=y0+dY
	}

}

class JEM_LensBalXY:JEM_LensBal
{
	image bLens0Img
		
	//override this
	object readLens1(object self,number &lensX,number &lensY)
	{		
		return self
	}

	//override this
	object readLens2(object self,number &lensX,number &lensY)
	{		
		return self
	}

	//override this
	object writeLens1(object self,number lensX,number lensY)
	{
		return self
	}

	//override this
	object writeLens2(object self,number lensX,number lensY)
	{
		return self
	}

	//override this
	number validRangeLens1(object self,number x,number y)
	{
		return 1;
	}
	
	//override this
	number validRangeLens2(object self,number x,number y)
	{
		return 1;
	}
	
	number validRange(object self,image lensImg)
	{
		number lens1X=getPixel(lensImg,0,0),lens1Y=getPixel(lensImg,0,1)
		number lens2X=getPixel(lensImg,0,2),lens2Y=getPixel(lensImg,0,3)
		return self.validRangeLens1(lens1X,lens1Y)&&self.validRangeLens2(lens2X,lens2Y)
	}

	object neutralize(object self)
	{
		self.writeLens1(0,0)
		self.writeLens2(0,0)
		return self
	}
	
	object transform(object self,image lensImg,image &bLensImg)
	{
		image balImg;self.super.getBal(balImg)	
		image defImg;self.super.getDef(defImg)	
		image balP_img:=matrixMultiply(defImg,balImg)
		bLensImg=matrixMultiply(matrixInverse(balP_img),lensImg-0x8000)+0x8000//lens unit
	}
		
	object untransform(object self,image bLensImg,image &lensImg)
	{
		image balImg;self.super.getBal(balImg)
		image defImg;self.super.getDef(defImg)	
		image balP_img:=matrixMultiply(defImg,balImg)
		lensImg:=matrixMultiply(balP_img,bLensImg-0x8000)+0x8000//lens unit
	}
	
	object read(object self,image &bLensImg)
	{
		number lens1X,lens1Y;self.readLens1(lens1X,lens1Y)
		number lens2X,lens2Y;self.readLens2(lens2X,lens2Y)
		image lensImg:=[1,4]:{{lens1X},{lens1Y},{lens2X},{lens2Y}}
		self.transform(lensImg,bLensImg)
		return self
	}
	
	object write(object self,image bLensImg)
	{
		image lensImg;self.untransform(bLensImg,lensImg)
		number lens1X=getPixel(lensImg,0,0),lens1Y=getPixel(lensImg,0,1)
		number lens2X=getPixel(lensImg,0,2),lens2Y=getPixel(lensImg,0,3)
		self.writeLens1(lens1X,lens1Y)
		self.writeLens2(lens2X,lens2Y)
		bLens0Img=bLensImg
		return self
	}
	
	object establishAxes(object self)
	{
		return self.read(bLens0Img)
	}

	object getAxes(object self,image &bLensImg)
	{
		bLensImg:=bLens0Img
		return self
	}

	object setAxes(object self,image &bLensImg)
	{
		bLens0Img:=bLensImg
		return self
	}

	object linkAxes(object self,object &otherLens)
	{
		image bLensImg;otherLens.getAxes(bLensImg)
		if(!bLensImg.imageIsValid())
		{
			if(!bLens0Img.imageIsValid())
			{
				bLensImg:=bLens0Img
			}
		}
		bLens0Img:=bLensImg
		return self
	}

	//read
	object readBal1(object self,number &bLens1X,number &bLens1Y)
	{
		image bLensImg;self.read(bLensImg)
		bLens1X=getPixel(bLensImg,0,0);bLens1Y=getPixel(bLensImg,0,1)
		return self
	}

	object readBal2(object self,number &bLens2X,number &bLens2Y)
	{
		image bLensImg;self.read(bLensImg)
		bLens2X=getPixel(bLensImg,0,2);bLens2Y=getPixel(bLensImg,0,3)
		return self
	}
	
	object getBal1(object self,image &coordImg)
	{
		number bLens1X,bLens1Y
		self.readBal1(bLens1X,bLens1Y)
		image bLens1Img:=[1,3]:{{bLens1X},{bLens1Y},{1}}
		image cImg;self.super.getCalib(cImg)
		coordImg:=matrixMultiply(cImg,bLens1Img)//xy unit
		return self
	}

	object getBal2(object self,image &coordImg)
	{
		number bLens2X,bLens2Y
		self.readBal2(bLens2X,bLens2Y)
		image bLens2Img:=[1,3]:{{bLens2X},{bLens2Y},{1}}
		image cImg;self.super.getCalib(cImg)
		coordImg:=matrixMultiply(cImg,bLens2Img)//xy unit
		return self
	}
	
	object getBal1(object self,number &x,number &y)
	{
		image coordImg;self.getBal1(coordImg)
		x=GetPixel(coordImg,0,0);y=GetPixel(coordImg,0,1)
		return self
	}

	object getBal2(object self,number &x,number &y)
	{
		image coordImg;self.getBal2(coordImg)
		x=GetPixel(coordImg,0,0);y=GetPixel(coordImg,0,1)
		return self
	}

	//write
	object writeBal1(object self,number bLens1X,number bLens1Y)
	{
		number bLens2X=getPixel(bLens0Img,0,2),bLens2Y=getPixel(bLens0Img,0,3)
		image bLensImg:=[1,4]:{{bLens1X},{bLens1Y},{bLens2X},{bLens2Y}}
		return self.write(bLensImg)
	}

	object writeBal2(object self,number bLens2X,number bLens2Y)
	{
		number bLens1X=getPixel(bLens0Img,0,0),bLens1Y=getPixel(bLens0Img,0,1)
		image bLensImg:=[1,4]:{{bLens1X},{bLens1Y},{bLens2X},{bLens2Y}}
		return self.write(bLensImg)
	}

	object setBal1(object self,image coordImg)
	{
		image cImg;self.super.getCalib(cImg)
		image cImgL:=matrixInverse(cImg)
		image bLens1Img:=matrixMultiply(cImgL,coordImg)//lens unit
		number bLens1X=getPixel(bLens1Img,0,0),bLens1Y=getPixel(bLens1Img,0,1)
		self.writeBal1(bLens1X,bLens1Y)
		return self
	}

	object setBal2(object self,image coordImg)
	{
		image cImg;self.super.getCalib(cImg)
		image cImgL:=matrixInverse(cImg)
		image bLens2Img:=matrixMultiply(cImgL,coordImg)//lens unit
		number bLens2X=getPixel(bLens2Img,0,0),bLens2Y=getPixel(bLens2Img,0,1)
		self.writeBal2(bLens2X,bLens2Y)
		return self
	}

	object setBal1(object self,number x,number y)
	{		
		image coordImg:=[1,3]:{{x},{y},{1}}		
		return self.setBal1(coordImg)
	}
	
	object setBal2(object self,number x,number y)
	{		
		image coordImg:=[1,3]:{{x},{y},{1}}		
		return self.setBal2(coordImg)
	}
	
	object defineOriginBal1(object self)
	{
		number bLens1X,bLens1Y;self.readBal1(bLens1X,bLens1Y)
		image bLens1Img:=[1,2]:{{bLens1X},{bLens1Y}}
		return self.super.defineOrigin(bLens1Img)
	}

	object defineOriginBal2(object self)
	{
		number bLens2X,bLens2Y;self.readBal2(bLens2X,bLens2Y)
		image bLens2Img:=[1,2]:{{bLens2X},{bLens2Y}}
		return self.super.defineOrigin(bLens2Img)
		
	}

	//scale, range
	number validRangeBal1(object self,number bLens1X,number bLens1Y)
	{
		image bLensImg=bLens0Img
		setPixel(bLensImg,0,0,bLens1X);setPixel(bLensImg,0,1,blens1Y)
		image lensImg;self.untransform(bLensImg,lensImg)
		return self.validRange(lensImg)
	}

	number validRangeBal2(object self,number bLens2X,number bLens2Y)
	{
		image bLensImg;self.read(bLensImg)
		setPixel(bLensImg,0,2,bLens2X);setPixel(bLensImg,0,3,bLens2Y)
		image lensImg;self.untransform(bLensImg,lensImg)
		return self.validRange(lensImg)
	}

	object scale(object self,image &bLensImg)
	{
		image lensImg;self.untransform(bLensImg,lensImg)
		number lens1X=getPixel(lensImg,0,0),lens1Y=getPixel(lensImg,0,1)
		number lens2X=getPixel(lensImg,0,2),lens2Y=getPixel(lensImg,0,3)
		
		//image bLens0Img;self.read(bLens0Img)
		image lens0Img;self.untransform(bLens0Img,lens0Img)
		number lens1X0=getPixel(lens0Img,0,0),lens1Y0=getPixel(lens0Img,0,1)
		number lens2X0=getPixel(lens0Img,0,2),lens2Y0=getPixel(lens0Img,0,3)
		
		number dLens1X=lens1X-lens1X0,dLens1Y=lens1Y-lens1Y0
		number dLens2X=lens2X-lens2X0,dLens2Y=lens2Y-lens2Y0

		number rscale=1
		//lens1
		if(lens1X0+dLens1X>0xFFFF)
		{
			number rat=(0xFFFF-lens1X0)/(lens1X-lens1X0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens1X0+dLens1X<0x0000)
		{
			number rat=(0x0000-lens1X0)/(lens1X-lens1X0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens1Y0+dLens1Y>0xFFFF)
		{
			number rat=(0xFFFF-lens1Y0)/(lens1Y-lens1Y0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens1Y0+dLens1Y<0x0000)
		{
			number rat=(0x0000-lens1Y0)/(lens1Y-lens1Y0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}

		//lens2
		if(lens2X0+dLens2X>0xFFFF)
		{
			number rat=(0xFFFF-lens2X0)/(lens2X-lens2X0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens2X0+dLens2X<0x0000)
		{
			number rat=(0x0000-lens2X0)/(lens2X-lens2X0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens2Y0+dLens2Y>0xFFFF)
		{
			number rat=(0xFFFF-lens2Y0)/(lens2Y-lens2Y0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}
		if(lens2Y0+dLens2Y<0x0000)
		{
			number rat=(0x0000-lens2Y0)/(lens2Y-lens2Y0)
			dLens1X*=rat;dLens1Y*=rat;dLens2X*=rat;dLens2Y*=rat
			rscale*=rat
		}

		number echo;self.getEcho(echo)
		if(echo)if(rscale<1)result("scaled by "+rscale+"\n")
		lens1X=lens1X0+dLens1X;lens1Y=lens1Y0+dlens1Y
		lens2X=lens2X0+dLens2X;lens2Y=lens2Y0+dlens2Y
		lensImg:=[1,4]:{{lens1X},{lens1Y},{lens2X},{lens2Y}}
		return self.transform(lensImg,bLensImg)
	}

	object scaleRangeBal1(object self,number &bLens1X,number &bLens1Y)
	{
		image bLensImg=bLens0Img.imageClone()
		setPixel(bLensImg,0,0,bLens1X);setPixel(bLensImg,0,1,bLens1Y)
		self.scale(bLensImg)
		bLens1X=getPixel(bLensImg,0,0);bLens1Y=getPixel(bLensImg,0,1)
		return self
	}

	object scaleRangeBal2(object self,number &bLens2X,number &bLens2Y)
	{
		image bLensImg=bLens0Img.imageClone()
		setPixel(bLensImg,0,2,bLens2X);setPixel(bLensImg,0,3,bLens2Y)
		self.scale(bLensImg)
		bLens2X=getPixel(bLensImg,0,2);bLens2Y=getPixel(bLensImg,0,3)
		return self
	}

}

class JEM_BeamShift:JEM_LensXY
{

	JEM_BeamShift(object self)
	{
	}
	
	object init(object self)
	{return self.super.init("Beam Shift","CLA1");}

	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getBeamShift(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}
	
	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setBeamShift(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}
}

//
class JEM_BeamTilt:JEM_LensXY
{

	JEM_BeamTilt(object self){}
	
	object init(object self)
	{return self.super.init("Beam Tilt","CLA2");}

	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getBeamTilt(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}
	
	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setBeamTilt(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}
}

//
class JEM_ImageShift1:JEM_LensXY
{
	JEM_ImageShift1(object self){}
	
	object init(object self)
	{return self.super.init("Image Shift 1","IS1");}

	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getImageShift1(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setImageShift1(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}
}
	
//
class JEM_ImageShift2:JEM_LensXY
{
	JEM_ImageShift2(object self){}
	
	object init(object self)
	{return self.super.init("Image Shift 2","IS2");}
	
	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getImageShift2(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setImageShift2(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}
}
		
//
class JEM_ImageShiftBal:JEM_LensBalXY
{
	object IS1,IS2
	
	JEM_ImageShiftBal(object self)
	{IS1=alloc(JEM_ImageShift1);IS2=alloc(JEM_ImageShift2);}
		
	object init(object self,string sN,string sSN)
	{
		self.super.init(sN,sSN)
		number online;self.super.getOnline(online)
		self.setBalName("ISBAL_bal")
		self.loadBal()		
		if(online)self.establishAxes()
		return self
	}

	object init(object self)
	{
		return self.init("Balanced image shift","ISBAL")
	}
	
	object setOnline(object self,number x)
	{
		IS1.setOnline(x);IS2.setOnline(x)
		self.super.setOnline(x)
		return self
	}

	object readLens1(object self,number &lensX1,number &lensY1)
	{
		number online;self.super.getOnline(online)
		if(online)IS1.read(lensX1,lensY1)
		return self
	}

	object writeLens1(object self,number lensX1,number lensY1)
	{
		number online;self.super.getOnline(online)
		if(online)IS1.write(lensX1,lensY1)
		return self
	}
	
	object readLens2(object self,number &lensX2,number &lensY2)
	{
		number online;self.super.getOnline(online)
		if(online)IS2.read(lensX2,lensY2)
		return self
	}

	object writeLens2(object self,number lensX2,number lensY2)
	{
		number online;self.super.getOnline(online)
		if(online)IS2.write(lensX2,lensY2)
		return self
	}
	
	number validRangeLens1(object self,number lensX1,number lensY1)
	{
		number res=1
		number online;self.super.getOnline(online)
		if(online)res=IS1.validRange(lensX1,lensY1)
		return res
	}

	number validRangeLens2(object self,number lensX2,number lensY2)
	{
		number res=1
		number online;self.super.getOnline(online)
		if(online)res=IS2.validRange(lensX2,lensY2)
		return res
	}

}
	
//
class JEM_ImageShiftBal1:JEM_ImageShiftBal
{
	JEM_ImageShiftBal1(object self){}

	object init(object self)
	{return self.super.init("Balanced mag shift","ISBAL1");}
	
	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.readBal1(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.writeBal1(lensX,lensY)
		return self
	}
	
	object get(object self,image &coordImg)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.getBal1(coordImg)
		return self
	}

	object set(object self,image coordImg)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.setBal1(coordImg)
		return self
	}
	
	object get(object self,number &x,number &y)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.getBal1(x,y)
		return self
	}

	object set(object self,number x,number y)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.setBal1(x,y)
		return self
	}
	
	object defineOrigin(object self)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.defineOriginBal1()
		return self
	}
	
	number validRange(object self,number x,number y)
	{
		number res=1
		number online;self.super.getOnline(online)
		if(online)res=self.validRangeBal1(x,y)
		return res
	}

	object scaleRange(object self,number &x,number &y)
	{
		number online;self.super.getOnline(online)
		if(online) self.scaleRangeBal1(x,y)
		return self
	}
}

//
class JEM_ImageShiftBal2:JEM_ImageShiftBal
{
	JEM_ImageShiftBal2(object self){}

	object init(object self)
	{return self.super.init("Balanced diff shift","ISBAL2");}
	
	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.readBal2(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.writeBal2(lensX,lensY)
		return self
	}
	
	object get(object self,image &coordImg)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.getBal2(coordImg)
		return self
	}

	object set(object self,image coordImg)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.setBal2(coordImg)
		return self
	}
	object get(object self,number &x,number &y)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.getBal2(x,y)
		return self
	}

	object set(object self,number x,number y)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.setBal2(x,y)
		return self
	}

	object defineOrigin(object self)
	{
		number online;self.super.getOnline(online)
		if(online)self.super.defineOriginBal2()
		return self
	}
	number validRange(object self,number x,number y)
	{
		number res=1
		number online;self.super.getOnline(online)
		if(online)res=self.validRangeBal2(x,y)
		return res
	}
	
	object scaleRange(object self,number &x,number &y)
	{
		number online;self.super.getOnline(online)
		if(online)self.scaleRangeBal2(x,y)
		return self
	}
}

//
class JEM_CondenserStig:JEM_LensXY
{
	JEM_CondenserStig(object self){}	
	
	object init(object self)
	{return self.super.init("Condenser Stigmator","CS");}

	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getCondensorStigmation(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setCondensorStigmation(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}		
}

//
class JEM_ProjectorDef:JEM_LensXY
{
	JEM_ProjectorDef(object self){}
	
	object init(object self)
	{return self.super.init("Projector Deflector","PLA");}
	
	object read(object self,number &lensX,number &lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getProjectorDef(lensX,lensY)
		if(online)self.super.read(lensX,lensY)
		return self
	}

	object write(object self,number lensX,number lensY)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setProjectorDef(lensX,lensY)
		if(online)self.super.write(lensX,lensY)
		return self
	}
}


//
class JEM_Brightness:JEM_LensX
{
	JEM_Brightness(object self){}
	
	object init(object self)
	{return self.super.init("Brightness","CL3");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getBrightness(x)
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setBrightness(x)
		if(online)self.super.write(x)
		return self
	}		
}

//
class JEM_ObjectiveFine:JEM_LensX
{
	JEM_ObjectiveFine(object self){}

	object init(object self)
	{return self.super.init("Fine Focus","OLf");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getObjectiveLensFine(x)
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setObjectiveLEnsFine(x)
		if(online)self.super.write(x)
		return self
	}		
}

//
class JEM_ObjectiveCoarse:JEM_LensX
{
	JEM_ObjectiveCoarse(object self){}

	object init(object self)
	{return self.super.init("Coarse Focus","OLc");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getObjectiveLensCoarse(x)
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setObjectiveLensCoarse(x)
		if(online)self.super.write(x)
		return self
	}		
}

//Smallest increment is 16
class JEM_ObjectiveRel:JEM_LensX
{
	JEM_ObjectiveRel(object self){}
	
	object init(object self)
	{return self.super.init("Relative Focus (OLr)","OLr");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)
		{
			number xc,xf
			JEM_getObjectiveLensCoarse(xc)
			JEM_getObjectiveLensFine(xf)
			x=(32*xc+xf)/16//convert to relative scale
		}
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setFocusRel(x)
		if(online)self.super.write(x)
		return self
	}		
}

//
class JEM_IntermediateLens1:JEM_LensX
{
	JEM_IntermediateLens1(object self){}
	
	object init(object self)
	{return self.super.init("Intermediate Lens 1","IL1");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getIntermediateLens1(x)
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setIntermediateLens1(x)
		if(online)self.super.write(x)
		return self
	}		
}

//
class JEM_ProjectorLens:JEM_LensX
{
	JEM_ProjectorLens(object self){}
	
	object init(object self)
	{return self.super.init("Projector Lens","PL1");}

	object read(object self,number &x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_getProjectorLens(x)
		if(online)self.super.read(x)
		return self
	}

	object write(object self,number x)
	{
		number online;self.super.getOnline(online)
		if(online)JEM_setProjectorLens(x)
		if(online)self.super.write(x)
		return self
	}		
}

