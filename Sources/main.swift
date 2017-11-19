import Vapor
import LeafProvider
import Foundation
import Git2Swift

let view = LeafRenderer(viewsDir: "./Resources/Views/")
let drop = try Droplet(view: view)

var plans: [Plan] = []

drop.get() { req in
    let serialized = plans.map {
        return ["name": $0.name]
    }
    let parameters = ["plans": serialized]
    return try drop.view.make("PlanList", parameters)
}

drop.get("new-plan") { req in
    return try drop.view.make("NewPlan")
}

drop.get("plan", Int.parameter) { req in
    let index = try req.parameters.next(Int.self)
    let plan = plans[index]
    let environment = plan.environment.map({ "\($0)=\($1)" }).joined(separator: "\n")
    let parameters = [
        "index": "\(index)",
        "name": plan.name,
        "repositoryURL": plan.repository.url.absoluteString,
        "branch": plan.repository.branch,
        "launch": plan.launch.url.absoluteString,
        "build": plan.build.url.absoluteString,
        "environment": environment,
    ]
    return try drop.view.make("Plan", parameters)
}

drop.post("plan") { req in
    guard let name = req.data["name"]?.string else {
        throw Abort.badRequest
    }
    guard let repositoryURLText = req.data["repositoryURL"]?.string, let repositoryURL = URL(string: repositoryURLText) else {
        throw Abort.badRequest
    }
    guard let branch = req.data["branch"]?.string else {
        throw Abort.badRequest
    }
    guard let launch = req.data["launch"]?.string, let launchURL = URL(string: launch) else {
        throw Abort.badRequest
    }
    guard let build = req.data["build"]?.string, let buildURL = URL(string: build) else {
        throw Abort.badRequest
    }
    guard let environmentText = req.data["environment"]?.string else {
        throw Abort.badRequest
    }
    
    let lines = environmentText.split(separator: "\n")
    let pairs = lines.flatMap { (line) -> (String, String)? in
        let pair = line.split(separator: "=")
        guard pair.count == 2 else {
            return nil
        }
        
        return (String(pair[0]), String(pair[1]))
    }
    let environment = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    
    let repository = Repository(url: repositoryURL, branch: branch)
    let plan = Plan(name: name,
                    repository: repository,
                    build: Script(url: launchURL),
                    launch: Script(url: buildURL),
                    environment: environment)
    
    plans.append(plan)
    
    return Response(redirect: "/")
}

drop.post("plan", Int.parameter) { req in
    let index = try req.parameters.next(Int.self)
    
    guard let name = req.data["name"]?.string else {
        throw Abort.badRequest
    }
    guard let repositoryURLText = req.data["repositoryURL"]?.string, let repositoryURL = URL(string: repositoryURLText) else {
        throw Abort.badRequest
    }
    guard let branch = req.data["branch"]?.string else {
        throw Abort.badRequest
    }
    guard let launch = req.data["launch"]?.string, let launchURL = URL(string: launch) else {
        throw Abort.badRequest
    }
    guard let build = req.data["build"]?.string, let buildURL = URL(string: build) else {
        throw Abort.badRequest
    }
    guard let environmentText = req.data["environment"]?.string else {
        throw Abort.badRequest
    }
    
    let lines = environmentText.split(separator: "\n")
    let pairs = lines.flatMap { (line) -> (String, String)? in
        let pair = line.split(separator: "=")
        guard pair.count == 2 else {
            return nil
        }
        
        return (String(pair[0]), String(pair[1]))
    }
    let environment = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    
    let repository = Repository(url: repositoryURL, branch: branch)
    let plan = Plan(name: name,
                    repository: repository,
                    build: Script(url: launchURL),
                    launch: Script(url: buildURL),
                    environment: environment)
    
    plans[index] = plan
    
    return Response(redirect: "/plan/\(index)")
}

drop.delete("plan", Int.parameter) { req in
    let index = try req.parameters.next(Int.self)
    plans.remove(at: index)
    return Response(redirect: "/")
}

drop.get("hello") { req in
    let remote = URL(string: "https://github.com/PixelPirate/CLibgit2.git")!
    let path = URL(string: "/Users/pA/CLibgit2")!
    
    print("clone ...")
    let man = RepositoryManager()
    let rpo = try man.cloneRepository(from: remote, at: path, progress: nil)
    print("fetch ...")
    try rpo.remotes.get(name: "origin").fetch()
    
    return try drop.view.make("hello", ["name": "Tim"])
}

try drop.run()
