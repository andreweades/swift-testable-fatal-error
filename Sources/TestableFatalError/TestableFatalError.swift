// TestableFatalError
// Andrew Eades, January 2022

import Foundation
import XCTest

// NB Testing Swift standard library does not seem to work
// as it must be ensuring that it calls Swift.fatalError
// preventing expectFatalError() from replacing the fatalError implementation

/* Example test
 func test_empty_MyCollection_raises_fatalError_when_accessing_element_before_startIndex() {
 let collection: MyCollection = []
 
 expectFatalError {
 // closure that should produce a fatalError()
 let _ = collection.index(before: collection.startIndex)
 } withMessage: {message, error in
 
 if let message = message {
 XCTAssertEqual(
 message,
 "Index out of bounds."
 )
 }
 
 if let error = error {
 XCTFail("\(error)")
 }
 }
 }
 */

public struct TestableFatalError {
  private static let _fatalError = { Swift.fatalError($0, file: $1, line: $2) }
  
  static var testsRunning: Bool { semaphore > 0 }
  static var semaphore = 0
  
  static var fatalError: (String, StaticString, UInt) -> Never = _fatalError
  
  public static func onFatalError(perform closure: @escaping (String, StaticString, UInt) -> Never) {
    TestableFatalError.semaphore += 1
    fatalError = closure
  }
  
  public static func fatalErrorDidComplete() {
    fatalError = _fatalError
    TestableFatalError.semaphore -= 1
  }
}

extension XCTestCase {
  public func expectFatalError(
    timeout: TimeInterval = 0.1,
    testCase: @escaping () -> Void,
    withMessage didRaiseFatalErrorWithMessage: @escaping (String?, Error?) -> Void
  ) {
    
    let expectation = expectation(description: "expected fatalError()")
    var actual: String? = nil
    
    TestableFatalError.onFatalError { message, _, _ in
      actual = message
      expectation.fulfill()
      _neverReturn()
    }
    
    DispatchQueue.global(qos: .userInteractive).async {
      testCase()
    }
    
    waitForExpectations(timeout: timeout) {error in
      
      didRaiseFatalErrorWithMessage(actual, error)
      
      TestableFatalError.fatalErrorDidComplete()
    }
  }
}

public func fatalError(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) -> Never {
  
  if TestableFatalError.testsRunning {
    TestableFatalError.fatalError(message(), file, line)
    // call to _fatalHang below is commented out to get rid of "Will never be executed" warning
    // _fatalHang(unless: !TestableFatalError.areTestsRunning)
  } else {
    fatalError(message(), file: file, line: line)
  }
  // this is here to get rid of "Will never be executed" warning above
  _fatalHang(unless: !TestableFatalError.testsRunning)
}

public func _fatalHang(unless predicate: @autoclosure () -> Bool = { false }() ) {
  guard !predicate() else { return }
  _neverReturn()
}

public func _neverReturn() -> Never {
  while true {
    /* loop forever */
  }
}

