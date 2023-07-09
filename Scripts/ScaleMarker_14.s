number SCALEMARKER_display=0
string SCALEMARKER_sGroup="SCALEMARKER"
string SCALEMARKER_sName="ScaleMarkerInfo"
string SCALEMARKER_sTitle="Scale Marker"
number SCALEMARKER_echo=0

class ScaleMarker:JEM_Widget
{
	
	string sOS,sPrefsName
	number sEcho

	//
	ScaleMarker(object self)
	{
		self.setGroup(SCALEMARKER_sGroup)
		self.setName(SCALEMARKER_sName)
		self.setTitle(SCALEMARKER_sTitle)
		self.setEcho(SCALEMARKER_echo)
	}
	
	//
	object load(object self)
	{
		self.addData("font size",12)
		self.addData("font","Arial")
		self.addData("position X",0.05)
		self.addData("position Y",0.95)
		self.addData("right aligned",0)
		self.addData("foreground",rgb(65535,65535,65535))
		self.addData("background",rgb(0,0,0))
		self.addData("attributes",0)
		return self.super.load()
	}
	
	//
	~ScaleMarker(object self)
	{
		self.super.unload()
	}
	
	object getFormat(object self,image &img)
	{
		imagedisplay imgDisp=img.imageGetImageDisplay(0)
		number nBar=imgDisp.componentCountChildrenOfType(31)
		if(nBar==0)
		{
			imgDisp.applyDataBar(0)
		}

		component scaleBar=imgDisp.componentGetNthChildOfType(31,0)

		number fontSize
		string sFont
		number attrib
		scaleBar.componentGetFontInfo(sFont,attrib,fontSize)
		self.setData("font",sFont)
		self.setData("font size",fontSize)
		self.setData("attributes",attrib)	
		
		scaleBar.componentSetDrawingMode(1)// set the font to black outlined with white

		number r,g,b
		scaleBar.componentGetForegroundColor(r,g,b)
		self.setData("foreground",rgb(r,g,b))

		scaleBar.componentGetBackgroundColor(r,g,b)
		self.setData("background",rgb(r,g,b))

		number sizeX,sizeY
		img.GetSize(sizeX,sizeY)

		number rTop,rLeft,rBottom,rRight
		scaleBar.componentGetRect(rTop,rLeft,rBottom,rRight)
	
		number sTop,sLeft,sBottom,sRight
		number posX,posY
		number rightAligned;self.getData("right aligned",rightAligned)
		if(rightAligned)
		{
			posX=rRight/sizeX
		}
		else
		{
			posX=rLeft/sizeX
		}
		self.setData("position X",posX)

		posY=rBottom/sizeY
		self.setData("position Y",posY)
		return self
	}

	
	object setFormat(object self,image &img)
	{
		imagedisplay imgDisp=img.imageGetImageDisplay(0)
		number nBar=imgDisp.componentCountChildrenOfType(31)
		if(nBar==0)
		{
			imgDisp.applyDataBar(0)
		}

		component scaleBar=imgDisp.componentGetNthChildOfType(31,0)

		number fontSize
		string sFont
		number attrib
		self.getData("font",sFont)
		self.getData("font size",fontSize)
		self.getData("attributes",attrib)
		scalebar.componentsetfontinfo(sFont,0,fontsize)

		scaleBar.componentSetDrawingMode(1)// set the font to black outlined with white

		rgbnumber col
		self.getData("foreground",col)
		scaleBar.componentSetForegroundColor(red(col),green(col),blue(col))
	
		self.getData("background",col)
		scaleBar.componentSetBackgroundColor(red(col),green(col),blue(col))
	
		number sizeX,sizeY
		img.GetSize(sizeX,sizeY)

		number rTop,rLeft,rBottom,rRight
		scaleBar.componentGetRect(rTop,rLeft,rBottom,rRight)
	
		number posX,posY
		self.getData("position X",posX)
		number sTop,sLeft,sBottom,sRight
		number rightAligned;self.getData("right aligned",rightAligned)
		if(rightAligned)
		{
			sRight=posX*sizeX
			sLeft=sRight-(rRight-rLeft)
		}
		else
		{
			sLeft=posX*sizeX
			sRight=sLeft+rRight-rLeft
		}
	
		self.getData("position Y",posY)
		sBottom=posY*sizeY
		sTop=sBottom+(rTop-rBottom)
		scaleBar.componentSetRect(sTop,sLeft,sBottom,sRight)
		return self
	}

	//	
	void setValues(object self)
	{
		self.setNumber("font size")
		self.setNumber("position X")
		self.setNumber("position Y")
		self.setPopup("font")
	}

	void pickForeground(object self)
	{
		rgbnumber col
		self.getData("foreground",col)
		rgbnumber default=col,choice=col
		if(getRGBColorDialog("Foreground color",default,choice))
			self.setData("foreground",choice)
	}

	void pickBackground(object self)
	{
		rgbnumber col
		self.getData("background",col)
		rgbnumber default=col,choice=col
		if(getRGBColorDialog("Background color",default,choice))
			self.setData("background",choice)
	}
	
	void getFormat(object self)
	{
		image img
		if(GetFrontImage(img))
		{
			self.getFormat(img)
			self.setValues()
		}
	}

	void setFormat(object self)
	{
		image img
		if(GetFrontImage(img))
			self.setFormat(img)
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		openandSetProgressWindow("","","")	
				
		TagGroup fontList=newTagList()
		fontList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Arial","Arial"))
		fontList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("Times New Roman","Times New Roman"))
		TagGroup fontTag=self.createPopup("font","Font",fontList).dlgExternalPadding(5,5)
		dlgItems.dlgAddElement(fontTag.dlgSide("West"))

		//dialog_items.DLGAddElement(self.NewString(font_tag,"Font",10).DLGSide("West"))
		dlgItems.dlgAddElement(self.createNumber("font size","Font Size",10,0).dlgSide("West"))
		dlgItems.dlgAddElement(self.createNumber("position X","Position X",10,2).dlgSide("West"))
		dlgItems.dlgAddElement(self.createNumber("position Y","Position Y",10,2).dlgSide("West"))
		dlgItems.dlgAddElement(self.createCheckBox("right aligned","Right Aligned").dlgSide("West").dlgExternalPadding(5,0))
		
		TagGroup foreTag=self.createButton("foreground","Foreground","pickForeground").dlgSide("West")
		TagGroup backTag=self.createButton("background","Background","pickBackground").dlgSide("West")
		TagGroup colorTag=dlgGroupItems(foreTag,backTag).dlgTableLayout(2,1,0)
		dlgItems.dlgAddElement(colorTag)
	//dialog_items.TagGroupOpenBrowserWindow(0)
		//dialog_items.DLGAddElement(self.NewReal(fontSize_tag,"Position Y",10,0).DLGSide("West"))
		//dialog_items.DLGAddElement(brightness_tag.get())

		TagGroup getTag=self.createButton("get","Get","getFormat").DLGAnchor("West")
		TagGroup setTag=self.createButton("set","Set","setFormat").DLGAnchor("West")
		
		TagGroup formatTag=dlgGroupItems(getTag,setTag).DLGTableLayout(2,1,0)

		dlgItems.dlgAddElement(formatTag)
		//TagGroup group5=DLGGroupItems(online_tag,show_tag);

		dlgTags.dlgTableLayout(1,8,0)
		
		self.super.init(dlgTags)
		return self
	}

	void showValues(object self)
	{
	}

}

void showScaleMarker()
{
	alloc(ScaleMarker).load().init().display()
}
if(SCALEMARKER_display)showScaleMarker()
	
