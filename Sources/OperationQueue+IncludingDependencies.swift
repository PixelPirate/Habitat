import Foundation

extension OperationQueue {
    func addOperation(includingDependencies operation: Operation) {
        addOperation(operation)
        for dependency in operation.dependencies {
            addOperation(includingDependencies: dependency)
        }
    }
}
