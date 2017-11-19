import Vapor
import Foundation

final class App {
    let scheduler: Scheduler
    
    init(root: URL) {
        self.scheduler = Scheduler(root: root, plans: [])
    }
    
    func index(_: Request) throws -> ResponseRepresentable {
        let serialized = scheduler.plans.map {
            return ["name": $0.name]
        }
        let parameters = ["plans": serialized]
        return try drop.view.make("PlanList", parameters)
    }
    
    func newPlan(_: Request) throws -> ResponseRepresentable {
        return try drop.view.make("NewPlan")
    }
    
    func getPlan(_ req: Request) throws -> ResponseRepresentable {
        let index = try req.parameters.next(Int.self)
        let plan = scheduler.plans[index]
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
    
    func postPlan(_ req: Request) throws -> ResponseRepresentable {
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
        
        scheduler.plans.append(plan)
        
        return Response(redirect: "/")
    }
    
    func updatePlan(_ req: Request) throws -> ResponseRepresentable {
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
        
        scheduler.plans[index] = plan
        
        return Response(redirect: "/plan/\(index)")
    }
    
    func deletePlan(_ req: Request) throws -> ResponseRepresentable {
        let index = try req.parameters.next(Int.self)
        scheduler.plans.remove(at: index)
        return Response(redirect: "/")
    }
}
