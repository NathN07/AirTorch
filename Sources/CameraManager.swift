import Foundation
import AVFoundation
import CoreMedia

public protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

public final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public weak var delegate: CameraManagerDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoOutputQueue = DispatchQueue(label: "com.gemini.AirTouch.videoQueue", qos: .userInteractive)
    private var isConfigured = false
    
    public override init() {
        super.init()
    }
    
    public func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    public func startSession() {
        requestPermission { [weak self] granted in
            guard let self = self, granted else {
                print("[CameraManager] Camera permission not granted")
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.isConfigured {
                    self.setupCaptureSession()
                }
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("[CameraManager] Capture session started")
                }
            }
        }
    }
    
    public func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("[CameraManager] Capture session stopped")
            }
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        
        guard let camera = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video) else {
            print("[CameraManager] No camera found")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("[CameraManager] Failed to create device input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
        isConfigured = true
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}
