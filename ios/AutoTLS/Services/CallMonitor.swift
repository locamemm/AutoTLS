import Foundation
import CallKit

class CallMonitor: NSObject, ObservableObject, CXCallObserverDelegate {
    @Published var isCallActive: Bool = false
    
    var onCallStarted: (() -> Void)?
    var onCallEnded: (() -> Void)?
    
    private let callObserver = CXCallObserver()
    
    override init() {
        super.init()
        callObserver.setDelegate(self, queue: DispatchQueue.main)
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if call.hasEnded {
                self.isCallActive = false
                self.onCallEnded?()
            } else if call.hasConnected || call.isOutgoing {
                self.isCallActive = true
                self.onCallStarted?()
            }
        }
    }
}
