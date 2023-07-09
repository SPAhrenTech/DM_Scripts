//uncalibrate film

image img
if(!GetFrontImage(img)){
	OKDialog("You must have an image on which to operate!")
	exit(0)
}

SetScale(img,1,1)
SetOrigin(img,0,0)
SetUnitString(img,"pix")
