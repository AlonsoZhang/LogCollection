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
    @IBOutlet weak var aplogdate: NSButton!
    @IBOutlet weak var aelogdate: NSButton!
    @IBOutlet weak var nonelogdate: NSButton!
    @IBOutlet weak var tmpdir: NSButton!
    @IBOutlet weak var docum: NSButton!
    
    var logType = "-t"
    var logDateFormat = "None"
    var username = ""
    var password = ""
    var ipArr:[String] = []
    let dateFormatter = DateFormatter()
    let queue = DispatchQueue(label: "LogCollection.wistron", qos: DispatchQoS.default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd HH:"
        endTime.stringValue = "\(dayFormatter.string(from: Date()))00:00"
        startTime.stringValue = "\(dayFormatter.string(from: Date().addingTimeInterval(-7*3600*24)))00:00"
        startTime.isEnabled = false
        endTime.isEnabled = false
        
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    @IBAction func chooseLogPathAction(_ sender: NSButton) {
        let tag = sender.tag
        if tag==0 {
            logType = "-t"
            aplogdate.isEnabled = true
            aelogdate.title = "(AE)yyyyMMdd-HHmmss"
        }
        if(tag==1){
            logType = "-l"
            aplogdate.isEnabled = false
            aelogdate.title = "(AE)yyyy-MM-dd HH/mm/ss"
        }
    }
    
    @IBAction func chooseLogDateFormatAction(_ sender: NSButton) {
        let tag = sender.tag
        if tag==0 {
            if docum.state.rawValue == 0{
                logDateFormat = "\\d{8}-\\d{6}"
            }else{
                logDateFormat = "\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}"
            }
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
        ipArr = ip.stringValue.components(separatedBy: ",")
        showmessage(inputString: "Start Program ... Total \(ipArr.count) IP")
        var countnum = ipArr.count
        let sTime = dateFormatter2.string(from: startDate!)
        let eTime = dateFormatter2.string(from: endDate!)
        let targetplanfile = Bundle.main.path(forResource:"TargetPlan", ofType: "")!
        let newlogDateFormat = self.logDateFormat.replacingOccurrences(of: "\\", with: "\\\\")
        let cmd = "/Users/\(self.username)/Downloads/TargetPlan \(self.logType) \(newlogDateFormat) \(sTime) \(eTime)"
        let tempsh = Bundle.main.path(forResource:"temp", ofType: "sh")!
        try! cmd.write(toFile: tempsh, atomically: true, encoding: String.Encoding.utf8)
        for (index, ipaddress) in ipArr.enumerated() {
            let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
            showmessage(inputString: "\(indexnum) User: \(username), Password: \(password)")
            DispatchQueue.global().async {
                self.queue.sync {
                    self.showmessage(inputString: "\(indexnum) Upload TargetPlan")
                    let beforescp = Date()
                    self.scp(frompath: targetplanfile, topath: "/Users/\(self.username)/Downloads/",upload: true,ip: ipaddress)
                    let afterscp = Date()
                    let scptime = Int(afterscp.timeIntervalSince1970-beforescp.timeIntervalSince1970)
                    if scptime > 9{
                        self.showmessage(inputString: "\(indexnum) Build Connection Fail!")
                        countnum = countnum - 1
                        return
                    }
                    self.scp(frompath: tempsh, topath: "/Users/\(self.username)/Downloads/", upload: true, ip: ipaddress)
                }
                self.showmessage(inputString: "\(indexnum) Start run TargetPlan...")
                var logfile = self.sshRun(command: "sh /Users/\(self.username)/Downloads/temp.sh",ip: ipaddress)
                if logfile.contains("No file match regex or time rule"){
                    self.showmessage(inputString: "\(indexnum) No file match regex or time rule")
                }
                logfile = self.findStringInString(str: logfile, pattern: ".*?.tar")
                if logfile.count > 0{
                    self.showmessage(inputString: "\(indexnum) Download \(logfile)")
                    let paths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
                    self.scp(frompath: logfile, topath: paths[0] as! String, upload: false, ip: ipaddress)
                }
                self.showmessage(inputString: "\(indexnum) Remove unwanted files")
                self.sshRemove(path: "/Users/\(self.username)/Downloads/temp.sh /Users/\(self.username)/Downloads/TargetPlan \(logfile)", ip: ipaddress)
                self.showmessage(inputString: "\(indexnum) Well Done!")
                countnum = countnum - 1
                if countnum == 0{
                    DispatchQueue.main.async {
                        self.exportBtn.isEnabled = true
                    }
                }
            }
        }
    }
    
    func scp(frompath:String ,topath:String, upload:Bool, ip:String) {
        let scpfile = Bundle.main.path(forResource:"scp", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        if upload{
            let arguments = ["\(scpfile)","\(frompath)","\(self.username)@\(ip):\(topath)","\(self.password)"]
            task.arguments = arguments
        }else{
            let arguments = ["\(scpfile)","\(self.username)@\(ip):\(frompath)","\(topath)","\(self.password)"]
            task.arguments = arguments
        }
        task.launch()
        task.waitUntilExit()
    }
    
    func sshRemove(path:String, ip:String) {
        let sshremovefile = Bundle.main.path(forResource:"sshremove", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshremovefile)","\(self.username)@\(ip)","\(self.password)","\(path)"]
        task.arguments = arguments
        task.launch()
        //task.waitUntilExit()
    }
    
    func sshRun(command:String ,ip:String) -> String{
        let sshfile = Bundle.main.path(forResource:"sshrun", ofType: "")!
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshfile)","\(self.username)@\(ip)","\(self.password)","\(command)"]
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
    }
    
    func ssh(ip:String) -> String{
        let sshfile = Bundle.main.path(forResource:"ssh", ofType: "")!
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshfile)","\(self.username)@\(ip)","\(self.password)"]
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
