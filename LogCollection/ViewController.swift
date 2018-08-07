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
    @IBOutlet weak var killProgram: NSTextField!
    @IBOutlet weak var uploadFile: NSTextField!
    @IBOutlet var dragView: FileDragView!
    @IBOutlet weak var uploadBtn: NSButton!
    @IBOutlet weak var scpPath: NSTextField!
    @IBOutlet weak var qexportBtn: NSButton!
    @IBOutlet weak var screenBtn: NSButton!
    @IBOutlet weak var biglabel: NSTextField!
    
    var file = ""
    var logType = "-t"
    var logDateFormat = "None"
    var username = ""
    var password = ""
    var ipArr:[String] = []
    var ConfigPlist = [String: Any]()
    let dateFormatter = DateFormatter()
    let queue = DispatchQueue(label: "LogCollection", qos: DispatchQoS.default)
    let aepsw = AEPassword()
    let paths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
    var downloadpath = ""
    var auto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd HH:"
        endTime.stringValue = "\(dayFormatter.string(from: Date()))00:00"
        startTime.stringValue = "\(dayFormatter.string(from: Date().addingTimeInterval(-7*3600*24)))00:00"
        startTime.isEnabled = false
        endTime.isEnabled = false
        if #available(OSX 10.13, *) {
            uploadBtn.isEnabled = false
            uploadFile.isEditable = false
        }
        downloadpath = paths[0] as! String
        file = Bundle.main.path(forResource:"Config", ofType: "plist")!
        ConfigPlist = NSDictionary(contentsOfFile: file)! as! [String : Any]
        auto = ConfigPlist["AutoRun"] as! Bool
        if auto{
            autoRun()
        }else{
            biglabel.isHidden = true
            if ((ConfigPlist["LastOpen"]! as! String).count != 0){
                let lastOpenDate = dateFormatter.date(from: (ConfigPlist["LastOpen"]! as! String))
                let scptime = Int(Date().timeIntervalSince1970-(lastOpenDate?.timeIntervalSince1970)!)
                if scptime > 3600*24*7{
                    aepsw.askpassword(0)
                    ConfigPlist["LastOpen"] = endTime.stringValue
                    NSDictionary(dictionary: ConfigPlist).write(toFile: file, atomically: true)
                }
            }else{
                aepsw.askpassword(0)
                ConfigPlist["LastOpen"] = endTime.stringValue
                NSDictionary(dictionary: ConfigPlist).write(toFile: file, atomically: true)
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    func autoRun(){
        logType = "-l"
        logDateFormat = "\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}"
        ip.stringValue = ConfigPlist["IP"] as! String
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "mm:ss"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        var going = true
        DispatchTimer(timeInterval: 1) { (timer) in
            let nowtime = hourFormatter.string(from: Date())
            if Int(nowtime.prefix(2))!%5 == 0 && going{
                going = false
                let delaytime = TimeInterval(60 - Int(nowtime.suffix(2))!)
                self.showmessage(inputString: "Delay:\(Int(nowtime.suffix(2))!)")
                DispatchQueue.main.asyncAfter(deadline:.now() + delaytime) {
                    going = true
                }
                self.endTime.stringValue = "\(dayFormatter.string(from: Date())):00"
                let standardtime = "\(dayFormatter.string(from: Date().addingTimeInterval(-300))):00"
                if self.ConfigPlist["LastEndTime"] != nil{
                    let lastendtime = self.ConfigPlist["LastEndTime"] as! String
                    if (lastendtime == standardtime){
                        self.startTime.stringValue = lastendtime
                    }else{
                        self.startTime.stringValue = standardtime
                    }
                }else{
                    self.startTime.stringValue = standardtime
                }
                self.export(self.exportBtn)
            }
        }
        
        //手动设定时间
//        self.endTime.stringValue = "2018-08-07 08:50:00"
//        self.startTime.stringValue = "2018-08-06 17:50:00"
//        self.export(self.exportBtn)
    }
    
    /// GCD定时器循环操作
    ///   - timeInterval: 循环间隔时间
    ///   - handler: 循环事件
    public func DispatchTimer(timeInterval: Double, handler:@escaping (DispatchSourceTimer?)->())
    {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: timeInterval)
        timer.setEventHandler {
            DispatchQueue.main.async {
                handler(timer)
            }
        }
        timer.resume()
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
        if !actionPrepare(){
            return
        }
        exportBtn.isEnabled = false
        showmessage(inputString: "Start Program ... Total \(ipArr.count) IP")
        var countnum = ipArr.count
        let sTime = dateFormatter2.string(from: startDate!)
        let eTime = dateFormatter2.string(from: endDate!)
        let targetplanfile = Bundle.main.path(forResource:"TargetPlan", ofType: "")!
        let newlogDateFormat = self.logDateFormat.replacingOccurrences(of: "\\", with: "\\\\")
        var cmd = "/Users/\(self.username)/Downloads/TargetPlan \(self.logType) \(newlogDateFormat) \(sTime) \(eTime)"
        let getLogDataplist = Bundle.main.path(forResource:"getLogData", ofType: "plist")!
        let autopath = "/Library/WebServer/Documents/PFA_Data_Audit_System/upload/\(sTime).\(eTime)"
        if auto{
            cmd.append(" csv")
            let fileManager = FileManager.default
            try! fileManager.createDirectory(atPath: autopath, withIntermediateDirectories: true, attributes: nil)
        }
        let tempsh = Bundle.main.path(forResource:"temp", ofType: "sh")!
        try! cmd.write(toFile: tempsh, atomically: true, encoding: String.Encoding.utf8)
        for (index, ipaddress) in ipArr.enumerated() {
            let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
            showmessage(inputString: "\(indexnum) User: \(username), Password: \(password)")
            var returnflag = false
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
                        returnflag = true
                        return
                    }
                    self.scp(frompath: tempsh, topath: "/Users/\(self.username)/Downloads/", upload: true, ip: ipaddress)
                    if self.auto{
                        self.scp(frompath: getLogDataplist, topath: "/Users/\(self.username)/Downloads/", upload: true, ip: ipaddress)
                    }
                }
                if !returnflag{
                    self.showmessage(inputString: "\(indexnum) Start run TargetPlan...")
                    let logfile = self.sshRun(command: "/Users/\(self.username)/Downloads/temp.sh",ip: ipaddress)
                    if logfile.contains("No file match regex or time rule"){
                        self.showmessage(inputString: "\(indexnum) No file match regex or time rule")
                    }
                    if logfile.contains("Error"){
                        self.showmessage(inputString:logfile)
                    }
                    var finallogfile = logfile.replacingOccurrences(of: "\r", with: "")
                    if self.auto{
                        finallogfile = self.findStringInString(str: finallogfile, pattern: ".*?.csv")
                    }else{
                        finallogfile = self.findStringInString(str: finallogfile, pattern: ".*?.tar")
                    }
                    if finallogfile.count > 0{
                        self.showmessage(inputString: "\(indexnum) Download \(finallogfile)")
                        if self.auto{
                            self.scp(frompath: finallogfile, topath: autopath, upload: false, ip: ipaddress)
                        }else{
                            self.scp(frompath: finallogfile, topath: self.downloadpath, upload: false, ip: ipaddress)
                        }
                    }
                    self.showmessage(inputString: "\(indexnum) Remove unwanted files")
                    self.sshRemove(path: "/Users/\(self.username)/Downloads/temp.sh /Users/\(self.username)/Downloads/TargetPlan \(finallogfile)", ip: ipaddress)
                    if self.auto{
                        self.sshRemove(path: "/Users/\(self.username)/Downloads/getLogData.plist", ip: ipaddress)
                    }
                    self.showmessage(inputString: "\(indexnum) Well Done!")
                    countnum = countnum - 1
                }
                if countnum == 0{
                    DispatchQueue.main.async {
                        self.exportBtn.isEnabled = true
                    }
                    if self.auto{
                        let returnmsg = self.getRequest(path: "127.0.0.1/PFA_Data_Audit_System/CoreData/Tasks.php?Action=AddTask&Status=File_OK&Type=ArtemisMMV&FilePath=\(sTime).\(eTime)")
                        self.showmessage(inputString: "Upload result:\(returnmsg)")
                        DispatchQueue.main.async {
                            self.ConfigPlist["LastEndTime"] = self.endTime.stringValue
                            NSDictionary(dictionary: self.ConfigPlist).write(toFile: self.file, atomically: true)
                        }
                    }
                }
            }
        }
    }

    func getRequest(path:String) -> String {
        var resStr:String?
        let urlString:String = path
        let url = URL(string:urlString)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = session.dataTask(with: request,completionHandler: {(data, response, error) -> Void in
            if error != nil{
                print(error!)
            }else{
                let str = String(data: data!, encoding: String.Encoding.utf8)
                resStr = str!
            }
            semaphore.signal()
        }) as URLSessionTask
        dataTask.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        if (resStr == nil){
            resStr = "FAIL"
        }
        return resStr!
    }
    
    @IBAction func Kill(_ sender: NSButton) {
        aepsw.askpassword(1)
        if actionPrepare(){
            if ipArr.count != 1{
                showmessage(inputString: "Please Input Only One IP !!!")
                return
            }
            let program = killProgram.stringValue
            if program.count == 0{
                showmessage(inputString: "Please Input program name!")
                return
            }
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    self.queue.sync {
                        self.sshKill(app: program, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Kill \(program)")
                    }
                }
            }
        }
    }
    
    @IBAction func Open(_ sender: NSButton) {
        if actionPrepare(){
            let program = killProgram.stringValue
            if program.count == 0{
                showmessage(inputString: "Please Input program name!")
                return
            }
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    self.queue.sync {
                        self.sshOpen(app: program, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Open \(program)")
                    }
                }
            }
        }
    }
    
    @IBAction func Upload(_ sender: NSButton) {
        if actionPrepare(){
            let uploadPath = uploadFile.stringValue
            if uploadPath.count == 0{
                showmessage(inputString: "Please Drag file to upload!")
                return
            }
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    self.queue.sync {
                        self.scp(frompath: uploadPath, topath: "/Users/\(self.username)/Downloads/", upload: true, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Upload files to Downloads")
                    }
                }
            }
        }
    }
    
    @IBAction func Remove(_ sender: NSButton) {
        if actionPrepare(){
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    self.queue.sync {
                        self.sshRemove(path: "/Users/\(self.username)/Downloads/*", ip: ipaddress)
                        //self.sshRemove(path: "/Users/\(self.username)/Documents/Old.app /Users/\(self.username)/Documents/No Fail.app /Users/\(self.username)/Documents/PlistEditor.app", ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Remove Downloads all files")
                    }
                }
            }
        }
    }
    
    @IBAction func Replace(_ sender: NSButton) {
        aepsw.askpassword(1)
        if actionPrepare(){
            let program = killProgram.stringValue
            if program.count == 0{
                showmessage(inputString: "Please Input program name!")
                return
            }
            let uploadPath = uploadFile.stringValue
            if uploadPath.count == 0{
                showmessage(inputString: "Please Drag file to upload!")
                return
            }
            if program != self.findStringInString(str: uploadPath, pattern: "(?<=Desktop/).*(?=.app)"){
                showmessage(inputString: "Replace app name must same as kill!")
                return
            }
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    self.queue.sync {
                        self.sshKill(app: program, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Kill \(program)")
                        self.sshRemove(path: "/Users/\(self.username)/Desktop/\(program)", ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Remove \(program) on Desktop")
                        self.scp(frompath: uploadPath, topath: "/Users/\(self.username)/Desktop/", upload: true, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Upload \(program) to Desktop")
                        self.sshOpen(app: program, ip: ipaddress)
                        self.showmessage(inputString: "\(indexnum) Open \(program)")
                    }
                }
            }
        }
    }
    
    
    @IBAction func QuickExport(_ sender: NSButton) {
        if actionPrepare(){
            let scppath = self.scpPath.stringValue
            var countnum = ipArr.count
            qexportBtn.isEnabled = false
            showmessage(inputString: "Start Quick Export ... Total \(ipArr.count) IP")
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    let myDirectory:String = "\(self.downloadpath)/\(ipaddress)/"
                    let fileManager = FileManager.default
                    try! fileManager.createDirectory(atPath: myDirectory,
                                                     withIntermediateDirectories: true, attributes: nil)
                    self.scp(frompath: "\(scppath)", topath: myDirectory, upload: false, ip: ipaddress)
                    self.showmessage(inputString: "\(indexnum) scp files from \(scppath)")
                    self.queue.sync {
                        countnum = countnum - 1
                        if countnum == 0{
                            DispatchQueue.main.async {
                                self.qexportBtn.isEnabled = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func ScreenCapture(_ sender: NSButton) {
        if actionPrepare(){
            showmessage(inputString: "Start Screen Capture ... Total \(ipArr.count) IP")
            var countnum = ipArr.count
            screenBtn.isEnabled = false
            for (index, ipaddress) in ipArr.enumerated() {
                let indexnum = "(\(index+1)/\(ipArr.count)) \(ipaddress)"
                DispatchQueue.global().async {
                    let picFormatter = DateFormatter()
                    picFormatter.dateFormat = "yyyyMMddHHmmss"
                    let picpath = "/Users/\(self.username)/Downloads/\(ipaddress)-\(picFormatter.string(from: Date())).png"
                    self.sshScreenCapture(picname: picpath, ip: ipaddress)
                    self.scp(frompath: "\(picpath)", topath: "\(self.downloadpath)", upload: false, ip: ipaddress)
                    self.sshRemove(path: "\(picpath)", ip: ipaddress)
                    self.showmessage(inputString: "\(indexnum) Screen Capture")
                    self.queue.sync {
                        countnum = countnum - 1
                        if countnum == 0{
                            DispatchQueue.main.async {
                                self.screenBtn.isEnabled = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func OpenSSH(_ sender: NSButton) {
        if actionPrepare(){
            let sshfile = Bundle.main.path(forResource:"ssh", ofType: "")!
            for (_, ipaddress) in ipArr.enumerated() {
                DispatchQueue.global().async {
                    self.queue.sync {
                        let script = NSAppleScript.init(source: "tell application \"Terminal\" \n activate \n do script \"\(sshfile) \(self.username)@\(ipaddress) \(self.password)\" \n end tell")
                        script?.executeAndReturnError(&self.error)
                        self.showmessage(inputString: "\(ipaddress) open ssh")
                    }
                }
            }
        }
    }
    
    func actionPrepare() -> Bool {
        if ip.stringValue.count == 0{
            showmessage(inputString: "No IP, please check.")
            return false
        }
        ipArr = ip.stringValue.components(separatedBy: ",")
        username = user.stringValue
        password = psw.stringValue
        return true
    }
    
    func scp(frompath:String ,topath:String, upload:Bool, ip:String) {
        let scpfile = Bundle.main.path(forResource:"scp", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        if upload{
            let arguments = ["\(scpfile)","\(frompath)","\(self.username)@\(ip):\(topath)","\(self.password)","10"]
            task.arguments = arguments
        }else{
            let arguments = ["\(scpfile)","\(self.username)@\(ip):\(frompath)","\(topath)","\(self.password)","1000"]
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
    
    func sshScreenCapture(picname:String, ip:String) {
        let sshremovefile = Bundle.main.path(forResource:"sshscreen", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshremovefile)","\(self.username)@\(ip)","\(self.password)","\(picname)"]
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
    }
    
    func sshKill(app:String ,ip:String) {
        let killfile = Bundle.main.path(forResource:"sshkill", ofType: "")!
        var appstr = "";
        if app.hasSuffix(".app"){
            appstr = app.replacingOccurrences(of: ".app", with: "")
        }else{
            appstr = app
        }
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(killfile)","\(ip)","\(self.password)","\(self.username)","\(appstr)"]
        task.arguments = arguments
        task.launch()
    }
    
    func sshOpen(app:String ,ip:String) {
        var appstr = "";
        if app.hasSuffix(".app"){
            appstr = app
        }else{
            appstr = "\(app).app"
        }
        if appstr.components(separatedBy: "/").count < 3 {
            appstr = "/Users/\(self.username)/Desktop/\(appstr)"
        }
        let openfile = Bundle.main.path(forResource:"sshopen", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(openfile)","\(self.username)@\(ip)","\(self.password)","\(appstr)"]
        task.arguments = arguments
        task.launch()
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

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ files:Array<Any>){
        if files.count > 1 {
            uploadFile.textColor = NSColor.red
            uploadFile.stringValue = "Please drag one folder once !!!"
            uploadBtn.isEnabled = false
        }else{
            uploadFile.textColor = NSColor.blue
            let path = files[0]
            uploadFile.stringValue = "\(path)"
            uploadBtn.isEnabled = true
        }
    }
}
