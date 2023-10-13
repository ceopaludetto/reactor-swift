import Foundation

class ConditionalVariable<T> {
  public var value: T? = nil
  private let group: DispatchGroup = .init()

  func dispatch(_ value: T) {
    group.enter()

    DispatchQueue.global().sync {
      self.value = value
      group.leave()
    }
  }

  func waitForValue(_ timeout: TimeInterval? = nil) -> T? {
    if case .timedOut = group.wait(timeout: timeout.toDispatchTime()) {
      return nil
    }

    return value
  }
}
