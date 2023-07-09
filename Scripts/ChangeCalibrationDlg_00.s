//Calibration dialog	
image img
if(!GetFrontImage(img))
{
	OKDialog("You must have an image on which to operate!")
	exit(0)
}

//line annotation
number i=0,annID
number islineAnnot=0
while((i<CountAnnotations(img))&&(!islineAnnot))
{
	annID=GetNthAnnotationID(img,i)
	if(AnnotationType(img,annID)==2)
		if(IsAnnotationSelected(img,annID))
			islineAnnot=1	
	i=i+1
}
	
if(!islineAnnot)
{
	OKDialog("Select a line annotation to show the marker length!")
	exit(0)
}

number sx,sy,ex,ey
GetAnnotationRect(img,annID,sx,sy,ex,ey)
number lineLenPix=((sx-ex)**2+(sy-ey)**2)**0.5//pix

number scaleX,scaleY
GetScale(img,scaleX,scaleY)

string sUnits
sUnits=GetUnitString(img)
if(sUnits=="")sUnits="pix"

number markerLen=lineLenPix*(scaleX+scaleY)/2//

object dataMngr=alloc(DataManager)
dataMngr.addData("length",markerLen,"")
dataMngr.addData("units",sUnits,"")
number E_eV
if(getNumberNote(img,"Microscope Info:Voltage",E_eV))
	dataMngr.addData("E (KeV)",E_eV/1000,"")
	
object dialog=alloc(CalibrationDialog).init(dataMngr)
if(dialog.pose())
{
	dataMngr.getData("length",markerLen)
	dataMngr.getData("units",sUnits)
	
	number scaleXY=markerLen/lineLenPix//nm/pix
	setScale(img,scaleXY,scaleXY)
	setUnitString(img,sUnits)
}


