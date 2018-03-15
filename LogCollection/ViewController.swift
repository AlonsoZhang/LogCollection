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
    @IBOutlet weak var password: NSTextField!
    @IBOutlet var info: NSTextView!
    @IBOutlet weak var startTime: NSTextField!
    @IBOutlet weak var endTime: NSTextField!
    var logType = "-t"
    var logDateFormat = "\\d{8}-\\d{6}"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let path = "/Users/alonso/Desktop/scp"
        
        
//        expect /Users/alonso/Desktop/scp /Users/alonso/Desktop/demo.txt gdlocal@172.17.68.147:/Users/gdlocal/Documents/ gdlocal
//
//        NSString shellPath = @"/Users/lengshengren/Desktop/tool/LSUnusedResources-master/simian/bin";
//        //脚本路径
//        NSString* path =[shellPaht stringByAppendingString:@"/aksimian.sh"];
//
//        NSTask *task = [[NSTask alloc] init];
//        [task setLaunchPath: @"/bin/sh"];
//        //数组index 0 shell路径, 如果shell 脚本有输入参数,可以加入数组里，index 1 可以输入$1 @[path,@"$1"],依次延后。
//        NSArray *arguments =@[path];
//        [task setArguments: arguments];
//        [task launch];
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
            logDateFormat = ""
        }
    }
    
    @IBAction func export(_ sender: NSButton) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyyMMddHHmmss"
        let startDate = dateFormatter.date(from: startTime.stringValue)
        let endDate = dateFormatter.date(from: endTime.stringValue)
        if startDate == nil || endDate == nil{
            showmessage(inputString: "Date format is error, please check.")
            return
        }
        let sTime = dateFormatter2.string(from: startDate!)
        let eTime = dateFormatter2.string(from: endDate!)
        let targetplanfile = Bundle.main.path(forResource:"TargetPlan", ofType: "")!
        scp(frompath: targetplanfile, topath: "/Users/\(user.stringValue)/Downloads/",style: "upload")
        let newlogDateFormat = logDateFormat.replacingOccurrences(of: "\\", with: "\\\\")
        let cmd = "/Users/\(user.stringValue)/Downloads/TargetPlan \(logType) \(newlogDateFormat) \(sTime) \(eTime)"
        let tempsh = Bundle.main.path(forResource:"temp", ofType: "sh")!
        try! cmd.write(toFile: tempsh, atomically: true, encoding: String.Encoding.utf8)
        
        //scp(frompath: "/Users/\(user.stringValue)/Downloads/\()", topath: "/Users/Alonso/Downloads/",style: "download")
        
        
        
        //cmd = "/Users/sw/Downloads/TargetPlan -t \\d{8}-\\d{6} 20180306000000 20180313000000"
        //print(cmd)
        //sshRun(command: cmd)
        //print("expect \(scpfile) \(targetplanfile) \(user.stringValue)@\(ip.stringValue):/Users/\(user.stringValue)/Downloads/ \(password.stringValue)")
//        let bbb = run(cmd: "\(scpfile) \(targetplanfile) \(user.stringValue)@\(ip.stringValue):/Users/\(user.stringValue)/Downloads/ \(password.stringValue)")
//        print(bbb)
        //let aaa = run(cmd: "\(file) \(logType) \(logDateFormat) \(sTime) \(eTime)")
        //print(aaa)
        
        

        var logfile = sshRun(command: "sh /Users/\(user.stringValue)/Downloads/temp.sh")
        logfile = findStringInString(str: logfile, pattern: ".*?.tar")
        print("aaa \(logfile)")
        
        sshRemove(path: "/Users/\(user.stringValue)/Downloads/temp.sh /Users/\(user.stringValue)/Downloads/TargetPlan" )
    
        
    }
    
    func scp(frompath:String ,topath:String, style:String) {
        let scpfile = Bundle.main.path(forResource:"scp", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        if style == "upload"{
            let arguments = ["\(scpfile)","\(frompath)","\(user.stringValue)@\(ip.stringValue):\(topath)","\(password.stringValue)"]
            task.arguments = arguments
        }else{
            let arguments = ["\(scpfile)","\(user.stringValue)@\(ip.stringValue):\(frompath)","\(topath)","\(password.stringValue)"]
            task.arguments = arguments
        }
        //task.arguments = arguments
        task.launch()
        task.waitUntilExit()
    }
    
    func sshRemove(path:String) {
        let sshremovefile = Bundle.main.path(forResource:"sshremove", ofType: "")!
        let task = Process()
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshremovefile)","\(user.stringValue)@\(ip.stringValue)","\(password.stringValue)","\(path)"]
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
    }
    
    func sshRun(command:String) -> String{
        let sshfile = Bundle.main.path(forResource:"sshrun", ofType: "")!
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/expect"
        let arguments = ["\(sshfile)","\(user.stringValue)@\(ip.stringValue)","\(password.stringValue)","\(command)"]
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
                self.info.string = inputString
            }else{
                self.info.string = self.info.string + "\n\(inputString)"
            }
        }
    }
    
    func findArrayInString(str:String , pattern:String ) -> [String]
    {
        do {
            var stringArray = [String]();
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            for checkingRes in res
            {
                let tmp = (str as NSString).substring(with: checkingRes.range)
                stringArray.append(tmp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            return stringArray
        }
        catch
        {
            showmessage(inputString: "findArrayInString Regex error")
            return [String]()
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

