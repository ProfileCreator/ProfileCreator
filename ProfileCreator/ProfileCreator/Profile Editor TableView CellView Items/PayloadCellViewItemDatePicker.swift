//
//  PayloadCellViewItemDatePicker.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorDatePicker {

    class func picker(offsetDays: Int,
                      offsetHours: Int,
                      offsetMinutes: Int,
                      showDate: Bool,
                      showTime: Bool,
                      cellView: PayloadCellView & DatePickerCellView) -> NSDatePicker {

        // ---------------------------------------------------------------------
        //  Create and setup Checkbox
        // ---------------------------------------------------------------------
        let datePicker = NSDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerMode = .single
        datePicker.target = cellView
        datePicker.action = #selector(cellView.selectDate(_:))
        datePicker.dateValue = Date()

        // ---------------------------------------------------------------------
        //  Check if pfm_date_allow_past was set
        // ---------------------------------------------------------------------
        if !cellView.subkey.dateAllowPast {
            var offsetComponents = DateComponents()
            offsetComponents.day = offsetDays
            offsetComponents.hour = offsetHours
            offsetComponents.minute = offsetMinutes
            let offsetDate = Calendar.current.date(byAdding: offsetComponents, to: datePicker.dateValue)
            datePicker.minDate = offsetDate
        }

        let elements: NSDatePicker.ElementFlags

        if !showDate && !showTime {
            elements = .yearMonthDay
        } else if showDate {
            if showTime {
                elements = [.yearMonthDay, .hourMinute]
            } else {
                elements = .yearMonthDay
            }
        } else {
            elements = .hourMinute
            let midnight = Calendar.current.startOfDay(for: Date())
            datePicker.dateValue = midnight

            if !cellView.subkey.dateAllowPast {
                datePicker.minDate = midnight
            }
        }

        datePicker.datePickerElements = elements

        return datePicker
    }
}
