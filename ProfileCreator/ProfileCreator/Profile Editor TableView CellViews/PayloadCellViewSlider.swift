//
//  PayloadCellViewDatePicker.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewSliderViewController: NSViewController {

    // MARK: -
    // MARK: Variables
    weak var cellView: PayloadCellViewSlider?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: PayloadCellViewSlider) {
        super.init(nibName: nil, bundle: nil)
        self.view = EditorSlider.slider(cellView: cellView)
        self.cellView = cellView
    }

    override func viewWillAppear() {
        self.cellView?.updateTickMarkConstraints()
        self.cellView?.setupSliderTickMarkTitles()
    }
}

class PayloadCellViewSlider: PayloadCellView, ProfileCreatorCellView, SliderCellView {

    // MARK: -
    // MARK: Instance Variables

    var slider: NSSlider?
    var sliderViewController: NSViewController?

    var tickMarkTextFields = [NSTextField]()
    var tickMarkConstraints = [NSLayoutConstraint]()
    var tickMarkConstraintsApplied = false

    var valueDefault: Double?
    @objc private var value: Any?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.sliderViewController = PayloadCellViewSliderViewController(cellView: self)
        let slider = self.sliderViewController?.view as? NSSlider ?? NSSlider()
        self.slider = slider
        self.setupSlider()
        self.setupSliderTickMarkTextFields()

        // Last textField add height to frame
        self.height += 3 + (tickMarkTextFields.first?.intrinsicContentSize.height ?? 0)

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.tickMarkTextFields.first)

        // ---------------------------------------------------------------------
        //  Get Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue() as? Double {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        var currentValue: Any
        if let value = profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? Double {
            currentValue = value
        } else if let valueDefault = self.valueDefault {
            currentValue = valueDefault
        } else if let valueMin = subkey.rangeMin as? Double {
            currentValue = valueMin
        } else {
            currentValue = slider.minValue
        }

        if let index = subkey.rangeList?.index(ofValue: currentValue, ofType: subkey.type) {
            slider.doubleValue = slider.tickMarkValue(at: index)
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.slider
        self.trailingKeyView = self.slider

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    func updateTickMarkConstraints() {
        guard !self.tickMarkConstraintsApplied, let slider = self.slider else { return }

        for (index, constraint) in self.tickMarkConstraints.enumerated() {
            if index == 0 || index == (self.tickMarkConstraints.count - 1) { continue }
            constraint.constant = slider.rectOfTickMark(at: index).midX
        }

        self.tickMarkConstraintsApplied = true
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.slider?.isEnabled = enable
    }

    // MARK: -
    // MARK: SliderCellView Functions

    func selected(_ slider: NSSlider) {
        var value: NSNumber = 0
        if let rangeList = self.subkey.rangeList {
            if let sliderCell = slider.cell as? NSSliderCell {
                let knobPoint = CGPoint(x: sliderCell.knobRect(flipped: false).midX, y: slider.rectOfTickMark(at: 0).origin.y)
                let index = slider.indexOfTickMark(at: knobPoint)
                if index < rangeList.count, let tickMarkValue = rangeList[index] as? NSNumber {
                    value = tickMarkValue
                }
            }
        } else {
            value = NSNumber(value: slider.doubleValue)
        }

        self.profile.settings.setValue(value, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewSlider {

    private func setupSlider() {

        // ---------------------------------------------------------------------
        //  Get Slider
        // ---------------------------------------------------------------------
        guard let slider = self.slider else { return }

        slider.allowsTickMarkValuesOnly = (self.subkey.rangeList != nil)

        // ---------------------------------------------------------------------
        //  Add Slider to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(slider)

        if let rangeMax = self.subkey.rangeList?.last as? NSNumber {
            slider.maxValue = rangeMax.doubleValue
        } else if let rangeMax = self.subkey.rangeMax as? NSNumber {
            slider.maxValue = rangeMax.doubleValue
        } else {
            slider.maxValue = Double(Int.max)
        }

        if let rangeMin = self.subkey.rangeList?.first as? NSNumber, rangeMin.doubleValue < slider.maxValue {
            slider.minValue = rangeMin.doubleValue
        } else if let rangeMin = self.subkey.rangeMin as? NSNumber, rangeMin.doubleValue < slider.maxValue {
            slider.minValue = rangeMin.doubleValue
        } else {
            slider.minValue = 0.0
        }

        if let rangeList = self.subkey.rangeList {
            slider.numberOfTickMarks = rangeList.count
        } else {
            slider.numberOfTickMarks = 2
        }

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: slider)

        // Leading
        self.addConstraints(forViewLeading: slider)

        // Trailing
        self.addConstraints(forViewTrailing: slider)
    }

    private func setupSliderTickMarkTextFields() {

        // ---------------------------------------------------------------------
        //  Get Slider
        // ---------------------------------------------------------------------
        guard let slider = self.slider else { return }

        for index in 0...(slider.numberOfTickMarks - 1) {
            let textFieldTickMark = EditorTextField.label(string: "", fontWeight: .regular, cellView: self)
            self.setupTextFieldTickMark(textFieldTickMark, first: index == 0, last: index == (slider.numberOfTickMarks - 1))
        }
    }

    func setupSliderTickMarkTitles() {

        // ---------------------------------------------------------------------
        //  Get Slider
        // ---------------------------------------------------------------------
        guard let slider = self.slider else { return }

        let sliderWidth = slider.frame.width

        if let rangeListTitles = self.subkey.rangeListTitles {
            self.setupSliderTickMarkTitles(rangeListTitles: rangeListTitles, sliderWidth: sliderWidth)
        } else if let rangeList = self.subkey.rangeList {
            // let rangeListTitles = rangeList.map({ String(describing: $0) })
            self.setupSliderTickMarkTitles(rangeList: rangeList, sliderWidth: sliderWidth)
            // self.setupSliderTickMarkTitles(rangeListTitles: rangeListTitles, sliderWidth: sliderWidth)
        }
    }

    func setupSliderTickMarkTitles(rangeList: [Any], sliderWidth: CGFloat) {

        // ---------------------------------------------------------------------
        //  Get Slider
        // ---------------------------------------------------------------------
        guard let slider = self.slider else { return }

        var combinedTextFieldWidth: CGFloat = 0.0

        for (index, textField) in self.tickMarkTextFields.enumerated() {

            var title: String
            if index < rangeList.count, let value = rangeList[index] as? NSNumber {
                title = String(value.doubleValue)
            } else {
                title = String(slider.tickMarkValue(at: index))
            }

            textField.stringValue = title

            combinedTextFieldWidth += textField.intrinsicContentSize.width
        }
    }

    func setupSliderTickMarkTitles(rangeListTitles titles: [String], sliderWidth: CGFloat) {

        // FIXME: This while thing could be made much more efficient, and also should be saved in the subkey to not have to recalculate the same info all the time.

        var titlesWidth: CGFloat = 1_000.0
        var titlesToSkip = -1

        while sliderWidth < titlesWidth {
            var combinedTextFieldWidth: CGFloat = 0.0
            titlesToSkip += 1
            var titlesSkipped = 0
            var previousTextField = NSTextField()
            var previousTextFieldFrame = CGRect()
            var titlesOverlapped = false

            for (index, textField) in self.tickMarkTextFields.enumerated() {
                if index == 0 || index == (self.tickMarkTextFields.count - 1) || titlesToSkip == titlesSkipped {
                    if index < titles.count {
                        textField.stringValue = titles[index]
                        previousTextFieldFrame = previousTextField.frame
                        previousTextField = textField
                    }
                    titlesSkipped = 0
                } else {
                    textField.stringValue = ""
                    titlesSkipped += 1
                }

                combinedTextFieldWidth += textField.intrinsicContentSize.width
                self.layoutSubtreeIfNeeded()

                if textField.frame.intersects(previousTextFieldFrame) {
                    titlesOverlapped = true
                    break
                }

            }

            if !titlesOverlapped {
                titlesWidth = combinedTextFieldWidth
            }

            // FIXME: Need to only keep first and last if there is no more room, even if they touch.

            if (self.tickMarkTextFields.count - 2) <= titlesToSkip {
                break
            }
        }
    }

    private func setupTextFieldTickMark(_ textField: NSTextField, first: Bool = false, last: Bool = false) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textField)
        self.tickMarkTextFields.append(textField)

        textField.alignment = .center

        // Below
        self.cellViewConstraints.append(NSLayoutConstraint(item: textField,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: slider,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: 3.0))

        if first {
            // Leading
            let constraintLeading = NSLayoutConstraint(item: textField,
                                                       attribute: .leading,
                                                       relatedBy: .equal,
                                                       toItem: slider,
                                                       attribute: .leading,
                                                       multiplier: 1.0,
                                                       constant: 0.0)
            self.cellViewConstraints.append(constraintLeading)
            self.tickMarkConstraints.append(constraintLeading)
        } else if last {
            // Trailing
            let constraintTrailing = NSLayoutConstraint(item: textField,
                                                        attribute: .trailing,
                                                        relatedBy: .equal,
                                                        toItem: slider,
                                                        attribute: .trailing,
                                                        multiplier: 1.0,
                                                        constant: 0.0)
            self.cellViewConstraints.append(constraintTrailing)
            self.tickMarkConstraints.append(constraintTrailing)
        } else {
            // Center
            let constraintCenter = NSLayoutConstraint(item: textField,
                                                      attribute: .centerX,
                                                      relatedBy: .equal,
                                                      toItem: slider,
                                                      attribute: .leading,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

            self.cellViewConstraints.append(constraintCenter)
            self.tickMarkConstraints.append(constraintCenter)
        }
    }
/*
    private func setupTextFieldInput() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldInput = self.textFieldInput, let slider = self.slider else { return }

        self.addSubview(textFieldInput)

        // ---------------------------------------------------------------------
        //  Add Number Formatter to TextField
        // ---------------------------------------------------------------------
        let numberFormatter = NumberFormatter()

        if self.subkey.type == .float {
            numberFormatter.allowsFloats = true
            numberFormatter.alwaysShowsDecimalSeparator = true
            numberFormatter.numberStyle = .decimal
        } else {
            numberFormatter.numberStyle = .none
        }

        if let rangeMax = self.subkey.rangeMax as? NSNumber {
            numberFormatter.maximum = rangeMax
        } else {
            numberFormatter.maximum = Int.max as NSNumber
        }

        if let rangeMin = self.subkey.rangeMin as? NSNumber {
            numberFormatter.minimum = rangeMin
        } else {
            numberFormatter.minimum = Int.min as NSNumber
        }

        if let decimalPlaces = self.subkey.valueDecimalPlaces {
            numberFormatter.maximumFractionDigits = decimalPlaces
            numberFormatter.minimumFractionDigits = decimalPlaces
        } else {
            numberFormatter.maximumFractionDigits = 16 // This is the default in plist <real> tags. which is a double.
        }

        textFieldInput.formatter = numberFormatter
        textFieldInput.bind(.value, to: self, withKeyPath: "value", options: [NSBindingOption.nullPlaceholder: "", NSBindingOption.continuouslyUpdatesValue: true])
        textFieldInput.isBordered = false

        // ---------------------------------------------------------------------
        //  Get TextField Number Maximum Width
        // ---------------------------------------------------------------------
        var valueMaxWidth: CGFloat = 0
        if let valueMax = numberFormatter.maximum {
            textFieldInput.stringValue = NSNumber(value: (valueMax.doubleValue - 0.000_000_000_000_001)).stringValue
        } else if let valueMin = numberFormatter.minimum {
            textFieldInput.stringValue = NSNumber(value: (valueMin.doubleValue + 0.000_000_000_000_001)).stringValue
        }
        textFieldInput.sizeToFit()
        valueMaxWidth = textFieldInput.frame.width + 2.0
        textFieldInput.stringValue = ""

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldInput,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: slider,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 4.0))

        // Baseline
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldInput,
                                                           attribute: .firstBaseline,
                                                           relatedBy: .equal,
                                                           toItem: slider,
                                                           attribute: .firstBaseline,
                                                           multiplier: 1.0,
                                                           constant: 0.0))

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldInput,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: valueMaxWidth))

        self.addConstraints(forViewTrailing: textFieldInput)

    }
 */
}
