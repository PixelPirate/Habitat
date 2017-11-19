import Vapor
import LeafProvider
import Foundation
import Git2Swift

let view = LeafRenderer(viewsDir: "./Resources/Views/")
let drop = try Droplet(view: view)

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
