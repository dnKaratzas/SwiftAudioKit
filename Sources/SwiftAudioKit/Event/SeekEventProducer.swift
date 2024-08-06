//
//  SwiftAudioKit
//
//  Created by Dionysios Karatzas.
//  Copyright © 2024 Dionysios Karatzas. All rights reserved.
//

import Foundation

/// A `SeekEventProducer` generates `SeekEvent`s when it's time to seek on the stream.
class SeekEventProducer: EventProducer {
    /// `SeekEvent` is an event generated by `SeekEventProducer`.
    ///
    /// - seekBackward: The event describes a seek backward in time.
    /// - seekForward: The event describes a seek forward in time.
    enum SeekEvent: Event {
        case seekBackward
        case seekForward
    }

    /// The timer used to generate events.
    private var timer: DispatchSourceTimer?

    /// The listener that will be alerted when a new event occurs.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently producing events or not.
    private(set) var isObserving = false

    /// The delay between seek events. Default value is 10 seconds.
    var intervalBetweenEvents: TimeInterval = 10

    /// A boolean value indicating whether the producer should generate backward or forward events.
    var isBackward = false

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard !isObserving else {
            return
        }

        // Start the timer
        startTimer()

        // Mark as listening
        isObserving = true
    }

    /// Stops listening to the player events.
    func stopProducingEvents() {
        guard isObserving else {
            return
        }

        // Stop the timer
        stopTimer()

        // Mark as not listening
        isObserving = false
    }

    /// Starts the timer to produce seek events.
    private func startTimer() {
        stopTimer() // Ensure any existing timer is stopped

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: intervalBetweenEvents)
        timer.setEventHandler { [weak self] in
            self?.timerTicked()
        }
        timer.resume()
        self.timer = timer
    }

    /// Stops the timer if it's running.
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    /// Called when the timer ticks.
    private func timerTicked() {
        eventListener?.onEvent(isBackward ? SeekEvent.seekBackward : .seekForward, generatedBy: self)
    }

    /// Stops producing events on deinitialization.
    deinit {
        stopProducingEvents()
    }
}
