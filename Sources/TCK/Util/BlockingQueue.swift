import Foundation

class BlockingQueue<T> {
  private let array: ConcurrentArray<T> = .init()
  private let semaphore: DispatchSemaphore = .init(value: 0)

  func add(_ element: T) {
    array.append(element)
    semaphore.signal()
  }

  func take(_ timeout: DispatchTime = .distantFuture) -> T? {
    if case .timedOut = semaphore.wait(timeout: timeout) {
      return nil
    }

    return array.removeFirst()
  }

  func takeAll(_ timeout: DispatchTime = .distantFuture) -> [T] {
    if case .timedOut = semaphore.wait(timeout: timeout) {
      return []
    }

    var elements: [T] = []
    while !array.isEmpty() {
      elements.append(array.removeFirst())
    }

    return elements
  }
}
