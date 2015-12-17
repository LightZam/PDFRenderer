# PDFRenderer

------------------------------------------

* Constant
  * DestinationType
  * EncodingType
  * OpenType
* API
	* open(success, fail, options)
	* close(success, fail)
	* getPage(success, fail, options)
	* getPDFInfo(success, fail)
	* getPageInfo(success, fail, pageNumber)
	* changePreference(preference)
* Quick Example
	* Example 1

------------------------------------------

# Constant
## DestinationType
```javascript
	{
		DATA_BIN,		// Return ArrayBuffer 
		DATA_URL,		// Return base64 encoded string
		FILE_URI		// Return file path in native way
	}
	
	// example
	PDFRenderer.DestinationType.FILE_URI
```
		
## EncodingType
```javascript
	{
		JPEG,			// Return JPEG encoded image
		PNG				// Return PNG encoded image
	}
		
	// example
	PDFRenderer.EncodingType.JPEG
```
		
## OpenType
```javascript
	{
		PATH,			// PDF path
		BUFFER			// PDF arraybuffer
	}
	
	// example
	PDFRenderer.OpenType.PATH
```	

------------------------------------------

# API
## open(success, fail, options)
* The example openFileObj's openType is default setting
	* you don't nedd to pass openType and password except you want oepn from array buffer or password protected PDF.
* Every thing should be done after PDF opened.

### Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`success` | `Function` || success callbcak
`fail` | `Function` || fail callback
`options` | `Object` | `{}` | An object describing relevant specific options.

###### options detail

Attribute | Type | Default | Description
--------- | ---- | ------- | -----------
`content` | `string` | | Path or ArrayBuffer
`openType` | `PDFRenderer.OpenType` | `OpenType.PATH` | Open from Path or ArrayBuffer
`password` | `string` | | PDF password

### Success Callback Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`data.numberOfPage` | `int` || PDF page count
`data.path` | `string` || PDF path
`data.name` | `string` || PDF name

### Example
```javascript
	var openFileObj = {
		content: 'PDFRendererTest.pdf',
    	openType: PDFRenderer.OpenType.PATH,
    	password: '123'
    };
	PDFRenderer.open(function successCallBack(data) {
		// data.numberOfPage
		// data.path
		// data.name
    	// do your stuff, start to getPage or something
    }, failCallBack, openFileObj);
```

## close(success, fail)
* close PDF when you finish.

### Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`success` | `Function` || success callbcak
`fail` | `Function` || fail callback

### Example
```javascript
	PDFRenderer.close(successCallback, failCallback);
```

## getPage(success, fail, options)
* get image from PDF

### Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`success` | `Function` || success callbcak
`fail` | `Function` || fail callback
`options` | `Object` | `{}` | An object describing relevant specific options.

###### options detail

**PatchX, PatchY, PatchWidth, PatchHeight means you want to get a cut block from image.**

Attribute | Type | Default | Description
--------- | ---- | ------- | -----------
`page` | `int` | | which page image
`width` | `PDFRenderer.OpenType` | `OpenType.PATH` | Image width
`height` | `int` | | Image height
`patchX` | `int` | | Patch x from image
`patchY` | `int` | | Patch y from image
`patchWidth` | `int` | | Patch width
`patchHeight` | `int` | | Patch height
`quality` | `int` | 100 | Image quality
`encodingType` | `PDFRenderer.EncondingType` | EncondingType.JPEG | 
`destinationType` | `PDFRenderer.DestinationType` | DestinationType.BIN | PDF type
`destinationPath` | `string` | | PDF path
	
### Success Callback Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`data` | `string` || File path or base64 or arraybuffer
	
### Example
```javascript
	var options = {
		page: 1,
		width: 800,
		height: 600,
		patchX: 0,
		patchY: 0,
		patchWidth: 800,
		patchHeight: 600,
		quality: 100,
		encodingType: EncodingType.JPEG,
		destinationType: DestinationType.FILE_URI,
		destinationPath: '/PDF/example'
	};
	PDFRenderer.getPage(function successCallback(data) {
		// data
	}, failCallback, options);
```
    
## getPDFInfo(success, fail)
* The PDF info

### Success Callback Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`data.numberOfPage` | `int` || PDF page count
`data.path` | `string` || PDF path
`data.name` | `string` || PDF name

### Example
```javascript
	PDFRenderer.getPDFInfo(function successCallback(data) {
    	// data.numberOfPage
    	// data.path
    	// data.name
    }, failCallback);	
```

## getPageInfo(success, fail, pageNumber)
* get page info by giving page number
		
### Success Callback Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`data.numberOfPage` | `int` || PDF page count
`data.width` | `int` || Page width
`data.height` | `int` || Page height

### Example
```javascript
	var pageNumber = 1;
	PDFRenderer.getPageInfo(function successCallback(data) {
    	// data.numberOfPage
    	// data.width
    	// data.height
    }, failCallback, pageNumber);
```

## changePreference(preference)
* The example preference is default setting, you can change it youself.
	
### Parameters
Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
`preference ` | `Object` |`{}`| success callbcak

###### options detail

Attribute | Type | Default | Description
--------- | ---- | ------- | -----------
`openType ` | `PDFRenderer.OpenType` | `OpenType.PATH` | Open from Path or ArrayBuffer
`quality ` | `int` | `100` | Image quality
`encodingType ` | `PDFRenderer.EncodingType` | `EncodingType.JPEG ` | Image format
`destinationType ` | `PDFRenderer.DestinationType` | `DestinationType.DATA_BIN` | PDF type 
`destinationPath ` | `string` | | PDF path.

	
### Example
```javascript
	var preference = {
		openType: PDFRenderer.OpenType.PATH,
		quality: 100,
		encodingType: PDFRenderer.EncodingType.JPEG,
		destinationType: PDFRenderer.DestinationType.DATA_BIN,
		destinationPath: ''
	};
	PDFRenderer.changePreference(preference);
```

# Quick Example

## Example 1: 

```javascript
	function fail(e) {
    	console.log(e);
    };
	PDFRenderer.open(function(pdf) {
		console.log('PDF Info: ', pdf.name, pdf.path);
		var i = pdf.numberOfPage,
			success = function(data) {
				console.log('Image output path', data);
			};
    	while (i-- > 0) {
			PDFRenderer.getPage(success, fail, {
				page: i,
				destinationType: PDFRenderer.DestinationType.FILE_URI
			});
    	} 
    	
    }, fail, {
		content: 'PDFRendererTest.pdf'
    });
```
