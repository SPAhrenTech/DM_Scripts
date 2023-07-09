/*
P. Ahrenkiel-2020
*/
module com.gatan.dm.JEM_Data
uses com.gatan.dm.DataManager

class JEM_Data:DataManager
{
	string sPath
	string sGroup
	number echo

	JEM_Data(object self)
	{
		sPath=getApplicationDirectory("preference",0)
		sPath=pathConcatenate(sPath,"JEM_files")
		sPath=pathConcatenate(sPath,"JEM_prefs.txt")
		sGroup="Group"
		echo=0
	}
	
	object setGroup(object self,string s){sGroup=s;return self;}
	object getGroup(object self,string &s){s=sGroup;return self;}
	string getGroup(object self){return sGroup;}
	object setPath(object self,string s){sPath=s;return self;}
	object getPath(object self,string &s){s=sPath;return self;}
	object setEcho(object self,number x){echo=x;return self;}
	object getEcho(object self,number &x){x=echo;return self;}
	number getEcho(object self){return echo;}

//
	object setDir(object self,string s)
	{
		string sDir,sFile;getFilenameParts(sPath,sDir,sFile)
		sPath=pathConcatenate(s,sFile);return self;
	}
	
	object setFile(object self,string s)
	{
		string sDir,sFile;getFilenameParts(sPath,sDir,sFile);
		sPath=pathConcatenate(sDir,s);return self;
	}
	
	object getDir(object self,string &s)
	{string sFile;getFilenameParts(sPath,s,sFile);return self;}

	object getFile(object self,string &s)
	{string sDir;getFilenameParts(sPath,sDir,s);return self;}

//Primary Group	
	//Read/write all data
	void read(object self)
	{self.super.read(sPath,sGroup,echo);}

	void write(object self)
	{self.super.write(sPath,sGroup,echo);}

	//Read/write particular data item	
	number writeData(object self,string sIdent,number nOccur)
	{return self.super.writeData(sPath,sGroup,sIdent,nOccur,echo);}
	
	number readData(object self,string sIdent,number nOccur)
	{return self.super.readData(sPath,sGroup,sIdent,nOccur,echo);}

	number writeData(object self,string sIdent)
	{return self.writeData(sIdent,1);}
	
	number readData(object self,string sIdent)
	{return self.readData(sIdent,1);}

	//add data item
	void addData(object self,string sIdent,string sVal)
	{self.super.addData(sGroup,sIdent,sVal);}

	void addData(object self,string sIdent,number val)
	{self.super.addData(sGroup,sIdent,val);}

	void addData(object self,string sIdent,rgbnumber val)
	{self.super.addData(sGroup,sIdent,val);}

	void addData(object self,string sIdent,TagGroup list)
	{self.super.addData(sGroup,sIdent,list);}
		
//Alternate Group
	//Read/write all data
	void write(object self,string sAltGroup)
	{self.super.write(sPath,sAltGroup,echo);}

	void read(object self,string sAltGroup)
	{self.super.read(sPath,sAltGroup,echo);}

	//Read/write particular data item
	number writeData(object self,string sAltGroup,string sIdent,number nOccur)
	{return self.super.writeData(sPath,sAltGroup,sIdent,nOccur,echo);}
	
	number readData(object self,string sAltGroup,string sIdent,number nOccur)
	{return self.super.readData(sPath,sAltGroup,sIdent,nOccur,echo);}

	number writeData(object self,string sAltGroup,string sIdent)
	{return self.writeData(sAltGroup,sIdent,1);}
	
	number readData(object self,string sAltGroup,string sIdent)
	{return self.readData(sAltGroup,sIdent,1);}
	
//Copy
	void copyData(object self,object sourceData,string sGroupP)
	{self.super.copyData(sGroup,sourceData,sGroupP);}
	
	object load(object self)
	{
		self.read()
		if(self.getEcho())result(self.getName()+" loaded\n")
		return self
	}

	object unload(object self)
	{
		self.write()
		if(self.getEcho())result(self.getName()+" unloaded\n")
		return self
	}

}

/*
string sGroup="MONTAGE"
object obj=alloc(JEM_Data)
obj.setGroup(sGroup)
obj.setEcho(1)
obj.addData("deflector","PLA")
obj.read()
TagGroup tags=obj.getTags()

*/
