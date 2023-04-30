//
//  MainWindowOutlineViewItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// MARK: -
// MARK: Protocols
// MARK: -

protocol OutlineViewItem: AnyObject {
    var title: String { get }
    var isEditable: Bool { get }
    var identifier: UUID { get }
}

protocol OutlineViewParentItem: OutlineViewItem {
    var group: SidebarGroup { get }
    var children: [OutlineViewChildItem] { get set }
    var cellView: OutlineViewParentCellView? { get }

    func loadSavedGroups()
}

protocol OutlineViewChildItem: OutlineViewItem, NSTextFieldDelegate {
    var group: SidebarGroup { get }
    var isEditing: Bool { get }
    var icon: NSImage? { get }
    var profileIdentifiers: [UUID] { get }
    var cellView: OutlineViewChildCellView? { get }
    var outlineViewController: MainWindowOutlineViewController { get }

    func addProfiles(withIdentifiers: [UUID])
    func removeProfiles(withIdentifiers: [UUID])
    func removeProfiles(atIndexes: IndexSet, withIdentifiers: [UUID])
    func removeFromDisk() throws
    func writeToDisk(title: String) throws
}

// MARK: -
// MARK: Parent CellView
// MARK: -

class OutlineViewParentCellView: NSTableCellView {

    // MARK: -
    // MARK: Variables

    private weak var parent: OutlineViewParentItem?
    private var buttonAdd: NSButton?
    private var trackingArea: NSTrackingArea?
    private let textFieldTitle = NSTextField()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(parent: OutlineViewParentItem) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.parent = parent
        var constraints = [NSLayoutConstraint]()

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Configure TextField
        // ---------------------------------------------------------------------
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byTruncatingTail
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.isSelectable = false
        self.textFieldTitle.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .medium)
        self.textFieldTitle.textColor = .secondaryLabelColor
        self.textFieldTitle.alignment = .left
        setupTextFieldTitle(constraints: &constraints, parent: parent)

        // ---------------------------------------------------------------------
        //  If parent is editable, create and add button 'Add'
        // ---------------------------------------------------------------------
        if parent.isEditable {
            self.buttonAdd = NSButton()
            self.buttonAdd?.translatesAutoresizingMaskIntoConstraints = false
            self.buttonAdd?.bezelStyle = .inline
            self.buttonAdd?.setButtonType(.momentaryChange)
            self.buttonAdd?.isBordered = false
            self.buttonAdd?.isTransparent = false
            self.buttonAdd?.imagePosition = .imageOnly
            self.buttonAdd?.image = NSImage(named: NSImage.addTemplateName)
            if let buttonCell = self.buttonAdd?.cell as? NSButtonCell {
                buttonCell.highlightsBy = NSCell.StyleMask(rawValue: (NSCell.StyleMask.pushInCellMask.rawValue | NSCell.StyleMask.changeBackgroundCellMask.rawValue))
            }
            self.buttonAdd?.sizeToFit()
            self.buttonAdd?.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
            self.buttonAdd?.target = self
            self.buttonAdd?.action = #selector(addGroup)
            self.buttonAdd?.isHidden = true
            setupButtonAdd(constraints: &constraints, button: self.buttonAdd!)
        }

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: Button Functions

    @objc func addGroup() {
        if let parent = self.parent {
            NotificationCenter.default.post(name: .addGroup, object: self, userInfo: [ NotificationKey.parentTitle: parent.title ])
        }
    }

    // MARK: -
    // MARK: NSResponder Functions

    override func mouseEntered(with event: NSEvent) {
        if let button = self.buttonAdd { button.isHidden = false }
    }

    override func mouseExited(with event: NSEvent) {
        if let button = self.buttonAdd { button.isHidden = true }
    }

    // MARK: -
    // MARK: NSView Methods

    override func viewWillDraw() {
        super.viewWillDraw()
        if let parent = self.parent {
            self.textFieldTitle.stringValue = parent.title.uppercased()
        }
    }

    override func updateTrackingAreas() {

        // ---------------------------------------------------------------------
        //  Remove previous tracking area if it was set
        // ---------------------------------------------------------------------
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        // ---------------------------------------------------------------------
        //  Create a new tracking area
        // ---------------------------------------------------------------------
        let trackingOptions = NSTrackingArea.Options(rawValue: (NSTrackingArea.Options.mouseEnteredAndExited.rawValue | NSTrackingArea.Options.activeAlways.rawValue))
        self.trackingArea = NSTrackingArea(rect: self.bounds, options: trackingOptions, owner: self, userInfo: nil)

        // ---------------------------------------------------------------------
        //  Add the new tracking area to the button
        // ---------------------------------------------------------------------
        self.addTrackingArea(self.trackingArea!)
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    func setupTextFieldTitle(constraints: inout [NSLayoutConstraint], parent: OutlineViewParentItem) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 2))

        if !parent.isEditable {

            // Trailing
            constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 2))
        }
    }

    func setupButtonAdd(constraints: inout [NSLayoutConstraint], button: NSButton) {

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(button)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 4))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: button,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 4))
    }
}

// MARK: -
// MARK: Child CellView
// MARK: -

class OutlineViewChildCellView: NSTableCellView {

    // MARK: -
    // MARK: Variables

    private weak var child: OutlineViewChildItem?
    private let textFieldTitle = NSTextField()
    private let buttonCount = NSButton()
    private let imageViewIcon = NSImageView()
    private var icon: NSImage?
    private var constraintTextFieldToSuperview = NSLayoutConstraint()
    private var constraintTextFieldToButtonCount = NSLayoutConstraint()
    private var constraintIconToTextField = NSLayoutConstraint()
    private var constraintSuperviewToTextField = NSLayoutConstraint()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(child: OutlineViewChildItem) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.child = child
        var constraints = [NSLayoutConstraint]()

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.mainWindowShowProfileCount, options: .new, context: nil)

        // ---------------------------------------------------------------------
        //  Configure TextField
        // ---------------------------------------------------------------------
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byTruncatingTail
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = child.isEditable
        self.textFieldTitle.delegate = child
        self.textFieldTitle.font = NSFont.systemFont(ofSize: 12)
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .left
        self.textFieldTitle.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultLow, for: .horizontal)
        setupTextFieldTitle(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Create and add Button count
        // ---------------------------------------------------------------------
        self.buttonCount.translatesAutoresizingMaskIntoConstraints = false
        self.buttonCount.bezelStyle = .inline
        self.buttonCount.setButtonType(.momentaryPushIn)
        self.buttonCount.isBordered = true
        self.buttonCount.isTransparent = false
        self.buttonCount.title = "0"
        self.buttonCount.font = NSFont.boldSystemFont(ofSize: 12)
        self.buttonCount.sizeToFit()
        if let buttonCell = self.buttonCount.cell as? NSButtonCell {
            buttonCell.highlightsBy = NSCell.StyleMask(rawValue: 0)
        }
        self.buttonCount.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
        self.buttonCount.isHidden = !UserDefaults.standard.bool(forKey: PreferenceKey.mainWindowShowProfileCount)
        setupButtonCount(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Configure Icon ImageView
        // ---------------------------------------------------------------------
        if let icon = child.icon {
            self.icon = child.icon
            self.imageViewIcon.translatesAutoresizingMaskIntoConstraints = false
            self.imageViewIcon.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
            self.imageViewIcon.image = icon
            setupImageViewIcon(constraints: &constraints)
            UserDefaults.standard.addObserver(self, forKeyPath: PreferenceKey.mainWindowShowGroupIcons, options: .new, context: nil)
        }

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Setup Initial Values for showProfileCount and showIcon
        // ---------------------------------------------------------------------
        self.profileCount(show: UserDefaults.standard.bool(forKey: PreferenceKey.mainWindowShowProfileCount))
        if self.icon != nil {
            self.icon(show: UserDefaults.standard.bool(forKey: PreferenceKey.mainWindowShowGroupIcons))
        }
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.mainWindowShowProfileCount, context: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: PreferenceKey.mainWindowShowGroupIcons, context: nil)
    }

    // MARK: -
    // MARK: Key/Value Observing Functions

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == PreferenceKey.mainWindowShowProfileCount {
            if let show = change?[.newKey] as? Bool { profileCount(show: show) }
        } else if keyPath == PreferenceKey.mainWindowShowGroupIcons {
            if let show = change?[.newKey] as? Bool { icon(show: show) }
        }
    }

    // MARK: -
    // MARK: Private Functions

    private func profileCount(show: Bool) {
        if show {
            self.constraintTextFieldToSuperview.isActive = false
            self.constraintTextFieldToButtonCount.isActive = true
        } else {
            self.constraintTextFieldToButtonCount.isActive = false
            self.constraintTextFieldToSuperview.isActive = true
        }
        self.buttonCount.isHidden = !show
    }

    private func icon(show: Bool) {
        if show {
            self.constraintSuperviewToTextField.isActive = false
            self.constraintIconToTextField.isActive = true
        } else {
            self.constraintIconToTextField.isActive = false
            self.constraintSuperviewToTextField.isActive = true
        }
        self.imageViewIcon.isHidden = !show
    }

    // MARK: -
    // MARK: Public Functions
    public func updateView() {
        if let child = self.child {
            self.textFieldTitle.stringValue = child.title
            self.buttonCount.title = String(child.profileIdentifiers.count)
        }
    }

    // MARK: -
    // MARK: NSView Functions

    override func viewWillDraw() {
        if let child = self.child {
            self.textFieldTitle.stringValue = child.title
            self.buttonCount.title = String(child.profileIdentifiers.count)
        }
        super.viewWillDraw()
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        self.constraintSuperviewToTextField = NSLayoutConstraint(item: self.textFieldTitle,
                                                                 attribute: .leading,
                                                                 relatedBy: .equal,
                                                                 toItem: self,
                                                                 attribute: .leading,
                                                                 multiplier: 1,
                                                                 constant: 16)
        constraints.append(self.constraintSuperviewToTextField)

        // Trailing
        self.constraintTextFieldToSuperview = NSLayoutConstraint(item: self,
                                                                 attribute: .trailing,
                                                                 relatedBy: .equal,
                                                                 toItem: self.textFieldTitle,
                                                                 attribute: .trailing,
                                                                 multiplier: 1,
                                                                 constant: 8)
        constraints.append(self.constraintTextFieldToSuperview)
    }

    func setupButtonCount(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonCount)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Width
        constraints.append(NSLayoutConstraint(item: self.buttonCount,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 24))

        // Height
        constraints.append(NSLayoutConstraint(item: self.buttonCount,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 18))

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.buttonCount,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.buttonCount,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 4))

        // Leading
        self.constraintTextFieldToButtonCount = NSLayoutConstraint(item: self.buttonCount,
                                                                   attribute: .leading,
                                                                   relatedBy: .equal,
                                                                   toItem: self.textFieldTitle,
                                                                   attribute: .trailing,
                                                                   multiplier: 1,
                                                                   constant: 6)
        constraints.append(self.constraintTextFieldToButtonCount)
    }

    func setupImageViewIcon(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add icon to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.imageViewIcon)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Width
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 24))

        // Height
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 16))

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.imageViewIcon,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 16))

        // Trailing
        self.constraintIconToTextField = NSLayoutConstraint(item: self.textFieldTitle,
                                                            attribute: .leading,
                                                            relatedBy: .equal,
                                                            toItem: self.imageViewIcon,
                                                            attribute: .trailing,
                                                            multiplier: 1,
                                                            constant: -2)
        constraints.append(self.constraintIconToTextField)
    }
}
