//
//  FileDragView.swift
//  GetLogData
//
//  Created by Alonso on 2017/8/18.
//  Copyright © 2017年 Alonso. All rights reserved.
//

import Cocoa

protocol FileDragDelegate: class {
    func didFinishDrag(_ files:Array<Any>)
}

class FileDragView: NSView {
    
    weak var delegate: FileDragDelegate?
    var highlight = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if highlight {
            NSColor.blue.set()
            NSBezierPath.defaultLineWidth = 10
            NSBezierPath.stroke(dirtyRect)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(OSX 10.13, *) {
            self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if (highlight == false) {
            highlight = true
            self.needsDisplay = true
        }
        let sourceDragMask = sender.draggingSourceOperationMask()
        let pboard = sender.draggingPasteboard()
        let dragTypes = pboard.types! as NSArray
        if #available(OSX 10.13, *) {
            if dragTypes.contains(NSPasteboard.PasteboardType.fileURL) {
                if sourceDragMask.contains([.link]) {
                    return .link
                }
                if sourceDragMask.contains([.copy]) {
                    return .copy
                }
            }
        } else {
            // Fallback on earlier versions
        }
        return .generic
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return self.draggingEntered(sender)
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        highlight = false
        self.needsDisplay = true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo)-> Bool {
        let pboard = sender.draggingPasteboard()
        let dragTypes = pboard.types! as NSArray
        if #available(OSX 10.13, *) {
            if dragTypes.contains(NSPasteboard.PasteboardType.fileURL) {
                let files = (pboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType"))) as! Array<String>
                let numberOfFiles = files.count
                if numberOfFiles > 0 {
                    if let delegate = self.delegate {
                        highlight = false
                        self.needsDisplay = true
                        delegate.didFinishDrag(files)
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
        return true
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
}
