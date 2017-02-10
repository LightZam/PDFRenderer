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
        case dataBin = 0, dataUrl, fileUri
    }

    enum EncodingType: Int {
        case jpeg = 0, png
    }

    enum OpenType: Int {
        case path = 0, buffer
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
            if self.encodingType == EncodingType.jpeg {
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

    // Deprecated in ios-4.0.0 and above, must remove this method if you are using version above it.
    override init(webView theWebView: UIWebView!) {
        pdfName = ""
        pdfPath = ""
        pdfPageCount = 0
        currentPage = 0
        customPath = ""
        SystemPath = ""
        self.core = PDFRendererCore()
        self.SystemPath = NSHomeDirectory() + "/Documents"
        super.init()
    }

    override func pluginInitialize() {
        self.core = PDFRendererCore()
        self.SystemPath = NSHomeDirectory() + "/Documents"
        super.pluginInitialize()
    }

    func open(_ command: CDVInvokedUrlCommand) {
        commandDelegate!.run(inBackground: {
            let content: AnyObject = command.arguments[0] as AnyObject
            let openType = command.arguments[1] as! Int
            let password = command.arguments[2] as! String

            let result: CDVPluginResult = self.doOpen(content, openType: openType, password: password)
            self.commandDelegate!.send(result, callbackId: command.callbackId)
        })
    }

    fileprivate func doOpen(_ content: AnyObject, openType: Int, password: String) -> CDVPluginResult {
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
                    return CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.preparePDFInfo())
                }
            }
        }
    }

    fileprivate func closeFile() {
        self.core!.closeFile()
        self.pdfName = "";
        self.pdfPath = "";
        self.pdfPageCount = 0;
        self.currentPage = 0;
    }

    fileprivate func openFile(_ content: AnyObject, openType: Int) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if openType == OpenType.path.rawValue {
            let path = content as! String
            self.pdfName = self.getFileName(path)
            self.pdfPath = path
            let nspath = self.SystemPath + "/" + path
            var cPath = nspath.cString(using: String.Encoding.utf8)!
            if !self.core!.openFile(&cPath) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Can not open document.")
            }
        } else {
            //            var buffer: NSData = content as NSData
            //            var magic = "".cStringUsingEncoding(NSUTF8StringEncoding)!
            //            if !self.core!.openFile(buffer, magic: &magic) {
            //                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
            //            }
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "iOS not support open buffer yet.")
        }
        return pluginResult
    }

    fileprivate func checkPassword(_ password: String) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if self.core!.needsPassword() {
            var cPassword = password.cString(using: String.Encoding.utf8)!
            if password.utf16.count == 0 {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "The PDF needs password.")
            } else if !self.core!.authenticatePassword(&cPassword) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Password incorrect.")
            }
        }
        return pluginResult
    }

    fileprivate func checkPDFReady() -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        self.pdfPageCount = self.core!.countPages()
        if self.pdfPageCount == 0 {
            self.closeFile()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Can not open document.")
        }
        return pluginResult
    }

    func close(_ command: CDVInvokedUrlCommand) {
        commandDelegate!.run(inBackground: {
            self.closeFile()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    func getPage(_ command: CDVInvokedUrlCommand) {
        commandDelegate!.run(inBackground: {
            if self.sendFailIfFileNotReady(command) {
                return
            }

            let index = command.arguments[0] as! NSNumber
            let info: PageInfo = PageInfo(args: command.arguments as [AnyObject], realSize: self.core!.getPageSize(index.int32Value))
            let data: Data = self.doGetPage(info)
            self.currentPage = index.intValue

            var pluginResult: CDVPluginResult? = nil
            switch info.destinationType {
            case .dataBin:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: data)
                break
            case .dataUrl:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))
                break
            case .fileUri:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.saveToDisk(info, data: data))
                break
            }
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    fileprivate func sendFailIfFileNotReady(_ command: CDVInvokedUrlCommand) -> Bool {
        if self.core!.isFileOpen() {
            return false
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Please open a file.")
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return true
        }
    }

    fileprivate func doGetPage(_ info: PageInfo) -> Data {
        let image: UIImage! = self.core!.drawPage(info.index.int32Value, pageSize: info.pageSize, patchRect: info.patchRect)
        if info.encodingType == EncodingType.jpeg {
            return UIImageJPEGRepresentation(image, info.quality)!
        } else {
            return UIImagePNGRepresentation(image)!
        }
    }

    fileprivate func saveToDisk(_ info: PageInfo, data: Data) -> String {
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
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])

        return path
    }

    fileprivate func addSlashFirstAndLast(_ destinationPath: String) -> String {
        var path = destinationPath
        if path[path.startIndex] != "/" {
            path = "/" + path
        }
        if path[path.characters.index(path.endIndex, offsetBy: -1)] != "/" {
            path = path + "/"
        }
        return path
    }

    fileprivate func createFolderIfNotExist(_ path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }

    func getPageInfo(_ command: CDVInvokedUrlCommand) {
        commandDelegate!.run(inBackground: {
            if self.sendFailIfFileNotReady(command) {
                return
            }

            let n = command.accessibilityElement(at: 0) == nil ? self.currentPage : command.arguments[0] as! Int
            let index: NSNumber = NSNumber(value: (n >= self.pdfPageCount ? self.pdfPageCount - 1 : n))
            let pageSize: CGSize = self.core!.getPageSize(index.int32Value)

            var result:Dictionary<String, AnyObject> = Dictionary()
            result[PDFInfo.NumberOfPage.rawValue] = self.pdfPageCount as AnyObject?
            result[PDFInfo.PageWidth.rawValue] = pageSize.width as AnyObject?
            result[PDFInfo.PageHeight.rawValue] = pageSize.height as AnyObject?
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    func getPDFInfo(_ command: CDVInvokedUrlCommand) {
        commandDelegate!.run(inBackground: {
            if self.sendFailIfFileNotReady(command) {
                return
            }

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.preparePDFInfo())
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    func changePreference(_ command: CDVInvokedUrlCommand) {
        self.customPath = command.arguments[0] as! String
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.preparePDFInfo())
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    fileprivate func preparePDFInfo() -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = Dictionary()
        result[PDFInfo.NumberOfPage.rawValue] = self.pdfPageCount as AnyObject?
        result[PDFInfo.FileName.rawValue] = self.pdfName as AnyObject?
        result[PDFInfo.FilePath.rawValue] = self.pdfPath as AnyObject?
        return result
    }

    fileprivate func getFileName(_ path: String) -> String {
        if let slashRange = path.range(of: "/") {
            let pdfName = path.substring(from: slashRange.upperBound)
            return getFileName(pdfName)
        } else {
            if let dotRange = path.range(of: ".") {
                return path.substring(to: dotRange.lowerBound)
            } else {
                return path
            }

        }
    }
}
