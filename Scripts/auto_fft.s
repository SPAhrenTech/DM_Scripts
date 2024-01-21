void autoFFT()
{
	image img
	if(!GetFrontImage(img))
		Exit(0)

	number width,height
	GetSize(img,width,height)

	number x0=width/2
	number y0=height/2

	number nx=trunc(log(width)/log(2))
	number ny=trunc(log(height)/log(2))

	number swidth=2**nx
	number sheight=2**ny

	number top=y0-sheight/2,bottom=y0+sheight/2
	number left=x0-swidth/2,right=x0+swidth/2

	SetSelection(img,top,left,bottom,right)

	ImageDisplay imgDisp=img.ImageGetImageDisplay(0)
	ROI roi=ImageDisplayGetROI(imgDisp,0)

	NewLiveFFT(imgDisp,roi,0)
}
autoFFT()