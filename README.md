# StoreKitCompanion

A lightweight wrapper for Apple's StoreKit, written in Swift.  

[![CI Status](https://travis-ci.org/recisio/StoreKitCompanion.svg)](https://travis-ci.org/recisio/StoreKitCompanion)
![Language](https://img.shields.io/badge/language-Swift%202.2-orange.svg)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/recisio/StoreKitCompanion.svg)](https://img.shields.io/cocoapods/v/StoreKitCompanion.svg)
[![Platform](https://img.shields.io/cocoapods/p/StoreKitCompanion.svg?style=flat)](http://cocoadocs.org/docsets/StoreKitCompanion)
[![License](https://img.shields.io/cocoapods/l/StoreKitCompanion.svg?style=flat)](http://cocoapods.org/pods/StoreKitCompanion)

## Installation

### CocoaPods

Add `pod 'StoreKitCompanion'` to your Podfile and run `pod install`.
For details about CocoaPods, please view [CocoaPods website](https://cocoapods.org).

### Swift Package Manager

StoreKitCompanion is available on SPM. Just add the following to your Package file:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/recisio/StoreKitCompanion.git", majorVersion: 1)
    ]
)
```
### Manually

Add `StoreKitCompanion.swift` to your project.

## Usage

StoreKitCompanion lets you **fetch products**, **launch payment transactions** and **send App Store Receipt data over the network for validation** in a couple of lines of code.

### Fetching Products

Fetching products is easy, call `fetchProductsWithIdentifiers(_:completion:)` and pass in a set of product identifiers.
At a very minimum, also supply a completion closure to get the valid `SKProduct` objects returned.
Optionally, supply a failure closure to handle errors.

```swift
StoreKitCompanion.sharedInstance.fetchProductsWithIdentifiers(["com.mycompany.MyKillerProduct"], completion: { products, invalids in
    print("Got products", products)
    print("Got invalids", invalids)
})
```

### Buying

Before trying to buy something, you should check whether users are allowed to make payments.
You can do so by calling `canMakePayments()`.

```swift
StoreKitCompanion.sharedInstance.canMakePayments()
```

Payments are submitted to the default payment queue (`SKPaymentQueue.defaultQueue()`) and StoreKitCompanion observes it.
Whenever something happen on it, StoreKitCompanion sends notifications, and calls closures that you set.

```swift
// Provide a closure to be called when transactions are updated
StoreKitCompanion.sharedInstance.transactionsUpdateHandler = { queue, transactions in
    // Process transactions..
}
// Add a payment, quantity is 1 by default
StoreKitCompanion.sharedInstance.addPaymentForProductIdentifier("com.mycompany.MyKillerProduct")
```

### Restoring previous transactions

You can restore completed transactions by calling `restoreCompletedTransactionsWithUsername(_:)`.  
You may also provide an optional username.  
Callbacks that you set are called in response to the restoration request.

```swift
StoreKitCompanion.restoreCompletedTransactionsWithUsername()
```

### Validating the App Store Receipt

Details about App Store receipt validation can be found on [Apple's website](https://developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Introduction.html).
While StoreKitCompanion doesn't perform any local validation (yet?) of the receipt, it let's you send it to a server for validation.

By default, StoreKitCompanion will send the data using a HTTP POST request, with a parameter named `receiptData`, but you can override those settings if you need to.


```swift
// First supply a validation URL, StoreKitCompanion will use it
StoreKitCompanion.sharedInstance.validationURLString = "http://myserver.com"
// Send the data out
StoreKitCompanion.sharedInstance.sendReceiptWithPOSTRequest() { responseData, error in
    print("Got response", responseData)
    print("Got error", error)
}
```

To customize the way the receipt is sent, use `sendReceiptWithDescriptor(_:completion:)` and provide it with any object that adopts the `ReceiptValidationRequestDescriptor` protocol.
Default values are already provided in a protocol extension, so override only what's needed.

```swift
struct MyRequestDescriptor: ReceiptValidationRequestDescriptor {

    // Name parameters differently or add parameters
    func parametersWithReceiptData(receiptData: NSData) -> [String: AnyObject]? {
        return ["best_param_name": receiptData, "new_param": "new_param_value"]
    }

}

// Send the data out
StoreKitCompanion.sharedInstance.sendReceiptWithDescriptor(MyRequestDescriptor()) { responseData, error in
    print("Got response", responseData)
    print("Got error", error)
}
```
## Other

### Notifications

StoreKitCompanion watches the default payment queue and sends notifications :  

```swift
/**
    The name of the notification sent when the payment queue finished to restore completed transactions.
    User info dictionary contains a reference to the `SKPaymentQueue` object.
*/
public static let PaymentQueueDidFinishRestoringCompletedTransactions  = "SKCPaymentQueueDidFinishRestoringCompletedTransactions"
/**
    The name of the notification sent when transactions are updated.
    User info dictionary contains a reference to the `SKPaymentQueue` object and an array of `SKPaymentTransaction` objects.
*/
public static let PaymentQueueDidUpdateTransactions                    = "SKCPaymentQueueDidUpdateTransactions"
/**
    The name of the notification sent when transactions are removed.
    User info dictionary contains a reference to the `SKPaymentQueue` object and an array of `SKPaymentTransaction` objects.
*/
public static let PaymentQueueDidRemoveTransactions                    = "SKCPaymentQueueDidRemoveTransactions"
/**
    The name of the notification sent when downloads are updated
    User info dictionary contains a reference to the `SKPaymentQueue` object and an array of `SKDownload` objects.
*/
public static let PaymentQueueDidUpdateDownloads                       = "SKCPaymentQueueDidUpdateDownloads"
/**
    The name of the notification sent when the payment queue fails to restore completed transactions.
    User info dictionary contains a reference to the `SKPaymentQueue` object and a reference to the `NSError` object.
*/
public static let PaymentQueueDidFailRestoringCompletedTransactions    = "SKCPaymentQueueDidFailRestoringCompletedTransactions"
```

### Callbacks

Another way to handle payment queue events is to provide StoreKitCompanion with closures for those events :

```swift
public typealias CompletedTransactionsRestoreCompletion    = (SKPaymentQueue) -> Void
public typealias CompletedTransactionsRestoreFailure       = (SKPaymentQueue, NSError) -> Void
public typealias DownloadsUpdateCompletion                 = (SKPaymentQueue, [SKDownload]) -> Void
public typealias TransactionsUpdateCompletion              = (SKPaymentQueue, [SKPaymentTransaction]) -> Void
public typealias TransactionsRemovalCompletion             = (SKPaymentQueue, [SKPaymentTransaction]) -> Void

// ....

/**
    Handles successful completed transactions restoration
*/
public var completedTransactionsRestorationSuccessHandler: CompletedTransactionsRestoreCompletion?
/**
    Handles completed transaction restoration failure
*/
public var completedTransactionsRestorationFailureHandler: CompletedTransactionsRestoreFailure?
/**
    Handles successful downloads restoration
*/
public var downloadsUpdateSuccessHandler: DownloadsUpdateCompletion?
/**
    Handles transaction updates
*/
public var transactionsUpdateHandler: TransactionsUpdateCompletion?
/**
    Handles transaction removals
*/
public var transactionsRemovalHandler: TransactionsRemovalCompletion?
```

## What's next

- Handling transaction restoration
- Validating App Store Receipt locally

## Contribution

- If you found a **bug**, open an **issue**
- If you have a **feature request**, open an **issue**
- If you want to **contribute**, submit a **pull request**

## License

StoreKitCompanion is available under the MIT license. See the LICENSE file for more info.
