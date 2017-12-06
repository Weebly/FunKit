//
//  PromiseTests.swift
//  WeeblyFoundationTests
//
//  Created by jacob berkman on 9/21/17.
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

import XCTest

@testable import FunKit

class PromiseTests: XCTestCase {

    enum Error: Swift.Error {
        case test
    }

    func testFulfill() {
        let thenBefore = expectation(description: "then before")
        let finallyBefore = expectation(description: "finally before")

        let thenAfter = expectation(description: "then after")
        let finallyAfter = expectation(description: "finally after")

        let promise = Promise<Bool>().then {
            XCTAssert($0)
            thenBefore.fulfill()
        }.catch {
            XCTFail("unexpected error: \($0)")
        }.finally(finallyBefore.fulfill)

        promise.fulfill(with: true)

        promise.then {
            XCTAssert($0)
            thenAfter.fulfill()
        }.catch {
            XCTFail("unexpected error: \($0)")
        }.finally(finallyAfter.fulfill)

        waitForExpectations(timeout: 30)
    }

    func testReject() {
        let catchBefore = expectation(description: "catch before")
        let finallyBefore = expectation(description: "finally before")

        let catchAfter = expectation(description: "catch after")
        let finallyAfter = expectation(description: "finally after")

        let promise = Promise<Bool>().then {
            XCTFail("unexpected success: \($0)")
        }.catch {
            XCTAssertEqual($0 as? Error, Error.test)
            catchBefore.fulfill()
        }.finally(finallyBefore.fulfill)

        promise.reject(with: Error.test)

        promise.then {
            XCTFail("unexpected success: \($0)")
        }.catch {
            XCTAssertEqual($0 as? Error, Error.test)
            catchAfter.fulfill()
        }.finally(finallyAfter.fulfill)

        waitForExpectations(timeout: 30)
    }

    func testThenTransforms() {
        let then = expectation(description: "then called")

        let promise = Promise<Bool>()
        promise.then { bool -> String in
            XCTAssertEqual(bool, true)
            return "false"
        }.then {
            XCTAssertEqual($0, "false")
            then.fulfill()
        }
        promise.fulfill(with: true)
        waitForExpectations(timeout: 30)
    }

    func testThenThrows() {
        let exp = expectation(description: "catch called")

        let promise = Promise<Bool>()
        promise.then { bool -> String in
            XCTAssertEqual(bool, true)
            throw Error.test
        }.catch {
            XCTAssertEqual($0 as? Error, .test)
            exp.fulfill()
        }
        promise.fulfill(with: true)
        waitForExpectations(timeout: 30)
    }

    func testVoidThenThrows() {
        let exp = expectation(description: "catch called")

        let promise = Promise<Bool>()
        promise.then {
            XCTAssertEqual($0, true)
            throw Error.test
        }.catch {
            XCTAssertEqual($0 as? Error, .test)
            exp.fulfill()
        }
        promise.fulfill(with: true)
        waitForExpectations(timeout: 30)
    }

    func testTry() {
        let then = expectation(description: "then called")

        let promise = Promise
            .try { Promise<Void>() }
            .then { _ in
                then.fulfill()
            }
            .catch {
                XCTFail("unexpected error: \($0)")
        }
        promise.fulfill(with: ())
        waitForExpectations(timeout: 30)
    }

    func testTryThrows() {
        let exp = expectation(description: "catch called")
        let promise = Promise
            .try { () -> Promise<Void> in
                throw Error.test
            }
            .then {
                XCTFail("unexpected success: \($0)")
            }
            .catch {
                XCTAssertEqual($0 as? Error, .test)
                exp.fulfill()
        }
        promise.fulfill(with: ())
        waitForExpectations(timeout: 30)
    }

}
