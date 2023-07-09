//ScriptManagerInstaller - P. Ahrenkiel 2021

//Open the ScriptManager script. 
//Select File:Install Script...
//In the dialog that appears select "Library" and
//"Install for all users".
//Then press "OK".

//Then run this script.

object dlg=alloc(ScriptDialog).init(1)
dlg.display("Scripts")
dlg.setValues()

	

