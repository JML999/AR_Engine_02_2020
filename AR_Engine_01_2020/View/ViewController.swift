import UIKit
import MetalKit
import ARKit
import MultipeerConnectivity

class ViewController: UIViewController, ARMTKViewDelegate {

    @IBOutlet weak var sendWorldMap: RoundedButton!
    @IBOutlet weak var recordButton: RoundedButton!
    
    var device: MTLDevice!
    var bufferAllocator: BufferAllocator!
    var arView: ARMTKView!
    
    var trackingStatusLabel: UILabel!
    var multipeerSession: MultipeerSession!
    
    var tapRecognizer: UITapGestureRecognizer!
    var modelGeometry: Geometry?
    var background: Background?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            device = defaultDevice
        } else {
            fatalError("Metal Device is not supported")
        }
        
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        bufferAllocator = BufferAllocator(device: device)
        
        arView = ARMTKView(frame: view.bounds, device: device)
        arView.colorPixelFormat = .bgra8Unorm
        arView.depthStencilPixelFormat = .depth32Float
        arView.rendererDelegate = self
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(arView)
        view.addSubview(sendWorldMap)
        view.addSubview(recordButton)
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureDidRecognize))
        arView.addGestureRecognizer(tapRecognizer)
        
        self.background = Background(bufferAllocator: bufferAllocator)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let sessionConfiguration = ARWorldTrackingConfiguration()
        sessionConfiguration.planeDetection = .horizontal
        sessionConfiguration.frameSemantics = .personSegmentationWithDepth
        arView.session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        arView.session.pause()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera){
        if trackingStatusLabel == nil {
            trackingStatusLabel = UILabel()
            trackingStatusLabel.translatesAutoresizingMaskIntoConstraints = false
            trackingStatusLabel.textAlignment = .center
            trackingStatusLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
            trackingStatusLabel.textColor = UIColor.white
            trackingStatusLabel.font = UIFont.boldSystemFont(ofSize: 16)
            trackingStatusLabel.numberOfLines = 2
            view.addSubview(trackingStatusLabel)
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(20)-[label]-(20)-|", options: [], metrics: nil,
                                                                   views: ["label" : trackingStatusLabel]))
            view.addConstraint(NSLayoutConstraint(item: trackingStatusLabel, attribute: .top, relatedBy: .equal,
                                                      toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 20))
        }
        
        trackingStatusLabel.isHidden = false
        
        switch camera.trackingState {
        case .normal:
            trackingStatusLabel.isHidden = true
        case .notAvailable:
            trackingStatusLabel.text = "Tracking is not available"
        case .limited(let reason):
            switch reason {
            case .initializing:
                trackingStatusLabel.text = "Tracking is limited:\nInitializing"
            case .excessiveMotion:
                trackingStatusLabel.text = "Tracking is limited:\nExcessive motion"
            case .insufficientFeatures:
                trackingStatusLabel.text = "Tracking is limited:\nInsufficient features"
            case .relocalizing:
                trackingStatusLabel.text = "Tracking is limited:\nRelocalizing..."
            @unknown default:
                fatalError("Unknown case")
            }
        }
    }
    
    func renderer(_: SceneRenderer, didAddNode node: Node, forAnchor anchor: ARAnchor){
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeGeometry = planeAnchor.geometry
            node.geometry = Plane(vertices: planeGeometry.vertices,
                                  texCoords: planeGeometry.textureCoordinates,
                                  indices: planeGeometry.triangleIndices,
                                  bufferAllocator: bufferAllocator)
            let material = node.geometry?.elements.first?.material
            material?.diffuse.contents = UIColor.white
            material?.fillMode = .wireframe
        } else {
            let backgroundEntity = background
            node.addChildNode(backgroundEntity!)
        }
    }
    
    func renderer(_: SceneRenderer, didUpdateNode node: Node, forAnchor anchor: ARAnchor) {
       if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeGeometry = planeAnchor.geometry
            node.geometry = Plane(vertices: planeGeometry.vertices,
                                  texCoords: planeGeometry.textureCoordinates,
                                  indices: planeGeometry.triangleIndices,
                                  bufferAllocator: bufferAllocator)
            let material = node.geometry?.elements.first?.material
            material?.diffuse.contents = UIColor.white
            material?.fillMode = .wireframe
        }
    }

    
    @objc func tapGestureDidRecognize(_ sender: UIGestureRecognizer) {
        let session = arView.session
        if let firstHit = arView.hitTest(sender.location(in: arView), types: [.estimatedHorizontalPlane]).first {
            let anchor = ARAnchor(transform: firstHit.worldTransform)
                session.add(anchor: anchor)
                    
                // Send the anchor info to peers, so they can place the same content.
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                    else { fatalError("can't encode anchor") }
                    self.multipeerSession.sendToAllPeers(data)
            }
    }
    
    // MARK: - Recorder
    @IBAction func touchDownRecord(_ button: UIButton) {
        arView.recorder?.startRecording()
    }
    
    
    @IBAction func touchUpEndRecord(_ button: UIButton) {
        arView.recorder?.endRecording()
    }
    
    // MARK: - Multiuser shared session
    
    @IBAction func sendMap(_ button: UIButton) {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    print("Error: \(error!.localizedDescription)"); return }
           guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
        print("Map sent")
    }
    
    var mapProvider: MCPeerID?
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.initialWorldMap = worldMap
                configuration.frameSemantics = .personSegmentationWithDepth
                arView.session.run(configuration, options: [.resetTracking])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                arView.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    
}
