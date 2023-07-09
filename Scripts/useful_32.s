//Moved to useful plugin
//image RightPseudoInverse(image rimg)
//image LeftPseudoInverse(image rimg)
//number get_tsec()
//number correct_angle(number x)


number hex_to_dec(string shex)
{
	number res=0
	number dig=len(shex)
	number i
	for(i=0;i<dig;i++)
	{
		string c=mid(shex,dig-i-1,1)
		number cval=asc(c)-48
		if(cval>9)
			cval-=7
		res+=cval*(16**i)
	}
	return res
}

void remove_endchars(string &s)
{
	number sl=len(s)
	while(sl>0)
	{
		number cend=asc(Right(s,1))
		if(cend>32) break
		s=Left(s,sl-1)
		sl=len(s)
	}
	
}

number get_index(TagGroup list,number item)
{
	TagGroup tagi
	number index=0,i=1
	string s
	number count=list.TagGroupCountTags()
	for(i=0;i<count;i+=1)
	{
		list.TagGroupGetIndexedTagAsTagGroup(i,tagi)
		number type=tagi.TagGroupGetTagType(0,0)
		tagi.TagGroupGetIndexedTagAsString(0,s)

		if(val(s)==item)
		{
			index=i+1
			break
		}
	}
	return index
}

number createTag(TagGroup &tg,string sLabel)
{
	if(!tg.tagGroupIsValid())tg=newTagGroup()
	number exists=tg.tagGroupDoesTagExist(sLabel)
	if(!exists)
		tg.tagGroupCreateNewLabeledTag(sLabel);
	return exists
}

number fillTag(TagGroup &tg,string sLabel,string sVal,number replace)
{
	number exists=createTag(tg,sLabel)
	if(replace||(!exists))
		tg.tagGroupSetTagAsString(sLabel,sVal)
	return exists
}

number fillTag(TagGroup &tg,string sLabel,number val,number replace)
{
	number exists=createTag(tg,sLabel)
	if(replace||(!exists))
		tg.tagGroupSetTagAsNumber(sLabel,val)
	return exists
}

number fillTag(TagGroup tg,string sLabel,object obj,number replace)
{
	number exists=createTag(tg,sLabel)
	if(replace||(!exists))
		tg.tagGroupSetTagAsNumber(sLabel,obj.scriptObjectGetID())
	return exists
}

number fillTag(TagGroup tg,string sLabel,TagGroup data,number replace)
{
	number exists=createTag(tg,sLabel)
	if(replace||(!exists))
		tg.tagGroupSetTagAsTagGroup(sLabel,data)
	return exists
}

number fillTag(TagGroup tg,string sLabel,image img,number replace)
{
	number exists=createTag(tg,sLabel)
	if(replace||(!exists))
		tg.tagGroupSetTagAsArray(sLabel,img)
	return exists
}

number checkTag(TagGroup tg,string sLabel)
{
	number exists=tg.tagGroupIsValid()
	if(exists)exists=tg.tagGroupDoesTagExist(sLabel)
	return exists
}

number getTag(TagGroup &tg,string sLabel,number &val)
{
	number exists=checkTag(tg,sLabel)
	if(exists)
		tg.tagGroupGetTagAsNumber(sLabel,val)
	return exists
}

number getTag(TagGroup tg,string sLabel,string &sVal)
{
	number exists=checkTag(tg,sLabel)
	if(exists)
		tg.tagGroupGetTagAsString(sLabel,sVal)
	return exists
}

number getTag(TagGroup tg,string sLabel,image &img)
{
	number exists=checkTag(tg,sLabel)
	if(exists)
		tg.tagGroupGetTagAsArray(sLabel,img)
	return exists
}

number getTag(TagGroup tg,string sLabel,TagGroup &data)
{
	number exists=checkTag(tg,sLabel)
	if(exists)
		tg.tagGroupGetTagAsTagGroup(sLabel,data)
	return exists
}

number getObj(object &ol,string sName,object &obj)
{
	if(!ol.scriptObjectIsValid())ol=alloc(ObjectList)
	number num=ol.sizeOfList()
	for(number i=0;i<num;++i)
	{
		obj=ol.objectAt(i)
		string sp=obj.getName()
		if(obj.getName()==sName)
			return 1
	}
	obj=null
	return 0
}

number fillObj(object &ol,string sName,object obj,number replace)
{
	obj.setName(sName)
	if(!ol.scriptObjectIsValid())ol=alloc(ObjectList)
	object prevObj
	number exists
	if(exists=getObj(ol,sName,prevObj))
	{
		if(replace)
		{
			ol.removeObjectFromList(prevObj)
			ol.addObjectToList(obj)
		}
	}
	else
	{
		ol.addObjectToList(obj)
		number num=ol.sizeOfList()
	}
	return exists
}

//
void image_func(image &img)
{
	number sizeX,sizeY
	GetSize(img,sizeX,sizeY)
	img=255*random()
}

/*
*/
image ComplexMultiply(image img1,image img2)
{
	number Nx,Ny
	GetSize(img1,Nx,Ny)
	image rimg:=RealImage("rimg",4,Nx,Ny)
	image iimg:=RealImage("iimg",4,Nx,Ny)

	rimg=real(img1)*real(img2)-imaginary(img1)*imaginary(img2)
	iimg=real(img1)*imaginary(img2)+imaginary(img1)*real(img2)
	//image img:=ComplexImage("img",8,Nx,Ny)

	image img:=complex(rimg,iimg)
	return img

}

/*
*/
image ComplexDivide(image img1,image img2)
{
	number Nx,Ny
	GetSize(img1,Nx,Ny)
	image rimg:=RealImage("rimg",4,Nx,Ny)
	image iimg:=RealImage("iimg",4,Nx,Ny)
	image dimg:=RealImage("dimg",4,Nx,Ny)
	
	dimg=real(img2)**2+imaginary(img2)**2
	rimg=(real(img1)*real(img2)+imaginary(img1)*imaginary(img2))/dimg
	iimg=(imaginary(img1)*real(img2)-real(img1)*imaginary(img2))/dimg
	//image img:=ComplexImage("img",8,Nx,Ny)

	image img:=complex(rimg,iimg)
	return img

}

/*
*/
image ComplexAdd(image img1,image img2)
{
	number Nx,Ny
	GetSize(img1,Nx,Ny)
	image rimg:=RealImage("rimg",4,Nx,Ny)
	image iimg:=RealImage("iimg",4,Nx,Ny)

	rimg=real(img1)+real(img2)
	iimg=imaginary(img1)+imaginary(img2)
	//image img:=ComplexImage("img",8,Nx,Ny)

	image img:=complex(rimg,iimg)
	return img

}

/*
*/
image ComplexSubtract(image img1,image img2)
{
	number Nx,Ny
	GetSize(img1,Nx,Ny)
	image rimg:=RealImage("rimg",4,Nx,Ny)
	image iimg:=RealImage("iimg",4,Nx,Ny)

	rimg=real(img1)-real(img2)
	iimg=imaginary(img1)-imaginary(img2)
	//image img:=ComplexImage("img",8,Nx,Ny)

	image img:=complex(rimg,iimg)
	return img

}

void FitSizeUnity(image img)
{
	number sw,sh,width,height
	number zoomPrev,zoom,zoomp1,zoomp2
 
	GetScreenSize(sw,sh)
	GetSize(img,width,height)
	zoomPrev=GetZoom(img)
	number top,left
	GetWindowPosition(img,left,top)

	zoomp1=(sh-top)/height
	zoomp2=(sw-left)/width

	if(zoomp1<zoomp2)
		zoom=zoomp1
	else
		zoom=zoomp2

	if(zoom>1)zoom=zoomPrev
	width*=zoom
	height*=zoom

	SetWindowSize(img,width,height)
	SetZoom(img,zoom)
	SetImagePositionWithinWindow(img,0,0)
}

number get_wvln(number E)
{
	number m0c2=511//KeV
	number hc=1.24//KeV.nm
	number lamd=hc/sqrt(E*(E+2*m0c2))
	return lamd//in nm
}
	
void copyTags(image &srcImg,image &destImg)
{
	TagGroup srcTag=srcImg.ImageGetTagGroup()
	TagGroup destTag=destImg.ImageGetTagGroup()
	TagGroupReplaceTagsWithCopy(destTag,srcTag)
}

//
number tagGroupGetTagType(TagGroup itemTags,string sIdent)
{
	number nItemTags=itemTags.tagGroupCountTags()
	number i
	for(number i=0;i<nItemTags;++i)
	{
		string sLabel=itemTags.tagGroupGetTagLabel(i)
		if(sLabel==sIdent)
		{
			return itemTags.TagGroupGetTagType(i,0)
		}
	}
	return -1
}

//
number choose(number n,number k)
{
	return factorial(n)/factorial(k)/factorial(n-k)
}

number GetPixel(image img,number x,number y,number z)
{
	return max(img[x,y,z,x+1,y+1,z+1])
}

//
number correct_angle(number x)
{
	number y=x
	if(y<0)
		while(1)
		{
			y+=360
			if(y>=0)return y
		}
	if(y>=360)
		while(1)
		{
			y-=360
			if(y<360)return y
		}
	return y
}

/*
number asin(number s)
{
	number c=sqrt(1-s*s)
	number theta=acos(c)
	if(s<0)theta=-theta
	return theta
}
*/
number asincos(number s,number c)
{
	number theta=acos(c)
	if(s<0)theta=-theta
	return theta
}

number acossin(number c,number s)
{
	return asincos(s,c)
}

number get_tsec()
{
	return GetHighResTickCount()/GetHighResTicksPerSecond()
}

//
void showScaleMarker(image img)
{
	imagedisplay imgdisp=img.imagegetimagedisplay(0)
	imgdisp.applydatabar(0)
}

number stringToUint32(string s)
{
	number res=0
	number nS=len(s)
	//result("string: "+s+", length: "+nS+", ")
	number i
	number j=nS
	for(i=4;i>0;i--)
	{
		if(i>nS)continue
		
		string c=mid(s,nS-i,1)
		result(c)
		number as=asc(c)
		res+=as*256**(i-1)
	}
	//result("\n")
	return res
}

string Uint32ToString(number n)
{
	string sRes=""
	number i=4
	number nFront=trunc(n/256**4)
	if(trunc(n/256**4)>0)n-=nFront*256**4

	for(i=4;i>0;i--)
	{
		number nR=trunc(n/256**(i-1))		
		sRes+=chr(nR)
		n-=nR*256**(i-1)
	}
	//result("\n")
	return sRes
}

TagGroup createMRCTags(image img,TagGroup &tg)
{
	number sizeX,sizeY
	img.getSize(sizeX,sizeY)
	
	number scaleX,scaleY
	img.getScale(scaleX,scaleY)
	
	number iMax,iMean
	iMax=img.max()
	iMean=img.mean()
		
	//Add tags and initialize with default values
	tg.tagGroupSetTagAsUInt32("Size X",sizeX)
	tg.tagGroupSetTagAsUInt32("Size Y",sizeY)
	tg.tagGroupSetTagAsUInt32("Size Z",0)
	tg.tagGroupSetTagAsUInt32("Sampling Y",sizeY)
	tg.tagGroupSetTagAsUInt32("Sampling X",sizeX)
	tg.tagGroupSetTagAsUInt32("Sampling Z",0)
	tg.tagGroupSetTagAsFloat("Cell dim X",sizeX*scaleX*10 )
	tg.tagGroupSetTagAsFloat("Cell dim Y",sizeY*scaleY*10 )
	tg.tagGroupSetTagAsFloat("Cell dim Z",0)
	tg.tagGroupSetTagAsFloat("Cell angle 1",90 )
	tg.tagGroupSetTagAsFloat("Cell angle 2",90 )
	tg.tagGroupSetTagAsFloat("Cell angle 3",90)
	tg.tagGroupSetTagAsFloat("Max",iMax )
	tg.tagGroupSetTagAsFloat("Mean",iMean)
	tg.tagGroupSetTagAsUInt32("Index Y",1)//
	tg.tagGroupSetTagAsUInt32("Index X",2)//
	tg.tagGroupSetTagAsUInt32("Index Z",3)//
	tg.tagGroupSetTagAsUInt32( "MAP",stringToUint32(" PAM"))//not sure why it's backwards
	tg.tagGroupSetTagAsUInt32( "MACHST", 0x4144 )//not sure why
	tg.tagGroupSetTagAsUInt32("Other", 0 )//
	return tg
}


number createMRCfile(TagGroup tg,object &fStream)
{
	number endian;tg.tagGroupGetTagAsNumber("Endian",endian)
	
	number doAutoClose=1
	string sPath="stack.mrc"
	if(!saveAsDialog("file",sPath,sPath))return 0
    createFile(sPath)

    number nRef=openFileForWriting(sPath)
	fStream=newStreamFromFileReference(nRef,doAutoClose)

	result("\n Writing to " + sPath )
	number nWord=1
	tg.TagGroupWriteTagDataToStream("Size X",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Size Y",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Size Z",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Data type",fStream,endian);nWord+=1
	
	while(nWord<8)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}
	tg.TagGroupWriteTagDataToStream("Sampling X",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Sampling Y",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Sampling Z",fStream,endian);nWord+=1

	while(nWord<11)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}

	tg.TagGroupWriteTagDataToStream("Cell dim X",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Cell dim Y",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Cell dim Z",fStream,endian);nWord+=1

	tg.TagGroupWriteTagDataToStream("Cell angle 1",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Cell angle 2",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Cell angle 3",fStream,endian);nWord+=1

	while(nWord<17)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}
	
	tg.TagGroupWriteTagDataToStream("Index Y",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Index X",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Index Z",fStream,endian);nWord+=1


	while(nWord<21)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}

	tg.TagGroupWriteTagDataToStream("Max",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("Mean",fStream,endian);nWord+=1

	while(nWord<27)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}
	
	tg.TagGroupWriteTagDataToStream("Type of header",fStream,endian);nWord+=1
	//fStream.streamWriteAsText(endian,"MRCO");nWord+=1
	tg.TagGroupWriteTagDataToStream("MRC version",fStream,endian);nWord+=1

	while(nWord<53)
	{
		tg.tagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}
	
	//tg.TagGroupWriteTagDataToStream("Test",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("MAP",fStream,endian);nWord+=1
	tg.TagGroupWriteTagDataToStream("MACHST",fStream,endian);nWord+=1

	while(nWord<257)
	{
		tg.TagGroupWriteTagDataToStream("Other",fStream,endian);nWord+=1
	}

   // result("\nfile created\n")
    return nRef
    //showImage(resImg)
}

void appendMRCfile(object fStream,image img,number nImg,TagGroup &tg)
{
	number endian;tg.tagGroupGetTagAsNumber("Endian",endian)
	
	tg.TagGroupSetTagAsUInt32("Size Z",nImg)
	tg.tagGroupSetTagAsUInt32("Sampling Z",nImg)

	fStream.streamSetPos(2,0)
	img.ImageWriteImageDataToStream(fStream,endian)

	fStream.streamSetPos(0,2*4)
	tg.TagGroupWriteTagDataToStream("Size Z",fStream,endian)
	
	fStream.streamSetPos(0,9*4)
	tg.TagGroupWriteTagDataToStream("Sampling Z",fStream,endian)
	
    //result("append successful\n")
    //showImage(resImg)
}

number isValid(image &img)
{
	return img.imageIsValid()
}

number isVisible(image &img)
{
	return (img.imageCountImageDisplays()>0)
}

number getSize(image img,number &x,number &y,number &z)
{
	x=img.ImageGetDimensionSize(0)
	y=img.ImageGetDimensionSize(1)
	z=img.ImageGetDimensionSize(2)
}

//
number getFilenameParts(string sPath,string &sDir,string &sName)
{
	number nChar=len(sPath)
	string c=""
	sDir="";sName=""
	number found=0
	number i
	for(i=nChar-1;i>0;i--)
	{
		c=mid(sPath,i,1)
		if(c=="\\")
		{
			sDir=left(sPath,i) 
			sName=right(sPath,nChar-i-1)

			found=1
			break			
		}
	
	}	
	return found
}


number fibonacci(number n)
{
	number f=0
	for(number i=1;i<=n;++i)
		f+=i
	return f
}	

class SmartAcqRef
{
	image refImg
	TagGroup refTagList
	
	object init(object self,image &img,TagGroup tags)
	{
		refImg=img.imageClone();
		refTagList=tags;
		return self
	}
	
	object getImage(object self,image &img){img:=refImg;return self;}
	TagGroup getTags(object self){return refTagList;}
}


class SmartAcq_STEM_ImageSet
{
	image JEOL_img,BFDF_img,HAADF_img
	
	number setImage(object self,number index,image &img)
	{
		if((index==1)&&isValid(img)){JEOL_img:=img;return 1;}
		if((index==0)&&isValid(img)){BFDF_img:=img;return 1;}
		if((index==2)&&isValid(img)){HAADF_img:=img;return 1;}
		return 0;
	}

	number getImage(object self,number index,image &img)
	{
		if((index==1)&&isValid(JEOL_img)){img:=JEOL_img;return 1;}
		if((index==0)&&isValid(BFDF_img)){img:=BFDF_img;return 1;}
		if((index==2)&&isValid(HAADF_img)){img:=HAADF_img;return 1;}
		return 0;
	}
}

