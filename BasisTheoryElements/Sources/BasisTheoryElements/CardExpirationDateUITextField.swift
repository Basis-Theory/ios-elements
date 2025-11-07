//
//  CardExpirationDateUITextField.swift
//
//
//  Created by Lucas Chociay on 11/28/22.
//

import UIKit

final public class CardExpirationDateUITextField: TextElementUITextField {
    override var validation: ((String?) -> Bool)? {
        get {
            validateExpirationDate
        }
        set { }
    }
    
    private func validateExpirationDate(text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        
        // check date is MM/YY -> 5 chars.
        guard text?.count == 5 else {
            return false
        }
        
        return validateFutureDate(text: text!)
    }
    
    public override func setConfig(options: TextElementOptions?) throws {
        if (options?.enableCopy != nil || options?.copyIconColor != nil) {
            try! super.setConfig(options: TextElementOptions(enableCopy: options?.enableCopy, copyIconColor: options?.copyIconColor))
        } else {
            throw ElementConfigError.configNotAllowed
        }
    }
    
    private func validateFutureDate(text: String) -> Bool {
        let inputDateArray = super.getValue()?.components(separatedBy: "/")
        let inputMonth = Int(String(inputDateArray![0]))!
        let inputYear = Int(String("20" + inputDateArray![1]))!
        
        let now = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "YYYY"
        let currentYear = Int(dateFormatter.string(from: now))!
        if inputYear > currentYear {
            return true
        } else if inputYear == currentYear {
            dateFormatter.dateFormat = "MM"
            let currentMonth = Int(dateFormatter.string(from: now))!
            
            return inputMonth >= currentMonth
        } else {
            return false
        }
    }
    
    override var inputMask: [Any]? {
        get {
            let digitRegex = try! NSRegularExpression(pattern: "\\d")
            return [digitRegex, digitRegex, "/", digitRegex, digitRegex]
        }
        set { }
    }
    
    public func month() -> ElementValueReference {
        let monthReference = ElementValueReference(elementId: self.elementId, valueMethod: getMonthValue, isComplete: self.isComplete, getValueType: .int)
        return monthReference
    }
    
    public func year() -> ElementValueReference {
        let yearReference = ElementValueReference(elementId: self.elementId, valueMethod: getYearValue, isComplete: self.isComplete, getValueType: .int)
        return yearReference
    }
    
    public func format(dateFormat: String) -> ElementValueReference {
        let dateReference = ElementValueReference(elementId: self.elementId, valueMethod: getFormattedValue(dateFormat: dateFormat), isComplete: self.isComplete)
        return dateReference
    }
    
    private func getFormattedValue(dateFormat: String) -> (() -> String)? {
        guard let value = super.getValue(),
              let year = Int(getYearValue()),
              let month = Int(getMonthValue()) else {
            return nil
        }

        var components = DateComponents(year: year, month: month)
        let calendar = Calendar.current

        guard let lastDayDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: (calendar.date(from: components)?.addingTimeInterval(86399))!),
              let lastDayOfMonth = calendar.dateComponents([.day], from: lastDayDate).day else {
            return nil
        }


        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let formattedDate = dateFormatter.string(from: lastDayDate)

        return {
            return formattedDate
        }
    }
    
    private func getMonthValue() -> String {
        if (super.getValue() != nil){
            let dateArray = super.getValue()?.components(separatedBy: "/")
            return String(dateArray![0])
        }
        
        return ""
    }
    
    private func getYearValue() -> String {
        if (super.getValue() != nil) {
            let dateArray = super.getValue()?.components(separatedBy: "/")
            return String("20" + dateArray![1])
        }
        
        return ""
    }
    
    public func setValue(month: ElementValueReference?, year: ElementValueReference?) {
        let month = month?.getValue() ?? ""
        let formattedMonth = "00\(month)".suffix(2)
        
        let year = year?.getValue() ?? ""
        let formattedYear = year.suffix(2)
        
        self.text = "\(formattedMonth)/\(formattedYear)"
    }
    
    override func textFieldDidChange(forceEvent: Bool = false) {
        if (super.getValue()!.count > 0) {
            let firstChar = super.getValue()?.first
            
            if (firstChar?.isNumber == true) {
                // check first char, if > 1 add 0 in front
                if (firstChar?.wholeNumberValue!)! > 1  {
                    super.text = "0" + super.getValue()!
                }
                
                // check second char - if first char 1, number cant be > 2
                if (super.getValue()!.count > 1) {
                    let secondChar = super.getValue()?.dropFirst().first
                    if ((firstChar?.wholeNumberValue!)!  == 1 && (secondChar?.isNumber == true && (secondChar?.wholeNumberValue!)! > 2)) {
                        super.text = "1"
                    }
                }
            }
        }
        
        super.textFieldDidChange(forceEvent: forceEvent)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.keyboardType = .asciiCapableNumberPad
        TelemetryLogging.info("CardExpirationDateUITextField init", attributes: [
            "elementId": self.elementId
        ])
    }
}
