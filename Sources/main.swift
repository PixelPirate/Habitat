import Vapor
import LeafProvider
import Foundation
import Git2Swift

let view = LeafRenderer(viewsDir: "./Resources/Views/")
let drop = try Droplet(view: view)
let app = App(root: URL(string: "~/app")!)

drop.get(handler: app.index)
drop.get("new-plan", handler: app.newPlan)
drop.get("plan", Int.parameter, handler: app.getPlan)
drop.post("plan", handler: app.postPlan)
drop.post("plan", Int.parameter, handler: app.updatePlan)
drop.delete("plan", Int.parameter, handler: app.deletePlan)

try drop.run()
