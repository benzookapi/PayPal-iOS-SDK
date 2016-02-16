//
//  MainViewController.swift
//  PayPal-iOS-SDK-Sample-App
//
//  Copyright (c) 2015 PayPal. All rights reserved.
//

import UIKit


class MainViewController: UIViewController, PayPalPaymentDelegate, PayPalFuturePaymentDelegate, PayPalProfileSharingDelegate, FlipsideViewControllerDelegate {
  var environment:String = PayPalEnvironmentNoNetwork {
    willSet(newEnvironment) {
      if (newEnvironment != environment) {
        PayPalMobile.preconnectWithEnvironment(newEnvironment)
      }
    }
  }

#if HAS_CARDIO
  var acceptCreditCards: Bool = true {
    didSet {
      payPalConfig.acceptCreditCards = acceptCreditCards
    }
  }
#else
  var acceptCreditCards: Bool = false {
    didSet {
      payPalConfig.acceptCreditCards = acceptCreditCards
    }
  }
#endif

  var resultText = "" // empty
  var payPalConfig = PayPalConfiguration() // default
  
  @IBOutlet weak var successView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    title = "PayPal SDK Demo"
    successView.hidden = true
    
    // Set up payPalConfig
    payPalConfig.acceptCreditCards = acceptCreditCards;
    payPalConfig.merchantName = "BO, Inc."
    payPalConfig.merchantPrivacyPolicyURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
    payPalConfig.merchantUserAgreementURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
    
    // Setting the languageOrLocale property is optional.
    //
    // If you do not set languageOrLocale, then the PayPalPaymentViewController will present
    // its user interface according to the device's current language setting.
    //
    // Setting languageOrLocale to a particular language (e.g., @"es" for Spanish) or
    // locale (e.g., @"es_MX" for Mexican Spanish) forces the PayPalPaymentViewController
    // to use that language/locale.
    //
    // For full details, including a list of available languages and locales, see PayPalPaymentViewController.h.
    
    payPalConfig.languageOrLocale = NSLocale.preferredLanguages()[0] 
    
    // Setting the payPalShippingAddressOption property is optional.
    //
    // See PayPalConfiguration.h for details.
    
    payPalConfig.payPalShippingAddressOption = .PayPal;
    
    print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    PayPalMobile.preconnectWithEnvironment(environment)
  }
  
  
  // MARK: Single Payment
  @IBAction func buyClothingAction(sender: AnyObject) {
    // Remove our last completed payment, just for demo purposes.
    resultText = ""
    
    // Note: For purposes of illustration, this example shows a payment that includes
    //       both payment details (subtotal, shipping, tax) and multiple items.
    //       You would only specify these if appropriate to your situation.
    //       Otherwise, you can leave payment.items and/or payment.paymentDetails nil,
    //       and simply set payment.amount to your total charge.
    
    // Optional: include multiple items
    let item1 = PayPalItem(name: "チケット１", withQuantity: 2, withPrice: NSDecimalNumber(string: "50"), withCurrency: "JPY", withSku: "Hip-0037")
    let item2 = PayPalItem(name: "商品１", withQuantity: 1, withPrice: NSDecimalNumber(string: "50"), withCurrency: "JPY", withSku: "Hip-00066")
    let item3 = PayPalItem(name: "月額１", withQuantity: 1, withPrice: NSDecimalNumber(string: "50"), withCurrency: "JPY", withSku: "Hip-00291")
    
    let items = [item1, item2, item3]
    let subtotal = PayPalItem.totalPriceForItems(items)
    
    // Optional: include payment details
    let shipping = NSDecimalNumber(string: "5")
    let tax = NSDecimalNumber(string: "5")
    let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
    
    let total = subtotal.decimalNumberByAdding(shipping).decimalNumberByAdding(tax)
    
    let payment = PayPalPayment(amount: total, currencyCode: "JPY", shortDescription: "テスト購入", intent: .Sale)
    
    payment.items = items
    payment.paymentDetails = paymentDetails
    
    if (payment.processable) {
      let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
      presentViewController(paymentViewController, animated: true, completion: nil)
    }
    else {
      // This particular payment will always be processable. If, for
      // example, the amount was negative or the shortDescription was
      // empty, this payment wouldn't be processable, and you'd want
      // to handle that here.
      print("Payment not processalbe: \(payment)")
    }
    
  }
  
  // PayPalPaymentDelegate
  
  func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
    print("PayPal Payment Cancelled")
    resultText = ""
    successView.hidden = true
    paymentViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
    print("PayPal Payment Success !")
    paymentViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
      // send completed confirmaion to your server
      print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")
      
      self.resultText = completedPayment!.description
      self.showSuccess()
    })
  }
  
  
  // MARK: Future Payments
  
  @IBAction func authorizeFuturePaymentsAction(sender: AnyObject) {
    let futurePaymentViewController = PayPalFuturePaymentViewController(configuration: payPalConfig, delegate: self)
    presentViewController(futurePaymentViewController, animated: true, completion: nil)
  }
  
  
  func payPalFuturePaymentDidCancel(futurePaymentViewController: PayPalFuturePaymentViewController!) {
    print("PayPal Future Payment Authorization Canceled")
    successView.hidden = true
    futurePaymentViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func payPalFuturePaymentViewController(futurePaymentViewController: PayPalFuturePaymentViewController!, didAuthorizeFuturePayment futurePaymentAuthorization: [NSObject : AnyObject]!) {
    print("PayPal Future Payment Authorization Success!")
    // send authorization to your server to get refresh token.
    futurePaymentViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
      self.resultText = futurePaymentAuthorization!.description
      self.showSuccess()
    })
    
    // 1. Sending my FP info to the server...
    let request = NSMutableURLRequest(URL: NSURL(string: "https://jo-pp-ruby-demo.herokuapp.com/rest/fp")!)
    request.HTTPMethod = "POST"
    let postString = "desc=\(futurePaymentAuthorization!.description)"
    request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
        guard error == nil && data != nil else {                                                          // check for fundamental networking error
            print("error=\(error)")
            return
        }
        
        if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(response)")
        }
        
        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
        print("responseString (FP) = \(responseString)")
    }
    task.resume()
    
    // 2. Getting access token from the server...
    var accessToken = ""
    let request2 = NSMutableURLRequest(URL: NSURL(string: "https://jo-pp-ruby-demo.herokuapp.com/rest/token")!)
    request2.HTTPMethod = "POST"
    let postString2 = ""
    request2.HTTPBody = postString2.dataUsingEncoding(NSUTF8StringEncoding)
    let task2 = NSURLSession.sharedSession().dataTaskWithRequest(request2) { data, response, error in
        guard error == nil && data != nil else {                                                          // check for fundamental networking error
            print("error=\(error)")
            return
        }
        
        if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(response)")
        }
        
        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
        print("responseString (TOKEN) = \(responseString)")
        accessToken = "\(responseString!)"
        print("accessToken = \(accessToken)")
        
        
        // 3. Registering card info to PayPal by vault...
        var vaultInfo = ""
        let now = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let nowString = formatter.stringFromDate(now)
        let jsonString = "{" +
            "\"payer_id\": \"user12345\"," +
            "\"type\": \"visa\"," +
            "\"number\": \"4417119669820331\"," +
            "\"expire_month\": \"11\"," +
            "\"expire_year\": \"2018\"," +
            "\"first_name\": \"iOS Vault \(nowString) \"," +
            "\"last_name\": \"Buyer\"," +
            "\"billing_address\": {" +
            "    \"line1\": \"222 First Street\"," +
            "    \"city\": \"Saratoga\"," +
            "    \"country_code\": \"US\"," +
            "    \"state\": \"CA\"," +
            "    \"postal_code\": \"95070\"" +
            "}" +
        "}"
        print("json: \(jsonString)")
        let request3 = NSMutableURLRequest(URL: NSURL(string: "https://api.sandbox.paypal.com/v1/vault/credit-cards")!)
        request3.HTTPMethod = "POST"
        request3.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request3.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let header = "Bearer \(accessToken)"
        print("Authorization: \(header)")
        request3.setValue(header, forHTTPHeaderField: "Authorization")
        let task3 = NSURLSession.sharedSession().dataTaskWithRequest(request3) { data, response, error in
            guard error == nil && data != nil else {                                                          // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString (VAULT) = \(responseString)")
            vaultInfo = "\(responseString!)"
            print("vaultInfo = \(vaultInfo)")
        }
        task3.resume()
        
        
    }
    task2.resume()
    
    
    
    
  }
  
  // MARK: Profile Sharing
  
  @IBAction func authorizeProfileSharingAction(sender: AnyObject) {
    let scopes = [kPayPalOAuth2ScopeOpenId, kPayPalOAuth2ScopeEmail, kPayPalOAuth2ScopeAddress, kPayPalOAuth2ScopePhone]
    let profileSharingViewController = PayPalProfileSharingViewController(scopeValues: NSSet(array: scopes) as Set<NSObject>, configuration: payPalConfig, delegate: self)
    presentViewController(profileSharingViewController, animated: true, completion: nil)
  }
  
  // PayPalProfileSharingDelegate
  
  func userDidCancelPayPalProfileSharingViewController(profileSharingViewController: PayPalProfileSharingViewController!) {
    print("PayPal Profile Sharing Authorization Canceled")
    successView.hidden = true
    profileSharingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func payPalProfileSharingViewController(profileSharingViewController: PayPalProfileSharingViewController!, userDidLogInWithAuthorization profileSharingAuthorization: [NSObject : AnyObject]!) {
    print("PayPal Profile Sharing Authorization Success!")
    
    // send authorization to your server
    
    profileSharingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
      self.resultText = profileSharingAuthorization!.description
      self.showSuccess()
    })

  }

  
  // MARK: - Navigation
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    
    if segue.identifier == "pushSettings" {
      // [segue destinationViewController] setDelegate:(id)self];
      if let flipSideViewController = segue.destinationViewController as? FlipsideViewController {
        flipSideViewController.flipsideDelegate = self
      }
    }
  }
  
  
  // MARK: Helpers
  
  func showSuccess() {
    successView.hidden = false
    successView.alpha = 1.0
    UIView.beginAnimations(nil, context: nil)
    UIView.setAnimationDuration(0.5)
    UIView.setAnimationDelay(2.0)
    successView.alpha = 0.0
    UIView.commitAnimations()
  }
  
  
  
  
  // MARK: Memory
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  
  
  
}
