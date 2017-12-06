//
//  RailwayTests.swift
//  FunKitTests
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

import XCTest

@testable import FunKit

class RailwayTests: XCTestCase {

    fileprivate func succeed(a: A) -> Result<B, C> {
        XCTAssertEqual(a, .a)
        return .success(.b)
    }

    fileprivate func notCalled(a: A) -> Result<B, C> {
        XCTFail("Method should not be reached")
        return .success(.b)
    }

    func testBind() {
        XCTAssertEqual(EquatableResult(bind(self.succeed)(.success(.a))), .success(.b))
        XCTAssertEqual(EquatableResult(bind(self.notCalled)(.failure(.c))), .failure(.c))
    }

    func testInfixBind() {
        XCTAssertEqual(EquatableResult(.success(.a) >>>= self.succeed), .success(.b))
        XCTAssertEqual(EquatableResult(.failure(.c) >>>= self.notCalled), .failure(.c))
    }

}

extension RailwayTests {

    private func succeed2(b: B) -> Result<D, C> {
        XCTAssertEqual(b, .b)
        return .success(.d)
    }

    private func fail(a: A) -> Result<B, C> {
        XCTAssertEqual(a, .a)
        return .failure(.c)
    }

    private func notCalled2(b: B) -> Result<D, C> {
        XCTFail("Method should not be reached")
        return .success(.d)
    }

    private func fail2(b: B) -> Result<D, C> {
        XCTAssertEqual(b, .b)
        return .failure(.c)
    }

    func testInfixComposedBind() {
        XCTAssertEqual(EquatableResult(.a |> self.succeed >=> self.succeed2),   .success(.d))
        XCTAssertEqual(EquatableResult(.a |> self.fail    >=> self.notCalled2), .failure(.c))
        XCTAssertEqual(EquatableResult(.a |> self.succeed >=> self.fail2),      .failure(.c))
    }

}

extension RailwayTests {

    private func succeed3(a: A) -> B {
        XCTAssertEqual(a, .a)
        return .b
    }

    private func notCalled3() -> (A) -> B {
        XCTFail("Method should not be reached")
        return succeed3
    }

    func testTurnout() {
        XCTAssertEqual(EquatableResult<B, C>(turnout(self.succeed3)(.a)), .success(.b))
        let _: (A) -> Result<B, C> = turnout(self.notCalled3())
    }

}

extension RailwayTests {

    private func notCalled7() -> (B) -> Result<A, C> {
        XCTFail("Method should not be reached")
        return fail3
    }

    private func fail3(b: B) -> Result<A, C> {
        XCTAssertEqual(b, .b)
        return .success(.a)
    }

    private func fail5(b: B) -> Result<A, C> {
        XCTAssertEqual(b, .b)
        return .failure(.c)
    }

    private func testTurnin() {
        XCTAssertEqual(EquatableResult(turnin(self.notCalled7())(.success(.a))), .success(.a))
        XCTAssertEqual(EquatableResult(turnin(self.fail3)(.failure(.b))), .success(.a))
        XCTAssertEqual(EquatableResult(turnin(self.fail5)(.failure(.b))), .failure(.c))
        _ = turnin(self.notCalled7())
    }

}

extension RailwayTests {

    private func notCalled8() -> (B) -> A {
        XCTFail("Method should not be reached")
        return fail6
    }

    private func fail6(b: B) -> A {
        XCTAssertEqual(b, .b)
        return .a
    }

    private func testTurnin2() {
        XCTAssertEqual(turnin(self.notCalled8())(.success(.a)), .a)
        XCTAssertEqual(turnin(self.fail6)(.failure(.b)), .a)
        _ = turnin(self.notCalled8())
    }

}

extension RailwayTests {

    private func testTee() {
        XCTAssertEqual(tee(self.succeed3)(.a), .a)
        _ = tee(self.notCalled3())
    }

}

enum Error: Swift.Error { case error }

extension RailwayTests {

    private func succeed4(a: A) throws -> B {
        XCTAssertEqual(a, .a)
        return .b
    }

    private func throwing(a: A) throws -> B {
        XCTAssertEqual(a, .a)
        throw Error.error
    }

    private func notCalled4() -> (A) throws -> B {
        XCTFail("Method should not be reached")
        return succeed4
    }

    func testTeeThows() {
        XCTAssertNoThrow(XCTAssertEqual(try tee(self.succeed4)(.a), .a))
        XCTAssertThrowsError(try tee(self.throwing)(.a))
        _ = tee(self.notCalled4())
    }

}

extension RailwayTests {

    private func fail4(c: C) -> D {
        XCTAssertEqual(c, .c)
        return .d
    }

    private func notCalled5() -> (C) -> D {
        XCTFail("Method should not be reached")
        return fail4
    }

    func testBimap() {
        XCTAssertEqual(EquatableResult(bimap(self.succeed3, self.notCalled5())(.success(.a))), .success(.b))
        XCTAssertEqual(EquatableResult(bimap(self.notCalled3(), self.fail4)(.failure(.c))), .failure(.d))
        _ = bimap(self.notCalled3(), self.notCalled5())
    }

    func testMap() {
        XCTAssertEqual(EquatableResult<B, C>(map(self.succeed3)(.success(.a))), .success(.b))
        XCTAssertEqual(EquatableResult<B, C>(map(self.notCalled3())(.failure(.c))), .failure(.c))
    }

}

extension RailwayTests {

    func testTryCatch() {
        switch tryCatch(self.succeed4)(.a) {
        case let .success(b): XCTAssertEqual(b, .b)
        case let .failure(e): XCTFail("Unexpected error thrown: \(e)")
        }

        switch tryCatch(self.throwing)(.a) {
        case let .success(b): XCTFail("Unexpected result: \(b)")
        case let .failure(e): XCTAssert(e is Error)
        }

        _ = tryCatch(self.notCalled4())
    }

}

extension RailwayTests {

    func unwrapA(a: A) -> B? {
        XCTAssertEqual(a, .a)
        return .b
    }

    func unwrapNil(a: A) -> B? {
        XCTAssertEqual(a, .a)
        return nil
    }

    private func notCalled6() -> (A) -> B? {
        XCTFail("Method should not be reached")
        return unwrapA
    }

    func testUnwrap() {
        XCTAssertEqual(EquatableResult<A, Nil>(unwrap(.a)), .success(.a))
        XCTAssertEqual(EquatableResult<A, Nil>(unwrap(nil)), .failure(.nil))
        XCTAssertEqual(EquatableResult(unwrap(self.unwrapA)(.a)), .success(.b))
        XCTAssertEqual(EquatableResult(unwrap(self.unwrapNil)(.a)), .failure(.nil))
        let _: (A) -> Result<B, Nil> = unwrap(self.notCalled6())
    }

}
