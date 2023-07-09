module com.gatan.dm.datamanager
uses com.gatan.dm.jemprefs

class DataManager:uiframe
{
	tagGroup dataTags
	
	DataManager(object self)
	{	
		//result("constructing DataManager\n")
		dataTags=newTagGroup()
	}
	
	TagGroup getTags(object self)
	{
		return dataTags
	}
	
	number getData(object self,string sIdent,string &sVal)
	{
		tagGroup data
		number res=dataTags.tagGroupGetTagAsTagGroup(sIdent,data);
		if(res)
			res=data.tagGroupGetTagAsString("Value",sVal)
		return res
	}

	number getData(object self,string sIdent,number &val)
	{

		tagGroup data
		number res=dataTags.tagGroupGetTagAsTagGroup(sIdent,data);
		
		
		if(res)
			res=data.tagGroupGetTagAsNumber("Value",val)

		return res
	}
	
	number getData(object self,string sIdent,rgbnumber &col)
	{
		tagGroup data
		number res=dataTags.tagGroupGetTagAsTagGroup(sIdent,data);
		if(res)
			res=data.tagGroupGetTagAsNumber("Value",col)
		return res
	}

	number getData(object self,string sIdent,TagGroup &list)
	{
		tagGroup data
		number res=dataTags.tagGroupGetTagAsTagGroup(sIdent,data);
		if(res)
			res=data.tagGroupGetTagAsTagGroup("Value",list)
		return res
	}
	
	void setData(object self,string sIdent,string sVal)
	{
		tagGroup data
		if(dataTags.tagGroupGetTagAsTagGroup(sIdent,data))
			data.tagGroupSetTagAsString("Value",sVal)
		else
			result("String data item \""+sIdent+"\" not found.\n")
	}

	void setData(object self,string sIdent,number val)
	{
		tagGroup data
		if(dataTags.tagGroupGetTagAsTagGroup(sIdent,data))
			data.tagGroupSetTagAsNumber("Value",val)
		else
			result("Number data item \""+sIdent+"\" not found.\n")
	}	
		
	void setData(object self,string sIdent,rgbnumber col)
	{
		tagGroup data
		if(dataTags.tagGroupGetTagAsTagGroup(sIdent,data))
			data.tagGroupSetTagAsNumber("Value",col)
		else
			result("RGBnumber data item \""+sIdent+"\" not found.\n")
	}	
		
	void setData(object self,string sIdent,TagGroup list)
	{
		tagGroup data
		if(dataTags.tagGroupGetTagAsTagGroup(sIdent,data))
			data.tagGroupSetTagAsTagGroup("Value",list)
		else
			result("TagGroup data item \""+sIdent+"\" not found.\n")
	}	
		
	number doesDataExist(object self,string sIdent)
	{
		return dataTags.tagGroupDoesTagExist(sIdent)
	}

	void deleteData(object self,string sIdent)
	{
		if(dataTags.tagGroupDoesTagExist(sIdent))
			dataTags.tagGroupDeleteTagWithLabel(sIdent)
	}

	//
	void addData(object self,string sOwner,string sIdent,string sVal)
	{
		self.deleteData(sIdent)
		TagGroup data=newTagGroup()			
		data.tagGroupCreateNewLabeledTag("Value");data.tagGroupSetTagAsString("Value",sVal)
		data.tagGroupCreateNewLabeledTag("Owner");data.tagGroupSetTagAsString("Owner",sOwner)
		dataTags.tagGroupCreateNewLabeledTag(sIdent);dataTags.tagGroupSetTagAsTagGroup(sIdent,data)
	}

	//
	void addData(object self,string sOwner,string sIdent,number val)
	{
		self.deleteData(sIdent)
		TagGroup data=newTagGroup()			
		data.tagGroupCreateNewLabeledTag("Value");data.tagGroupSetTagAsNumber("Value",val)
		data.tagGroupCreateNewLabeledTag("Owner");data.tagGroupSetTagAsString("Owner",sOwner)
		dataTags.tagGroupCreateNewLabeledTag(sIdent);dataTags.tagGroupSetTagAsTagGroup(sIdent,data)
	}

	//
	void addData(object self,string sOwner,string sIdent,rgbnumber col)
	{
		self.deleteData(sIdent)
		TagGroup data=newTagGroup()			
		data.tagGroupCreateNewLabeledTag("Value");data.tagGroupSetTagAsNumber("Value",col)
		data.tagGroupCreateNewLabeledTag("Owner");data.tagGroupSetTagAsString("Owner",sOwner)
		dataTags.tagGroupCreateNewLabeledTag(sIdent);dataTags.tagGroupSetTagAsTagGroup(sIdent,data)
	}

	//
	void addData(object self,string sOwner,string sIdent,TagGroup list)
	{
		self.deleteData(sIdent)
		TagGroup data=newTagGroup()			
		data.tagGroupCreateNewLabeledTag("Value");data.tagGroupSetTagAsTagGroup("Value",list)
		data.tagGroupCreateNewLabeledTag("Owner");data.tagGroupSetTagAsString("Owner",sOwner)
		dataTags.tagGroupCreateNewLabeledTag(sIdent);dataTags.tagGroupSetTagAsTagGroup(sIdent,data)
	}

	void setDataTag(object self,string sIdent,TagGroup data)
	{
		self.deleteData(sIdent)
		dataTags.tagGroupCreateNewLabeledTag(sIdent)
		tagGroup dataP=data.tagGroupClone()
		dataTags.tagGroupSetTagAsTagGroup(sIdent,dataP)
	}

	TagGroup getDataTag(object self,string sIdent)
	{
		TagGroup data
		dataTags.tagGroupGetTagAsTagGroup(sIdent,data)
		return data
	}
	
	void copyDataTo(object self,string sIdent,object origDataMngr)
	{
		tagGroup data
		number res=dataTags.tagGroupGetTagAsTagGroup(sIdent,data);
		if(res)
			origDataMngr.setDataTag(sIdent,data)	
	}

	void copyDataFrom(object self,string sIdent,object origDataMngr)
	{
		tagGroup data=origDataMngr.getDataTag(sIdent)
		self.setDataTag(sIdent,data)
	}

	number findItem(object self,string sIdent,tagGroup itemList)
	{
		TagGroup item=newTagGroup()
		item.tagGroupCreateNewLabeledTag("Data")
		number nData=dataTags.tagGroupCountTags()
		number dataType=0
		for(number i=0;i<nData;++i)
		{
			string sLabel=dataTags.tagGroupGetTagLabel(i)
			if(sLabel==sIdent)
			{
				tagGroup dataTag;dataTags.tagGroupGetIndexedTagAsTagGroup(i,dataTag)
				dataType=dataTag.TagGroupGetTagType(0,0)
				if(dataType==20)//string
				{
					string sData;self.getData(sIdent,sData);
					item.tagGroupSetTagAsString("Data",sData)
					//result(sLabel+" (string): "+sData+"\n")
					break
				}
				if(dataType==3)//rgbnumber
				{
					rgbnumber col;self.getData(sIdent,col)
					item.tagGroupSetTagAsNumber("Data",col)
					//result(sLabel+" (number): "+data+"\n")
					break
				}
				//Must be number
				{
					number val;self.getData(sIdent,val)
					item.tagGroupSetTagAsNumber("Data",val)
					break
				}
			}	
		}
		number nItems=itemList.tagGroupCountTags()
		number n
		for(n=0;n<nItems;n++)
		{
			tagGroup itemTag;itemList.tagGroupGetIndexedTagAsTagGroup(n,itemTag)
			number valType=itemTag.tagGroupGetTagType(1,0)
			if(dataType==20)//string
			{
				string s;itemTag.tagGroupGetTagAsString("Value",s)
				string sVal;item.tagGroupGetTagAsString("Data",sVal)
				if(s==sVal)break
				continue
			}
			if(dataType==3)//rgbnumber
			{
				rgbnumber x;itemTag.tagGroupGetTagAsNumber("Value",x)
				rgbnumber val;item.tagGroupGetTagAsNumber("Data",val)
				if(x==val)break
				continue
			}
			//Must be number
			{
				number x;itemTag.tagGroupGetTagAsNumber("Value",x)
				number val;item.tagGroupGetTagAsNumber("Data",val)
				if(x==val)break
				continue
			}
		}
		return n
	}

	//Write single item
	number writeData(object self,string sPath,string sOwner,string sIdent,number nOccur,number echo)
	{
		number res=0
		TagGroup data;dataTags.tagGroupGetTagAsTagGroup(sIdent,data)
		string sOwnerp;data.tagGroupGetTagAsString("Owner",sOwnerp)
		if(sOwnerp==sOwner)
		{
			string sDesc
			number nInfo=data.tagGroupCountTags()
			number j
			for(j=0;j<nInfo;++j)
			{
				sDesc=data.tagGroupGetTagLabel(j)
				if(sDesc=="Value")break
			}
			number dataType=data.tagGroupGetTagType(j,0)
			if(dataType==0)//TagGroup
			{
				TagGroup dataList;data.tagGroupGetTagAsTagGroup("Value",dataList)
				res=writePrefList(sPath,sOwner,sIdent,dataList,nOccur,echo)
				return res
			}
			if(dataType==20)//String
			{
				string sData
				data.tagGroupGetTagAsString("Value",sData)
				res=writePref(sPath,sOwner,sIdent,sData,nOccur,echo)
				return res
			}
			//
			if(dataType==3)
			{
				rgbnumber xData
				data.tagGroupGetTagAsNumber("Value",xData)
				res=writePref(sPath,sOwner,sIdent,xData,nOccur,echo)
				return res
			}
			//Must be number
			{
				number xData
				data.tagGroupGetTagAsNumber("Value",xData)
				res=writePref(sPath,sOwner,sIdent,xData,"%g",nOccur,echo)
				return res
			}
		}
		return res
	}

	//Read single item
	number readData(object self,string sPath,string sOwner,string sIdent,number nOccur,number echo)
	{
		number res=0
		TagGroup data;dataTags.tagGroupGetTagAsTagGroup(sIdent,data)
		string sOwnerp;data.tagGroupGetTagAsString("Owner",sOwnerp)
		if(sOwnerp==sOwner)
		{
			string sDesc
			number nInfo=data.tagGroupCountTags()
			number j
			for(j=0;j<nInfo;++j)
			{
				sDesc=data.tagGroupGetTagLabel(j)
				if(sDesc=="Value")break
			}
			number dataType=data.tagGroupGetTagType(j,0)
			//result("Ident: "+sIdent+", type: "+dataType+"\n")

			if(dataType==0)//TagGroup
			{
				TagGroup dataList
				if(res=readPrefList(sPath,sOwner,sIdent,dataList,nOccur,echo))
					data.tagGroupSetTagAsTagGroup("Value",dataList)
				else
					if(echo)result("Could not read \""+sOwner+" "+sIdent+"\".\n")
				return res
			}
			
			//string
			if(dataType==20)
			{
				string sData
				if(res=readPref(sPath,sOwner,sIdent,sData,nOccur,echo))
					data.tagGroupSetTagAsString("Value",sData)
				else
					if(echo)result("Could not read \""+sOwner+" "+sIdent+"\".\n")
				return res
			}
			//RGB
			if(dataType==3)
			{
				rgbnumber xData
				if(res=readPref(sPath,sOwner,sIdent,xData,nOccur,echo))
					data.tagGroupSetTagAsNumber("Value",xData)
				else
					if(echo)result("Could not read \""+sOwner+" "+sIdent+"\".\n")
				return res
			}
			//Must be number
			{
				number xData
				
				if(res=readPref(sPath,sOwner,sIdent,xData,nOccur,echo))
					data.tagGroupSetTagAsNumber("Value",xData)
				else
					if(echo)result("Could not read \""+sOwner+" "+sIdent+"\".\n")
				return res
			}
			//dataTags.tagGroupSetIndexedTagAsTagGroup(i,data)
		}
		return res
	}

	//Read/write first occurence
	number readData(object self,string sPath,string sOwner,string sIdent,number echo)
	{return self.readData(sPath,sOwner,sIdent,1,echo);}
	
	number writeData(object self,string sPath,string sOwner,string sIdent,number echo)
	{return self.writeData(sPath,sOwner,sIdent,1,echo);}

	//Read/write all owned data
	void read(object self,string sPath,string sOwner,number echo)
	{
		number nTags=dataTags.tagGroupCountTags()
		for(number i=0;i<nTags;++i)
		{
			string sIdent=dataTags.tagGroupGetTagLabel(i)
			self.readData(sPath,sOwner,sIdent,echo)
		}
	}

	void write(object self,string sPath,string sOwner,number echo)
	{
		number nTags=dataTags.tagGroupCountTags()
		for(number i=0;i<nTags;++i)
		{
			string sIdent=dataTags.tagGroupGetTagLabel(i)
			self.writeData(sPath,sOwner,sIdent,echo)
		}
		
	}
		
	void copyData(object self,string sOwner,string sIdent,TagGroup sourceTag)
	{	
		TagGroup copyTag
		if(dataTags.tagGroupGetTagAsTagGroup(sIdent,copyTag))
		{
			dataTags.tagGroupDeleteTagWithLabel(sIdent)
		}
		copyTag=newTagGroup()
		copyTag.tagGroupCreateNewLabeledTag("Owner")
		copyTag.tagGroupSetTagAsString("Owner",sOwner)
		number res=0
		//if TagList, need to clone
		string sDesc
		number nInfo=sourceTag.tagGroupCountTags()
		number j
		for(j=0;j<nInfo;++j)
		{
			sDesc=sourceTag.tagGroupGetTagLabel(j)
			if(sDesc=="Value")break
		}
		number dataType=sourceTag.tagGroupGetTagType(j,0)
		copyTag.tagGroupCreateNewLabeledTag("Value")
		if(dataType==0)//TagGroup
		{
			
			TagGroup sourceList;sourceTag.tagGroupGetTagAsTagGroup("Value",sourceList)
			TagGroup copyList=newTagGroup()
			copyList=newTagList()
			copyTag.tagGroupSetTagAsTagGroup("Value",copyList)
			number nItems=sourceList.tagGroupCountTags()
			for(number i=0;i<nItems;++i)
			{
				number dataType=sourceList.tagGroupGetTagType(i,0)	
				
				if(dataType==20)//string
				{
					string sData;sourceList.tagGroupGetIndexedTagAsString(i,sData)
					copyList.tagGroupInsertTagAsString(infinity(),sData)
				}
				else//assume number
				{
					number data;sourceList.tagGroupGetIndexedTagAsNumber(i,data)
					copyList.tagGroupInsertTagAsNumber(infinity(),data)
				}
			}
			res=1
		}
		if(dataType==20)//String
		{
			string sData;sourceTag.tagGroupGetTagAsString("Value",sData)
			copyTag.tagGroupSetTagAsString("Value",sData)
			res=1
		}
			
		if(dataType==3)//RGB
		{
			rgbnumber data;sourceTag.tagGroupGetTagAsNumber("Value",data)
			copyTag.tagGroupSetTagAsNumber("Value",data)
			res=1
		}
		if(!res)//number
		{
			number data;sourceTag.tagGroupGetTagAsNumber("Value",data)
			copyTag.tagGroupSetTagAsNumber("Value",data)
			res=1
		}
		dataTags.tagGroupCreateNewLabeledTag(sIdent)
		dataTags.tagGroupSetTagAsTagGroup(sIdent,copyTag)
	}
	
	void copyData(object self,string sOwner,object sourceData,string sOwnerP)
	{
		TagGroup sourceTags=sourceData.getTags()
		number nTags=sourceTags.tagGroupCountTags()
		
		for(number i=0;i<nTags;++i)
		{
			string sIdent=sourceTags.tagGroupGetTagLabel(i)
			TagGroup sourceTag;sourceTags.tagGroupGetIndexedTagAsTagGroup(i,sourceTag)
			string sOwnerT;sourceTag.tagGroupGetTagAsString("Owner",sOwnerT)
			if(sOwnerP==sOwnerT)
			{
				self.copyData(sOwner,sIdent,sourceTag)
			}
		}

	}
}

/*
string sOwner="ACQCONTROL"
object dataMngr=alloc(DataManager)
string sDataDir=getApplicationDirectory("preference",0)
string sDataName="JEM_prefs"
string sPath=pathConcatenate(sDataDir,sDataName+".txt")

dataMngr.addData("not saved","online",0)
		//self.addData("control filament",0,sOwner)		
dataMngr.addData(sOwner,"screen up",0)		
dataMngr.addData(sOwner,"control screen",1)
dataMngr.addData(sOwner,"string info","test")
		
dataMngr.addData(sOwner,"use SmartAcq",1)		

dataMngr.read(sPath,sOwner,1)
TagGroup tags=dataMngr.getTags()
tags.tagGroupOpenBrowserWindow(0)

dataMngr.write(sPath,sOwner,1)
*/