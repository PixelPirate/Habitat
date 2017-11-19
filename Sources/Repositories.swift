import Foundation
import Git2Swift

final class Config: Codable {
    var plans: [Plan] = []
}

enum HabitatError: Error {
    case missingParameter
    case notAGitRepository(URL)
    case invalidConfiguration
}

struct PlanBuilder {
    private var name: String?
    private var repository: Repository?
    private var head: Commit?
    private var build: Script?
    private var launch: Script?
    private var environment: [String: String]?

    mutating func set(name: String) {
        self.name = name
    }

    mutating func set(_ repository: Repository) {
        self.repository = repository
    }

    mutating func set(_ head: Commit) {
        self.head = head
    }

    mutating func set(build: Script) {
        self.build = build
    }

    mutating func set(launch: Script) {
        self.launch = launch
    }

    mutating func set(_ environment: [String: String]) {
        self.environment = environment
    }

    func make() throws -> Plan {
        guard let name = name, let repository = repository, let build = build, let launch = launch, let environment = environment else {
            throw HabitatError.missingParameter
        }

        let head = self.head.map(Plan.Head.init(from:)) ?? .notYetCheckedOut

        return Plan(name: name, repository: repository, head: head, build: build, launch: launch, environment: environment)
    }
}

extension Plan {

    enum Head: Codable {
        case notYetCheckedOut
        case commit(Commit)

        init(from commit: Commit) {
            self = .commit(commit)
        }

        var isNotYetCheckedOut: Bool {
            switch self {
            case .notYetCheckedOut:
                return true
            default:
                return false
            }
        }

        private enum CodingKeys: String, CodingKey {
            case notYetCheckedOut
            case commit
        }

        enum CodingError: Error {
            case decoding(String)
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            if values.contains(.notYetCheckedOut) {
                self = .notYetCheckedOut
                return
            }
            if let commit = try? values.decode(Commit.self, forKey: .commit) {
                self = .commit(commit)
                return
            }
            throw CodingError.decoding("Decoding error: \(dump(values))")
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .notYetCheckedOut:
                try container.encodeNil(forKey: .notYetCheckedOut)
            case .commit(let commit):
                try container.encode(commit, forKey: .commit)
            }
        }
    }
}

final class Scheduler {
    var plans: [Plan] = []
    var assetLocator: AssetLocator

    init(assetLocator: AssetLocator, plans: [Plan]) {
        self.assetLocator = assetLocator
        self.plans = plans
    }

    private func update(for plan: Plan) -> Operation? {
        return plan.makeUpdate(assetLocator)
    }
}

final class Plan: Codable {
    var name: String
    var repository: Repository
    var head: Head
    var build: Script
    var launch: Script
    var environment: [String: String]

    init(name: String, repository: Repository, head: Head, build: Script, launch: Script, environment: [String: String]) {
        self.name = name
        self.repository = repository
        self.head = head
        self.build = build
        self.launch = launch
        self.environment = environment
    }

    init(name: String, repository: Repository, build: Script, launch: Script, environment: [String: String]) {
        self.name = name
        self.repository = repository
        self.head = .notYetCheckedOut
        self.build = build
        self.launch = launch
        self.environment = environment
    }

    var needsUpdate: Bool {
        switch head {
        case .notYetCheckedOut:
            return true
        case .commit(let commit):
            return (try? commit.isMostRecent(in: repository)) ?? false
        }
    }

    func makeUpdate(_ assetLocator: AssetLocator) -> ResultOperation<()>? {
        let update = ResultOperation<()>()
        if head.isNotYetCheckedOut {
            let clone: ResultOperation<Git2Swift.Repository> = ResultOperation {
                let manager = RepositoryManager()
                return try manager.cloneRepository(from: self.repository.url, at: assetLocator.repository)
            }
            update.addDependency(clone)
        }
        update.setExecutionBlock {
            func open(repositoryFrom assetLocator: AssetLocator) throws -> Git2Swift.Repository? {
                let manager = RepositoryManager()
                let repo = try manager.openRepository(at: assetLocator.repository)
                return repo
            }

            let clone = update.dependencies.first as? ResultOperation<Git2Swift.Repository>
            guard let repo = try clone?.result.value ?? open(repositoryFrom: assetLocator) else {
                throw HabitatError.invalidConfiguration
            }
            try repo.head().checkout(branch: repo.branches.get(name: self.repository.branch))
        }
        return update
    }

    var buildProcess: Process {
        return process(for: build)
    }

    var launchProcess: Process {
        return process(for: launch)
    }

    private func process(for script: Script) -> Process {
        let process = script.process
        if #available(macOS 10.13, *) {
            process.currentDirectoryURL = repository.url
        } else {
            process.currentDirectoryPath = repository.url.absoluteString
        }
        var environment = ProcessInfo.processInfo.environment
        for (key, value) in self.environment {
            environment[key] = value
        }
        process.environment = environment

        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        return process
    }
}

struct Commit: Codable {
    let hash: String

    func isMostRecent(in repository: Repository) throws -> Bool {
        let manager = RepositoryManager()
        let repo = try manager.openRepository(at: repository.url)
        try repo.remotes.get(name: "origin").fetch()
        let branchTip = try repo.branches.get(name: repository.branch).targetCommit()
        let headTip = try repo.head().targetCommit()
        guard let branchTipSHA = branchTip.oid.sha(), let headTipSHA = headTip.oid.sha() else {
            throw HabitatError.notAGitRepository(repository.url)
        }
        return branchTipSHA == headTipSHA
    }
}

/// Provides paths for a specific plan.
struct AssetLocator {
    let prefix: String
    let repository: URL

    init?(plan: Plan) {
        self.init(prefix: plan.name)
    }

    init?(prefix: String) {
        self.prefix = prefix
        guard let repository = URL(string: "~/\(prefix)/Repository") else {
            return nil
        }
        self.repository = repository
    }
}

struct Repository: Codable {
    let url: URL
    let branch: String
    
    init(url: URL, branch: String = "master") {
        self.url = url
        self.branch = branch
    }

    func head(_ locator: AssetLocator) throws -> Commit {
        let manager = RepositoryManager()
        let repo = try manager.openRepository(at: locator.repository)
        let headRef = try repo.head()
        let commit = try headRef.targetCommit()
        guard let sha = commit.oid.sha() else {
            throw HabitatError.notAGitRepository(locator.repository)
        }
        return Commit(hash: sha)
    }
}

struct Script: Codable {
    let url: URL

    var process: Process {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [url.absoluteString]
        return process
    }
}
