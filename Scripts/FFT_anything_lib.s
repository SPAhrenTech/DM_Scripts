//Takes the FFT of any (real or int) image,
//regardless of size or aspect ratio

/*
*/
image scaleForFFT(image img)
{
	number Nx,Ny
	GetSize(img,Nx,Ny)

//calibration
	string units
	number dx,dy
	units=GetUnitString(img)
	GetScale(img,dx,dy)
	number Lx=Nx*dx,Ly=Ny*dy

	number Nxp=2**trunc(log(Nx)/log(2))
	number Nyp=2**trunc(log(Ny)/log(2))

	if(Nxp<Nx)Nxp*=2
	if(Nyp<Ny)Nyp*=2
	

	image simg:=RealImage("simg",4,Nxp,Nyp)
	number xrat=Nxp/Nx,yrat=Nyp/Ny
	simg=warp(img,icol/xrat,irow/yrat)

	number dxp=dx/xrat,dyp=dy/yrat
	SetUnitString(simg,units)
	SetScale(simg,dxp,dyp)
	return simg
}

/*
Rescale an fft computed with distorted dimensions.
*/
image unscaleFFT(image sfft_img,number Nx,number Ny)
{
	number Nxp,Nyp
	GetSize(sfft_img,Nxp,Nyp)

	number dkxp,dkyp
	GetScale(sfft_img,dkxp,dkyp)
	
	number Kxp=Nxp*dkxp,Kyp=Nyp*dkyp
	number r=Kxp/Kyp
	number Nxpp=round((r*Nx*Ny)**0.5)
	number Nypp=round((Nx*Ny/r)**0.5)
	number dkxpp=Kxp/Nxpp,dkypp=Kyp/Nypp

	image fft_img:=ComplexImage("fft",8,Nxpp,Nypp)
	image mfft_img:=RealImage("mfft",4,Nxpp,Nypp)
	image pfft_img:=RealImage("pfft",4,Nxpp,Nypp)
	image rfft_img:=RealImage("rfft",4,Nxpp,Nypp)
	image ifft_img:=RealImage("ifft",4,Nxpp,Nypp)

	number sxrat=Nxp/Nxpp,syrat=Nyp/Nypp
	mfft_img=warp(modulus(sfft_img),icol*sxrat,irow*syrat)
	pfft_img=warp(phase(sfft_img),icol*sxrat,irow*syrat)

	rfft_img=mfft_img*cos(pfft_img)
	ifft_img=mfft_img*sin(pfft_img)
	
	fft_img=complex(rfft_img,ifft_img)
		
	string kunits=GetUnitString(sfft_img)
	//if(units=="")kunits=""
	//else kunits="1/"+units
	number x0pp=Nxpp/2,y0pp=Nypp/2
	SetScale(fft_img,dkxpp,dkypp)
	SetOrigin(fft_img,x0pp,y0pp)
	SetUnitString(fft_img,kunits)
	return fft_img
}

/*
*/
image shiftImage(image img)
{
	number sizeX,sizeY
	GetSize(img,sizeX,sizeY)
	number x0=sizeX/2,y0=sizeY/2

	image simg
	if(IsComplexDataType(img,8))simg:=ComplexImage("imgp",8,sizeX,sizeY)
	if(IsRealDataType(img,4))simg:=RealImage("simg",4,sizeX,sizeY)

	simg[0,0,y0,x0]=img[y0,x0,sizeY,sizeX]
	simg[y0,x0,sizeY,sizeX]=img[0,0,y0,x0]
	simg[y0,0,sizeY,x0]=img[0,x0,y0,sizeX]
	simg[0,x0,y0,sizeX]=img[y0,0,sizeY,x0]
	return simg
}

/*
Smooth uses method from Microsc. Microanal. 21, 436–441, 2015
*/
image FFT_anything(image img,number smooth)
{
	number Nx,Ny
	GetSize(img,Nx,Ny)

	image simg:=scaleForFFT(img)
	image sfft_img:=realFFT(simg)

	if(smooth>0)
	{
		number dx,dy
		GetScale(img,dx,dy)
		number Lx=Nx*dx,Ly=Ny*dy
		string units=GetUnitString(img)
		number Nxp,Nyp
		GetSize(simg,Nxp,Nyp)
		
		//image ufft_img:=FFT_anything(u_img)	
		//ShowImage(sfft_img)
		
		image b_img:=RealImage("b",4,Nxp,Nyp)
		b_img=0
		b_img[0,0,Nyp,1]=simg[0,Nxp-1,Nyp,Nxp]-simg[0,0,Nyp,1]
		b_img[0,Nxp-1,Nyp,Nxp]+=simg[0,0,Nyp,1]-simg[0,Nxp-1,Nyp,Nxp]
		b_img[0,0,1,Nxp]+=simg[Nyp-1,0,Nyp,Nxp]-simg[0,0,1,Nxp]
		b_img[Nyp-1,0,Nyp,Nxp]+=simg[0,0,1,Nxp]-simg[Nyp-1,0,Nyp,Nxp]
		b_img*=smooth
		image bfft_img:=RealFFT(b_img)
		//ShowImage(bfft_img)
		//
		number kNx,kNy
		GetSize(sfft_img,kNx,kNy)
		number kx0=kNx/2,ky0=kNy/2
		
		image kfft_img:=ComplexImage("kfft",8,kNx,kNy)
		kfft_img=complex(1/(2*cos(2*pi()*(icol-kx0)/kNx)+2*cos(2*pi()*(irow-ky0)/kNy)-4),0)

		image sbfft_img:=ComplexImage("smooth_fft",8,kNx,kNy)
		sbfft_img=ComplexMultiply(bfft_img,kfft_img)
		sbfft_img[ky0,kx0,ky0+1,kx0+1]=complex(0,0)
		sfft_img=ComplexSubtract(sfft_img,sbfft_img)
	}
	return unscaleFFT(sfft_img,Nx,Ny)
}

/*
*/
image crossCorrelateAnything(image img1,image img2)
{
	string units
	number scaleX,scaleY
	number sizeX,sizeY
	GetUnitString(img1,units)	
	GetScale(img1,scaleX,scaleY)
	GetSize(img1,sizeX,sizeY)

	image simg1:=scaleForFFT(img1)
	image simg2:=shiftImage(scaleForFFT(img2))//need to do this, have to figure out why.

	image fft1_img:=RealFFT(simg1)
	image fft2_img:=RealFFT(simg2)
	fft2_img=conjugate(fft2_img)
	image prod:=ComplexMultiply(fft1_img,fft2_img)

	image res:=real(IFFT(prod))
	res-=mean(res)

	number sizeXp,sizeYp
	GetSize(res,sizeXp,sizeYp)
	res/=sqrt(sizeXp*sizeYp)

	image res2:=RealImage("cc",4,sizeX,sizeY)
	res2=warp(res,icol*sizeXp/sizeX,irow*sizeYp/sizeY)
	SetUnitString(res2,units)	
	SetScale(res2,scaleX,scaleY)
	SetOrigin(res2,sizeX/2,sizeY/2)

	return res2
}

/*
*/
image FFT_asymm(image img)
{
	image simg:=scaleForFFT(img)
	image sfft_img:=RealFFT(simg)
	return sfft_img
}

image getCC_shift(image imgA,image imgB,number subPix,number &dX,number &dY)
{
	image ccImg:=crossCorrelateAnything(imgA,imgB)
	number maxX,maxY
	number imax=max(ccImg,maxX,maxY)
	//result("XY:"+maxX+", "+maxY+"\n")

	number ccSizeX,ccSizeY
	getSize(ccImg,ccSizeX,ccSizeY)

	number subTop,subLeft,subBottom,subRight
	subTop=subLeft=subBottom=subRight=subPix
	number top=maxY-subPix;if(top<0)subTop=maxY
	number left=maxX-subPix;if(left<0)subLeft=maxX
	number bottom=maxY+subPix;if(bottom>ccSizeY)subBottom=ccSizeY-maxY
	number right=maxX+subPix;if(right>ccSizeX)subRight=ccSizeX-maxX
	
	image ccSubImg=ccImg[maxY-subTop,maxX-subLeft,maxY+subBottom,maxX+subRight]

	number totSub=sum(ccSubImg)
	number totSubX=sum(icol*ccSubImg)
	number totSubY=sum(irow*ccSubImg)
	number dSubX=totSubX/totSub,dSubY=totSubY/totSub
	number ccX0=maxX-subLeft+dSubX,ccY0=maxY-subTop+dSubY

	dX=ccX0-ccSizeX/2;dY=ccY0-ccSizeY/2
	return ccImg
}

