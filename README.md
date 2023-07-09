# DM_Scripts
 Gatan collection

ScriptManager Overview, Phil Ahrenkiel, 2022

To install:

1) Put the whole JEM_files folder in ProgramData/Gatan/Prefs. I left the SmartACQRefs folder empty, because you would need to reqacuire those for your camera, anyway, and they can be fairly large. Everything in Calibration_files will need to be adjusted or overwritten for your TEM.

2) Copy the contents of PlugIns to the folder ProgramData/Gatan/PlugIns. If you actually have a JEOL JEM-series TEM, using the JEOL TEMCON software, you can drag the JeolComPlug.dll out from the JEOL folder. But I noticed these plugins don't load properly on the most recent version of DM (something like v3.52), so they would need to be rebuilt, which is a big job. They work fine on DM v3.40. They are only used by a few things, so you could probably find ways around using them. I don't mind sharing that C++ code, if you get to that point.

3) Open the ScriptManagerInstall script in DM. Follow the instructions at the top of that file.

4) The ScriptsManager panel should open. Also, a Scripts menu should show up in DM, with a Script Manager menu item. From the ScriptsManager panel, select "Import Set" from the Actions popup. Navigate to the folder "Scripts" and select "OK". It will try install all of the scripts that are in that folder.

5) There will almost certainly be some information that it doesn't like, in which case, open the ScriptManagerUninstall script and follow those instructions. The challenge is finding at which script the problem occurred. I usually use "Install To" and keep working down the list from top to bottom until I find the problem. 

6) A few of the scripts, like DigiScanSim and CameraMgrSim are included to make it easier to switch between online and offline versions. If you have the actual Gatan PlugIns for those, I would recommend just commenting out (using /* */) everything in the files, in order to use the online versions. Also, swap out JEM_lib_offline with JEM_lib, and you will have full external control of the TEM. But I would be amazed if that works for you. This version puts several tasks in the TechniqueManager, which didn't exist before DM 3, I think. I have older versions that will work in that case, if needed. 