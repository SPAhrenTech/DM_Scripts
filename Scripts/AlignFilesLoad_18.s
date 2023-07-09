//Get prefs file (input)
void doLoadAlign()
{
	string sAlignPath
	OpenandSetProgressWindow("align file...","","")	
	if(!OpenDialog(sAlignPath))exit(0)
	//result("align file: "+sAlignPath+"\n")

	object align=alloc(JEM_AlignFiles)

	if(align.init().pose())
		align.load(sAlignPath)

	align.load(sAlignPath)

}
doLoadAlign()