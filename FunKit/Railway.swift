//
//  Railway.swift
//  FunKit
//
//  Created by jacob berkman on 12/5/2017.
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
//  Based on "Railway oriented programming"
//  http://fsharpforfunandprofit.com/posts/recipe-part2/
//

infix operator >>>=: PipePrecedence
infix operator >=>: ComposePrecedence

/**
 A result captures both successful and failed return values of a method.
 */
public enum Result<A, B> {
    /**
     A value representing a successful result.
     */
    case success(A)

    /**
     A value representing a failed result.
     */
    case failure(B)

    /**
     Create a successful result with the provided value.

     - Parameter a: successful value represented by this result.
     */
    public init(success a: A) {
        self = .success(a)
    }

    /**
     Create a failed result with the provided value.

     - Parameter b: failure value represented by this result.
     */
    public init(failure b: B) {
        self = .failure(b)
    }
}

extension Result where A: Equatable, B: Equatable {

    /**
     Determine whether two results containing equatable values are equal.

     - Parameter lhs: left-hand result to compare.
     - Parameter rhs: right-hand result to compare.
     - Returns: `true` if lhs are both successes or failures containing equal
     values.
     */
    public static func==(lhs: Result, rhs: Result) -> Bool {
        return EquatableResult(lhs) == EquatableResult(rhs)
    }

}

/**
 A result containing equatable values.
 */
public enum EquatableResult<A: Equatable, B: Equatable>: Equatable {

    /**
     A value representing a successful result.
     */
    case success(A)

    /**
     A value representing a failed result.
     */
    case failure(B)

    /**
     Wrap a result in an equatable result.

     - Parameter result: result whose value to adopt.
     */
    public init(_ result: Result<A, B>) {
        switch result {
        case let .success(a): self = .success(a)
        case let .failure(b): self = .failure(b)
        }
    }

    /**
     Determine whether two results containing equatable values are equal.

     - Parameter lhs: left-hand result to compare.
     - Parameter rhs: right-hand result to compare.
     - Returns: `true` if lhs are both successes or failures containing equal
     values.
     */
    public static func==(lhs: EquatableResult, rhs: EquatableResult) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhs), .success(rhs)): return lhs == rhs
        case let (.failure(lhs), .failure(rhs)): return lhs == rhs
        default: return false
        }
    }

    /**
     Determine whether two results containing equatable values are equal.

     - Parameter lhs: left-hand result to compare.
     - Parameter rhs: right-hand result to compare.
     - Returns: `true` if lhs are both successes or failures containing equal
     values.
     */
    public static func==(lhs: Result<A, B>, rhs: EquatableResult) -> Bool {
        return EquatableResult(lhs) == rhs
    }

    /**
     Determine whether two results containing equatable values are equal.

     - Parameter lhs: left-hand result to compare.
     - Parameter rhs: right-hand result to compare.
     - Returns: `true` if lhs are both successes or failures containing equal
     values.
     */
    public static func==(lhs: EquatableResult, rhs: Result<A, B>) -> Bool {
        return lhs == EquatableResult(rhs)
    }

}

/**
 `bind` creates a function that passes a `Result`'s success value to another
 function, while errors are passed through unchanged.

 - Parameter f: a function which maps a value to a `Result`.
 - Returns: a function which maps one `Result` to another.
 */
public func bind<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> Result<B, C>) -> (Result<A, C>) -> Result<B, C> {
    return {
        switch $0 {
        case let .success(a): return f()(a)
        case let .failure(c): return .failure(c)
        }
    }
}

extension Result {

    /**
     Infix version of `bind` returning a value rather than a function.

     - Parameter result: incoming `Result` to evaluate.
     - Parameter f: function mapping a value to a `Result`.
     - Returns: the result of `f` if `result` was successful, `result` otherwise.
     */
    public static func >>>=<C>(_ result: Result, _ f: @autoclosure @escaping () -> (A) -> Result<C, B>) -> Result<C, B> {
        return bind(f())(result)
    }

}

/**
 Infix version of `f` composed with `bind`. Returns a function that maps a value
 through both `f` and `g`.

 - Parameter f: function mapping a value to a `Result`.
 - Parameter g: function mapping a value to a `Result`.
 - Returns: the result of `g` if `f` and `g` are both successful, a failure
 otherwise.
 */
public func >=><A, B, C, D>(_ f: @autoclosure @escaping () -> (A) -> Result<B, D>,
                            _ g: @autoclosure @escaping () -> (B) -> Result<C, D>) -> (A) -> Result<C, D> {
    return compose(f(), bind(g()))
}

/**
 Creates a switched function that always returns success.

 - Parameter f: function being evaluated.
 - Returns: a function mapping a value to a result via `f`.
 */
public func turnout<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> B) -> (A) -> Result<B, C> {
    return compose(f(), Result.init)
}

/**
 Recover form a failure by mapping a failure to success.

 - Parameter f: function mapping the `Result` type to something else.
 - Returns: a function mapping a `Result` to a value via `f`.
 */
public func turnin<A, B>(_ f: @autoclosure @escaping () -> (B) -> A) -> (Result<A, B>) -> A {
    return {
        switch $0 {
        case let .success(a): return a
        case let .failure(b): return f()(b)
        }
    }
}

/**
 Recover form a failure by re-mapping to success.

 - Parameter f: function mapping the `Result` type to something else.
 - Returns: a function mapping a `Result` to a value via `f`.
 */
public func turnin<A, B, C>(_ f: @autoclosure @escaping () -> (B) -> Result<A, C>) -> (Result<A, B>) -> Result<A, C> {
    return {
        switch $0 {
        case let .success(a): return .success(a)
        case let .failure(b): return f()(b)
        }
    }
}

/**
 Pipes a value to another function, returning the original value instead.

 - Parameter f: function to evaluate.
 - Returns: a function which maps a value to itself, passig it to `f` first.
 */
public func tee<A, B>(_ f: @autoclosure @escaping () -> (A) -> B) -> (A) -> A {
    return {
        _ = f()($0)
        return $0
    }
}

/**
 Pipes a value to another function, returning the original value instead.

 This version may throw.

 - Parameter f: function to evaluate.
 - Returns: a function which maps a value to itself, passig it to `f` first.
 */
public func tee<A, B>(_ f: @autoclosure @escaping () -> (A) throws -> B) -> (A) throws -> A {
    return {
        _ = try f()($0)
        return $0
    }
}

/**
 Map both the success and failure values of a `Result` to different values.

 - Parameter success: function evaluated if the `Result` succeeded.
 - Parameter failure: function evaluated if the `Result` failed.
 - Returns: a function mapping one `Result` to another.
 */
public func bimap<A, B, C, D>(_ success: @autoclosure @escaping () -> (A) -> B,
                              _ failure: @autoclosure @escaping () -> (C) -> D) -> (Result<A, C>) -> Result<B, D> {
    return {
        switch $0 {
        case let .success(a): return .success(success()(a))
        case let .failure(c): return .failure(failure()(c))
        }
    }
}

/**
 Map both the successful value of a `Result` to a different value.

 - Parameter success: function evaluated if the `Result` succeeded.
 - Returns: a function mapping one `Result` to another.
 */
public func map<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> B) -> (Result<A, C>) -> Result<B, C> {
    return bimap(f(), identity)
}

/**
 Create a function that interprets a thrown error as a failed result.

 - Parameter f: function evaluated with the passed-in value.
 - Returns: a function mapping a value to a `Result`.
 */
public func tryCatch<A, B>(_ f: @autoclosure @escaping () -> (A) throws -> B) -> (A) -> Result<B, Error> {
    return {
        do    { return try .success(f()($0)) }
        catch { return .failure(error) }
    }
}

/**
 Nil represents a failed unwrapping of an Optional value.
 */
public enum Nil {
    /**
     A nil value.
     */
    case `nil`
}

/**
 Evaluate a function returning an optional value, returning a failure if `nil`
 was returned, converting an optional to a two-way track.

 - Parameter f: function to evaluate.
 - Returns: a function mapping a value to a `Result`.
 */
public func unwrap<A, B>(_ f: @autoclosure @escaping () -> (A) -> B?) -> (A) -> Result<B, Nil> {
    return {
        guard let b = $0 |> f() else { return .failure(.nil) }
        return .success(b)
    }
}

/**
 Unwrap an optional value, returning a `Result`, converting an optional to a
 two-way track.

 - Parameter a: value to attempt to unwrap.
 - Returns: a `Result` indicating whether or not the unwrapping was successful.
 */
public func unwrap<A>(_ a: A?) -> Result<A, Nil> {
    guard let a = a else { return .failure(.nil) }
    return .success(a)
}
