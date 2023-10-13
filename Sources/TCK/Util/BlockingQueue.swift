import Foundation

class BlockingQueue<T> {
  private var array: [T] = []
  private var group: DispatchGroup = .init()

  func add(_ element: T) {
    group.enter()

    DispatchQueue.global().sync {
      array.append(element)
      group.leave()
    }
  }

  func take(_ timeout: TimeInterval? = nil) -> T? {
    if case .timedOut = group.wait(timeout: timeout.toDispatchTime()) {
      return nil
    }

    if array.isEmpty {
      return nil
    }

    return array.removeFirst()
  }

  func takeAll(_ timeout: TimeInterval? = nil) -> [T] {
    if case .timedOut = group.wait(timeout: timeout.toDispatchTime()) {
      return []
    }

    var elements: [T] = []
    while !array.isEmpty {
      elements.append(array.removeFirst())
    }

    return elements
  }
}
