
Object CM_GetCameraManager(){return NULL;}
Object CM_GetCameras( Object cam_mgr){return NULL;}
void   CM_SelectCamera( Object cam_mgr, Object camera){return;}
Object CM_GetCurrentCamera(){return NULL;}
String CM_GetCameraName( Object camera){return "";}
void   CM_SetCameraName( Object camera, String new_camera_name );
String CM_GetCameraControllerClass( Object camera){return "";}
String CM_GetCameraIdentifier( Object camera){return "";}
void   CM_CCD_GetSize( Object camera, Number &ccd_width, Number &ccd_height){return;}
void   CM_CCD_GetPixelSize_um( Object camera, Number &pix_width, Number &pix_height){return;}
Number CM_Config_GetDefaultTranspose( Object camera){return 0;}
void   CM_Config_SetDefaultTranspose( Object camera, Number trans){return;}
void   CM_CalcFrameSize( Object camera, Number transpose, Number adj_x, Number adj_y\
	    ,Number bin_x, Number bin_y, Number &dst_width_out, Number &dst_height_out){return;}
Number CM_CountShutters( Object camera){return 0;}

void   CM_GetIdleShutterState( Object camera, Number shutter_index, Number &is_closed){return;}
void   CM_SetIdleShutterState( Object camera, Number shutter_index, Number  is_closed){return;}
void   CM_SetCurrentShutterState( Object camera, Number shutter_index, Number is_closed){return;}
Number CM_IsCameraRetractable( Object camera){return 0;}
Number CM_GetCameraInserted( Object camera){return 0;}
void   CM_SetCameraInserted( Object camera, Number inserted){return;}
void   CM_Config_GetInsertabilityDelays( Object camera, Number &insert_delay, Number &retract_delay){return;}
void   CM_Config_SetInsertabilityDelays( Object camera, Number insert_delay, Number retract_delay){return;}
Number CM_CanSetAntiblooming( Object camera){return 0;}
Number CM_DoesCameraNeedToBeCooled( Object camera){return 0;}
Number CM_HasTemperatureControl( Object camera){return 0;}
Number CM_GetTemperatureResolution_C( Object camera){return 0;}
Number CM_GetMinimumTemperature_C( object camera){return 0;}
Number CM_GetMaximumTemperature_C( Object camera){return 0;}
Number CM_GetActualTemperature_C( Object camera){return 0;}
void   CM_SetTargetTemperature_C( Object camera, Number use_target_temp, Number temp_C){return;}
Number CM_GetTargetTemperature_C( Object camera, Number &temp_C){return 0;}
void   CM_SetStartupTemperature_C( Object camera, Number use_startup_temp, Number temp_C){return;}
Number CM_GetStartupTemperature_C( Object camera, Number &temp_C){return 0;};
void   CM_SetShutdownTemperature_C( Object camera, Number use_shutdown_temp, Number temp_C){return;}
Number CM_GetShutdownTemperature_C( Object camera, Number &temp_C){return 0;}
Number CM_GetLocalTargetTemperature_C( Object camera, Number &temp_C){return 0;}
Number CM_IsTemperatureStable( Object camera, Number &targ_temp_C){return 0;}
Number CM_GetTemperatureMaxChangeRate( Object camera){return 0;}
void   CM_SetTemperatureMaxChangeRate( Object camera, Number maxTempChange){return;}
Object CM_GetCameraAcquisitionParameterSet_LowQualityImagingView( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet_MediumQualityImagingView( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet_HighQualityImagingView( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet_LowQualityImagingAcquire( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet_MediumQualityImagingAcquire( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet_HighQualityImagingAcquire( Object camera){return NULL;}
Object CM_GetCameraAcquisitionParameterSet(Object camera,string s1,string s2,string s3,number notused){return NULL;}
Object CM_CreateAcquisitionParameters_FullCCD( Object camera, Number processing\
	   , Number exposure, Number binning_x, Number binning_y );
void   CM_LoadCameraAcquisitionParameterSet( Object camera, Object acq_params){return;}
void   CM_SaveCameraAcquisitionParameterSet( Object camera, Object acq_params){return;}
Number CM_GetExposure( Object acq_params){return 0;}
void   CM_SetExposure( Object acq_params, Number exposure){return;}
void   CM_GetBinning( Object acq_params, Number &bin_x, Number &bin_y){return;}
void   CM_SetBinning( Object acq_params, Number  bin_x, Number  bin_y){return;}
void   CM_GetCCDReadArea( Object acq_params, Number &top, Number &left, Number &bottom, Number &right){return;}
void   CM_SetCCDReadArea( Object acq_params, Number  top, Number  left, Number  bottom, Number  right){return;}
void   CM_GetBinnedReadArea( Object camera, Object acq_params, Number &bin_area_t\
	   , Number &bin_area_l, Number &bin_area_b, Number &bin_area_r){return;}
void   CM_SetBinnedReadArea( Object camera, Object acq_params, Number bin_area_t\
	   , Number bin_area_l, Number bin_area_b, Number bin_area_r){return;}
void   CM_SetProcessing( Object acq_params, Number processing){return;}
Number CM_GetProcessing( Object acq_params){return 0;}
Number CM_GetDoContinuousReadout( Object acq_params){return 0;}
void   CM_SetDoContinuousReadout( Object acq_params, Number dcr){return;}
void   CM_SetStandardParameters( Object acq_params\
	   ,Number processing, Number exposure,number bin_x,Number bin_y\
       ,Number ccd_area_t, Number ccd_area_l, Number ccd_area_b, Number ccd_area_r){return;}
void   CM_SetStandardParameters_Dst( Object camera, Object acq_params\
	   ,Number processing, Number exposure, Number bin_x_dst, Number bin_y_dst\
       ,Number bin_area_t, Number bin_area_l, Number bin_area_b, Number bin_area_r){return;}
Number CM_GetDoAntiblooming( Object acq_params){return 0;}
void   CM_SetDoAntiblooming( Object acq_params, Number do_antiblooming){return;}
Number CM_GetShutterExposure( Object acq_params){return 0;}
void   CM_SetShutterExposure( Object acq_params, Number do_shutter_exposure){return;}
Number CM_GetSettling( Object acq_params){return 0;}
void   CM_SetSettling( Object acq_params, Number settling){return;}
Number CM_GetShutterIndex( Object acq_params){return 0;}
void   CM_SetShutterIndex( Object acq_params, Number index){return;}
Number CM_GetShutterClosedBetweenFrames(Object acq_params){return 0;}
void   CM_SetShutterClosedBetweenFrames( Object acq_params, Number is_closed){return;}
Number CM_GetAcqTranspose( Object acq_params){return 0;}
void   CM_SetAcqTranspose( Object acq_params, Number transform){return;}
void   CM_SetNumberToSum( Object acq_params, Number num){return;}
Number CM_GetNumberToSum( Object acq_params){return 0;}
void   CM_SetAutoExpose( Object camera, Object acq_params, Number has_auto_expose, number do_auto_expose){return;}
number CM_IsAutoExposeOn( Object camera, Object acq_params){return 0;}
Number CM_Validate_AcquisitionParameters( Object camera, Object acq_params){return 0;}
Number CM_IsValid_AcquisitionParameters( Object camera, Object acq_params){return 0;}
void   CM_CameraCalcImageForm( Object camera, Object acq_params, Number &data_type\
	   , Number &width, Number &height){return;}
Image  NewImage( String title, Number data_type, Number width, Number height){return NULL;}
Image  CM_CreateImageForAcquire( Object camera, Object acq_params, String name){return NULL;}
Image  CM_AcquireImage( Object camera, Object acq_params){return NULL;}
void   CM_AcquireImage( Object camera, Object acq_params, Image img){return;}
void   CM_AcquireDarkReference( Object camera, Object acq_params, Image img, Object frame_set_info){return;}
number	CM_GetCorrections(object params,number mask){return 0;}
void	CM_SetCorrections(object params,number mask,number corr){return;}
number cameraGetActiveCameraID( ){return 0;}
void cameraStartContinuousAcquisition(number camID,number exp,number binx,number biny,number proc){return;}
void cameraStopContinuousAcquisition(number camID){return;}
number cameraGetFrameInContinuousMode(number camID,image &img,number timeout_s){return 0;}

