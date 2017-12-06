//
//  Promise.swift
//  TestContext
//
//  Created by jacob berkman on 11/30/2017.
//  Copyright © 2017 Weebly, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

private struct Completions<Value> {

    let fulfillments: [(Value) -> Void]
    let rejections: [(Error) -> Void]

    static func +(lhs: Completions, rhs: Completions) -> Completions {
        return Completions(fulfillments: lhs.fulfillments + rhs.fulfillments,
                           rejections: lhs.rejections + rhs.rejections)
    }

}

private enum State<Value> {
    case pending(Completions<Value>)
    case fulfilled(Value)
    case rejected(Error)
}

/**
 A promise represents the eventual result of an asynchronous operation. The
 primary way of interacting with a promise is through its then method, which
 registers callbacks to receive either a promise’s eventual value or the
 reason why the promise cannot be fulfilled.
 */
public final class Promise<Value> {

    fileprivate typealias Fulfillment = (Value) -> Void
    fileprivate typealias Rejection = (Error) -> Void

    // `lock` must be held while accessing state
    private let lock = NSLock()
    private var state: State<Value> = .pending(Completions(fulfillments: [], rejections: []))

    private let dispatch: (@escaping () -> Void) -> Void

    /**
     Wrap creating a promise in a promise.

     - Parameter makePromise: block which creates a promise. Errors thrown will be
     reflected in the returned promise.
     - Returns: the promise returned by `makePromise`, or rejected by an error thrown by `makePromise`.
     */
    public class func `try`(_ makePromise: () throws -> Promise) -> Promise {
        do {
            return try makePromise()
        } catch {
            return Promise() |> tee { error |> $0.reject }
        }
    }

    /**
     Initialize a new promise. Callbacks will be performed by calling `dispatch`.

     - Parameter dispatch: block used to execute callbacks.
     */
    public required init(dispatch: @escaping (@escaping () -> Void) -> Void = { $0() }) {
        self.dispatch = dispatch
    }

    fileprivate func giveLock<A>(_ a: A) -> A { lock.unlock(); return a }

    fileprivate func pendingCallbacks<A>(_: A) -> Completions<Value>? {
        guard case let .pending(completions) = state else { return nil }
        return completions
    }

    fileprivate func stateSetter<A>(state: State<Value>) -> (A) -> A {
        return { self.state = state; return $0 }
    }

    fileprivate func setPending(with completions: Completions<Value>) {
        state = .pending(completions)
    }

    fileprivate func addCompletions(fulfillments: [Fulfillment] = [],
                                    rejections: [Rejection] = []) -> (Any) -> Void {
        return unwrap(self.pendingCallbacks)
            >=> turnout(curry(reverse(+))(Completions(fulfillments: fulfillments, rejections: rejections)))
            >=> turnout(self.setPending)
            >>> ignore
    }

    fileprivate func dispatch<A>(_ a: A) -> ([(A) -> Void]) -> Void {
        return { funcs in
            self.dispatch {
                funcs.forEach { a |> $0 }
            }
        }
    }

}

extension Promise {

    private func fulfillments<A>(_ a: A) -> [Fulfillment]? {
        return pendingCallbacks(a)?.fulfillments
    }

    /**
     Fulfills this promise with a value. Any previous or future calls to
     `then()` will be completed with `value`. If this promise has already
     been fulfilled or rejected, this function does nothing.

     - Parameter value: the value fulfilling this promise.
     */
    public func fulfill(with value: Value) {
        _ = lock.lock()
            |> unwrap(self.fulfillments)
            >>>= turnout(.fulfilled(value) |> self.stateSetter)
            |> giveLock
            >>>= turnout(self.dispatch(value))
    }

    /**
     Returns a function which fulfills a promise with a value. Any previous or
     future calls to `promise.then()` will be fulfilled with `value`. If the
     promise has already been fulfilled or rejected, the returned function does
     nothing.

     - Parameter value: the value to fulfill `Promise`s with.
     */
    public static func fulfill(with value: @autoclosure @escaping () -> Value) -> (Promise) -> Void {
        return { $0.fulfill(with: value()) }
    }

    private func rejections<A>(_ a: A) -> [Rejection]? {
        return pendingCallbacks(a)?.rejections
    }

    /**
     Rejects this promise with an error. Any previous or future calls to
     `catch()` will be completed with `error`. If this promise has already
     been fulfilled or rejected, this function does nothing.

     - Parameter error: the error rejecting this promise.
     */
    public func reject(with error: Error) {
        _ = lock.lock()
            |> unwrap(self.rejections)
            >>>= turnout(.rejected(error) |> self.stateSetter)
            |> giveLock
            >>>= turnout(self.dispatch(error))
    }

    /**
     Returns a function which rejects a promise with an error. Any previous or
     future calls to `promise.catch()` will be completed with `error`. If the
     promise has already been fulfilled or rejected, the returned function does
     nothing.

     - Parameter error: the error rejecting this promise.
     */
    public static func reject(with error: @autoclosure @escaping () -> Error) -> (Promise) -> Void {
        return { $0.reject(with: error()) }
    }

    private func value<A>(_: A) -> Value? {
        guard case let .fulfilled(value) = state else { return nil }
        return value
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: self
     */
    @discardableResult
    public func then(_ fulfillment: @autoclosure @escaping () -> (Value) -> Void) -> Promise {
        return lock.lock()
            |> unwrap(self.value)
            |> bimap(identity, self.addCompletions(fulfillments: [fulfillment()]))
            |> giveLock
            >>>= turnout(fulfillment())
            |> uncurry { self }
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The value this promise was fulfilled with will fulfill the returned promise,
     unless an error is thrown by `completion`, which will reject the promise
     instead.

     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public func then(_ fulfillment: @autoclosure @escaping () -> (Value) throws -> Void) -> Promise {
        let promise = Promise()
        self
            .then(tryCatch(tee(fulfillment()))
                >>> bimap(promise.fulfill, promise.reject)
                >>> ignore)
            .catch(promise.reject)
        return promise
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The value returned by `completion` will fulfill the returned promise,
     unless an error is thrown, which will reject the promise instead.

     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public func then<NewValue>(_ fulfillment: @autoclosure @escaping () -> (Value) throws -> NewValue) -> Promise<NewValue> {
        let promise = Promise<NewValue>()
        self
            .then(tryCatch(fulfillment())
                >>> bimap(promise.fulfill, promise.reject)
                >>> ignore)
            .catch(promise.reject)
        return promise
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The promise returned by `completion` will be used to fulfill or reject the
     returned promise.

     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public func then<NewValue>(_ fulfillment: @autoclosure @escaping () -> (Value) -> NewValue) -> Promise<NewValue> {
        let promise = Promise<NewValue>()
        self
            .then(fulfillment() >>> promise.fulfill)
            .catch(promise.reject)
        return promise
    }

    private func error<A>(_: A) -> Error? {
        guard case let .rejected(error) = state else { return nil }
        return error
    }

    /**
     Register a completion to be called when this promise is rejected. If this
     promise has already been rejected, `completion` will still be called. If
     this promise is fulfilled, `completion` will not be called.

     - Parameter completion: the completion to be called upon rejection.
     - Returns: self
     */
    @discardableResult
    public func `catch`(_ rejection: @autoclosure @escaping () -> (Error) -> Void) -> Promise {
        return lock.lock()
            |> unwrap(self.error)
            |> bimap(identity, self.addCompletions(rejections: [rejection()]))
            |> giveLock
            >>>= turnout(rejection())
            |> uncurry { self }
    }

    /**
     Register a completion to be called when this promise is fulfilled or
     rejected. If this promise has already been fulfilled or rejected,
     `completion` will still be called.

     - Parameter completion: the completion to be called upon fulfillment or
     rejection.
     - Returns: self
     */
    @discardableResult
    public func finally(_ completion: @autoclosure @escaping () -> () -> Void) -> Promise {
        return self
            ?> uncurry(completion())
            !> uncurry(completion())
    }

}

extension Promise {

    /**
     Create a new promise fulfilled or rejected by this promise which runs any
     completions on `queue`.

     - Parameter queue: a dispatch queue on which to run completions.
     - Returns: a block returning new promise to be fulfilled or rejected by the
     provided promise.
     */
    public static func async(with queue: DispatchQueue) -> (Promise) -> Promise {
        return { $0.async(with: queue) }
    }

    /**
     Create a new promise fulfilled or rejected by this promise which runs any
     completions on `queue`.

     - Parameter queue: a dispatch queue on which to run completions.
     - Returns: a new promise to be fulfilled or rejected by `self`.
     */
    public func async(with queue: DispatchQueue) -> Promise {
        let promise = Promise.init { queue.async(execute: $0) }
        self
            ?> promise.fulfill
            !> promise.reject
        return promise
    }

    /**
     Create a new promise fulfilled or rejected by `promise` which runs any
     completions on the main thread.

     - Returns: a new promise to be fulfilled or rejected by `promise`.
     */
    public static func main(_ promise: Promise) -> Promise {
        return promise.main()
    }

    /**
     Create a new promise fulfilled or rejected by this promise which runs any
     completions on the main thread.

     - Returns: a new promise to be fulfilled or rejected by `self`.
     */
    public func main() -> Promise {
        return async(with: .main)
    }

}

/**
 An error which represents a failed result.
 */
public enum Failure<E>: Error {
    /**
     The value this failure represents.
     */
    case failure(E)

    /**
     Initialize a failure with a value.
     */
    public init(value: E) {
        self = .failure(value)
    }

}

infix operator ?>: PipePrecedence
infix operator !>: PipePrecedence
infix operator *>: PipePrecedence

extension Promise {

    /**
     Fulfill or reject this promise with a `Result`.

     - Parameter result: the result containing a value which will fulfill or
     reject `self`.
     */
    public func complete<E>(with result: Result<Value, E>) {
        _ = result |> bimap(self.fulfill, Failure.init >>> self.reject)
    }

    /**
     Create a `Promise` fulfilled or rejected by the given `Result`.

     - Parameter result: the result containing a value which will fulfill or
     reject `self`.
     */
    public convenience init<E>(result: Result<Value, E>) {
        self.init()
        result |> complete
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     - Parameter promise: the promise on which to add the fulfillment.
     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: `promise`
     */
    @discardableResult
    public static func ?>(promise: Promise, f: @autoclosure @escaping () -> (Value) -> Void) -> Promise {
        return promise.then(f())
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The value this promise was fulfilled with will fulfill the returned promise,
     unless an error is thrown by `completion`, which will reject the promise
     instead.

     - Parameter promise: the promise on which to add the fulfillment.
     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public static func ?>(promise: Promise, f: @autoclosure @escaping () -> (Value) throws -> Void) -> Promise {
        return promise.then(f())
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The promise returned by `completion` will be used to fulfill or reject the
     returned promise.

     - Parameter promise: the promise on which to add the fulfillment.
     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public static func ?><NewValue>(promise: Promise, f: @autoclosure @escaping () -> (Value) -> NewValue) -> Promise<NewValue> {
        return promise.then(f())
    }

    /**
     Register a completion to be called when this promise is fulfilled. If this
     promise has already been fulfilled, `completion` will still be called. If
     this promise is rejected, `completion` will not be called.

     The value returned by `completion` will fulfill the returned promise,
     unless an error is thrown, which will reject the promise instead.

     - Parameter promise: the promise on which to add the fulfillment.
     - Parameter completion: the completion to be called upon fulfillment.
     - Returns: a new promise to be fulfilled or rejected by `completion`.
     */
    @discardableResult
    public static func ?><NewValue>(promise: Promise, f: @autoclosure @escaping () -> (Value) throws -> NewValue) -> Promise<NewValue> {
        return promise.then(f())
    }

    /**
     Register a completion to be called when this promise is rejected. If this
     promise has already been rejected, `completion` will still be called. If
     this promise is fulfilled, `completion` will not be called.

     - Parameter promise: the promise on which to add the completion.
     - Parameter completion: the completion to be called upon rejection.
     - Returns: `promise`.
     */
    @discardableResult
    public static func !>(promise: Promise, f: @autoclosure @escaping () -> (Error) -> Void) -> Promise {
        return promise.catch(f())
    }

    /**
     Register a completion to be called when this promise is fulfilled or
     rejected. If this promise has already been fulfilled or rejected,
     `completion` will still be called.

     - Parameter promise: the promise on which to add the completion.
     - Parameter completion: the completion to be called upon fulfillment or
     rejection.
     - Returns: `promise`.
     */
    @discardableResult
    public static func *>(promise: Promise, f: @autoclosure @escaping () -> () -> Void) -> Promise {
        return promise.finally(f())
    }

}
