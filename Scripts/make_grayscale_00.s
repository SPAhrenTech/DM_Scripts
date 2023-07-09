//get front image

void ZoomSize(image img,number zoom)
{
	number sw,sh,width,height
 
	GetScreenSize(sw,sh)
	GetSize(img,width,height )

	SetWindowSize(img,width*zoom,height*zoom)
	SetZoom(img,zoom)
	SetImagePositionWithinWindow(img,0,0)
}


image img
if(!GetFrontImage(img)) Exit(0)
ZoomSize(img,1)

image rgbimg:=CreateImageFromDisplay(img)

number Xsize,Ysize
GetSize(rgbimg,Xsize,Ysize)

image nimg:=IntegerImage("intimg",1,0,Xsize,Ysize)

nimg=blue(rgbimg)
ShowImage(nimg)
