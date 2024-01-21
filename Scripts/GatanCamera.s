//Gatan camera

class GatanCamera:object
{
	object camera,params
	number online
	number simTop,simLeft,simBottom,simRight
	number simBin,simtExp
	number camID

	GatanCamera(object self)
	{
		online=0
		simTop=0;simLeft=0;simBottom=1024;simRight=1024
		simBin=1
		simtExp=1
	}
	
	object init(object self,number t_online)
	{
		online=t_online
		if(online)
		{
			camera=CM_GetCurrentCamera()
		}
		return self
	}
	
	object getCurrent(object self)
	{
		if(online)
		{
			camera=CM_GetCurrentCamera()
			camID=cameraGetActiveCameraID( )
		}
		return self
	}
	
	object get(object self)
	{
		return camera
	}

	object get(object self,object &other_camera)
	{
		other_camera=camera
		return self
	}


	object set(object self,object other_camera)
	{
		camera=other_camera
		return self
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

	object getName(object self,string &s)
	{
		if(online)
		{
			s=CM_GetCameraName(camera)
		}
	}

	object getControllerClass(object self,string &s)
	{
		if(online)
		{
			s=CM_GetCameraControllerClass(camera)
		}
		return self
	}
	
	object validateParams(object self)
	{
		if(online)
			CM_Validate_AcquisitionParameters(camera,params)
		return self
	}

	
	object readParams(object self,string mode,string style,string set,number create)
	{
		if(online)
		{
			params=CM_GetCameraAcquisitionParameterSet(camera,mode,style,set,create)
		}
		return self
	}
		
	object loadParams(object self)
	{
		if(online)
		{
			CM_LoadCameraAcquisitionParameterSet(camera,params)
		}
		return self
	}
	
	object writeParams(object self)
	{
		if(online)
		{
			CM_SaveCameraAcquisitionParameterSet(camera,params)
		}
		return self
	}
	
	//Created to change parameters externally
	object readParams(object self,string mode,string style,string set,number create,object &p)
	{
		if(online)
		{
			p=CM_GetCameraAcquisitionParameterSet(camera,mode,style,set,create)
		}
		return self
	}
			
	object writeParams(object self,object p)
	{
		if(online)
		{
			CM_SaveCameraAcquisitionParameterSet(camera,p)
		}
		return self
	}
	
	object getParams(object self,object &p)
	{
		if(online)
		{
			p=params
		}
		return self
	}
	
	object setParams(object self,object p)
	{
		if(online)
		{
			params=p
		}
		return self
	}
	object getSize(object self,number &x,number &y)
	{
		if(online)
		{
			CM_CCD_GetSize(camera,x,y)
		}
		else
		{
			x=simRight-simLeft
			y=simBottom-simTop
		}
		return self
	}
	
	object getPixelSize(object self,number &x,number &y)
	{
		if(online)
		{
			CM_CCD_GetPixelSize_um(camera,x,y)
		}
		return self
	}	
	
	object getArea(object self,number &top,number &left,number &bottom,number &right)
	{
		if(online)
		{
			CM_GetCCDReadArea(params,top,left,bottom,right)
		}
		else
		{
			top=simTop;left=simLeft;bottom=simBottom;right=simRight
		}
		return self
	}	
	
	object setArea(object self,number top,number left,number bottom,number right)
	{
		if(online)
		{
			//doesn't work?
			CM_SetCCDReadArea(params,top,left,bottom,right)
		}
		else
		{
			simTop=top;simLeft=left;simBottom=bottom;simRight=right
		}
		return self
	}	
	
	object getBinnedArea(object self,number &top,number &left,number &bottom,number &right)
	{
		if(online)
		{
			CM_GetBinnedReadArea(camera,params,top,left,bottom,right)
		}
		else
		{
			top=simTop;left=simLeft;bottom=simBottom;right=simRight
		}
		return self
	}	
	
	object setBinnedArea(object self,number top,number left,number bottom,number right)
	{
		if(online)
		{
			CM_SetBinnedReadArea(camera,params,top,left,bottom,right)
		}
		else
		{
			simTop=top;simLeft=left;simBottom=bottom;simRight=right
		}
		return self
	}	

	object getBinnedSize(object self,number &sizeX,number &sizeY)
	{
		number top,left,bottom,right
		if(online)
		{
			CM_GetBinnedReadArea(camera,params,top,left,bottom,right)
		}
		else
		{
			top=simTop;left=simLeft;bottom=simBottom;right=simRight
		}
		sizeX=right-left;sizeY=bottom-top
		return self
	}	

	object getInserted(object self,number &x)
	{
		if(online)
		{
			x=CM_GetCameraInserted(camera)
		}
		return self
	}
	
	object setInserted(object self,number x)
	{
		if(online)
		{
			CM_SetCameraInserted(camera,x)
		}
		return self
	}
	
	object getExposure(object self,number &x)
	{
		if(online)
		{
			x=CM_GetExposure(params)
		}
		else
		{
			x=simtExp
		}
		return self
	}
	
	object setExposure(object self,number x)
	{
		if(online)
		{
			CM_SetExposure(params,x)
		}
		return self
	}
		
	object getBinning(object self,number &x,number &y)
	{
		if(online)
		{
			CM_GetBinning(params,x,y)
		}
		else
		{
			x=y=simBin;
		}
		return self
	}
		
	object setBinning(object self,number x,number y)
	{
		if(online)
		{
			CM_SetBinning(params,x,y)
		}
		else
		{
			simBin=x;
		}
		return self
	}

	object getProcessing(object self,number &proc)
	{
 		if(online)
		{
			proc=CM_GetProcessing(params);
		}
		return self;
	}

	object setProcessing(object self,number proc)
	{
 		if(online)
		{
			CM_SetProcessing(camera,proc);
		}
		return self;
	}

	object getCorrections(object self,number mask,number &corr)
	{
 		if(online)
		{
			corr=CM_GetCorrections(params,mask);
		}
		return self;
	}

	object setCorrections(object self,number mask,number corr)
	{
 		if(online)
		{
			CM_SetCorrections(params,mask,corr);
		}
		return self;
	}

	object getTranspose(object self,number &trans)
	{
 		if(online)
		{
			trans=CM_Config_GetDefaultTranspose(camera);
		}
		return self;
	}

	object setTranspose(object self,number trans)
	{
 		if(online)
		{
			CM_Config_SetDefaultTranspose(camera,trans);
		}
		return self;
	}

	object createImageForAcquire(object self,image &img,string name)
	{
		if(online)
		{
			img:=CM_CreateImageForAcquire(camera,params,name)
		}
		else
		{
			number sizeX=simRight-simLeft
			number sizeY=simBottom-simTop
			//result(sizeX+", "+sizeY+"\n")
			img:=RealImage(name,4,sizeX,sizeY)
		}
		return self
	}
	
	object acquire(object self,image &img)
	{
		if(online)
		{
			CM_AcquireImage(camera,params,img)
		}
		else
		{
			img=255*random()
		}
		return self
	}
	
	object acquire(object self,image &img,number from_scratch)
	{
		if(online)
		{
			if(from_scratch)
				img:=CM_AcquireImage(camera,params)
			else
				CM_AcquireImage(camera,params,img)
		}
		else
		{
			img=255*random()
		}
		return self
	}
	
	object acquireDarkRef(object self,image &img)
	{
		if(online)
		{
			CM_AcquireDarkReference(camera,params,img,null);
		}
		return self
	}
	
	object startContinuous(object self)
	{
		if(online)
		{
			number bin;self.getBinning(bin,bin)
			number proc;self.getProcessing(proc);
			number exp;self.getExposure(exp);
			cameraStartContinuousAcquisition(camID,exp,bin,bin,proc)
		}
	}
	
	object stopContinuous(object self)
	{
		if(online)
		{
			cameraStopContinuousAcquisition(camID)
		}
	}
	
	number getContinuous(object self,image &img,number timeout_s)
	{
		if(online)
		{
			return cameraGetFrameInContinuousMode(camID,img,timeout_s)
		}
		return 0
	}
	
	object getIdleShutterState(object self,number index,number &is_closed)
	{
		if(online)
		{
			CM_GetIdleShutterState(camera,index,is_closed)
		}
		return self
	}

	object setIdleShutterState(object self,number index,number is_closed)
	{
		if(online)
		{
			CM_SetIdleShutterState(camera,index,is_closed)
		}
		return self
	}
	
	object setStandardArea(object self)
	{
		if(online)
		{
			number top,left,bottom,right
			self.getArea(top,left,bottom,right)

			number sizeX,sizeY
			self.getSize(sizeX,sizeY)

			number bin
			self.getBinning(bin,bin)
			number binSizeX,binSizeY		
			binSizeX=floor(sizeX/bin)
			binSizeY=floor(sizeY/bin)

			number stop,sleft,sbottom,sright
			stop=top;sleft=left
			sbottom=binSizeY;sRight=binSizeX
			//doesn't do anything
			self.setBinnedArea(stop,sleft,sbottom,sright)
		}
	}

}