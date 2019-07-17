//
//  PayloadCellViewItemTextView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorTextView {

    class func scrollView(string: String?,
                          visibleRows: Int,
                          constraints: inout [NSLayoutConstraint],
                          cellView: PayloadCellView & NSTextViewDelegate) -> OverlayScrollView {

        let scrollView = OverlayScrollView(frame: NSRect.zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.verticalScroller = OverlayScroller()
        scrollView.borderType = .bezelBorder

        let textView = PayloadTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textView.textColor = .labelColor
        textView.delegate = cellView
        textView.string = string ?? ""

        // Use old resizing masks until I know how to replicate with AutoLayout.
        textView.autoresizingMask = .width

        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.heightTracksTextView = false

        // Add TextView to ScrollView
        scrollView.documentView = textView

        cellView.addSubview(scrollView)

        let heightMultiplier: Int
        if visibleRows < 2 {
            heightMultiplier = 2
        } else {
            heightMultiplier = visibleRows
        }

        let scrollViewHeight = CGFloat(20 + (17 * (heightMultiplier - 1)))
        cellView.updateHeight(scrollViewHeight)

        // Height
        constraints.append(NSLayoutConstraint(item: scrollView,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: scrollViewHeight))

        return scrollView
    }
}
