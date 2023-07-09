void	DSInvokeAcquisitionButton(number buttonID){return;}
number	DSCreateParameters(number width,number height\
		,number rotation,number acqTime,number lineSynch){return 0;}
void	DSSetParametersSignal(number paramID,number signalIndex\
		,number dataDepth,number acquire,number imageID){return;}
void	DSStartAcquisition(number paramID,number continuous\
		,number synchronous){return;}
void	DSStopAcquisition(number paramID){return;}
void	DSDeleteParameters(number paramID ){return;}
number	DSGetAcquiredImageID(number signalIndex){return 0;}
number 	DSIsAcquisitionActive( ){return 0;}
void	DSInvokeButton(number ID){return;}
number	DSParametersExist(number ID){return 0;}
number	DSGetWidth(number ID){return 0;}
number	DSGetHeight(number ID){return 0;}
number	DSGetPixelTime(number ID){return 0;}
number	DSGetRotation(number ID){return 0;}
number	DSGetLineSynch(number ID){return 0;}
number	DSGetSignalAcquired(number ID,number index){return 0;}