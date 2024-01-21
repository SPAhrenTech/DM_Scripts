image img
if(!getFrontImage(img))Exit(0)

number zoom=getZoom(img)
if(getNumber("Zoom factor:",zoom,zoom))
	zoomSize(img,zoom)
