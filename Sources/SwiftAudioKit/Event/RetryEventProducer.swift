//
//  SwiftAudioKit
//
//  Created by Dionysios Karatzas.
//  Copyright © 2024 Dionysios Karatzas. All rights reserved.
//

import Foundation

/// A `RetryEventProducer` generates `RetryEvent`s when there should be a retry based on some information about interruptions.
class RetryEventProducer: EventProducer {
    /// `RetryEvent` is a list of events that can be generated by `RetryEventProducer`.
    ///
    /// - retryAvailable: A retry is available.
    /// - retryFailed: Retrying is no longer an option.
    enum RetryEvent: Event {
        case retryAvailable
        case retryFailed
    }

    /// The timer used for retrying.
    private var timer: DispatchSourceTimer?

    /// The listener that will be alerted when a new event occurs.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently producing events or not.
    private(set) var isObserving = false

    /// Interruption counter. It will be used to determine whether the quality should change.
    private var retryCount = 0

    /// The maximum number of retries before generating an event. Default value is 10.
    var maximumRetryCount = 10

    /// The delay to wait before cancelling the last retry and retrying. Default value is 10 seconds.
    var retryTimeout = TimeInterval(10)

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard !isObserving else {
            return
        }

        // Reset state
        retryCount = 0

        // Create and start a new timer for the next retry
        startTimer()

        // Mark as listening
        isObserving = true
    }

    /// Stops listening to the player events.
    func stopProducingEvents() {
        guard isObserving else {
            return
        }

        stopTimer()

        // Mark as not listening
        isObserving = false
    }

    /// Starts the timer for retrying.
    private func startTimer() {
        stopTimer() // Ensure any existing timer is stopped

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + retryTimeout)
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

    /// Called when the retry timer ticks.
    private func timerTicked() {
        retryCount += 1

        if retryCount < maximumRetryCount {
            eventListener?.onEvent(RetryEvent.retryAvailable, generatedBy: self)
            startTimer() // Schedule the next retry
        } else {
            eventListener?.onEvent(RetryEvent.retryFailed, generatedBy: self)
        }
    }

    /// Stops producing events on deinitialization.
    deinit {
        stopProducingEvents()
    }
}
