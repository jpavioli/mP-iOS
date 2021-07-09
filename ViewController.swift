import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport
import mParticle_Apple_SDK
import UserNotifications
import WebKit

class ViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet weak var variantIdValue: UITextField!
    @IBOutlet weak var includeEmailValue: UISwitch!
    @IBOutlet weak var includeCustomerIdValue: UISwitch!
    @IBOutlet weak var variantNumberValue: UIStepper!
    @IBOutlet weak var productActionSelector: UIPickerView!
    
    @IBOutlet weak var mpidDisplay: UILabel!
    @IBOutlet weak var customerIdDisplay: UILabel!
    @IBOutlet weak var emailDisplay: UILabel!
    @IBOutlet weak var idfaDisplay: UILabel!
    @IBOutlet weak var idfvDisplay: UILabel!
    @IBOutlet weak var ATTstatusDisplay: UILabel!
    @IBOutlet weak var ccpaConsentDisplay: UILabel!
    
    var variantNumber = 0
    var pickerData = [
        "Add to cart",
        "Remove from cart",
        "Checkout",
        "Checkout option",
        "Click",
        "View Detail",
        "Purchase",
        "Refund",
        "Add to wishlist",
        "Remove from wishlist"
    ]
    var productAction = "Add to cart"
    
    func updateIdentifiers(){
        let user =  MParticle.sharedInstance().identity.currentUser
        if (user != nil){
            mpidDisplay.text =  "\(user!.userId)"
            customerIdDisplay.text =  user?.identities[1]
            emailDisplay.text =  user?.identities[7]
            idfvDisplay.text = UIDevice.current.identifierForVendor!.uuidString
            idfaDisplay.text = user?.identities[22]
            ccpaConsentDisplay.text = user?.consentState()?.ccpaConsentState()?.consented.description
            switch (ATTrackingManager.trackingAuthorizationStatus.rawValue){
                case (0): ATTstatusDisplay.text = "Not Determined"; break
                case (1): ATTstatusDisplay.text = "Restricted"; break
                case (2): ATTstatusDisplay.text = "Denied"; break
                case (3):
                    ATTstatusDisplay.text = "Authorized";
                    idfaDisplay.text = ASIdentifierManager.shared().advertisingIdentifier.uuidString;
                break
                default: ATTstatusDisplay.text = "???"; break
            }
        }
        return
    }
    
    let identityCallback = {(result: MPIdentityApiResult?, error: Error?) in
        if (result?.user != nil) {
            //IDSync request succeeded, mutate attributes or query for the MPID as needed
            result?.user.setUserAttribute("Callback", value: "Value")
            var check = result?.user.identities[1]
        } else {
            NSLog(error!.localizedDescription)
            let resultCode = MPIdentityErrorResponseCode(rawValue: UInt((error! as NSError).code))
            switch (resultCode!) {
            case .clientNoConnection,
                 .clientSideTimeout:
                //retry the IDSync request
                break;
            case .requestInProgress,
                 .retry:
                //inspect your implementation if this occurs frequency
                //otherwise retry the IDSync request
                break;
            default:
                // inspect error.localizedDescription to determine why the request failed
                // this typically means an implementation issue
                break;
            }
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        let customerId = variantIdValue.text! + "-TestUser-\(variantNumber)"
        let email =  variantIdValue.text! + "-Test-\(variantNumber)@gmail.com"
        let identityRequest = MPIdentityApiRequest.withEmptyUser()

        if (includeEmailValue.isOn) {identityRequest.customerId = customerId}
        if (includeCustomerIdValue.isOn) {identityRequest.email = email}
        MParticle.sharedInstance().identity.login(identityRequest, completion: identityCallback)
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        let identityRequest = MPIdentityApiRequest.withEmptyUser()
        MParticle.sharedInstance().identity.logout(identityRequest, completion: identityCallback)
    }

    @IBAction func logEventAction(_ sender: Any) {
        let event = MPEvent(name: "Button Clicked", type: MPEventType.other)
        event?.customAttributes = [
            "text": "Text Custom Attribute",
            "integer": 123,
            "double":12.345,
            "boolean":true
        ]
        event?.addCustomFlag("app", withKey: "Facebook.ActionSource")
        event?.addCustomFlag("iOS", withKey: "Google.Category")
        if (event != nil) {
            MParticle.sharedInstance().logEvent(event!)
        }
    }
    
    @IBAction func logCustomNavigationEventAction(_ sender: Any) {
        let event = MPEvent(name: "Custom Screen View", type: MPEventType.navigation)
        event?.customAttributes = [
            "text": "Text Custom Attribute",
            "integer": 123,
            "double":12.345,
            "boolean":true
        ]
        event?.addCustomFlag("app", withKey: "Facebook.ActionSource")
        event?.addCustomFlag("iOS", withKey: "Google.Category")
        if (event != nil) {
            MParticle.sharedInstance().logEvent(event!)
        }
    }
    
    @IBAction func logScreenViewEvent(_ sender: Any) {
        //This is specifically for the native Screen View event
        let screenInfo = [
            "text":"Text Screen View",
            "boolean":"true" //only text strings allowed
        ];
        MParticle.sharedInstance().logScreen("Viewed Screen", eventInfo: screenInfo)
    }
    
    @IBAction func addCcpaConsentAction(_ sender: Any) {
        let user =  MParticle.sharedInstance().identity.currentUser
        let ccpaConsent = MPCCPAConsent.init()
        ccpaConsent.consented = true; // true represents a "data sale opt-out", false represents the user declining a "data sale opt-out"
        ccpaConsent.timestamp = Date.init()
        let consentState = MPConsentState.init()
        consentState.setCCPA(ccpaConsent)
        user?.setConsentState(consentState)
    }
    
    @IBAction func removeCcpaConsentAction(_ sender: Any) {
        let user =  MParticle.sharedInstance().identity.currentUser
        if let consentState = user?.consentState() {
            consentState.removeCCPAConsentState()
            user?.setConsentState(consentState)
        }
    }
    
    @IBAction func logProductActionAction(_ sender: Any) {
        let product = MPProduct.init(name: "Pants",
                                    sku: "Pants-9000",
                                    quantity: 1,
                                    price: 24.99)
        product.brand = "Levi"
        product.variant = "Blue"
        product.category = "Jeans"
        product.couponCode = "I GOT THE PANTS"
        product.position = 1

        // 2. Summarize the transaction
        let attributes = MPTransactionAttributes.init()
        attributes.transactionId = "foo-transaction-id"
        attributes.revenue = 430.00
        attributes.tax = 30.00
        attributes.couponCode = "TRANSACTION CODE"
        attributes.shipping = 12.99
        
        var action = MPCommerceEventAction.purchase
        switch (productAction){
        case("Add to cart"): action = MPCommerceEventAction.addToCart; break
        case("Remove from cart"): action = MPCommerceEventAction.removeFromCart; break
        case("Checkout"): action = MPCommerceEventAction.checkout; break
        case("Checkout option"): action = MPCommerceEventAction.checkoutOptions; break
        case("Click"): action = MPCommerceEventAction.click; break
        case("Purchase"): action = MPCommerceEventAction.purchase; break
        case("Refund"): action = MPCommerceEventAction.refund; break
        case("Add to wishlist"): action = MPCommerceEventAction.addToWishList; break
        case("Remove to wishlist"): action = MPCommerceEventAction.removeFromWishlist; break
        default:
            action = MPCommerceEventAction.purchase; break
        }
        let event = MPCommerceEvent.init(action: action, product: product)
        event.transactionAttributes = attributes
        MParticle.sharedInstance().logEvent(event)
    }
    
    
    @IBAction func variantNumberUpdated(_ sender: UIStepper) {
        variantNumber = Int(sender.value)
    }
    
    @IBAction func refreshUser(_ sender: Any) {
        updateIdentifiers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        productAction = pickerData[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        variantNumberValue.wraps = true
        variantNumberValue.autorepeat = true
        variantNumberValue.maximumValue = 10
        
        self.productActionSelector.delegate = self
        self.productActionSelector.dataSource = self
        
        updateIdentifiers()
    }

}
