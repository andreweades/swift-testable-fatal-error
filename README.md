# swift-testable-fatal-error

## TestableFatalError

```swift
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
 ```
## NB
Testing Swift standard library does not seem to work as it must be ensuring that it calls `Swift.fatalError` preventing `expectFatalError()` from replacing the fatalError implementation.
