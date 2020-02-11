import MetalKit
import simd
import Foundation

class Background: EntityNode {
    
    let geometryNode = Node()
    var counter: Int = 1
    
    override func buildScene() {
        geometry = MeshGeometry(meshType: .Quad_Custom)
        geometryNode.geometry = geometry
        geometryNode.geometry?.setTexture(.flower)
        addChildNode(geometryNode)
    }
    
}
