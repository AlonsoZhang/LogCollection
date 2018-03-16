//
//  ViewController.swift
//  LogCollection
//
//  Created by Alonso on 13/03/2018.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var ip: NSTextField!
    @IBOutlet weak var user: NSTextField!
    @IBOutlet weak var psw: NSTextField!
    @IBOutlet var info: NSTextView!
    @IBOutlet weak var startTime: NSTextField!
    @IBOutlet weak var endTime: NSTextField!
    @IBOutlet weak var exportBtn: NSButton!
    @IBOutlet weak var scrollview: NSScrollView!
    
    var logType = "-t"
    var logDateFormat = "\\d{8}-\\d{6}"
    var username = ""
    var password = ""
    var ipaddress = ""
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd HH:"
        endTime.stringValue = "\(dayFormatter.string(from: Date()))00:00"
        startTime.stringValue = "\(dayFormatter.string(from: Date().addingTimeInterval(-7*3600*24)))00:00"
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    @IBAction func chooseLogPathAction(_ sender: NSButton) {
        let tag = sender.tag
        if tag==0 {
            logType = "-t"
        }
        if(tag==1){
            logType = "-l"
        }
    }
    
    @IBAction func chooseLogDateFormatAction(_ sender: NSButton) {
        let tag = sender.tag
        if tag==0 {
            logDateFormat = "\\d{8}-\\d{6}"
        }
        if(tag==1){
            logDateFormat = "\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}\\.\\d{3}"
        }
        if(tag==2){
            logDateFormat = "None"
            startTime.isEnabled = false
            endTime.isEnabled = false
        }else{
            startTime.isEnabled = true
            endTime.isEnabled = true
        }
    }
    
    @IBAction func export(_ sender: NSButton) {
        showmessage(inputString: "Start Program")
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyyMMddHHmmss"
        let startDate = dateFormatter.date(from: startTime.stringValue)
        let endDate = dateFormatter.date(from: endTime.stringValue)
        if startDate == nil || endDate == nil{
            showmessage(inputString: "Date format is error, please check.")
            return
        }
        exportBtn.isEnabled = false
        username = user.stringValue
        password = psw.stringValue
        ipaddress = ip.stringValue
        showmessage(inputString: "IP: \(ipaddress), User: \(username), Password: \(password)")
        DispatchQueue.global().async {
            let sTime = dateFormatter2.string(from: startDate!)
            let eTime = dateFormatter2.string(from: endDate!)
            let targetplanfile = Bundle.main.path(forResource:"TargetPlan", ofType: "")!
            self.showmessage(inputString: "Upload TargetPlan to \(self.ipaddress)")
            self.scp(frompath: targetplanfile, topath: "/Users/\(self.username)/Downloads/",upload: true)
            let newlogDateFormat = self.logDateFormat.replacingOccurrences(of: "\\", with: "\\\\")
            let cmd = "/Users/\(self.username)/Downloads/TargetPlan \(self.logType) \(newlogDateFormat) \(sTime) \(eTime)"
            let tempsh = Bundle.main.path(forResource:"temp", ofType: "sh")!
            try! cmd.write(toFile: tempsh, atomically: true, encoding: String.Encoding.utf8)
            self.scp(frompath: tempsh, topath: "/Users/\(self.username)/Downloads/", upload: true)
            self.showmessage(inputString: "Start run TargetPlan...")
            var logfile = self.sshRun(command: "sh /Users/\(self.username)/Downloads/temp.sh")
            if logfile.contains("No file match regex or time rule"){
                self.showmessage(inputString: "No file match regex or time rule")
            }
            logfile = self.findStringInString(str: logfile, pattern: ".*?.tar")
            if logfile.count > 0{
                self.showmessage(inputString: "Download \(logfile)")
                let paths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
                self.scp(frompath: logfile, topath: paths[0] as! String, upload: false)
            }
            self.showmessage(inputString: "Remove unwanted files")
            self.sshRemove(path: "/Users/\(self.username)/Downloads/temp.sh /Users/\(self.username)/Downloads/TargetPlan \(logfile)" )
            self.showmessage(inputString: "Finish")
            DispatchQueue.main.async {
                self.exportBtn.isEnabled = true
            }
        }
    }
    
    func scp(frompath:String ,topath:String, upload:Bool) {
        let scpfile = Bundle.main.path(forResource:"scp", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        if upload{
            let arguments = ["\(scpfile)","\(frompath)","\(self.username)@\(self.ipaddress):\(topath)","\(self.password)"]
            task.arguments = arguments
        }else{
            let arguments = ["\(scpfile)","\(self.username)@\(self.ipaddress):\(frompath)","\(topath)","\(self.password)"]
            task.arguments = arguments
        }
        task.launch()
        task.waitUntilExit()
    }
    
    func sshRemove(path:String) {
        let sshremovefile = Bundle.main.path(forResource:"sshremove", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshremovefile)","\(self.username)@\(self.ipaddress)","\(self.password)","\(path)"]
        task.arguments = arguments
        task.launch()
        //task.waitUntilExit()
    }
    
    func sshRun(command:String) -> String{
        let sshfile = Bundle.main.path(forResource:"sshrun", ofType: "")!
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshfile)","\(self.username)@\(self.ipaddress)","\(self.password)","\(command)"]
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
    }
    
    func ssh() -> String{
        let sshfile = Bundle.main.path(forResource:"ssh", ofType: "")!
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshfile)","\(self.username)@\(self.ipaddress)","\(self.password)"]
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
    }
    
    var error: NSDictionary?
    @discardableResult
    func run(cmd:String) -> String {
        var ncmd = cmd
        if cmd.contains("\\") {
            ncmd = cmd.replacingOccurrences(of: "\\", with: "\\\\\\\\")
        }
        let des = NSAppleScript(source: "do shell script \"\(ncmd)\"")!.executeAndReturnError(&error)
        if error != nil {
            return String(describing: error!)
        }
        if des.stringValue != nil {
            return des.stringValue!
        }else{
            return ""
        }
    }
    
    func showmessage(inputString: String) {
        DispatchQueue.main.async {
            if self.info.string == "" {
                self.info.string = "\(self.dateFormatter.string(from: Date()))  \(inputString)"
            }else{
                self.info.string = self.info.string + "\n\(self.dateFormatter.string(from: Date()))  \(inputString)"
            }
            if let height = self.scrollview.documentView?.bounds.size.height{
                var diff = height-self.scrollview.documentVisibleRect.height
                if diff < 0 {
                    diff = 0
                }
                self.scrollview.contentView.scroll(NSMakePoint(0, diff))
            }
        }
    }
    
    func findStringInString(str:String , pattern:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            if let checkingRes = res
            {
                return ((str as NSString).substring(with: checkingRes.range)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return ""
        }
        catch
        {
            showmessage(inputString: "findStringInString Regex error")
            return ""
        }
    }
}

