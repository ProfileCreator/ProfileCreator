//
//  OverlayScrollView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class OverlayScrollView: NSScrollView {

    // MARK: -
    // MARK: Variables

    lazy var headerOffset: CGFloat = {
        self.tableHeaderOffsetFromSuperview()
    }()

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
        self.wantsLayer = true
    }

    // MARK: -
    // MARK: Custom Methods

    func tableHeaderOffsetFromSuperview() -> CGFloat {
        for subview in self.subviews where subview is NSClipView {
            for clipViewSubview in subview.subviews {
                if
                    let tableView = clipViewSubview as? NSTableView,
                    let headerView = tableView.headerView {
                    return headerView.frame.size.height
                }
            }
        }
        return 0.0
    }

    // MARK: -
    // MARK: NSScrollView Method Overrides

    override func tile() {

        guard let methodScrollerWidth = class_getClassMethod(OverlayScroller.self, #selector(OverlayScroller.scrollerWidth(for:scrollerStyle:))) else { return }
        guard let methodZeroWidth = class_getClassMethod(OverlayScroller.self, #selector(OverlayScroller.zeroWidth)) else { return }

        // Fake zero scroller width so the contentView gets drawn to the edge
        method_exchangeImplementations(methodScrollerWidth, methodZeroWidth)
        super.tile()

        // Restore original scroller width
        method_exchangeImplementations(methodZeroWidth, methodScrollerWidth)

        // Resize vertical scroller
        if let verticalScroller = self.verticalScroller {
            let width = OverlayScroller.scrollerWidth(for: verticalScroller.controlSize,
                                                      scrollerStyle: verticalScroller.scrollerStyle)
            verticalScroller.frame = NSRect(x: self.bounds.size.width - width,
                                            y: self.headerOffset,
                                            width: width,
                                            height: self.bounds.size.height - self.headerOffset)
        }

        // Move scroller to front
        self.sortSubviews({ view1, view2, context -> ComparisonResult in
            if view1 is OverlayScroller {
                return .orderedDescending
            } else if view2 is OverlayScroller {
                return .orderedAscending
            }
            return .orderedSame
        }, context: nil)
    }
}
