//
//  Functional.swift
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

precedencegroup PipePrecedence {
    associativity: left
    higherThan: NilCoalescingPrecedence
}

precedencegroup ComposePrecedence {
    associativity: left
    higherThan: PipePrecedence
}

infix operator |>: PipePrecedence

infix operator >>>: ComposePrecedence

// f(a) -> b

/**
 Return the result of evaluating a function `f` with argument(s) `a`.

 - Parameter a: Value to be passed to `f`.
 - Parameter f: Function to evaluate.
 - Returns: f(a)
 */
public func pipe<A, B>(_ a: A, _ f: (A) -> B) -> B {
    return f(a)
}

/**
 Infix `pipe` operator.

 - Parameter a: Value to be passed to `f`.
 - Parameter f: Function to evaluate.
 - Returns: f(a)
 */
public func |><A, B>(a: A, f: (A) -> B) -> B {
    return pipe(a, f)
}

/**
 Returns a new function which returns the result of evaluating a function `g`
 with the result of evaluating another function `f`.

 - Parameter f: First function to be called.
 - Parameter g: Second function to be called.
 - Returns: A function which returns the result of calling `g` with the output
 of calling `f` with the function's input: `g(f($0))`.
 */
public func compose<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> B,
                             _ g: @autoclosure @escaping () -> (B) -> C) -> (A) -> C {
    return { g()(f()($0)) }
}

/**
 Infix `compose` operator.

 - Parameter f: First function to be called.
 - Parameter g: Second function to be called.
 - Returns: A function which returns the result of calling `g` with the output
 of calling `f` with the function's input: `g(f($0))`.
 */
public func >>><A, B, C>(_ f: @escaping (A) -> B,
                         _ g: @escaping (B) -> C) -> (A) -> C {
    return compose(f, g)
}

/**
 A function which returns its argument.

 - Parameter a: value to return.
 - Returns: `a`.
 */
public func identity<A>(_ a: A) -> A { return a }

/**
 A function which ignores its argument.

 - Parameter a: value to ignore.
 */
public func ignore<A>(_: A) -> Void { }

/**
 Create a curried version of a two-argument function.

 - Parameter f: function to curry.
 - Returns: a chain of functions each taking a single argument.
 */
public func curry<A, B, C>(_ f: @autoclosure @escaping () -> (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { f()(a, $0) } }
}

/**
 Create a curried version of a three-argument function.

 - Parameter f: function to curry.
 - Returns: a chain of functions each taking a single argument.
 */
public func curry<A, B, C, D>(_ f: @autoclosure @escaping () -> (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in curry { f()(a, $0, $1) } }
}

/**
 Create a curried version of a four-argument function.

 - Parameter f: function to curry.
 - Returns: a chain of functions each taking a single argument.
 */
public func curry<A, B, C, D, E>(_ f: @autoclosure @escaping () -> (A, B, C, D) -> E) -> (A) -> (B) -> (C) -> (D) -> E {
    return { a in curry { f()(a, $0, $1, $2) } }
}

/**
 Create a function accepting an ignored argument.

 - Parameter f: function to uncurry.
 - Returns: A function which ignores its argument, returning f().
 */
public func uncurry<A, B>(_ f: @autoclosure @escaping () -> () -> B) -> (A) -> B {
    return { _ in f()() }
}

/**
 Convert a curried function into one that takes two arguments.

 - Parameter f: function to uncurry.
 - Returns: A function taking two arguments.
 */
public func uncurry<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> (B) -> C) -> (A, B) -> C {
    return { f()($0)($1) }
}

/**
 Convert a curried function into one that takes three arguments.

 - Parameter f: function to uncurry.
 - Returns: A function taking three arguments.
 */
public func uncurry<A, B, C, D>(_ f: @autoclosure @escaping () -> (A) -> (B) -> (C) -> D) -> (A, B, C) -> D {
    return { f()($0)($1)($2) }
}

/**
 Convert a curried function into one that takes four arguments.

 - Parameter f: function to uncurry.
 - Returns: A function taking four arguments.
 */
public func uncurry<A, B, C, D, E>(_ f: @autoclosure @escaping () -> (A) -> (B) -> (C) -> (D) -> E) -> (A, B, C, D) -> E {
    return { f()($0)($1)($2)($3) }
}

/**
 Reverse the order of a two-argument function's arguments.

 - Parameter f: a function.
 - Returns: a function which accepts arguments in the reverse order.
 */
public func reverse<A, B, C>(_ f: @autoclosure @escaping () -> (A, B) -> C) -> (B, A) -> C {
    return { f()($1, $0) }
}

/**
 Reverse the order of a three-argument function's arguments.

 - Parameter f: a function.
 - Returns: a function which accepts arguments in the reverse order.
 */
public func reverse<A, B, C, D>(_ f: @autoclosure @escaping () -> (A, B, C) -> D) -> (C, B, A) -> D {
    return { f()($2, $1, $0) }
}

/**
 Reverse the order of a four-argument function's arguments.

 - Parameter f: a function.
 - Returns: a function which accepts arguments in the reverse order.
 */
public func reverse<A, B, C, D, E>(_ f: @autoclosure @escaping () -> (A, B, C, D) -> E) -> (D, C, B, A) -> E {
    return { f()($3, $2, $1, $0) }
}

/**
 Reverse the order of a two-curry function.

 - Parameter f: a function.
 - Returns: a function which accepts curried arguments in the reverse order.
 */
public func reverse<A, B, C>(_ f: @autoclosure @escaping () -> (A) -> (B) -> C) -> (B) -> (A) -> C {
    return curry(reverse(uncurry(f())))
}

/**
 Reverse the order of a three-curry function.

 - Parameter f: a function.
 - Returns: a function which accepts curried arguments in the reverse order.
 */
public func reverse<A, B, C, D>(_ f: @autoclosure @escaping () -> (A) -> (B) -> (C) -> D) -> (C) -> (B) -> (A) -> D {
    return curry(reverse(uncurry(f())))
}

/**
 Reverse the order of a four-curry function.

 - Parameter f: a function.
 - Returns: a function which accepts curried arguments in the reverse order.
 */
public func reverse<A, B, C, D, E>(_ f: @autoclosure @escaping () -> (A) -> (B) -> (C) -> (D) -> E) -> (D) -> (C) -> (B) -> (A) -> E {
    return curry(reverse(uncurry(f())))
}
