//Flatten
//P.Ahrenkiel,6/26/2019
//Removes smooth image background.
//Flattens contrast

class Flatten
{
	number pmax//maximum exponent
	number deg2rad
	number dx,dy
	number fac

	Flatten(object self)
	{
		pmax=2//maximum exponent
		deg2rad=180/(4*atan(1))
		dx=0.5;dy=0.5
		fac=2
	}

	//find x-integral matrix
	image find_xIntegrals(object self,number xsize,number ysize)
	{	
		image mI:=RealImage("Matrix",4,pmax+1,pmax+1)

		//workspace
		image wimg:=RealImage("Workspace",8,xsize,ysize)

		number i,j
		for(i=0;i<=pmax;i++)
			for(j=0;j<=pmax;j++)
			{
				wimg=((icol/xsize-dx)/fac)**(i+j)
				SetPixel(mI,i,j,mean(wimg))
			}	
		DeleteImage(wimg)
		mI=MatrixInverse(mI)
		return mI
	}

	//find y-integral matrix
	image find_yIntegrals(object self,number xsize,number ysize)
	{	
		image mI:=RealImage("Matrix",4,pmax+1,pmax+1)

		//workspace
		image wimg:=RealImage("Workspace",8,xsize,ysize)

		number i,j
		for(i=0;i<=pmax;i++)
			for(j=0;j<=pmax;j++)
			{
				wimg=((irow/ysize-dy)/fac)**(i+j)
				SetPixel(mI,i,j,mean(wimg))
			}	
		deleteImage(wimg)
		mI=matrixInverse(mI)
		return mI
	}

	//Find moments
	image findMoments(object self,image img,number xsize,number ysize)
	{
		//integral
		image mimg:=RealImage("Moments",8,pmax+1,pmax+1)

		//workspace
		image wimg:=RealImage("Workspace",8,xsize,ysize)

		number ix,iy
		for(ix=0;ix<=pmax;ix++)
			for(iy=0;iy<=pmax;iy++)
			{
				wimg=img*(((icol/xsize-dx)/fac)**ix)*(((irow/ysize-dy)/fac)**iy)
				SetPixel(mimg,ix,iy,mean(wimg))
			}
		deleteImage(wimg)
		return mimg
	}

	//background
	image background(object self,image img)
	{

		//size
		number sizeX,sizeY
		GetSize(img,sizeX,sizeY)


		image mimg=self.findMoments(img,sizeX,sizeY)

		image iimgx=self.find_xIntegrals(sizeX,sizeY)
		image iimgy=self.find_yIntegrals(sizeX,sizeY)

		//ShowImage(mimg)
		//ShowImage(iimgx)
		//ShowImage(iimgy)

		//workspace
		image wimg:=RealImage("Workspace",8,sizeX,sizeY)
		wimg=0

		//Get background
		number ix,jx
		number iy,jy
		for(ix=0;ix<=pmax;ix++)
			for(iy=0;iy<=pmax;iy++)
				if(1)
				{
					number f=0
					for(jx=0;jx<=pmax;jx++)
						for(jy=0;jy<=pmax;jy++)

							f+=GetPixel(iimgx,ix,jx)\
								*GetPixel(iimgy,iy,jy)\
								*GetPixel(mimg,jx,jy)
				
					wimg+=f*(((icol/sizeX-dx)/fac)**ix)\
							*(((irow/sizeY-dy)/fac)**iy)
				}
		
		return wimg
	}

	image apply(object self,image img,number brightness,number contrast)
	{
		number m=mean(img)

		//linear
		image bimg=self.background(img)
		image nimg=img-bimg
		image mimg=sqrt(nimg**2)
		//ShowImage(n2img)
		image vimg=self.background(mimg)
		vimg=vimg>0?vimg:1e-6
		number v=mean(vimg)
		vimg/=v
		vimg=contrast*(vimg-1)+1
		image cimg=nimg/vimg+bimg-brightness*(bimg-m)
		return cimg
	}
	
	void images(object self,image img,image &bimg,image &vimg)
	{
		number m=mean(img)

		//linear
		bimg:=self.background(img)
		image nimg=img-bimg
		image mimg=sqrt(nimg**2)
		//ShowImage(n2img)
		vimg:=self.background(mimg)
		vimg=vimg>0?vimg:1e-6
		number v=mean(vimg)
		vimg/=v
	}

}
