import Foundation

final class Scheduler {
    let queue = DispatchQueue(label: "habitat.scheduler")
    let operationQueue: OperationQueue
    let timer: DispatchSourceTimer
    var plans: [Plan] = []
    var root: URL
    private(set) var state: State = .idle {
        didSet {
            NSLog("New state: %@", String(describing: state))
        }
    }
    
    init(root: URL, plans: [Plan]) {
        self.root = root // TODO: Not allowed to be a relative path. Triggers errors with Git.
        self.plans = plans
        operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.scheduleRepeating(deadline: .now() + 10, interval: .seconds(1 * 15), leeway: .seconds(60))
        timer.setEventHandler { [weak self] in
            guard let scheduler = self else {
                return
            }
            scheduler.updateIfNeeded()
        }
        timer.resume()
    }
    
    /// Perform deployment of all plans that need it
    ///
    /// **Note**: Has to be performed on `Scheduler.queue`.
    private func updateIfNeeded() {
        guard state == .idle else { // TODO: Be a little smarter about this.
            return
        }

        let updates = plans.filter { $0.needsUpdate }
                           .flatMap { $0.makeUpdate(AssetLocator(root: root, plan: $0)) }
        guard !updates.isEmpty else {
            return
        }
        let completion = BlockOperation {
            self.state = .idle
        }
        updates.forEach { completion.addDependency($0) }
        state = .updating
        operationQueue.addOperation(includingDependencies: completion)
        // TODO: Handle errors in operation and dependencies.
    }
    
    private func update(for plan: Plan) -> Operation? {
        return plan.makeUpdate(AssetLocator(root: root, plan: plan))
    }
}

extension Scheduler {
    
    enum State {
        case idle
        case updating
    }
}
