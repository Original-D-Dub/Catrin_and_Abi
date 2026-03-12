import Flutter
import UIKit
import AVFoundation
import Vision

/// Flutter plugin that streams hand landmark data from the front camera
/// using Apple's Vision framework (VNDetectHumanHandPoseRequest, iOS 14+).
///
/// EventChannel: "com.catrinabi.bsl/hand_tracking"
///
/// Each event is a `List` of hand maps:
/// ```
/// [
///   {
///     "landmarks": [x0, y0, x1, y1, …, x20, y20],   // 42 doubles, normalised 0–1
///     "isLeftHand": true | false
///   },
///   …
/// ]
/// ```
/// Landmarks follow the MediaPipe 21-point convention:
///   0=wrist, 4=thumb tip, 8=index tip, 12=middle tip, 16=ring tip, 20=pinky tip.
///
/// Vision y-coordinates (origin bottom-left) are flipped to top-left origin
/// to match the Flutter/MediaPipe coordinate system.
@available(iOS 14.0, *)
class HandTrackingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
    AVCaptureVideoDataOutputSampleBufferDelegate {

    static let channelName = "com.catrinabi.bsl/hand_tracking"

    private var eventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "hand.tracking.session",
                                             qos: .userInitiated)
    private let videoQueue  = DispatchQueue(label: "hand.tracking.video",
                                            qos: .userInitiated)

    // Vision request – kept alive across frames.
    private lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
        return request
    }()

    /// Vision joint names in MediaPipe landmark order (indices 0–20).
    private let jointNames: [VNHumanHandPoseObservation.JointName] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP,  .indexPIP,  .indexDIP,  .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP,   .ringPIP,   .ringDIP,   .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip,
    ]

    // MARK: - FlutterPlugin

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = HandTrackingPlugin()
        let eventChannel = FlutterEventChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?,
                  eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        sessionQueue.async { self.startCapture() }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sessionQueue.async { self.stopCapture() }
        eventSink = nil
        return nil
    }

    // MARK: - Camera capture

    private func startCapture() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            DispatchQueue.main.async {
                self.eventSink?(FlutterError(
                    code: "CAMERA_UNAVAILABLE",
                    message: "Cannot access the front camera",
                    details: nil))
            }
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        output.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        captureSession = session
        session.startRunning()
    }

    private func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // .leftMirrored: correct orientation for the front camera in portrait mode.
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )
        do {
            try handler.perform([handPoseRequest])
        } catch {
            return
        }

        guard let observations = handPoseRequest.results else { return }

        if observations.isEmpty {
            DispatchQueue.main.async { self.eventSink?([]) }
            return
        }

        let hands: [[String: Any]] = observations.compactMap { observation in
            guard let flatLandmarks = try? extractLandmarks(from: observation) else {
                return nil
            }
            let isLeft = determineLeftHand(observation: observation,
                                           flatLandmarks: flatLandmarks)
            return ["landmarks": flatLandmarks, "isLeftHand": isLeft]
        }

        DispatchQueue.main.async { self.eventSink?(hands) }
    }

    // MARK: - Landmark extraction

    /// Returns 42 doubles [x0, y0, x1, y1, …] in MediaPipe order (indices 0–20).
    /// Vision's y-axis (origin bottom-left) is flipped to match top-left origin.
    private func extractLandmarks(
        from observation: VNHumanHandPoseObservation
    ) throws -> [Double] {
        var result = [Double]()
        result.reserveCapacity(42)
        for jointName in jointNames {
            let point = try observation.recognizedPoint(jointName)
            result.append(Double(point.x))
            result.append(Double(1.0 - point.y))   // flip y: Vision origin is bottom-left
        }
        return result
    }

    // MARK: - Handedness

    /// Returns true when the hand belongs to the player's left hand.
    ///
    /// On iOS 15+ uses Vision's `chirality` property. Front-camera images are
    /// mirrored, so Vision's `.left` chirality means the player's *right* hand
    /// and vice versa — hence the inversion.
    ///
    /// On iOS 14 falls back to the same geometric cross-product used by the
    /// Android service: wrist→index-MCP × wrist→pinky-MCP. A positive result
    /// in image coordinates (y downward, mirrored front camera) indicates the
    /// player's left hand.
    private func determineLeftHand(
        observation: VNHumanHandPoseObservation,
        flatLandmarks: [Double]
    ) -> Bool {
        if #available(iOS 15.0, *) {
            // Vision chirality is image-perspective (mirrored for front camera).
            return observation.chirality == .right
        }

        // iOS 14 fallback — indices in flatLandmarks:
        //   wrist     = landmark  0 → flat[0],  flat[1]
        //   indexMCP  = landmark  5 → flat[10], flat[11]
        //   littleMCP = landmark 17 → flat[34], flat[35]
        let wx = flatLandmarks[0],  wy = flatLandmarks[1]
        let ix = flatLandmarks[10], iy = flatLandmarks[11]
        let px = flatLandmarks[34], py = flatLandmarks[35]
        let cross = (ix - wx) * (py - wy) - (iy - wy) * (px - wx)
        return cross > 0
    }
}
