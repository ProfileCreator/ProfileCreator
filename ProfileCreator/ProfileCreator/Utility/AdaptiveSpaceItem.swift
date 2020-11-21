//
//  AdaptiveSpaceItem.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

public class AdaptiveSpaceItem: NSToolbarItem {

    // MARK: -
    // MARK: NSToolbarItem Variables

    override public var label: String {
        get { "" }
        set { }
    }

    override public var paletteLabel: String {
        get { "Adaptive Space" }
        set { }
    }

    // MARK: -
    // MARK: Computed Variables

    var calculatedMinSize: NSSize {
        guard let items = toolbar?.items else { return super.minSize }
        guard let index = items.firstIndex(of: self) else { return super.minSize }
        guard let thisFrame = view?.superview?.frame else { return super.minSize }

        if thisFrame.origin.x > 0 {
            var space: CGFloat = 0
            if items.count > index + 1 {
                let nextItem = items[index + 1]
                guard let nextFrame = nextItem.view?.superview?.frame else { return super.minSize }
                guard let toolbarFrame = nextItem.view?.superview?.superview?.frame else { return super.minSize }

                space = (toolbarFrame.size.width - nextFrame.size.width) / 2 - thisFrame.origin.x - 3
                if space < 0 { space = 0 }
            }

            let size = super.minSize
            return NSSize(width: space, height: size.height)
        }

        return super.minSize
    }

    var calculatedMaxSize: NSSize {
        let size = super.maxSize
        return NSSize(width: minSize.width, height: size.height)
    }

    // MARK: -
    // MARK: Initialization

    convenience init() {
        self.init(itemIdentifier: .adaptiveSpace)
    }

    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier)
        self.view = AdaptiveSpaceItemView(spaceItem: self)
    }

    // MARK: -
    // MARK: Public Methods

    public func updateWidth() {
        self.minSize = self.calculatedMinSize
        self.maxSize = self.calculatedMaxSize
    }
}

class AdaptiveSpaceItemView: NSView {

    // MARK: -
    // MARK: Variables

    let adaptiveSpaceItem: AdaptiveSpaceItem

    // MARK: -
    // MARK: Initialization

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(spaceItem: AdaptiveSpaceItem) {
        self.adaptiveSpaceItem = spaceItem
        super.init(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    }

    // MARK: -
    // MARK: De-Initialization

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: -
    // MARK: NSView Methods

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSWindow.didResizeNotification, object: self.window)
        adaptiveSpaceItem.updateWidth()
    }

    // MARK: -
    // MARK: Notification Observer Methods

    @objc func windowDidResize() {
        adaptiveSpaceItem.updateWidth()
    }

}
