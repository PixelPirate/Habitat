import Foundation

enum Result<Value> {
    case Ok(Value)
    case Error(Error)

    func ok(or: @autoclosure () -> Value) -> Value {
        switch self {
        case .Ok(let value): return value
        case .Error: return or()
        }
    }

    var value: Value? {
        switch self {
        case .Ok(let value): return value
        case .Error: return nil
        }
    }
}

extension ResultOperation {
    enum Error: Swift.Error {
        case didNotStart
        case undefinedError
        case noExecutionBlock
    }
}

final class ResultOperation<Value>: AsynchronousOperation {
    var result: Result<Value> = .Error(Error.didNotStart)
    var block: (() throws -> Value)?

    convenience init(_ block: @escaping () throws -> Value) {
        self.init()
        self.block = block
    }

    func setExecutionBlock(_ block: @escaping () throws -> Value) {
        self.block = block
    }

    override func execute() {
        result = .Error(Error.undefinedError)

        guard let block = block else {
            result = .Error(Error.noExecutionBlock)
            return
        }

        do {
            result = .Ok(try block())
        } catch let error {
            result = .Error(error)
        }

        finish()
    }
}

open class AsynchronousOperation: Operation {
    private let stateQueue = DispatchQueue(
        label: "com.calebd.operation.state",
        attributes: .concurrent)

    enum State {
        case ready, executing, finished
        var keyPath: String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }

    private var rawState = State.ready
    private(set) var state: State {
        set {
            let oldValue = state
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: oldValue.keyPath)
            stateQueue.sync(
                flags: .barrier,
                execute: { rawState = newValue })
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
        get {
            return stateQueue.sync(execute: { rawState })
        }
    }


    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }

    public final override var isExecuting: Bool {
        return state == .executing
    }

    public final override var isFinished: Bool {
        return state == .finished
    }

    public final override var isAsynchronous: Bool {
        return true
    }

    public override final func start() {
        super.start()

        if isCancelled {
            finish()
            return
        }

        state = .executing
        execute()
    }


    // MARK: - Public
    /// Subclasses must implement this to perform their work and they must not
    /// call `super`. The default implementation of this function throws an
    /// exception.
    open func execute() {
        fatalError("Subclasses must implement `execute`.")
    }

    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        state = .finished
    }
}
