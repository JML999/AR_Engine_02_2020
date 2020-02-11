import Foundation

open class Scene {
    public var rootNode: Node
    public init(){
        rootNode = Node()
    }
    
    func update(deltaTime: Float){
        rootNode.update(deltaTime: deltaTime)
    }
}
