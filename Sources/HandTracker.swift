import Foundation
import CoreGraphics
import Vision
import CoreMedia

public struct HandJoint {
    public let point: CGPoint
    public let confidence: Float
    
    public init(point: CGPoint, confidence: Float) {
        self.point = point
        self.confidence = confidence
    }
}

public struct HandLandmarks {
    public var wrist: HandJoint?
    
    public var thumbTip: HandJoint?
    public var thumbIP: HandJoint?
    public var thumbMP: HandJoint?
    public var thumbCMC: HandJoint?
    
    public var indexTip: HandJoint?
    public var indexDIP: HandJoint?
    public var indexPIP: HandJoint?
    public var indexMCP: HandJoint?
    
    public var middleTip: HandJoint?
    public var middleDIP: HandJoint?
    public var middlePIP: HandJoint?
    public var middleMCP: HandJoint?
    
    public var ringTip: HandJoint?
    public var ringDIP: HandJoint?
    public var ringPIP: HandJoint?
    public var ringMCP: HandJoint?
    
    public var littleTip: HandJoint?
    public var littleDIP: HandJoint?
    public var littlePIP: HandJoint?
    public var littleMCP: HandJoint?

    public init() {}
}

public final class HandTracker {
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    
    public init() {
        handPoseRequest.maximumHandCount = 1
    }
    
    public func processFrame(_ sampleBuffer: CMSampleBuffer) -> HandLandmarks? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        return processPixelBuffer(pixelBuffer)
    }
    
    public func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> HandLandmarks? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return nil
            }
            return extractLandmarks(from: observation)
        } catch {
            return nil
        }
    }
    
    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> HandLandmarks {
        var landmarks = HandLandmarks()
        
        let jointsToFetch: [(VNHumanHandPoseObservation.JointName, (inout HandLandmarks, HandJoint) -> Void)] = [
            (.wrist, { $0.wrist = $1 }),
            (.thumbTip, { $0.thumbTip = $1 }),
            (.thumbIP, { $0.thumbIP = $1 }),
            (.thumbMP, { $0.thumbMP = $1 }),
            (.thumbCMC, { $0.thumbCMC = $1 }),
            (.indexTip, { $0.indexTip = $1 }),
            (.indexDIP, { $0.indexDIP = $1 }),
            (.indexPIP, { $0.indexPIP = $1 }),
            (.indexMCP, { $0.indexMCP = $1 }),
            (.middleTip, { $0.middleTip = $1 }),
            (.middleDIP, { $0.middleDIP = $1 }),
            (.middlePIP, { $0.middlePIP = $1 }),
            (.middleMCP, { $0.middleMCP = $1 }),
            (.ringTip, { $0.ringTip = $1 }),
            (.ringDIP, { $0.ringDIP = $1 }),
            (.ringPIP, { $0.ringPIP = $1 }),
            (.ringMCP, { $0.ringMCP = $1 }),
            (.littleTip, { $0.littleTip = $1 }),
            (.littleDIP, { $0.littleDIP = $1 }),
            (.littlePIP, { $0.littlePIP = $1 }),
            (.littleMCP, { $0.littleMCP = $1 }),
        ]
        
        for (jointName, assigner) in jointsToFetch {
            if let point = try? observation.recognizedPoint(jointName), point.confidence > 0.3 {
                assigner(&landmarks, HandJoint(point: point.location, confidence: point.confidence))
            }
        }
        
        return landmarks
    }
}
