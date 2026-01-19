//
//  RawProxyResponseController.swift
//  IntegrationTester
//
//  Created by kevin on 23/5/23.
//

import Foundation
import UIKit
import BasisTheoryElements

class RawProxyResponseController: UIViewController {
    @IBOutlet weak var textField: TextElementUITextField!
    @IBOutlet weak var result: UITextView!
    @IBOutlet weak var error: UITextView!
    
    @IBAction func proxy(_ sender: Any) {
        BasisTheoryElements.basePath = "https://api.basistheory.com"
        
        let prodBtApiKey = Configuration.getConfiguration().prodBtApiKey!
        BasisTheoryElements.createSession(apiKey: prodBtApiKey) { data, error in
            if(error != nil) {
                print(error!)
                self.error.text = error?.localizedDescription
            }
            
            if(data != nil) {
                let sessionApiKey = data!.sessionKey!
                let nonce = data!.nonce!
                
                // AUTHORIZING A SESSION SHOULD HAPPEN ON THE BACKEND
                let privateProdBtApiKey = Configuration.getConfiguration().privateProdBtApiKey!
                BasisTheoryElements.authorizeSession(nonce: nonce, permissions: ["token:read", "token:use"], apiKey: privateProdBtApiKey) { data, error in
                    if(error != nil) {
                        print(error!)
                        self.error.text = error?.localizedDescription
                    }
                    
                    if(data != nil) {
                        let proxyKey = Configuration.getConfiguration().proxyKey
                        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: ["text": "test"])
                        BasisTheoryElements.proxy(
                            apiKey: sessionApiKey,
                            proxyKey: proxyKey,
                            proxyHttpRequest: proxyHttpRequest)
                        { response, data, error in
                            DispatchQueue.main.async {
                                if let data = data! as JSON? {
                                    print(data)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
