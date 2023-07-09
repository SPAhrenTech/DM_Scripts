
void zoomSize(image img,number zoom)
{
	number sw,sh,width,height
	//number left=134,top=39
	number zoomOld,zoomNew
 
	GetScreenSize(sw,sh)
	GetSize(img,width,height)

	//SetWindowPosition(img,left,top)
	SetWindowSize(img,width*zoom,height*zoom)
	SetZoom(img,zoom)
	SetImagePositionWithinWindow(img,0,0)
 }

void sameSize(image img)
{
	number sw,sh,width,height
	number top=39,left=134,edge=4
 
	GetScreenSize(sw,sh)
	GetSize(img,width,height )
	number zoom=GetZoom(img)
	ZoomSize(img,zoom)
 }

void fullSize(image img)
{
	ZoomSize(img,1)
}


void fitSize(image img)
{
	number sw,sh,width,height
	number zoom,zoomp1,zoomp2
 
	GetScreenSize(sw,sh)
	GetSize(img,width,height)
	zoom=GetZoom(img)
	number top,left
	GetWindowPosition(img,left,top)

	zoomp1=(sh-top)/height
	zoomp2=(sw-left)/width

	if(zoomp1<zoomp2)
		zoom=zoomp1
	else
		zoom=zoomp2

	ZoomSize(img,zoom)
 }

