//Get align file (output)

void doSaveAlign()
{
	string sAlignPath="align.txt"
	OpenandSetProgressWindow("New alignment file...","","")	
	if(!SaveAsDialog("align file:",sAlignPath,sAlignPath)) exit(0)
	//result("align file: "+sAlignPath+"\n")
	if(DoesFileExist(sAlignPath))
		Deletefile(sAlignPath)
	CreateFile(sAlignPath)

	object align=alloc(JEM_AlignFiles)
	align.save(sAlignPath)
	//number nfile=OpenFileForReadingAndWriting(sAlign_path)
}
doSaveAlign()