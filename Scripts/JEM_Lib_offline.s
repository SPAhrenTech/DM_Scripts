//External control through JEOL DM Plugin
module com.gatan.dm.jemlib

void JEM_getHTValue(number &x)
{
	//HT3GetHtValue(x)
}

//
void JEM_setHTValue(number x)
{
	//HT3SetHtValue(x)
}

//
void JEM_getMagValue(number &mag,string &sUnit,string &sString)
{
	//EOS3GetMagValue(mag,sunit,sstring)
}

//
void JEM_setMagValue(number magValue)
{
	//EOS3SetMagValue(magValue)	
}

//
void JEM_getCondenserLens1(number &x)
{
	//LENS3GetCL1(x)
}

//
void JEM_getCondenserLens2(number &x)
{
	//LENS3GetCL2(x)
}

//
void JEM_getCondenserMiniLens(number &x)
{
	//LENS3GetCM(x)
}

//
void JEM_getObjectiveLensFine(number &x)
{
	//LENS3GetOLf(x)
}

void JEM_getObjectiveLensCoarse(number &x)
{
	//LENS3GetOLc(x)
}

void JEM_getObjectiveMiniLens(number &x)
{
	//LENS3GetOM(x)
}

//
void JEM_getIntermediateLens1(number &x)
{
	//LENS3GetIL1(x)
}

//
void JEM_getIntermediateLens2(number &x)
{
	//LENS3GetIL2(x)
}

//
void JEM_getIntermediateLens3(number &x)
{
	//LENS3GetIL2(x)
}

//
void JEM_getProjectorLens(number &x)
{
	//LENS3GetPL1(x)
}

//Set lenses
void JEM_setCondenserLens3(number x)
{
	//LENS3SetCL3(x)
}

void JEM_setObjectiveLensFine(number x)
{
	//LENS3SetOLf(x)
}

void JEM_setObjectiveMiniLens(number x)
{
	//LENS3SetOM(x)
}

void JEM_setObjectiveLensCoarse(number x)
{
	//LENS3SetOLc(x)
}

void JEM_setIntermediateLens1(number x)
{
	//LENS3SetILFocus(x)
}

//Changes IL3 in MAG mode, IL1 in DIFF mode
void JEM_setIntermediateLensFocus(number x)
{
	//LENS3SetDiffFocus(x)
}

void JEM_setProjectorLens(number x)
{
	//LENS3SetPL1(x)
}

//Other lens routines
//Same as turning FOCUS FINE knob x clicks
//Change step size in "Operation" panel
void JEM_setFocusRel(number x)
{
	//EOS3SetObjFocus(x)
}

//Same as turning DIFF FOCUS knob x clicks in DIFF mode
//No effect in MAG mode
void JEM_setDiffFocusRel(number x)
{
//EOS3SetDiffFocus(x)
}

//Same as JEM_setCondenserLens3
void JEM_setBrightness(number x)
{
	//LENS3SetCL3(x)
}


//Same as JEM_getCondenserLens3
void JEM_getBrightness(number &x)
{
	//LENS3GetCL3(x)
}


//Aligment routines
//
void JEM_getBeamTilt(number &x,number &y)
{
	//DEF3GetCLA2(x,y)
}

void JEM_setBeamTilt(number x,number y)
{
	//DEF3SetCLA2(x,y)
}

//
void JEM_getBeamShift(number &x,number &y)
{
	//DEF3GetCLA1(x,y)
}

void JEM_setBeamShift(number x,number y)
{
	//DEF3SetCLA1(x,y)
}

//
void JEM_getImageShift1(number &x,number &y)
{
	//DEF3GetIS1(x,y)
}

void JEM_setImageShift1(number x,number y)
{
	//DEF3SetIS1(x,y)
}

//
void JEM_getImageShift2(number &x,number &y)
{
	//DEF3GetIS2(x,y)
}

void JEM_setImageShift2(number x,number y)
{
	//DEF3SetIS2(x,y)
}

//
void JEM_getProjectorDef(number &x,number &y)
{
	//DEF3GetPLA(x,y)
}

void JEM_setProjectorDef(number x,number y)
{
	//DEF3SetPLA(x,y)
}
void JEM_getCondensorStigmation(number &x,number &y)
{
	//DEF3GetCLs(x,y)
}

void JEM_setCondensorStigmation(number x,number y)
{
	//DEF3SetCLs(x,y)
}

void JEM_getMagValue(string &unit,number &x,string &s)
{
	//EOS3GetMagValue(x,unit,s)
}

void JEM_setShiftX(number x)
{
	//STAGE3SetX(x)
}

void JEM_setShiftY(number x)
{
	//STAGE3SetY(x)
}

void JEM_setShiftZ(number x)
{
	//STAGE3SetZ(x)
}

void JEM_setShiftXRel(number x)
{
	//STAGE3SetXRel(x)
}

void JEM_setShiftYRel(number x)
{
	//STAGE3SetYRel(x)
}

void JEM_setShiftZRel(number x)
{
	//STAGE3SetZRel(x)
}

void JEM_setTiltAlpha(number x)
{
	//STAGE3SetTiltXAngle(x)
}

void JEM_setTiltBeta(number x)
{
	//STAGE3SetTiltYAngle(x)
}

void JEM_getStagePos(number &x,number &y,number &z,number &tx,number &ty)
{
	//STAGE3GetPos(x,y,z,tx,ty)
}

void JEM_setStagePos(number &x,number &y)//nm
{
	//STAGE3SetStagePosition(x,y)
}

//0:Rest / 1:Moving / 2: Hardware limiter error. 
void JEM_getStageStatus(number &x,number &y,number &z,number &tx,number &ty)
{
	//STAGE3GetStatus(x,y,z,tx,ty)
}

void JEM_getGunA1(number &x,number &y)
{
	//DEF3GetGunA1(x,y)
}

void JEM_setGunA1(number x,number y)
{
	//DEF3SetGunA1(x,y)
}

void JEM_getCLA1(number &x,number &y)
{
	//DEF3GetCLA1(x,y)
}

void JEM_setCLA1(number x,number y)
{
	//DEF3SetCLA1(x,y)
}

void JEM_getCLA2(number &x,number &y)
{
	//DEF3GetCLA2(x,y)
}

void JEM_setCLA2(number x,number y)
{
	//DEF3SetCLA2(x,y)
}

void JEM_getGunA2(number &x,number &y)
{
	//DEF3GetGunA2(x,y)
}

void JEM_setGunA2(number x,number y)
{
	//DEF3SetGunA2(x,y)
}

void JEM_getIS1(number &x,number &y)
{
	//DEF3GetIS1(x,y)
}

void JEM_setIS1(number x,number y)
{
	//DEF3SetIS1(x,y)
}

void JEM_getIS2(number &x,number &y)
{
	//DEF3GetIS2(x,y)
}

void JEM_setIS2(number x,number y)
{
	//DEF3SetIS2(x,y)
}

void JEM_getPLA(number &x,number &y)
{
	//DEF3GetPLA(x,y)
}

void JEM_setPLA(number x,number y)
{
	//DEF3SetPLA(x,y)
}

void JEM_getShifBal(number &x,number &y)
{
//	DEF3GetShifBal(x,y)
}

void JEM_setShifBal(number x,number y)
{
	//DEF3SetShifBal(x,y)
}

void JEM_getTiltBal(number &x,number &y)
{
	//DEF3GetTiltBal(x,y)
}

void JEM_setTiltBal(number x,number y)
{
	//DEF3SetTiltBal(x,y)
}

void JEM_getAngBal(number &x,number &y)
{
	//DEF3GetAngBal(x,y)
}

void JEM_setAngBal(number x,number y)
{
	//DEF3SetAngBal(x,y)
}

void JEM_getCLs(number &x,number &y)
{
	//DEF3GetCLs(x,y)
}

void JEM_setCLs(number x,number y)
{
	//DEF3SetCLs(x,y)
}

void JEM_getOLs(number &x,number &y)
{
	//DEF3GetOLs(x,y)
}

void JEM_setOLs(number x,number y)
{
	//DEF3SetOLs(x,y)
}

void JEM_getILs(number &x,number &y)
{
	//DEF3GetILs(x,y)
}

void JEM_setILs(number x,number y)
{
	//DEF3SetILs(x,y)
}

void JEM_getFunctionMode(number &n,string &s)
{
	//EOS3GetFunctionMode(n,s)
}

void JEM_selectFunctionMode(number n)
{
	//EOS3SelectFunctionMode(n)
}

void JEM_raiseScreen()
{
	//DETECTOR3SetScreen(2)
}

void JEM_lowerScreen()
{
	//DETECTOR3SetScreen(0)
}

//0: down, 1: middle, 2: up
void JEM_setScreenAngle(number x)
{
	//SCREEN1SetAngle(x)
}

//0: down, 1: middle, 2: up
void JEM_getScreenAngle(number &x)
{
	//SCREEN1GetAngle(x)
}

void JEM_getShutterPosition(number &x)
{
	//CAMERA3GetShutterPosition(x)
}

void JEM_setShutterPosition(number x)
{
	//CAMERA3SetShutterPosition(x)
}

void JEM_setFilamentOn()
{
	//GUN3SetBeamSw(1);
}

void JEM_setFilamentOff()
{
	//GUN3SetBeamSw(0);
}
