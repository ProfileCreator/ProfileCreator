//
//  OverlayScroller.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class OverlayScroller: NSScroller {

    // MARK: -
    // MARK: Variables

    override var floatValue: Float {
        get {
            return super.floatValue
        }
        set {
            super.floatValue = newValue
            self.animator().alphaValue = 1.0
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.fadeOut), object: nil)
            self.perform(#selector(self.fadeOut), with: nil, afterDelay: 1.0)
        }
    }

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initialize()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.initialize()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initialize()
    }

    func initialize() {
        let trackingArea = NSTrackingArea(rect: self.bounds,
                                               options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved],
                                               owner: self,
                                               userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    // MARK: -
    // MARK: Custom Methods

    @objc func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 0.0
        }
    }

    @objc class func zeroWidth() -> CGFloat {
        return 0.0
    }

    // MARK: -
    // MARK: NSView Method Overrides

    override func draw(_ dirtyRect: NSRect) {
        // Only draw the knob. drawRect: should only be invoked when overlay scrollers are not used
        self.drawKnob()
    }

    // MARK: -
    // MARK: - NSScroller Method Overrides

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Don't draw the background. Should only be invoked when using overlay scrollers
    }

    // MARK: -
    // MARK: NSResponder Method Overrides

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.fadeOut()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().alphaValue = 1.0
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.fadeOut), object: nil)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        self.alphaValue = 1.0
    }
}
