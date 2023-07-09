//calibrate film

image img,imgref

if(!GetFrontImage(img)) Exit(0)

if(!GetOneImage("Reference Image",imgref)) Exit(0)

ImageCopyCalibrationFrom(img,imgref)

