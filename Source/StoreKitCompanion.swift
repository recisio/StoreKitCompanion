// StoreKitCompanion.swift
//
// Copyright (c) 2016 Recisio (http://www.recisio.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import StoreKit
import Alamofire

// MARK: Typealiases for StoreKitCompanion

extension StoreKitCompanion {

    // MARK: Transaction Observer Callbacks

    public typealias CompletedTransactionsRestoreCompletion    = (SKPaymentQueue) -> Void
    public typealias CompletedTransactionsRestoreFailure       = (SKPaymentQueue, NSError) -> Void
    public typealias DownloadsUpdateCompletion                 = (SKPaymentQueue, [SKDownload]) -> Void
    public typealias TransactionsUpdateCompletion              = (SKPaymentQueue, [SKPaymentTransaction]) -> Void
    public typealias TransactionsRemovalCompletion             = (SKPaymentQueue, [SKPaymentTransaction]) -> Void

    // MARK: Request Failure

    public typealias Failure               = (NSError?) -> Void

    // MARK: Products Fetch Callbacks

    public typealias ProductsResult        = ([SKProduct]?, [String]?) -> Void

}

public class StoreKitCompanion: NSObject {

    // MARK: Notification Names

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

    // MARK: User Info Keys

    /**
        The key for the payment queue (`SKPaymentQueue`) in user info dictionaries
    */
    public static let PaymentQueueKey = "PaymentQueue"
    /**
        The key for an array of transactions (`SKPaymentTransaction`) in user info dictionaries
    */
    public static let TransactionsKey = "Transactions"
    /**
        The key for an array of downloads (`SKDownload`) in user info dictionaries
    */
    public static let DownloadsKey    = "Downloads"
    /**
        The key for an error (`NSError`) in user info dictionaries
    */
    public static let ErrorKey        = "Error"

    // MARK: Error Domains

    public static let StoreKitCompanionErrorDomain = "com.recisio.StoreKitCompanion.ErrorDomain"

    // MARK: Error Codes

    public enum ErrorCodes: Int {
        case NoReceiptData
        case NoValidationURL
    }

    // MARK: Transaction Queue Observer callbacks

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

    /**
        The URL string for App Store Receipt validation
    */
    public var validationURLString: String?

    // MARK: Singleton

    /**
    The shared store kit companion
    */
    public static let sharedInstance = StoreKitCompanion()

    // MARK: Lifecycle

    private override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    // MARK: Interacting with the Apple Store

    /**
        Starts a receipt refresh request.
        On OS X, checks if the receipt is avalable and exits with code 173 if not
        On iOS, starts a new `SKReceiptRefreshRequest`
    */
    public func refreshReceipt() {
        #if os(OSX)
        guard let appStoreReceiptURL = NSBundle.mainBundle().appStoreReceiptURL else {
            return
        }
        var err: NSError?
        guard appStoreReceiptURL.checkResourceIsReachableAndReturnError(&err) else {
            exit(173)
        }
        #elseif os(iOS)
        guard self.receiptRequest == nil else {
            return
        }
        self.receiptRequest = SKReceiptRefreshRequest(receiptProperties: nil)
        self.receiptRequest?.delegate = self
        self.receiptRequest?.start()
        #endif
    }

    /**
        Try fetching products with a given set of product identifiers.

        - parameter identifiers:    The set of identifiers for the products to fetch
        - parameter completion:     Called when the product request succeed
        - parameter failure:        Called when the product request fail, if provided
    */
    public func fetchProductsWithIdentifiers(identifiers: Set<String>, completion: ProductsResult, failure: Failure? = nil) {
        guard self.productsRequest == nil else {
            return
        }

        productsRequestCompletion = completion
        productsRequestFailure = failure

        self.productsRequest = SKProductsRequest(productIdentifiers: identifiers)
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }

    // MARK: Making purchases

    /**
        Tells whether payments can be made.

        - returns:  A Bool telling whether payments can be made
    */
    public func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    /**
        Submits a payment to the default payment queue.

        - parameter productID:  The identifier of the product to buy
        - parameter quantity:   The quantity to buy, defaults to 1
     
        - returns: A Bool telling whether the payment is successfuly submitted to the queue
    */
    public func addPaymentForProductIdentifier(productID: String, quantity: Int = 1) -> Bool {
        guard quantity > 0, let product = self.productWithIdentifier(productID) else {
            return false
        }

        #if os(OSX)
        guard let payment = SKMutablePayment.paymentWithProduct(product) as? SKMutablePayment else {
            return false
        }
        #elseif os(iOS)
        let payment = SKMutablePayment(product: product)
        #endif

        payment.quantity = quantity
        SKPaymentQueue.defaultQueue().addPayment(payment)
        return true
    }
    
    // MARK: Restoring purchases
    
    /**
        Asks the default payment queue to restore completed transactions

        - parameter username:   An optional opaque identifier for the user's account, which is nil by default
    */
    public func restoreCompletedTransactionsWithUsername(username: String? = nil) {
        if let user = username {
            SKPaymentQueue.defaultQueue().restoreCompletedTransactionsWithApplicationUsername(user)
        } else {
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }

    // MARK: Validating receipts

    /**
        Returns App Store Receipt data as NSData if present or nil
    */
    public func appStoreReceiptData() -> NSData? {
        if let appStoreReceiptURL = NSBundle.mainBundle().appStoreReceiptURL, receiptData = NSData(contentsOfURL: appStoreReceiptURL) {
            return receiptData
        }
        return nil
    }

    /**
        Sends the App Store Receipt data using a HTTP POST request asynchronously.

        - parameter completion: The closure to handle the request completion
    */
    public func sendReceiptWithPOSTRequest(completion: (responseData: NSData?, error: NSError?) -> Void) {
        self.sendReceiptWithDescriptor(self, completion: completion)
    }

    /**
        Sends the App Store Receipt data using a HTTP request asynchronously.

        - parameter descriptor: An object used to provide parameters for the request
        - parameter completion: The closure to handle the request completion
    */
    public func sendReceiptWithDescriptor(descriptor: ReceiptValidationRequestDescriptor, completion: (responseData: NSData?, error: NSError?) -> Void) {
        guard let receiptData = self.appStoreReceiptData() else {
            let error = NSError(domain: StoreKitCompanion.StoreKitCompanionErrorDomain, code: ErrorCodes.NoReceiptData.rawValue, userInfo: nil)
            completion(responseData: nil, error: error)
            return
        }
        guard let urlString = descriptor.URL else {
            let error = NSError(domain: StoreKitCompanion.StoreKitCompanionErrorDomain, code: ErrorCodes.NoValidationURL.rawValue, userInfo: nil)
            completion(responseData: nil, error: error)
            return
        }

        Alamofire.request(descriptor.HTTPMethod, urlString, parameters: descriptor.parametersWithReceiptData(receiptData), encoding: descriptor.encoding, headers: descriptor.headers).response { _, _, data, error in
            completion(responseData: data, error: error)
        }
    }

    // MARK: Private Stuff

    private var productsRequest: SKProductsRequest?
    private var products = [SKProduct]()
    private var productsRequestCompletion: ProductsResult?
    private var productsRequestFailure: Failure?

    #if os(iOS)
    private var receiptRequest: SKReceiptRefreshRequest?
    #endif

    // MARK: Helpers

    private func productWithIdentifier(productID: String) -> SKProduct? {
        return products.filter({ $0.productIdentifier == productID }).first
    }

}

/**
    Types adopting the `ReceiptValidationRequestDescriptor` protocol can be used to customize parameters for the validation request
*/
public protocol ReceiptValidationRequestDescriptor {

    var HTTPMethod: Alamofire.Method { get }
    var URL: String? { get }
    var encoding: Alamofire.ParameterEncoding { get }
    var headers: [String: String]? { get }
    func parametersWithReceiptData(receiptData: NSData) -> [String: AnyObject]?

}

/**
    Default common values and implementation for `ReceiptValidationRequestDescriptor`
*/
extension ReceiptValidationRequestDescriptor {

    /**
        Sending receipt data through a POST request by default
    */
    public var HTTPMethod: Alamofire.Method {
        return .POST
    }

    public var encoding: Alamofire.ParameterEncoding {
        return .URL
    }

    public var headers: [String: String]? {
        return nil
    }

    /**
        The receipt data is transmitted with the 'receiptData' parameter name by default
    */
    public func parametersWithReceiptData(receiptData: NSData) -> [String: AnyObject]? {
        return ["receiptData": receiptData]
    }
}

/**
    `StoreKitCompanion` adopts `ReceiptValidationRequestDescriptor`
*/
extension StoreKitCompanion: ReceiptValidationRequestDescriptor {

    public var URL: String? {
        return self.validationURLString
    }

}

// MARK: SKPaymentTransactionObserver

extension StoreKitCompanion: SKPaymentTransactionObserver {

    public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCompanion.PaymentQueueDidFinishRestoringCompletedTransactions, object: self, userInfo: [
            StoreKitCompanion.PaymentQueueKey : queue
        ])
        if let handler = self.completedTransactionsRestorationSuccessHandler {
            handler(queue)
        }
    }

    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCompanion.PaymentQueueDidUpdateTransactions, object: self, userInfo: [
            StoreKitCompanion.PaymentQueueKey : queue,
            StoreKitCompanion.TransactionsKey : transactions
        ])
        if let handler = self.transactionsUpdateHandler {
            handler(queue, transactions)
        }
    }

    public func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCompanion.PaymentQueueDidRemoveTransactions, object: self, userInfo: [
            StoreKitCompanion.PaymentQueueKey : queue,
            StoreKitCompanion.TransactionsKey : transactions
        ])
        if let handler = self.transactionsRemovalHandler {
            handler(queue, transactions)
        }
    }

    public func paymentQueue(queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCompanion.PaymentQueueDidUpdateDownloads, object: self, userInfo: [
            StoreKitCompanion.PaymentQueueKey : queue,
            StoreKitCompanion.DownloadsKey    : downloads
        ])
        if let handler = self.downloadsUpdateSuccessHandler {
            handler(queue, downloads)
        }
    }

    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCompanion.PaymentQueueDidFailRestoringCompletedTransactions, object: self, userInfo: [
            StoreKitCompanion.PaymentQueueKey : queue,
            StoreKitCompanion.ErrorKey        : error
        ])
        if let handler = self.completedTransactionsRestorationFailureHandler {
            handler(queue, error)
        }
    }

}

// MARK: SKRequestDelegate, SKProductsRequestDelegate

extension StoreKitCompanion: SKRequestDelegate, SKProductsRequestDelegate {

    // MARK: SKProductsRequestDelegate

    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        defer {
            self.clearProductsRequestStuff()
        }
        guard let callback = self.productsRequestCompletion, products = response.products else {
            return
        }

        self.products = products

        callback(response.products, response.invalidProductIdentifiers)
    }

    // MARK: SKRequestDelegate

    #if os(iOS)
    public func requestDidFinish(request: SKRequest) {
        if request == self.receiptRequest {
            defer {
                self.clearReceiptRequestStuff()
            }
        }
    }
    #endif

    #if os(OSX)
    public func request(request: SKRequest, didFailWithError error: NSError?) {
        defer {
            self.clearProductsRequestStuff()
        }
        guard let callback = self.productsRequestFailure else {
            return
        }
        callback(error)
    }
    #elseif os(iOS)
    public func request(request: SKRequest, didFailWithError error: NSError) {
        if request == self.productsRequest {
            defer {
                self.clearProductsRequestStuff()
            }
            guard let callback = self.productsRequestFailure else {
                return
            }
            callback(error)
        } else if request == self.receiptRequest {
            defer {
                self.clearReceiptRequestStuff()
            }
        } else {
            print("Unknow request", request)
        }
    }
    #endif

    private func clearProductsRequestStuff() {
        self.productsRequest?.cancel()
        self.productsRequest = nil
        self.productsRequestCompletion = nil
        self.productsRequestFailure = nil
    }

    #if os(iOS)
    private func clearReceiptRequestStuff() {
        self.receiptRequest?.cancel()
        self.receiptRequest = nil
    }
    #endif
}
