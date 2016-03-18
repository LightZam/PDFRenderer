//
//  MuPDF.swift
//  mupdf
//
//  Created by Zam-mbpr on 2015/3/4.
//
//

import Foundation

@objc(PDFRenderer)
class PDFRenderer : CDVPlugin {
    var core: PDFRendererCore?
    
    var DataBin: Int = 0
    var DataUrl: Int = 1
    var FileUri: Int = 2
    
    var Jpeg: Int = 0
    var Png: Int = 1
    
    var Path: Int = 0
    var Buffer: Int = 1
    
    var NumberOfPage: String = "numberOfPag1e"
    var PageWidth: String = "width"
    var PageHeight: String = "height"
    var FilePath: String = "path"
    var FileName: String = "name"
    var SystemPath: String = ""
    
    var pdfName: String = ""
    var pdfPath: String = ""
    var pdfPageCount: Int = 0
    var currentPage: Int!
    var customPath: String = ""
    
    override init() {
        super.init()
    }
    
    override func pluginInitialize() {
        self.core = PDFRendererCore()
        self.DataBin = 0
        self.DataUrl = 1
        self.FileUri = 2
        
        self.Jpeg = 0
        self.Png = 1
        
        self.Path = 0
        self.Buffer = 1
        
        self.NumberOfPage = "numberOfPag1e"
        self.PageWidth = "width"
        self.PageHeight = "height"
        self.FilePath = "path"
        self.FileName = "name"
        
        self.pdfName = ""
        self.pdfPath = ""
        self.pdfPageCount = 0
        self.currentPage = 0
        self.customPath = ""
        self.SystemPath = NSHomeDirectory() + "/Documents"
        super.pluginInitialize()
    }
    
    func open(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            let content: AnyObject = command.arguments[0] as AnyObject
            let openType = command.arguments[1] as! Int
            let password = command.arguments[2] as! String
            var pluginResult: CDVPluginResult?
            
            self.closeFile()
            if let result = self.openFile(content, openType: openType) {
                pluginResult = result
            } else {
                if let result = self.checkPassword(password) {
                    pluginResult = result
                } else {
                    if let result = self.checkPDFReady() {
                        pluginResult = result
                    } else {
                        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: self.preparePDFInfo())
                    }
                }
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func close(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            self.closeFile()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPage(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if !self.checkFileOpen() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            let index = command.arguments[0] as! NSNumber
            var pageSize: CGSize = self.core!.getPageSize(index.intValue)
            var patchRect: CGRect = CGRect()
            pageSize.width = command.arguments[1] as! Int == -1 ? pageSize.width : command.arguments[1] as! CGFloat
            pageSize.height = command.arguments[2] as! Int == -1 ? pageSize.height : command.arguments[2] as! CGFloat
            patchRect.origin.x = command.arguments[3] as! CGFloat
            patchRect.origin.y = command.arguments[4] as! CGFloat
            patchRect.size.width = command.arguments[5] as! Int == -1 ? pageSize.width : command.arguments[5] as! CGFloat
            patchRect.size.height = command.arguments[6] as! Int == -1 ? pageSize.height : command.arguments[6] as! CGFloat
            let quality = command.arguments[7] as! CGFloat
            let encodingType = command.arguments[8] as! Int
            let destinationType = command.arguments[9] as! Int
            let destinationPath = command.arguments[10] as! String
            self.currentPage = index.integerValue
            let image: UIImage! = self.core!.drawPage(index.intValue, pageSize: pageSize, patchRect: patchRect)
            var pluginResult: CDVPluginResult? = nil
            var data: NSData
            var format:String
            
            if encodingType == self.Jpeg {
                data = UIImageJPEGRepresentation(image, quality)!
                format = ".jpeg"
            } else {
                data = UIImagePNGRepresentation(image)!
                format = ".png"
            }
            
            if destinationType == self.DataBin {            // array buffer
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)
            } else if destinationType == self.DataUrl {     // base64
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))
            } else if destinationType == self.FileUri {     // file path
                var path: String = self.SystemPath
                if (!destinationPath.isEmpty) {
                    path = path + self.addSlashFirstAndLast(destinationPath)
                } else if (!self.customPath.isEmpty) {
                    path = self.addSlashFirstAndLast(self.customPath)
                } else {
                    path = path + self.addSlashFirstAndLast(self.pdfName)
                }
                path = path + String(self.currentPage) + format
                data.writeToFile(path, atomically: true)
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: path)
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPageInfo(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if !self.checkFileOpen() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            let n = command.accessibilityElementAtIndex(0) == nil ? self.currentPage : command.arguments[0] as! Int
            let index: NSNumber = n >= self.pdfPageCount ? self.pdfPageCount - 1 : n
            let pageSize: CGSize = self.core!.getPageSize(index.intValue)
            
            var result:Dictionary<String, AnyObject> = Dictionary()
            result[self.NumberOfPage] = self.pdfPageCount
            result[self.PageWidth] = pageSize.width
            result[self.PageHeight] = pageSize.height
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: result)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPDFInfo(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if !self.checkFileOpen() {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: self.preparePDFInfo())
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func changePreference(command: CDVInvokedUrlCommand) {
        self.customPath = command.arguments[0] as! String
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: self.preparePDFInfo())
        self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }
    
    private func preparePDFInfo() -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = Dictionary()
        result[self.NumberOfPage] = self.pdfPageCount
        result[self.FileName] = self.pdfName
        result[self.FilePath] = self.pdfPath
        return result
    }
    
    private func checkPassword(password: String) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if self.core!.needsPassword() {
            var cPassword = password.cStringUsingEncoding(NSUTF8StringEncoding)!
            if password.utf16.count == 0 {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "The PDF needs password.")
            } else if !self.core!.authenticatePassword(&cPassword) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Password incorrect.")
            }
        }
        return pluginResult
    }
    
    private func checkPDFReady() -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        self.pdfPageCount = self.core!.countPages()
        if self.pdfPageCount == 0 {
            self.closeFile()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
        }
        return pluginResult
    }
    
    private func openFile(content: AnyObject, openType: Int) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if openType == self.Path {
            let path = content as! String
            self.pdfName = self.getFileName(path)
            self.pdfPath = path
            let nspath = SystemPath + "/" + path
            var cPath = nspath.cStringUsingEncoding(NSUTF8StringEncoding)!
            if !self.core!.openFile(&cPath) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
            }
        } else {
            //            var buffer: NSData = content as NSData
            //            var magic = "".cStringUsingEncoding(NSUTF8StringEncoding)!
            //            if !self.core!.openFile(buffer, magic: &magic) {
            //                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
            //            }
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "iOS not support open buffer yet.")
        }
        return pluginResult
    }
    
    private func checkFileOpen() -> Bool {
        return self.core!.isFileOpen()
    }
    
    private func getFileName(path: String) -> String {
        if let slashRange = path.rangeOfString("/") {
            let pdfName = path.substringFromIndex(slashRange.endIndex)
            return getFileName(pdfName)
        } else {
            if let dotRange = path.rangeOfString(".") {
                return path.substringToIndex(dotRange.startIndex)
            } else {
                return path
            }
            
        }
    }
    
    private func closeFile() {
        self.core!.closeFile()
        self.pdfName = "";
        self.pdfPath = "";
        self.pdfPageCount = 0;
        self.currentPage = 0;
    }
    
    private func addSlashFirstAndLast(destinationPath: String) -> String {
        var path = destinationPath
        if path[path.startIndex] != "/" {
            path = "/" + path
        }
        if path[path.endIndex.advancedBy(-1)] != "/" {
            path = path + "/"
        }
        return path
    }
}