//
//  ViewWhite.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ViewWhite: NSView {

    let color: NSColor
    let acceptFirstResponder: Bool
    var showBackground: Bool = true

    weak var draggingDestination: NSDraggingDestination?

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(acceptsFirstResponder: Bool = true) {
        self.color = .controlBackgroundColor
        self.acceptFirstResponder = acceptsFirstResponder
        super.init(frame: NSRect.zero)
    }

    init(draggingDestination: NSDraggingDestination, draggingTypes: [NSPasteboard.PasteboardType], acceptsFirstResponder: Bool = true, showBackground: Bool, color: NSColor? = nil) {
        self.color = color ?? .controlBackgroundColor
        self.showBackground = showBackground
        self.acceptFirstResponder = acceptsFirstResponder
        super.init(frame: NSRect.zero)
        self.draggingDestination = draggingDestination
        self.registerForDraggedTypes(draggingTypes)
        self.focusRingType = .default
    }

    override func draw(_ dirtyRect: NSRect) {
        if self.showBackground {
            self.color.set()
            self.bounds.fill()
        } else {
            super.draw(dirtyRect)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let draggingEntered = self.draggingDestination?.draggingEntered {
            return draggingEntered(sender)
        }
        return NSDragOperation()
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let draggingExited = self.draggingDestination?.draggingExited {
            draggingExited(sender)
        }
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let prepareForDragOperation = self.draggingDestination?.prepareForDragOperation {
            return prepareForDragOperation(sender)
        }
        return false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let performDragOperation = self.draggingDestination?.performDragOperation {
            return performDragOperation(sender)
        }
        return false
    }
}

// FIXME: Test to draw a focus ring orund the view. Haven't really tried much yet, should fix.
extension ViewWhite {

    override var acceptsFirstResponder: Bool {
        return self.acceptFirstResponder
    }

    override func drawFocusRingMask() {
        // return __NSRectFill( self.bounds )
    }

    override var focusRingMaskBounds: NSRect {
        return self.bounds
    }

}
