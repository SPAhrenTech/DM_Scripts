/*
P. Ahrenkiel-2020
JEM_Dialog is parent class for making dialogs.
The TagGroup dataTags contains tags with data for the various dialog elements.
This is copied by reference from the inherited class.
There is no way to determine which button was pressed after the fact without using
BevelButton, and I don't know how to make those work like standard buttons, so you have to provide
a separate method for every button.
*/
module com.gatan.dm.JEM_Dialog
uses com.gatan.dm.JEM_Data

number TestDialog_doDisplay=0

interface JEM_DialogProto
{
//	
}

class JEM_Dialog:JEM_Thread
{
	JEM_Dialog(object self){}

	object init(object self,TagGroup dlgTags)
	{
		return self.super.init(dlgTags);
	}

	void setValues(object self){}
	void numberChanged(object self,string sIdent,number val){self.setData(sIdent,val);}
	void stringChanged(object self,string sIdent,string sVal){self.setData(sIdent,sVal);}
	void boxChecked(object self,string sIdent,number val){self.setData(sIdent,val);}		
	void buttonPressed(object self,string sIdent){}
	void stepChanged(object self,string sIdent,number step){self.setData(sIdent+" step",step);}			
	TagGroup getField(object self,string sIdent)
	{
		TagGroup fieldTag=self.lookUpElement(sIdent)
		return fieldTag
	}

	void popupChanged(object self,string sIdent,tagGroup itemTag)
	{	
		number i=0,nTags=itemTag.tagGroupCountTags()
		for(i=0;i<nTags;++i)
			if(itemTag.tagGroupGetTagLabel(i)=="Value")break
				
		number itemType=itemTag.tagGroupGetTagType(i,0)
	
		if(itemType==20)//string
		{
			string sVal;itemTag.tagGroupGetTagAsString("Value",sVal)
			self.setData(sIdent,sVal);
			//result(sIdent+" (string): "+sVal+"\n")
		}
		else
		{
			number val;itemTag.tagGroupGetTagAsNumber("Value",val)
			if(right(sIdent,4)=="step")
				self.stepChanged(left(sIdent,len(sIdent)-5),val)
			else
				self.setData(sIdent,val)
			//result(sIdent+" (number): "+val+"\n")
		}
	}

	//	
	void changedAction(object self,TagGroup fieldTag)
	{
		string sIdent;fieldTag.dlgGetIdentifier(sIdent)		
		string sType=fieldTag.dlgGetType()

		if(sType=="Field")
		{
			string sStyle
			fieldTag.tagGroupGetTagAsString("Style",sStyle)
			if(sStyle=="String")
				self.stringChanged(sIdent,fieldTag.dlgGetStringValue())
			if((sStyle=="Real")||(sStyle=="Integer"))
				self.numberChanged(sIdent,fieldTag.dlgGetValue())
		}
		
		if(sType=="Checkbox")
			self.boxChecked(sIdent,fieldTag.dlgGetValue())

		if(sType=="Popup")
		{
			TagGroup itemList,itemTag
			fieldTag.tagGroupGetTagAsTagGroup("Items",itemList)
			number n=fieldTag.dlgGetValue()-1
			itemList.tagGroupGetIndexedTagAsTagGroup(n,itemTag)
			self.popupChanged(sIdent,itemTag)
		}		

		if(sType=="BevelButton")
		{
			string sTrueIdent
			fieldTag.tagGroupGetTagAsString("button ID",sTrueIdent)
			self.buttonPressed(sTrueIdent)
		}	
	}

	//	
	TagGroup createNumber(object self,string sIdent,string sTitle,number nDig,number nDec,string sPos)
	{
		number val;self.getData(sIdent,val)
		TagGroup labelTag=dlgCreateLabel(sTitle)
		if(sPos=="Top")labelTag.dlgSide("West")
		if(sPos=="Left")labelTag.dlgAnchor("East")

		TagGroup fieldTag=dlgCreateRealField(val,nDig,nDec).dlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		TagGroup groupTag=dlgGroupItems(labelTag,fieldTag)
		if(sPos=="Top")groupTag.dlgTableLayout(1,2,0)
		if(sPos=="Left")groupTag.dlgTableLayout(2,1,0)
		return groupTag
	}

	//	
	TagGroup createNumber(object self,string sIdent,string sTitle,number nDig,number nDec)
	{
		number val;self.getData(sIdent,val)
		TagGroup fieldTag,groupTag=dlgCreateRealField(sTitle,fieldTag,val,nDig,nDec)
		fieldTag.dlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		return groupTag
	}

	//	
	TagGroup createNumber(object self,string sIdent,string sTitle,number nDig)
	{
		number val;self.getData(sIdent,val)
		TagGroup fieldTag,groupTag=dlgCreateIntegerField(sTitle,fieldTag,val,ndig)
		fieldTag.dlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		return groupTag
	}
	
	//	
	TagGroup createNumber(object self,string sIdent,string sTitle,number nDig,string sPos)
	{
		number val;self.getData(sIdent,val)
		TagGroup labelTag=dlgCreateLabel(sTitle)
		if(sPos=="Top")labelTag.dlgAnchor("West")
		if(sPos=="Left")labelTag.dlgAnchor("East")

		TagGroup fieldTag=dlgCreateIntegerField(val,ndig)
		fieldTag.dlgIdentifier(sIdent).dlgChangedMethod("changedAction")

		TagGroup groupTag=dlgGroupItems(labelTag,fieldTag)
		if(sPos=="Top")groupTag.dlgTableLayout(1,2,0)
		if(sPos=="Left")groupTag.dlgTableLayout(2,1,0)
		return groupTag
	}
	
	//	
	TagGroup createString(object self,string sIdent,string sTitle,number width,string sPos)
	{
		string sVal;self.getData(sIdent,sVal);
		TagGroup labelTag=dlgCreateLabel(sTitle)
		if(sPos=="Top")labelTag.dlgAnchor("West")
		if(sPos=="Left")labelTag.dlgAnchor("East")

		TagGroup fieldTag,groupTag
		fieldTag=dlgCreateStringField(sVal,width).dlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		groupTag=dlgGroupItems(labelTag,fieldTag)
		if(sPos=="Top")groupTag.dlgTableLayout(1,2,0)
		if(sPos=="Left")groupTag.dlgTableLayout(2,1,0)
		return groupTag
	}

	//	
	TagGroup createString(object self,string sIdent,string sTitle,number width)
	{
		string sVal;self.getData(sIdent,sVal);	
		TagGroup fieldTag,groupTag
		groupTag=dlgCreateStringField(sTitle,fieldTag,sVal,width)
		fieldTag.dlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		return groupTag
	}

	//	
	TagGroup createCheckBox(object self,string sIdent,string sTitle)
	{
		number val;self.getData(sIdent,val)
		TagGroup fieldTag=dlgCreateCheckBox(sTitle,val).dlgInternalPadding(5,0).dlgAnchor("West")
		return fieldTag.dlgIdentifier(sIdent).dlgChangedMethod("changedAction")		
	}
	
	//	
	TagGroup createButton(object self,string sIdent,string sTitle,string sAction)
	{
		return dlgCreatePushButton(sTitle,sAction).dlgIdentifier(sIdent)
	}	
	
	//	
	TagGroup createButton(object self,string sIdent,image onImg,image offImg,string sAction)
	{
		return dlgCreateDualStateBevelButton(sIdent,onImg,offImg,sAction)
	}	

	//	
	TagGroup createButton(object self,string sIdent,string sTitle,string sLabelOn,string sLabelOff,number initState,string sAction)
	{
		TagGroup fieldTag=dlgCreatePushButton(sTitle,sAction).dlgIdentifier(sIdent)
		TagGroup labelTag
		if(initState)
			labelTag=dlgCreateLabel(sLabelOn)
		else
			labelTag=dlgCreateLabel(sLabelOff)
		labelTag=labelTag.dlgIdentifier(sIdent+" label")
		labelTag.tagGroupCreateNewLabeledTag("on label")//,sLabelOn
		labelTag.tagGroupSetTagAsString("on label",sLabelOn)
		labelTag.tagGroupCreateNewLabeledTag("off label")//sLabelOff)
		labelTag.tagGroupSetTagAsString("off label",sLabelOff)
		return dlgGroupItems(fieldTag,labelTag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}	

	//	
	TagGroup createTabList(object self,string sIdent,number value)
	{
		TagGroup fieldTag=dlgCreateTabList(value)
		return fieldTag.dlgIdentifier(sIdent)
	}	

	TagGroup createTextBox(object self,string sIdent,number width,number height,number length)
	{
		TagGroup fieldTag=dlgCreateTextBox(width,height,length)
		fieldTag.dlgIdentifier(sIdent)
		return fieldTag
	}	

	TagGroup createList(object self,string sIdent,number width,number height,string sChanged,string sAction)
	{
		TagGroup fieldTag=dlgCreateList(width,height)
		fieldTag.dlgIdentifier(sIdent).dlgChangedMethod(sChanged).dlgActionMethod(sAction)
		return fieldTag
	}	

	//Select popup value
	void changePopup(object self,string sIdent,TagGroup fieldTag)
	{
		TagGroup itemList;fieldTag.tagGroupGetTagAsTagGroup("Items",itemList)
		number n=self.findItem(sIdent,itemList)		
		fieldTag.dlgValue(n+1)
	}
	
	//	
	TagGroup createPopup(object self,string sIdent,TagGroup itemList)
	{
		TagGroup dlgItems
		TagGroup fieldTag=dlgCreatePopup(dlgItems).DlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		number nItems=itemList.TagGroupCountTags()
		for(number i=0;i<nItems;++i)
		{
			TagGroup itemTag;itemList.tagGroupGetIndexedTagAsTagGroup(i,itemTag)
			dlgItems.tagGroupInsertTagAsTagGroup(infinity(),itemTag)
		}

		//Set popup value
		self.changePopup(sIdent,fieldTag)
		return fieldTag
	}


	//	
	TagGroup createPopup(object self,string sIdent,string sTitle,TagGroup itemList,string sPos)
	{
		TagGroup dlgItems
		TagGroup fieldTag=dlgCreatePopup(dlgItems).DlgIdentifier(sIdent).dlgChangedMethod("changedAction")
		number nItems=itemList.TagGroupCountTags()
		for(number i=0;i<nItems;++i)
		{
			TagGroup itemTag;itemList.tagGroupGetIndexedTagAsTagGroup(i,itemTag)
			dlgItems.tagGroupInsertTagAsTagGroup(infinity(),itemTag)
		}

		tagGroup titleTag=dlgCreateLabel(sTitle)
		if(sPos=="Top")titleTag.dlgAnchor("West")
		if(sPos=="Left")titleTag.dlgAnchor("East")

		TagGroup groupTag=dlgGroupItems(titleTag,fieldTag)
		if(sPos=="Top")groupTag.dlgTableLayout(1,2,0)
		if(sPos=="Left")groupTag.dlgTableLayout(2,1,0)

		//Set popup value
		self.changePopup(sIdent,fieldTag)
		return groupTag
	}

	//	
	TagGroup createPopup(object self,string sIdent,string sTitle,TagGroup itemList)
	{
		return self.createPopup(sIdent,sTitle,itemList,"Left")
	}

	//	
	TagGroup createStringLabel(object self,string sIdent,string sTitle,number nLen)
	{
		string sVal;self.getData(sIdent,sVal)		
		TagGroup fieldTag=dlgCreateLabel(sVal,nLen).dlgIdentifier(sIdent).dlganchor("East")
		tagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("East")
		return dlgGroupItems(titleTag,fieldTag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberLabel(object self,string sIdent,string sTitle,string sFormat,number nLen)
	{
		number val;self.getData(sIdent,val)		
		string sVal=format(val,sFormat);//while(len(sVal)<nLen){sVal=" "+sVal;}	
		TagGroup fieldTag=dlgCreateLabel(sVal,nLen).dlgIdentifier(sIdent).dlganchor("East")
		number index=fieldTag.tagGroupCreateNewLabeledTag("Format")
		fieldTag.tagGroupSetIndexedTagAsString(index,sFormat)
		tagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("East")
		return dlgGroupItems(titleTag,fieldTag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createHexNumberLabel(object self,string sIdent,string sTitle,number nLen)
	{
		number val;self.getData(sIdent,val)
		string sVal=hex(val)
		TagGroup fieldTag=dlgCreateLabel(sVal,nLen).dlgIdentifier(sIdent).dlganchor("East")
		number index=fieldTag.tagGroupCreateNewLabeledTag("Format")
		tagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("East")
		return dlgGroupItems(titleTag,fieldTag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberStep(object self,string sIdent,string sTitle,number nDig,number nDec,string sIncMethod,string sDecMethod)
	{
		TagGroup group1Tag=self.createNumber(sIdent,sTitle,nDig,nDec)
		TagGroup incTag=self.createButton(sIdent+"+","+",sIncMethod)
		TagGroup decTag=self.createButton(sIdent+"-","-",sDecMethod)
		TagGroup group2Tag=dlgGroupItems(incTag,decTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,2)
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberStep(object self,string sIdent,string sTitle,number nDig,string sIncMethod,string sDecMethod)
	{
		TagGroup group1Tag=self.createNumber(sIdent,sTitle,nDig)
		TagGroup incTag=self.createButton(sIdent+"+","+",sIncMethod)
		TagGroup decTag=self.createButton(sIdent+"-","-",sDecMethod)
		TagGroup group2Tag=dlgGroupItems(incTag,decTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,2)
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberLabelStep(object self,string sIdent,string sTitle,string sFormat,number nLen,string sIncMethod,string sDecMethod)
	{
		TagGroup group1Tag=self.createNumberLabel(sIdent,sTitle,sFormat,nLen)
		TagGroup incTag=self.createButton(sIdent+"+","+",sIncMethod)
		TagGroup decTag=self.createButton(sIdent+"-","-",sDecMethod)
		TagGroup group2Tag=dlgGroupItems(incTag,decTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,2)
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberStepSel(object self,string sIdent,string sTitle,number nDig,number nDec,string sIncMethod,string sDecMethod,TagGroup itemList)
	{
		TagGroup group1Tag=self.createNumberStep(sIdent,sTitle,nDig,nDec,sIncMethod,sDecMethod)
		TagGroup group2Tag=self.createPopup(sIdent+" step","Step:",itemList,"Top")
		TagGroup group1=dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlganchor("West").dlgexternalpadding(0,2)	
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,2,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberStepSel(object self,string sIdent,string sTitle,number nDig,string sIncMethod,string sDecMethod,TagGroup itemList)
	{

		TagGroup group1Tag=self.createNumberStep(sIdent,sTitle,nDig,sIncMethod,sDecMethod)
		TagGroup group2Tag=self.createPopup(sIdent+" step","Step:",itemList,"Top")
		TagGroup group1=dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlganchor("West").dlgexternalpadding(0,2)	
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,2,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberLabelStepSel(object self,string sIdent,string sTitle,string sFormat,number nLen,string sIncMethod,string sDecMethod,TagGroup itemList)
	{
		TagGroup group1Tag=self.createNumberLabelStep(sIdent,sTitle,sFormat,nLen,sIncMethod,sDecMethod)
		TagGroup group2Tag=self.createPopup(sIdent+" step","Step:",itemList,"Top")
		TagGroup group1=dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,1,0).dlganchor("West").dlgexternalpadding(0,2)	
		return dlgGroupItems(group1Tag,group2Tag).dlgTableLayout(2,2,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberStepSelXY(object self,string sIdent,string sTitle,number nDig,number nDec,string sIncXMethod,string sDecXMethod,string sIncYMethod,string sDecYMethod,TagGroup itemList)
	{
		TagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("West").dlgexternalpadding(0,5)

		TagGroup XTag=self.createNumber(sIdent+" X","X",nDig,nDec)
		TagGroup incXTag=self.createButton(sIdent+"+","+",sIncXMethod)
		TagGroup decXTag=self.createButton(sIdent+"-","-",sDecXMethod)

		TagGroup yTag=self.createNumber(sIdent+" Y","Y",nDig,nDec)
		TagGroup incYTag=self.createButton(sIdent+"+","+",sIncYMethod)
		TagGroup decYTag=self.createButton(sIdent+"-","-",sDecYMethod)
		TagGroup group1Tag=dlgGroupItems(incYTag,decYTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,2)

		TagGroup group2Tag=dlgGroupItems(decXTag,group1Tag,incXTag).dlgTableLayout(3,1,0).dlganchor("West")
		TagGroup group3Tag=dlgGroupItems(titleTag,group2Tag).dlgTableLayout(1,2,0).dlganchor("West")	
		TagGroup group4Tag=dlgGroupItems(XTag,YTag).dlgTableLayout(2,1,0).dlganchor("West").dlgexternalpadding(0,2)	
		TagGroup group5Tag=self.createPopup(sIdent+" step","Step:",itemList,"Top")
		
		TagGroup group6Tag=dlgGroupItems(group4Tag,group5Tag).dlgTableLayout(1,3,0).dlganchor("West").dlgexternalpadding(0,2)	

		TagGroup groupTag=dlgGroupItems(group3Tag,group6Tag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
		return groupTag
	}

	//	
	TagGroup createNumberStepSelXY(object self,string sIdent,string sTitle,number nDig,string sIncXMethod,string sDecXMethod,string sIncYMethod,string sDecYMethod,TagGroup itemList)
	{
		TagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("West").dlgexternalpadding(0,5)

		TagGroup XTag=self.createNumber(sIdent+" X","X",nDig)
		TagGroup incXTag=self.createButton(sIdent+"+","+",sIncXMethod)
		TagGroup decXTag=self.createButton(sIdent+"-","-",sDecXMethod)

		TagGroup yTag=self.createNumber(sIdent+" Y","Y",nDig)
		TagGroup incYTag=self.createButton(sIdent+"+","+",sIncYMethod)
		TagGroup decYTag=self.createButton(sIdent+"-","-",sDecYMethod)
		TagGroup group1Tag=dlgGroupItems(incYTag,decYTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,2)

		TagGroup group2Tag=dlgGroupItems(decXTag,group1Tag,incXTag).dlgTableLayout(3,1,0).dlganchor("West")
		TagGroup group3Tag=dlgGroupItems(titleTag,group2Tag).dlgTableLayout(1,2,0).dlganchor("West")	
		TagGroup group4Tag=dlgGroupItems(XTag,YTag).dlgTableLayout(2,1,0).dlganchor("West").dlgexternalpadding(0,2)	
		TagGroup group5Tag=self.createPopup(sIdent+" step","Step",itemList,"Top")
		
		TagGroup group6Tag=dlgGroupItems(group4Tag,group5Tag).dlgTableLayout(1,3,0).dlganchor("West").dlgexternalpadding(0,5)	
		return dlgGroupItems(group3Tag,group6Tag).dlgTableLayout(2,1,0).dlgexternalpadding(2,0)
	}

	//	
	TagGroup createNumberLabelStepSelXY(object self,string sIdent,string sTitle,string sFormat,number nLen,string sIncXMethod,string sDecXMethod,string sIncYMethod,string sDecYMethod,TagGroup itemList)
	{
		TagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("West").dlgexternalpadding(0,5)
		TagGroup X_Tag=self.createNumberLabel(sIdent+" X","X",sFormat,nLen)
		TagGroup Y_Tag=self.createNumberLabel(sIdent+" Y","Y",sFormat,nLen)
		TagGroup group1Tag=dlgGroupItems(titleTag,X_Tag,Y_Tag).dlgTableLayout(1,3,0).dlganchor("West")	

		TagGroup incXTag=self.createButton(sIdent+"+","+",sIncXMethod)
		TagGroup decXTag=self.createButton(sIdent+"-","-",sDecXMethod)
		TagGroup incYTag=self.createButton(sIdent+"+","+",sIncYMethod)
		TagGroup decYTag=self.createButton(sIdent+"-","-",sDecYMethod)
		TagGroup group2Tag=dlgGroupItems(incYTag,decYTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,5)
		TagGroup group3Tag=dlgGroupItems(decXTag,group2Tag,incXTag).dlgTableLayout(3,1,0).dlganchor("West")

		TagGroup group4Tag=self.createPopup(sIdent+" step","Step",itemList,"Top")
		return dlgGroupItems(group1Tag,group3Tag,group4Tag).dlgTableLayout(3,1,0).dlgexternalpadding(5,0)
	}

	//	
	TagGroup createHexNumberLabelStepSelXY(object self,string sIdent,string sTitle,number nLen,string sIncXMethod,string sDecXMethod,string sIncYMethod,string sDecYMethod,TagGroup itemList)
	{
		TagGroup titleTag=dlgCreateLabel(sTitle).dlganchor("West").dlgexternalpadding(0,5)
		TagGroup X_Tag=self.createHexNumberLabel(sIdent+" X","X",nLen)
		TagGroup Y_Tag=self.createHexNumberLabel(sIdent+" Y","Y",nLen)
		TagGroup group1Tag=dlgGroupItems(titleTag,X_Tag,Y_Tag).dlgTableLayout(1,3,0).dlganchor("West")	

		TagGroup incXTag=self.createButton(sIdent+"+","+",sIncXMethod)
		TagGroup decXTag=self.createButton(sIdent+"-","-",sDecXMethod)
		TagGroup incYTag=self.createButton(sIdent+"+","+",sIncYMethod)
		TagGroup decYTag=self.createButton(sIdent+"-","-",sDecYMethod)
		TagGroup group2Tag=dlgGroupItems(incYTag,decYTag).dlgTableLayout(1,2,0).dlganchor("West").dlgexternalpadding(0,5)
		TagGroup group3Tag=dlgGroupItems(decXTag,group2Tag,incXTag).dlgTableLayout(3,1,0).dlganchor("West")

		TagGroup group4Tag=self.createPopup(sIdent+" step","Step",itemList,"Top")		
		return dlgGroupItems(group1Tag,group3Tag,group4Tag).dlgTableLayout(3,1,0).dlgexternalpadding(5,0)
	}

//Set functions
	//	
	void setButtonState(object self,string sIdent,number isOn)
	{
		//self.dlgBevelButtonOn(sIdent,isOn)
		TagGroup labelTag=self.lookUpElement(sIdent+" label")
		string sLabel
		if(isOn)
			labelTag.tagGroupGetTagAsString("on label",sLabel)
		else
			labelTag.tagGroupGetTagAsString("off label",sLabel)
		labelTag.dlgTitle(sLabel)		
	}
		
	//
	void setNumber(object self,string sIdent)
	{
		number val;self.getData(sIdent,val)
		self.lookUpElement(sIdent).dlgValue(val)	
	}
			
	//
	void setStringLabel(object self,string sIdent)
	{
		string sVal;self.getData(sIdent,sVal)
		TagGroup fieldTag=self.lookUpElement(sIdent)
		fieldTag.dlgTitle(sVal)	
	}

	//
	void setNumberLabel(object self,string sIdent)
	{
		number val;self.getData(sIdent,val)
		TagGroup fieldTag=self.lookUpElement(sIdent)
		string sFormat;fieldTag.tagGroupGetTagAsString("Format",sFormat)
		string sVal=format(val,sFormat)
		fieldTag.dlgTitle(sVal)	
	}

	//
	void setHexNumberLabel(object self,string sIdent)
	{
		number val;self.getData(sIdent,val)
		TagGroup fieldTag=self.lookUpElement(sIdent)
		string sVal=hex(val)
		fieldTag.dlgTitle(sVal)	
	}

	void setString(object self,string sIdent)
	{
		string sVal;self.getData(sIdent,sVal)
		self.lookUpElement(sIdent).dlgValue(sVal)
	}
			
	void setCheckBox(object self,string sIdent)
	{
		number val;self.getData(sIdent,val)
		self.lookUpElement(sIdent).dlgValue(val)
	}
			
	void setPopup(object self,string sIdent)
	{
		TagGroup fieldTag=self.lookUpElement(sIdent)
		self.changePopup(sIdent,fieldTag)
	}
	
	void setInvalid(object self,string sIdent,number isInvalid)
	{
		TagGroup fieldTag=self.lookUpElement(sIdent)
		fieldTag.dlgInvalid(isInvalid)
	}
	
	//	
	void setNumberLabelStepSel(object self,string sIdent)
	{
		self.setNumberLabel(sIdent)
	}

	//	
	void setNumberLabelStepSelXY(object self,string sIdent)
	{
		self.setNumberLabel(sIdent+" X")
		self.setNumberLabel(sIdent+" Y")
	}
	//	
	void setHexNumberLabelStepSelXY(object self,string sIdent)
	{
		self.setHexNumberLabel(sIdent+" X")
		self.setHexNumberLabel(sIdent+" Y")
	}

//Get functions
	//
	void getNumber(object self,string sIdent)
	{
		number val;self.lookUpElement(sIdent).dlgGetValue(val)
		self.setData(sIdent,val);
	}
			
	void getString(object self,string sIdent)
	{
		string sVal=self.lookUpElement(sIdent).dlgGetStringValue();
		self.setData(sIdent,sVal);
	}
			
	void getCheckBox(object self,string sIdent)
	{
		number val;self.lookUpElement(sIdent).dlgValue(val)
		self.setData(sIdent,val);
	}
			
	void getPopup(object self,string sIdent)
	{
		TagGroup fieldTag=self.lookUpElement(sIdent)
		number n;fieldTag.dlgGetValue(n)
		TagGroup itemList;fieldTag.TagGroupGetTagAsTagGroup("Items",itemList)
		//dlgItems.dlgGetNthLabel(n-1,sVal)
		TagGroup itemTag;itemList.tagGroupGetIndexedTagAsTagGroup(n-1,itemTag)
		number valueType=itemTag.tagGroupGetTagType(1,0)
		if(valueType==20)
		{
			string sVal;itemTag.tagGroupGetTagAsString("Value",sVal)
			self.setData(sIdent,sVal);
		}
		else
		{
			number val;itemTag.tagGroupGetTagAsNumber("Value",val)
			self.setData(sIdent,val);
		}		
	}

//These are for popups that change step size
	void stepData(object self,string sIdent,number plusOrMinus)
	{
		number val,valStep
		self.getData(sIdent,val)
		self.getData(sIdent+" step",valStep)
		self.setData(sIdent,val+plusOrMinus*valStep)
	}
	
	void stepData(object self,string sIdent,number plusOrMinus,number minVal,number maxVal)
	{
		number val,valStep
		self.getData(sIdent,val)
		self.getData(sIdent+" step",valStep)
		number newVal=val+plusOrMinus*valStep
		if(newVal<minVal)newVal=minVal
		if(newVal>maxVal)newVal=maxVal		
		self.setData(sIdent,newVal)
	}

	void stepData(object self,string sIdent,string sVariant,number plusOrMinus)
	{
		number val,valStep
		self.getData(sIdent+" step",valStep)
		string sIdentVar=sIdent
		if(sVariant!="")
			sIdentVar+=" "+sVariant
		self.getData(sIdentVar,val)
		number newVal=val+plusOrMinus*valStep		
		self.setData(sIdentVar,newVal)
	}

	void stepData(object self,string sIdent,string sVariant,number plusOrMinus,number minVal,number maxVal)
	{
		number val,valStep
		self.getData(sIdent+" step",valStep)
		string sIdentVar=sIdent
		if(sVariant!="")
			sIdentVar+=" "+sVariant
		self.getData(sIdentVar,val)
		number newVal=val+plusOrMinus*valStep
		if(newVal<minVal)newVal=minVal
		if(newVal>maxVal)newVal=maxVal		
		self.setData(sIdentVar,newVal)
	}
	
//These are just for convenience in making and responding to popups
	tagGroup newItemTagGroup(object self,string sLabel,string sVal)
	{
		TagGroup itemTag=NewTagGroup()
		
		number index
		index=itemTag.tagGroupCreateNewLabeledTag("Label")
		itemTag.tagGroupSetIndexedTagAsString(index,sLabel)

		index=itemTag.tagGroupCreateNewLabeledTag("Value")
		itemTag.tagGroupSetIndexedTagAsString(index,sVal)
		return itemTag
	}

	TagGroup newItemTagGroup(object self,string sLabel,number val)
	{
		TagGroup itemTag=NewTagGroup()
		
		number index
		index=itemTag.tagGroupCreateNewLabeledTag("Label")
		itemTag.tagGroupSetIndexedTagAsString(index,sLabel)

		index=itemTag.tagGroupCreateNewLabeledTag("Value")
		itemTag.tagGroupSetIndexedTagAsNumber(index,val)
		return itemTag
	}

	TagGroup newItemTagGroup(object self,string sLabel,rgbnumber val)
	{
		TagGroup itemTag=NewTagGroup()
		
		number index
		index=itemTag.tagGroupCreateNewLabeledTag("Label")
		itemTag.tagGroupSetIndexedTagAsString(index,sLabel)

		index=itemTag.tagGroupCreateNewLabeledTag("Value")
		itemTag.tagGroupSetIndexedTagAsNumber(index,val)
		return itemTag
	}

}

/*
Example dialog (not instantiated)
*/
class TestDialog:JEM_Dialog
{
	object obj

	/*
	*/
	void setValues(object self)
	{
		self.setHexNumberLabelStepSelXY("position")
		self.setNumberLabelStepSel("range")
		self.setNumber("scale")
	}

	/*
	*/
	void getValues(object self)
	{
	}	

	void incScale(object self){self.stepData("scale",1);self.setValues();}		
	void decScale(object self){self.stepData("scale",-1);self.setValues();}
	
	void incRange(object self){self.stepData("range",1);self.setValues();}		
	void decRange(object self){self.stepData("range",-1);self.setValues();}

	void incPositionX(object self){self.stepData("position","X",1,0,0xFFFF);self.setValues();}		
	void decPositionX(object self){self.stepData("position","X",-1,0,0xFFFF);self.setValues();}

	void incPositionY(object self){self.stepData("position","Y",1,0,0xFFFF);self.setValues();}		
	void decPositionY(object self){self.stepData("position","Y",-1,0,0xFFFF);self.setValues();}

	void neutralize(object self){self.setData("range",0);self.setValues();}
	void pausePressed(object self){}
	
	image getPauseImage(object self)
	{
		image thumbnail:=[64,28]:
		{
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,220,225,249,255,255,253,237,222,222,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,226,223,193,152,127,156,222,255,224,221,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,248,194,3,18,49,25,14,153,254,222,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,251,182,0,144,255,230,58,0,199,254,255,255,255,236,219,217,246,255,223,220,217,255,255,218,219,239,255,255,245,220,219,227,254,255,255,230,219,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,186,0,153,255,255,225,0,125,248,144,93,127,229,245,235,175,138,222,230,235,156,147,232,250,220,115,101,171,228,239,254,152,93,139,246,239,219,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,186,0,152,255,255,212,0,162,163,30,70,10,51,231,255,79,0,221,244,255,23,0,255,207,36,41,46,82,245,255,86,11,72,2,75,249,231,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,186,0,151,255,222,35,0,226,215,241,255,249,0,110,255,96,0,221,241,254,46,23,255,74,0,255,255,216,255,122,0,239,255,235,0,130,255,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,191,1,19,38,15,26,179,254,255,201,100,96,3,90,255,97,0,221,241,254,48,25,255,157,0,80,210,255,254,30,30,180,145,177,0,36,255,225,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,188,1,83,143,159,234,255,249,125,11,74,108,7,92,255,91,0,227,239,255,54,23,250,255,164,21,0,139,252,29,31,54,39,44,55,121,247,224,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,249,185,0,170,255,252,234,246,193,0,132,255,255,12,68,255,98,0,235,255,255,35,23,246,249,255,255,119,0,209,34,61,255,247,241,255,241,218,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,250,184,0,142,255,223,223,253,180,0,128,252,136,0,97,255,171,0,103,229,125,0,49,253,179,178,255,138,0,221,163,0,143,244,226,184,213,229,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,250,185,0,143,255,223,223,228,245,106,1,41,90,35,77,255,251,105,0,16,84,72,45,255,121,19,42,15,124,252,255,123,8,38,40,46,201,243,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,228,216,182,209,229,223,223,220,232,251,182,151,238,208,183,229,233,250,184,158,242,222,180,227,226,179,147,197,255,224,228,255,209,150,155,201,228,224,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,219,228,254,234,219,223,223,223,220,227,250,253,227,244,246,219,220,227,251,254,226,238,250,219,228,248,254,244,224,221,222,223,240,254,252,239,223,222,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218},
			{232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232}
		}
		return thumbnail
	}

	image getProceedImage(object self)
	{
		image thumbnail:=[64,28]:
		{
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,222,224,229,225,222,223,223,223,223,223,223},
			{223,223,223,223,223,223,219,230,251,255,255,250,233,221,222,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,221,226,245,232,220,223,223,223,223,223,223},
			{223,223,223,223,223,223,227,220,189,141,128,168,235,255,220,222,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,240,201,62,162,246,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,156,0,32,49,17,31,188,250,221,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,251,188,0,124,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,131,0,198,255,212,17,6,229,255,249,238,255,226,219,242,255,255,251,226,220,223,219,232,255,255,255,234,218,222,248,255,255,238,219,222,219,234,255,255,251,224,221,220,225,251,255,255,202,0,138,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,137,0,200,255,255,172,0,184,183,182,215,117,207,255,210,114,94,174,255,234,218,252,239,145,93,121,198,234,255,184,93,114,224,251,219,252,234,121,93,174,255,225,231,255,176,94,144,197,3,135,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,137,0,200,255,255,157,0,226,80,25,39,10,244,179,6,46,64,0,104,252,243,218,42,8,57,33,147,255,137,0,69,27,31,217,246,221,39,34,69,0,129,255,255,116,0,59,58,38,5,148,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,138,0,202,255,198,0,28,255,100,0,112,248,220,0,69,255,255,145,0,151,255,28,0,221,255,231,240,187,0,165,255,255,19,59,255,48,35,255,255,148,0,236,185,0,128,255,255,87,0,154,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,153,0,28,39,5,50,215,255,63,4,253,255,107,0,227,253,232,255,25,59,208,0,165,255,223,233,255,97,0,164,148,178,38,0,223,0,86,172,156,143,0,162,99,11,255,237,255,210,0,138,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,144,0,109,137,173,246,251,255,58,16,246,255,74,0,244,232,222,255,59,46,162,0,207,251,222,224,255,76,10,62,39,42,51,113,183,6,51,49,40,48,56,195,57,36,255,223,245,205,0,135,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,135,0,225,255,250,230,221,255,61,14,240,255,121,0,211,255,249,255,7,78,219,0,142,255,236,246,255,72,2,255,255,239,255,255,197,0,149,255,239,248,255,255,59,2,253,255,255,197,0,143,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,134,0,191,248,223,223,224,255,53,3,241,246,230,5,23,225,243,79,0,193,255,46,0,169,230,182,215,198,0,84,237,234,191,205,254,58,0,193,242,210,187,252,184,0,79,236,204,45,0,149,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,255,135,0,192,248,223,223,224,255,56,7,241,229,254,195,35,25,39,20,162,255,238,229,66,0,35,26,149,255,167,20,28,42,37,158,255,236,73,13,46,34,84,237,255,145,0,23,41,111,24,125,255,223,223,223,223,223,223},
			{223,223,223,223,223,223,229,207,182,217,227,223,223,223,229,193,184,226,224,219,255,238,165,153,226,255,224,218,245,250,186,150,184,222,226,255,227,160,148,190,225,223,243,252,188,147,170,213,226,227,255,209,153,193,255,189,199,229,223,223,223,223,223,223},
			{223,223,223,223,223,223,219,235,254,227,220,223,223,223,219,246,252,221,222,223,221,232,251,253,235,221,222,223,221,228,247,254,246,227,221,221,235,252,254,242,226,221,221,227,245,254,249,233,221,221,222,242,254,241,223,251,238,219,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223,223},
			{218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218,218},
			{232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232,232}
		}
		return thumbnail
	}
	
	TestDialog(object self)
	{
		self.setGroup("TEST")
		self.addData("frequency",60)
		self.addData("amplitude",10)		
		self.addData("name","Fred")		
		self.addData("alive",1)		
		self.addData("acquisition mode","mode 3")		
		self.addData("wavelength",540)		
		self.addData("scale",50)		
		self.addData("range",10)		
		self.addData("position X",1)		
		self.addData("position Y",2)		
		
		self.addData("TEST dialog","scale step",10)		
		self.addData("TEST dialog","range step",10)		
		self.addData("TEST dialog","position step",256)		
	}

	object init(object self)
	{
		TagGroup dlgItems,dlgTags=dlgCreateDialog("test",dlgItems)

		TagGroup tag3=self.createString("name","Name",10,"Left").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag3)
	
		TagGroup tag1=self.createNumber("frequency","freq (Hz)",10,2,"Left").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag1)

		TagGroup tag2=self.createNumber("amplitude","amp (mrad)",10,"Top").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag2)

		TagGroup tag4=self.createCheckBox("alive","Alive").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag4)

//
		TagGroup rangeStepList=newTagList()
		rangeStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1",1))
		rangeStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("10",10))
		rangeStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("100",100))
	
		TagGroup tag8=self.createNumberLabelStepSel("range","Range","%6.3g",7,"incRange","decRange",rangeStepList).dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag8)

		//
		TagGroup modeListTag=newTagList()
		modeListTag.TagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mode 1","1"))
		modeListTag.TagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mode 2","2"))
		modeListTag.TagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mode 3","3"))
		modeListTag.TagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("mode 4","4"))
		TagGroup tag5=self.createPopup("acquisition mode","Mode:",modeListTag,"Top").dlgSide("West").dlgexternalpadding(5,0)

		//TagGroup tag6=self.createParField(dataTags,"wavelength","lambda (nm)",10,2).dlgSide("West").dlgexternalpadding(5,0)
	//	dialogItems.dlgAddElement(tag6)

		dlgItems.dlgAddElement(tag5)


		TagGroup tag6=self.createButton("neutral","NTRL","neutralize").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag6)

		TagGroup tag7=self.createNumberStep("scale","Scale",10,2,"incScale","decScale").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag7)

		TagGroup tag7p5=self.createButton("pause",self.getPauseImage(),self.getProceedImage(),"pausePressed").dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag7p5)

//
		TagGroup posStepList=newTagList()
		posStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1",1))
		posStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("10",16))
		posStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("100",256))
		posStepList.tagGroupInsertTagAsTagGroup(infinity(),self.newItemTagGroup("1000",4096))
		TagGroup tag9=self.createHexNumberLabelStepSelXY("position","Position",6,"incPositionX","decPositionX","incPositionY","decPositionY",\
			posStepList).dlgSide("West").dlgexternalpadding(5,0)
		dlgItems.dlgAddElement(tag9)

//
		dlgTags.dlgTableLayout(1,11,0);		
		TagGroup position;
		position=dlgBuildPositionFromApplication();
		position.TagGroupSetTagAsString("Width","Medium")
		position.dlgSide("Right");
		dlgTags.dlgPosition(position);

		self.super.init(dlgTags)
		
		//The dialog elements can't be accessed by identifier until the dialog has been "display"ed of "pose"d.
		//dataTags.TagGroupSetTagAsNumber("frequency",70)
		//dataTags.TagGroupSetTagAsString("acquisition mode","mode 4")
		//self.setNumber(dataTags,"frequency")
		//self.setPopup(dataTags,"acquisition mode")

		return self
	}
	
	void changedAction(object self,TagGroup fieldTag)
	{
		self.super.changedAction(fieldTag)
	}

	object test(object self)
	{
		self.setData("frequency",100);self.setNumber("frequency")
		self.setData("name","Jeff");self.setString("name")	
		self.setData("acquisition mode","mode 2");self.setPopup("acquisition mode")
		return self
	}
}

//Test the above

if(TestDialog_doDisplay)
{
	object dlg=alloc(TestDialog).init()
	dlg.display("test")
	dlg.test()
}
