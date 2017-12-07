//
//  FunctionalTests.swift
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

class FunctionalTests: XCTestCase {

    fileprivate func f(a: A) -> B {
        XCTAssertEqual(a, .a)
        return .b
    }

    fileprivate func g(b: B) -> C {
        XCTAssertEqual(b, .b)
        return .c
    }

    func testPipe() {
        XCTAssertEqual(pipe(.a, f), .b)
    }

    func testInlinePipe() {
        XCTAssertEqual(.a |> f, .b)
    }

    func testCompose() {
        XCTAssertEqual(compose(self.f, self.g)(.a), .c)
    }

    func testInlineCompose() {
        XCTAssertEqual(.a |> f >>> g, .c)
    }

}

extension FunctionalTests {

    private func f() -> (A) -> B {
        XCTFail("Should not be evaluated")
        return f
    }

    private func g() -> (B) -> C {
        XCTFail("Should not be evaluated")
        return g
    }

    func testComposeAutoclosures() {
        _ = compose(self.f(), self.g())
    }

}

extension FunctionalTests {

    func testIdentity() {
        XCTAssertEqual(identity(.a), A.a)
    }

    func testIgnore() {
        let _: (A) -> Void = ignore
        ignore(A.a)
    }

}

extension FunctionalTests {

    fileprivate func f(a: A, b: B) -> C {
        XCTAssertEqual(a, .a)
        XCTAssertEqual(b, .b)
        return .c
    }

    private func f2() -> (A, B) -> C {
        XCTFail("Should not be evaluated")
        return f
    }

    func testCurry2() {
        XCTAssertEqual(curry(self.f)(.a)(.b), .c)
        _ = curry(self.f2())
    }

}

extension FunctionalTests {

    fileprivate func f(a: A, b: B, c: C) -> D {
        XCTAssertEqual(a, .a)
        XCTAssertEqual(b, .b)
        XCTAssertEqual(c, .c)
        return .d
    }

    private func f3() -> (A, B, C) -> D {
        XCTFail("Should not be evaluated")
        return f
    }

    func testCurry3() {
        XCTAssertEqual(curry(self.f)(.a)(.b)(.c), .d)
        _ = curry(self.f3())
    }

}

extension FunctionalTests {

    fileprivate func f(a: A, b: B, c: C, d: D) -> E {
        XCTAssertEqual(a, .a)
        XCTAssertEqual(b, .b)
        XCTAssertEqual(c, .c)
        XCTAssertEqual(d, .d)
        return .e
    }

    private func f4() -> (A, B, C, D) -> E {
        XCTFail("Should not be evaluated")
        return f
    }

    func testCurry4() {
        XCTAssertEqual(curry(self.f)(.a)(.b)(.c)(.d), .e)
        _ = curry(self.f4())
    }

}

extension FunctionalTests {

    private func vf() -> B { return .b }

    private func f1() -> () -> B {
        XCTFail("Should not be evaluated")
        return vf
    }

    func testUncurry1() {
        let f: (A) -> B = uncurry(self.vf)
        XCTAssertEqual(f(.a), .b)
        let _: (A) -> B = uncurry(self.f1())
    }

}

extension FunctionalTests {

    private func curryf(a: A) -> (B) -> C {
        XCTAssertEqual(a, .a)
        return {
            XCTAssertEqual($0, .b)
            return .c
        }
    }

    fileprivate func f2() -> (A) -> (B) -> C {
        XCTFail("Should not be evaluated")
        return curryf
    }

    func testUncurry2() {
        XCTAssertEqual(uncurry(self.curryf)(.a, .b), .c)
        _ = uncurry(self.f2())
    }

    func testReverse2() {
        XCTAssertEqual(reverse(self.curryf)(.b)(.a), .c)
        _ = reverse(self.f2())
    }

}

extension FunctionalTests {

    private func f(a: A) -> (B) -> (C) -> D {
        XCTAssertEqual(a, .a)
        return {
            XCTAssertEqual($0, .b)
            return {
                XCTAssertEqual($0, .c)
                return .d
            }
        }
    }

    fileprivate func f3() -> (A) -> (B) -> (C) -> D {
        XCTFail("Should not be evaluated")
        return f
    }

    func testUncurry3() {
        XCTAssertEqual(uncurry(self.f)(.a, .b, .c), .d)
        _ = uncurry(self.f3())
    }

    func testReverse3() {
        XCTAssertEqual(reverse(self.f)(.c)(.b)(.a), .d)
        _ = reverse(self.f3())
    }

}

extension FunctionalTests {

    private func f(a: A) -> (B) -> (C) -> (D) -> E {
        XCTAssertEqual(a, .a)
        return {
            XCTAssertEqual($0, .b)
            return {
                XCTAssertEqual($0, .c)
                return {
                    XCTAssertEqual($0, .d)
                    return .e
                }
            }
        }
    }

    fileprivate func f4() -> (A) -> (B) -> (C) -> (D) -> E {
        XCTFail("Should not be evaluated")
        return f
    }

    func testUncurry4() {
        XCTAssertEqual(uncurry(self.f)(.a, .b, .c, .d), .e)
        _ = uncurry(self.f4())
    }

    func testReverse4() {
        XCTAssertEqual(reverse(self.f)(.d)(.c)(.b)(.a), .e)
        _ = reverse(self.f4())
    }

}

extension FunctionalTests {

    func testReverse() {
        XCTAssertEqual(reverse(self.f)(.b, .a), .c)
        XCTAssertEqual(reverse(self.f)(.c, .b, .a), .d)
        XCTAssertEqual(reverse(self.f)(.d, .c, .b, .a), .e)
        let _ = reverse(self.f2())
        let _ = reverse(self.f3())
        let _ = reverse(self.f4())
    }

}
