## PDFRenderer run test instruction
* Only Android for now
	* Prerequires
		1. install cordova-test-framework
			- cordova plugin add https://github.com/apache/cordova-plugin-test-framework.git
		2. install PDFRenderer tests 
			- cordova plugin add {PDFRenderer path}/tests
		3. Get Ready a file with name: PDFRendererTest.pdf and password 1234
		4. Put file to /storage/emulated/0/Download/PDFRendererTest.pdf
		5. change the config.xml to cdvtests/index.html
	* Step
		1. cordova run android
		2. see the phone or emulator running result