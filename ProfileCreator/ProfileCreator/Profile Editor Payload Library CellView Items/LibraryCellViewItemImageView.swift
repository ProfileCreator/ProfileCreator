//
//  LibraryCellViewItemImageVIew.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class LibraryImageView {

    class func icon(image: NSImage?,
                    width: CGFloat,
                    indent: CGFloat,
                    constraints: inout [NSLayoutConstraint],
                    cellView: PayloadLibraryCellView) -> NSImageView {

        // ---------------------------------------------------------------------
        //  Create and setup ImageView
        // ---------------------------------------------------------------------
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)

        if let icon = image {
            imageView.image = icon
        } else if let defaultImage = NSImage(named: "") {
            // FIXME: Add a default icon if missing
            imageView.image = defaultImage
        }

        // ---------------------------------------------------------------------
        //  Add ImageView to cell view
        // ---------------------------------------------------------------------
        cellView.addSubview(imageView)

        // ---------------------------------------------------------------------
        //  Setup Layout Constraings for text field
        // ---------------------------------------------------------------------
        // Width
        constraints.append(NSLayoutConstraint(item: imageView,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: width))

        // Height
        constraints.append(NSLayoutConstraint(item: imageView,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: imageView,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Top
        constraints.append(NSLayoutConstraint(item: imageView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: cellView,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: indent))

        return imageView
    }
}
