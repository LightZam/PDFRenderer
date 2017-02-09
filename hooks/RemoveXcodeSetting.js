#!/usr/bin/env node

var fs = require('fs');
var xcode = require('xcode');
var path = require('path');

module.exports = function(context) {
    var projectName, pbxPath, xcodeProj;
    var projectRoot = context.opts.projectRoot;

    projectName = getConfigParser(context, path.join(projectRoot, 'config.xml')).name();
    pbxPath = path.join(projectRoot, 'platforms', 'ios', projectName + '.xcodeproj/project.pbxproj');
    xcodeProj = xcode.project(pbxPath);

    xcodeProj.parseSync();
    console.log(1)
    xcodeProj.removeFromUserHeaderSearchPaths('../../plugins/com.gss.pdfrenderer/include');
    console.log(2)
    xcodeProj.removeSwiftObjcBridgingHeader('$(PROJECT_DIR)/$(PROJECT_NAME)/Plugins/com.gss.pdfrenderer/PDFRenderer-Bridging-Header.h');
    console.log(3)
    fs.writeFileSync(pbxPath, xcodeProj.writeSync());
    console.log(4)
};

function getConfigParser(context, config) {
    var semver = context.requireCordovaModule('semver');

    if (semver.lt(context.opts.cordova.version, '5.4.0')) {
        ConfigParser = context.requireCordovaModule('cordova-lib/src/ConfigParser/ConfigParser');
    } else {
        ConfigParser = context.requireCordovaModule('cordova-common/src/ConfigParser/ConfigParser');
    }

    return new ConfigParser(config);
}