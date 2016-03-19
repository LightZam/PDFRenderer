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
    enum DestinationType: Int {
        case DataBin = 0, DataUrl, FileUri
    }

    enum EncodingType: Int {
        case Jpeg = 0, Png
    }

    enum OpenType: Int {
        case Path = 0, Buffer
    }

    enum PDFInfo: String {
        case NumberOfPage = "numberOfPage"
        case PageWidth = "width"
        case PageHeight = "height"
        case FilePath = "path"
        case FileName = "name"
    }

    class PageInfo {
        var index: NSNumber
        var pageSize: CGSize
        var patchRect: CGRect
        var quality: CGFloat
        var encodingType: EncodingType
        var destinationType: DestinationType
        var destinationPath: String

        init(args: [AnyObject], realSize: CGSize) {
            index = args[0] as! NSNumber

            pageSize = CGSize()
            pageSize.width = args[1] as! Int == -1 ? realSize.width : args[1] as! CGFloat
            pageSize.height = args[2] as! Int == -1 ? realSize.height : args[2] as! CGFloat

            patchRect = CGRect()
            patchRect.origin.x = args[3] as! CGFloat
            patchRect.origin.y = args[4] as! CGFloat
            patchRect.size.width = args[5] as! Int == -1 ? realSize.width : args[5] as! CGFloat
            patchRect.size.height = args[6] as! Int == -1 ? realSize.height : args[6] as! CGFloat

            quality = args[7] as! CGFloat
            encodingType = EncodingType.init(rawValue: args[8] as! Int)!
            destinationType = DestinationType.init(rawValue: args[9] as! Int)!
            destinationPath = args[10] as! String
        }

        func name() -> String {
            if self.encodingType == EncodingType.Jpeg {
                return self.index.stringValue + ".jpeg"
            } else {
                return self.index.stringValue + ".png"
            }
        }
    }

    var core: PDFRendererCore?
    var pdfName: String
    var pdfPath: String
    var pdfPageCount: Int
    var currentPage: Int
    var customPath: String
    var SystemPath: String

    override init() {
        pdfName = ""
        pdfPath = ""
        pdfPageCount = 0
        currentPage = 0
        customPath = ""
        SystemPath = ""
        super.init()
    }

    override func pluginInitialize() {
        self.core = PDFRendererCore()
        self.SystemPath = NSHomeDirectory() + "/Documents"
        super.pluginInitialize()
    }

    func open(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            let content: AnyObject = command.arguments[0] as AnyObject
            let openType = command.arguments[1] as! Int
            let password = command.arguments[2] as! String

            let result: CDVPluginResult = self.doOpen(content, openType: openType, password: password)
            self.commandDelegate!.sendPluginResult(result, callbackId: command.callbackId)
        })
    }

    private func doOpen(content: AnyObject, openType: Int, password: String) -> CDVPluginResult {
        self.closeFile()
        if let result = self.openFile(content, openType: openType) {
            return result
        } else {
            if let result = self.checkPassword(password) {
                return result
            } else {
                if let result = self.checkPDFReady() {
                    return result
                } else {
                    return CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: self.preparePDFInfo())
                }
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

    private func openFile(content: AnyObject, openType: Int) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if openType == OpenType.Path.rawValue {
            let path = content as! String
            self.pdfName = self.getFileName(path)
            self.pdfPath = path
            let nspath = self.SystemPath + "/" + path
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

    func close(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            self.closeFile()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }

    func getPage(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if self.sendFailIfFileNotReady(command) {
                return
            }

            let index = command.arguments[0] as! NSNumber
            let info: PageInfo = PageInfo(args: command.arguments, realSize: self.core!.getPageSize(index.intValue))
            let data: NSData = self.doGetPage(info)
            self.currentPage = index.integerValue

            var pluginResult: CDVPluginResult? = nil
            switch info.destinationType {
            case .DataBin:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)
                break
            case .DataUrl:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))
                break
            case .FileUri:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: self.saveToDisk(info, data: data))
                break
            }
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }

    private func sendFailIfFileNotReady(command: CDVInvokedUrlCommand) -> Bool {
        if self.core!.isFileOpen() {
            return false
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
            return true
        }
    }

    private func doGetPage(info: PageInfo) -> NSData {
        let image: UIImage! = self.core!.drawPage(info.index.intValue, pageSize: info.pageSize, patchRect: info.patchRect)
        if info.encodingType == EncodingType.Jpeg {
            return UIImageJPEGRepresentation(image, info.quality)!
        } else {
            return UIImagePNGRepresentation(image)!
        }
    }

    private func saveToDisk(info: PageInfo, data: NSData) -> String {
        var destPath: String

        if (!info.destinationPath.isEmpty) {
            destPath = self.SystemPath + self.addSlashFirstAndLast(info.destinationPath)
        } else if (!self.customPath.isEmpty) {
            destPath = self.customPath
        } else {
            destPath = self.SystemPath + self.addSlashFirstAndLast(self.pdfName)
        }
        self.createFolderIfNotExist(destPath)

        let path: String = destPath + info.name()
        data.writeToFile(path, atomically: true)

        return path
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

    private func createFolderIfNotExist(path: String) {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }

    func getPageInfo(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if self.sendFailIfFileNotReady(command) {
                return
            }

            let n = command.accessibilityElementAtIndex(0) == nil ? self.currentPage : command.arguments[0] as! Int
            let index: NSNumber = n >= self.pdfPageCount ? self.pdfPageCount - 1 : n
            let pageSize: CGSize = self.core!.getPageSize(index.intValue)

            var result:Dictionary<String, AnyObject> = Dictionary()
            result[PDFInfo.NumberOfPage.rawValue] = self.pdfPageCount
            result[PDFInfo.PageWidth.rawValue] = pageSize.width
            result[PDFInfo.PageHeight.rawValue] = pageSize.height
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: result)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }

    func getPDFInfo(command: CDVInvokedUrlCommand) {
        commandDelegate!.runInBackground({
            if self.sendFailIfFileNotReady(command) {
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
        result[PDFInfo.NumberOfPage.rawValue] = self.pdfPageCount
        result[PDFInfo.FileName.rawValue] = self.pdfName
        result[PDFInfo.FilePath.rawValue] = self.pdfPath
        return result
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
}