//
image GoodCreateImageFromDisplay(image img,number gray,number maxMB)
{
	number sizeX,sizeY
	GetSize(img,sizeX,sizeY)
	number zoom=GetZoom(img)
	
	number Nmax=maxMB*(1024**2)
	number newzoom=Nmax/(sizeX*sizeY)
	if(newzoom>1)newzoom=1
//result(newzoom+"\n")
	number left,top
	GetWindowPosition(img,left,top)

	number screenSizeX,screenSizeY
	GetScreenSize(screenSizeX,screenSizeY)
	number pleft=screenSizeX,ptop=screenSizeY
	SetWindowPosition(img,pleft,ptop)
	//SetWindowPosition(img,100,100)
	SetWindowSize(img,newzoom*sizeX,newzoom*sizeY)
	SetZoom(img,newzoom)
	SetImagePositionWithinWindow(img,0,0)

	image temp:=CreateImageFromDisplay(img)
	SetWindowPosition(img,left,top)
	SetZoom(img,zoom)
	SetWindowSize(img,zoom*sizeX,zoom*sizeY)

	//needed to avoid making window too big (for some reason)
	SetImagePositionWithinWindow(img,0,0)
	SetZoom(img,zoom)
	//result("Tiffen10\n")
	number sizeXp,sizeYp
	GetSize(temp,sizeXp,sizeYp)

	image out
	image rout:=IntegerImage("r",1,0,sizeXp,sizeYp) 
	image gout:=IntegerImage("g",1,0,sizeXp,sizeYp) 
	image bout:=IntegerImage("b",1,0,sizeXp,sizeYp) 
	rout=red(temp);gout=green(temp);bout=blue(temp)
	if(gray)
	{
		out:=IntegerImage("",1,0,sizeXp,sizeYp)
		if(ImageIsDataTypeRGB(temp))
		{
			out=(rout+gout+bout)/3
		}
		else
			out=temp
	}
	else
	{
		if(ImageIsDataTypeRGB(temp))
		{
			number tot=sum((rout-gout)**2)+sum((gout-bout)**2)
			if(tot>0)
				out:=temp
			else
				out:=rout
		}
		else
			out:=temp

	}
	return out
}

//Create 8-bit or RGB image
number SaveTIFFDisplay(image img,string pathandfilename,number TIFFgray,number TIFFmaxMB)
{
	number sizeX,sizeY	 	

	image out:=GoodCreateImageFromDisplay(img,TIFFgray,TIFFmaxMB)
	GetSize(out,sizeX,sizeY)

	number res=0
	if(!ImageIsDataTypeRGB(out))
	{
		SetSurvey(out,0)
		SetLimits(out,0,255)
	}

	//Save image 
	try 
	{
		SaveAsTIFF(out,pathandfilename,1)
		res=1
	}
	catch
		res=0

	DeleteImage(out)
	return res
}


/*
image img
if(!GetFrontImage(img))
Exit(0)

image out:=GoodCreateImageFromDisplay(img,1,20)

ShowImage(out)
*/