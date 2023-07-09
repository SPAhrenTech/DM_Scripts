//Takes the FFT of any (real or int) image,
//regardless of size or aspect ratio

image fimg
if(!GetFrontImage(fimg))exit(0)

number stop,sleft,bottom,sright
image img
if(GetSelection(fimg,stop,sleft,bottom,sright))
	img:=fimg[stop,sleft,bottom,sright]
else
	img:=fimg

image fft_img:=FFT_anything(img,1)
ShowImage(fft_img)
//checkcontrast(fft_img)
