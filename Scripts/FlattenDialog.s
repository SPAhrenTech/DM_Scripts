//Flatten
//P.Ahrenkiel,6/26/2019
//Removes smooth image background.
//Flattens contrast
string FLATTENDIALOG_sGroup="FLATTENDIALOG"
string FLATTENDIALOG_sName="Flatten"
string FLATTENDIALOG_sTitle="Flatten"
number FLATTENDIALOG_echo=0

number FLATTENDIALOG_brightness=0.5//brightness
number FLATTENDIALOG_contrast=0.5//contrast

//
class FlattenDialog:JEM_Widget
{
	object flattener
	image bimg,vimg
	image nimg
	number m
	image img,img0
	
	object dataMngr
	//

	void findImages(object self)
	{
		flattener.images(img,bimg,vimg)
		m=mean(img)
		img0=img
	}
	/*
	*/
	void setValues(object self)
	{
		self.setNumber("brightness")
		self.setNumber("contrast")
	}


	void adjustImage(object self)
	{
		number brightness;self.getData("brightness",brightness)
		number contrast;self.getData("contrast",contrast)
		img=(img0-bimg)/(contrast*(vimg-1)+1)+bimg-brightness*(bimg-m)
		UpdateImage(img)
	}
	
	void numberChanged(object self,string sIdent,number val)
	{	
		self.super.numberChanged(sIdent,val)
		self.adjustImage()
	}
	
	void incBrightness(object self){self.stepData("brightness",1,0,1);self.setValues();}
	void decBrightness(object self){self.stepData("brightness",-1,0,1);self.setValues();}
	void incContrast(object self){self.stepData("contrast",1,0,1);self.setValues();}
	void decContrast(object self){self.stepData("contrast",-1,0,1);self.setValues();}
	
	FlattenDialog(object self)
	{
		self.setGroup(FLATTENDIALOG_sGroup)
		self.setName(FLATTENDIALOG_sName)
		self.setTitle(FLATTENDIALOG_sTitle)		
		self.setEcho(FLATTENDIALOG_echo)			

	}	
	object load(object self)
	{
		self.addData("brightness",FLATTENDIALOG_brightness)		
		self.addData("brightness step",0.1)		
		self.addData("contrast",FLATTENDIALOG_contrast)	
		self.addData("contrast step",0.1)		
		return self.super.load()
	}
	
	~FlattenDialog(object self)
	{
		self.unload()
	}

	object init(object self,image &timg)
	{
		img:=timg
		flattener=alloc(flatten)
		self.findImages()
		self.adjustImage()

		TagGroup dlgItems,dlgTags=dlgCreateDialog(self.getTitle(),dlgItems)
		
		TagGroup brightnessTag=self.createNumberStep("brightness","brightness",6,2,"incBrightness","decBrightness").DLGSide("West")
		dlgItems.dlgAddElement(brightnessTag)

		TagGroup contrastTag=self.createNumberStep("contrast","contrast",6,2,"incContrast","decContrast").DLGSide("West")
		dlgItems.dlgAddElement(contrastTag)

		dlgTags.dlgTableLayout(1,5,0)
		TagGroup position;
		position=DLGBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.DLGSide("Right");
		dlgTags.DLGPosition(position);

		self.super.init(dlgTags)
		return self
	}

	number AboutToCloseDocument(object self,number verify)
	{
	}		
}


//Main
image img	
if(!GetFrontImage(img)){exit(0);}
image img0=img
object dlg=alloc(FlattenDialog).load().init(img)
if(!dlg.pose())
	img=img0


