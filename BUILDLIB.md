## PDFRenderer build lib instruction
* How to build library
	* Prerequires
		1. minNDK = `ndk-r10d`
		2. build muPDF `reference: http://www.mupdf.com/docs/how-to-build-mupdf-for-android`
	* Android
		* create new cordova project
		* copy muPDF source to PDFRenderer
			- resources
			- scripts
			- thirdparty
			- source
		* unmark PDFRenderer jni directory under plugin.xml
		* install PDFRenderer
			- cordova plugin add {PDFRenderer path}
		* add native support (usgin eclipse)
		* build project (using eclipse)
	* iOS
		* using muPDF iOS native app to build library by xcode 