//
//  CardBrandSelectorUIButton.swift
//  BasisTheoryElements
//
//  Created by Basis Theory on 11/10/25.
//

import UIKit
import Combine

public struct CardBrandSelectorOptions {
    let cardNumberUITextField: CardNumberUITextField?
    
    public init(cardNumberUITextField: CardNumberUITextField? = nil) {
        self.cardNumberUITextField = cardNumberUITextField
    }
}

final public class CardBrandSelectorUIButton: UIButton {
    private var cardNumberUITextField: CardNumberUITextField?
    private var cancellables = Set<AnyCancellable>()
    internal var availableBrands: [String] = []
    internal var selectedBrand: String?
    private var brandSelectionAction: ((String) -> Void)?
    private var defaultTitle: String?
    
    // Combine publisher for events
    public let subject = PassthroughSubject<ElementEvent, Never>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        self.setupButton()
    }
    
    public var selectedCardBrand: String? {
        return selectedBrand
    }
    
    public var availableCardBrands: [String] {
        return availableBrands
    }
    
    public var brandOptionsCount: Int {
        return availableBrands.count
    }
    
    public func setConfig(options: CardBrandSelectorOptions) {
        if (options.cardNumberUITextField != nil) {
            self.cardNumberUITextField = options.cardNumberUITextField
        }
    }
    
    @objc private func brandOptionsUpdated(_ notification: Notification) {
        if let brandOptions = notification.object as? [String] {
            updateAvailableBrandsFromBrandOptions(brandOptions)
        }
    }
    
    private func setupButton() {
        self.defaultTitle = self.configuration?.title
        self.isHidden = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(brandOptionsUpdated(_:)),
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: nil
        )
    }

    private func getDisplayName(for brandKey: String) -> String {
        return brandKey.uppercased().replacingOccurrences(of: "-", with: " ")
    }

    private func updateBrandSelectionMenu() {
        guard availableBrands.count > 1 else {
            self.isHidden = true
            self.menu = nil
            return
        }

        self.isHidden = false

        var menuActions: [UIAction] = []

        for brandKey in availableBrands {
            let displayName = getDisplayName(for: brandKey)
            let action = UIAction(title: displayName) { _ in
                self.setSelectedBrand(brandKey)
            }

            if let selectedBrand = selectedBrand, selectedBrand == brandKey {
                action.state = .on
            }

            menuActions.append(action)
        }

        let brandMenu = UIMenu(title: "Select Card Brand", children: menuActions)
        self.menu = brandMenu
    }

    private func updateAvailableBrandsFromBrandOptions(_ brandOptions: [String]) {
        self.availableBrands = brandOptions

        if brandOptions.isEmpty {
            self.isHidden = true
            self.setTitle(self.defaultTitle, for: .normal)
        } else {
            self.isHidden = false
        }

        updateBrandSelectionMenu()
    }
    
    internal func setSelectedBrand(_ brandKey: String) {
        selectedBrand = brandKey
        let displayName = getDisplayName(for: brandKey)
        self.setTitle(displayName, for: .normal)

        updateBrandSelectionMenu()

        sendBrandSelectionEvent()
        brandSelectionAction?(brandKey)
    }
    
    public func onBrandSelection(_ action: @escaping (String) -> Void) {
        self.brandSelectionAction = action
    }

    private func sendBrandSelectionEvent() {
        guard let selectedBrand = selectedBrand else { return }

        NotificationCenter.default.post(
            name: NSNotification.Name("CardBrandSelected"),
            object: selectedBrand
        )
    }
}
