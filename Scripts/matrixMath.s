
image RightPseudoInverse(image rimg)
{
	return matrixRightPseudoInverse(rImg)
	/*
	image rTimg:=MatrixTranspose(rimg)
	image rrTImg:=MatrixMultiply(rimg,rTimg)
	number det=MatrixDeterminant(rrTImg)
	number sizeX,sizeY
	GetSize(rrTImg,sizeX,sizeY)
	if(abs(det)/sizeX<1e-32)
	
	{
		result("singular matrix\n")
		return NULL
	}
	image rrTIimg:=MatrixInverse(rrTimg)
	image rRimg:=MatrixMultiply(rTimg,rrTIimg)
	return rRimg
*/
}

image LeftPseudoInverse(image rimg)
{
	return matrixLeftPseudoInverse(rImg)
	/*
	image rTimg:=MatrixTranspose(rimg)
	image rTrImg:=MatrixMultiply(rTimg,rimg)
	number det=MatrixDeterminant(rTrImg)
	number sizeX,sizeY
	GetSize(rTrImg,sizeX,sizeY)
	if(abs(det)/sizeX<1e-32)
	{
		result("singular matrix\n")
		return NULL
	}
	image rTrIimg:=MatrixInverse(rTrimg)
	image rLimg:=MatrixMultiply(rTrIimg,rTimg)
	return rLimg
	*/
}

//uses library functions
number diagSymm(image img,image &dImg,image &vImg)
{
	return matrixDiagSymm(img,dImg,vImg)
}

image pseudoInverse(image img,number tol)
{
	return MatrixPseudoInverse(img,tol)
}

image SVD(image rImg,image &uImg,image &sImg,image &vImg)
{
	return MatrixSVD(rimg,uImg,sImg,vImg)
}

number MatrixTrace(image img)
{
	image dimg:=img*(icol==irow)
	return sum(dimg)
}

number MatrixIsSingular(image img)
{
	number xSize,ySize
	GetSize(img,xSize,ySize)
	if(xSize!=ySize)
		return 1
	number trace=MatrixTrace(img)
	if(trace==0)
		return 1
	number det=MatrixDeterminant(img)			
	number crit=(abs(det)**(1/xSize))/abs(trace)
	if(crit<1e-12)
		return 1
	return 0
}
