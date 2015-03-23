//
//  MuPDF.swift
//  mupdf
//
//  Created by Zam-mbpr on 2015/3/4.
//
//

import Foundation

@objc(MuPDF)
class MuPDF : CDVPlugin {
    var core: MuPDFCore?
    
    let DataBin:Int = 0
    let DataUrl:Int = 1
    let FileUri:Int = 2
    
    let Jpeg:Int = 0
    let Png:Int = 1
    
    let Path:Int = 0
    let Buffer:Int = 1
    
    let NumberOfPage:String = "numberOfPage"
    let PageWidth:String = "width"
    let PageHeight:String = "height"
    let FilePath:String = "path"
    let FileName:String = "name"
    
    var fileName: String;
    var filePath: String;
    var numberOfPage: Int;
    var currentPage: Int;
    
    override
    init!(webView theWebView: UIWebView!) {
        self.core = MuPDFCore()
        self.fileName = ""
        self.filePath = ""
        self.numberOfPage = 0
        self.currentPage = 0
        super.init()
    }
    
    func open(command: CDVInvokedUrlCommand) {
        commandDelegate.runInBackground({
            var content = command.arguments[0] as AnyObject
            var openType = command.arguments[1] as Int
            var password = command.arguments[2] as String
            var cPassword = password.cStringUsingEncoding(NSUTF8StringEncoding)!
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
            self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func close(command: CDVInvokedUrlCommand) {
        commandDelegate.runInBackground({
            self.closeFile()
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPage(command: CDVInvokedUrlCommand) {
        commandDelegate.runInBackground({
            if !self.checkFileOpen() {
                var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            var page = command.arguments[0] as Int
            var width = command.arguments[1] as Int
            var height = command.arguments[2] as Int
            var patchX = command.arguments[3] as Int
            var patchY = command.arguments[4] as Int
            var patchWidth = command.arguments[5] as Int
            var patchHeight = command.arguments[6] as Int
            var quality = command.arguments[7] as Int
            var encodingType = command.arguments[8] as Int
            var destinationType = command.arguments[9] as Int
            
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: "message")
            self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPageInfo(command: CDVInvokedUrlCommand) {
        commandDelegate.runInBackground({
            if !self.checkFileOpen() {
                var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            let n = command.accessibilityElementAtIndex(0) == nil ? self.currentPage : command.arguments[0] as Int
            let index: NSNumber = n >= self.numberOfPage ? self.numberOfPage - 1 : n
            let pageSize: CGSize = self.core!.getPageSize(index.intValue)
            
            var result:Dictionary<String, AnyObject> = Dictionary()
            result[self.NumberOfPage] = self.numberOfPage
            result[self.PageWidth] = pageSize.width
            result[self.PageHeight] = pageSize.height
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: result)
            self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    func getPDFInfo(command: CDVInvokedUrlCommand) {
        commandDelegate.runInBackground({
            if !self.checkFileOpen() {
                var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Please open a file.")
                self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: self.preparePDFInfo())
            self.commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        })
    }
    
    private func preparePDFInfo() -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = Dictionary()
        result[self.NumberOfPage] = self.numberOfPage
        result[self.FileName] = self.fileName
        result[self.filePath] = self.filePath
        return result
    }
    
    private func checkPassword(password: String) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if self.core!.needsPassword() {
            var cPassword = password.cStringUsingEncoding(NSUTF8StringEncoding)!
            if password.utf16Count == 0 {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "The PDF needs password.")
            } else if !self.core!.authenticatePassword(&cPassword) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Password incorrect.")
            }
        }
        return pluginResult
    }
    
    private func checkPDFReady() -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        self.numberOfPage = self.core!.countPages()
        if self.numberOfPage == 0 {
            self.closeFile()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
        }
        return pluginResult
    }
    
    private func openFile(content: AnyObject, openType: Int) -> CDVPluginResult? {
        var pluginResult:CDVPluginResult?
        if openType == self.Path {
            let path = content as String
            var nspath = NSHomeDirectory() + "/Documents/" + path
            var cPath = nspath.cStringUsingEncoding(NSUTF8StringEncoding)!
            if !(self.core?.openFile(&cPath) != nil) {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Can not open document.")
            }
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Not support.")
        }
        return pluginResult
    }
    
    private func checkFileOpen() -> Bool {
        return self.core!.isFileOpen()
    }
    
    private func closeFile() {
        self.core?.closeFile()
        self.fileName = "";
        self.filePath = "";
        self.numberOfPage = 0;
        self.currentPage = 0;
    }
}