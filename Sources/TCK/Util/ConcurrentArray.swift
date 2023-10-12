import Foundation

class ConcurrentArray<T> {
  private var queue: DispatchQueue = .init(
    label: "com.reactor.tck.concurrent-array", attributes: .concurrent)

  private var array: [T] = []

  func append(_ element: T) {
    queue.async(flags: .barrier) {
      self.array.append(element)
    }
  }

  func removeFirst() -> T {
    return queue.sync {
      self.array.removeFirst()
    }
  }

  func isEmpty() -> Bool {
    return queue.sync {
      self.array.isEmpty
    }
  }
}
