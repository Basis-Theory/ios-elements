//
//  TextElementUITextField.swift
//  
//
//  Created by Brian Gonzalez on 10/26/22.
//

import Foundation
import UIKit
import Combine

public struct TextElementOptions {
    let mask: [Any]?
    let transform: ElementTransform?
    
    public init(mask: [Any]? = nil, transform: ElementTransform? = nil) {
        self.mask = mask
        self.transform = transform
    }
}

public class TextElementUITextField: UITextField, InternalElementProtocol, ElementProtocol {
    var validation: ((String?) -> Bool)?
    var backspacePressed: Bool = false
    var inputMask: [Any]?
    var inputTransform: ElementTransform?
    
    public var subject = PassthroughSubject<ElementEvent, Error>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.smartDashesType = .no
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        subject.send(ElementEvent(type: "ready", complete: true, empty: true, invalid: false))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.smartDashesType = .no
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        subject.send(ElementEvent(type: "ready", complete: true, empty: true, invalid: false))
    }
    
    deinit {
        subject.send(completion: .finished)
    }
    
    public override var text: String? {
        set {
            if inputMask != nil {
                super.text = conformToMask(text: newValue)
            } else {
                super.text = newValue
            }
        }
        get { nil }
    }
    
    // detecting backspace, used for masking
    override public func deleteBackward() {
        self.backspacePressed = true
        super.deleteBackward()
    }
    
    public func setConfig(options: TextElementOptions?) throws {
        if (options?.mask != nil) {
            guard validateMask(inputMask: (options?.mask)!) else {
                throw ElementConfigError.invalidMask
            }
            
            self.inputMask = options?.mask
        }
        
        if (options?.transform != nil) {
            self.inputTransform = options?.transform
        }
    }
    
    func transform(text: String) -> String {
        let transformedText = inputTransform?.matcher?.stringByReplacingMatches(in: text, options: .reportCompletion, range: NSRange(location: 0, length: text.count), withTemplate: (inputTransform?.stringReplacement)!)
        return transformedText
    }
    
    private func validateMask(inputMask: [(Any)]) -> Bool {
        for maskValue in inputMask {
            guard (maskValue is String && (maskValue as! String).count == 1) || maskValue is NSRegularExpression else {
                return false
            }
        }
        
        return true
    }
    
    private func conformToMask(text: String?) -> String {
        var userInput = text ?? ""
        let placeholderChar = "_"
        var placeholderString = ""
        var maskedText = ""
        
        // create placeholder string
        for maskValue in inputMask! as [(Any)] {
            if maskValue is NSRegularExpression {
                placeholderString.append(placeholderChar)
            } else if maskValue is String {
                placeholderString.append(maskValue as! String)
            }
        }
        
        var maskIndex = 0
        
        // run through placeholder string, replace gaps w/ user input
        for char in placeholderString {
            if (userInput.count > 0) {
                if String(char) == placeholderChar {
                    // start going through user input to fill array
                    var validChar = ""
                    
                    while (userInput.count > 0) {
                        let firstChar = userInput.removeFirst()
                        
                        // check for placeholder char in mask
                        if (inputMask![maskIndex] is String) {
                            maskedText.append(inputMask![maskIndex] as! String)
                            break
                        } else {
                            
                            // regex matches, is valid, we can add
                            let regex = inputMask![maskIndex] as! NSRegularExpression
                            if String(firstChar).range(of: regex.pattern, options: .regularExpression) != nil {
                                validChar = String(firstChar)
                                break // move to next placeholder position
                            }}
                    }
                    
                    maskedText.append(validChar)
                } else {
                    // just add the char as its the string part of the mask
                    maskedText.append(String(char))
                }
            }
            maskIndex += 1
        }
        
        return maskedText
    }
    
    @objc private func textFieldDidChange() {
        var maskComplete = true
        
        if inputMask != nil {
            let previousValue = super.text
            
            // dont conform on backspace pressed - just remove the value + check for backspace on empty
            if (!backspacePressed || super.text != nil) {
                super.text = conformToMask(text: super.text)
            } else {
                backspacePressed = false
            }
            
            if (super.text?.count != inputMask!.count ) {
                maskComplete = false
            }
            
            guard previousValue == super.text else {
                return
            }
        }
        
        let currentTextValue = super.text
        var invalid = false
        
        if let validation = validation {
            invalid = !validation(currentTextValue)
        }
        
        let complete = !invalid && maskComplete
        
        subject.send(ElementEvent(type: "textChange", complete: complete, empty: currentTextValue?.isEmpty ?? true, invalid: invalid))
    }
    
    func getValue() -> String? {
        if (inputTransform) != nil {
            return transform(text: super.text ?? "")
        } else {
            return super.text
        }
    }
}
