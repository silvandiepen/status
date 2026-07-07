import Foundation

public struct TriggerScheduleResult: Equatable, Sendable {
    public var trigger: TriggerDefinition
    public var enqueuedJob: JobRecord?

    public init(trigger: TriggerDefinition, enqueuedJob: JobRecord?) {
        self.trigger = trigger
        self.enqueuedJob = enqueuedJob
    }
}

public final class TriggerScheduler {
    private let queue: InMemoryJobQueue
    private let baseBackoffSeconds: TimeInterval
    private let maxBackoffSeconds: TimeInterval

    public init(
        queue: InMemoryJobQueue,
        baseBackoffSeconds: TimeInterval = 60,
        maxBackoffSeconds: TimeInterval = 3_600
    ) {
        self.queue = queue
        self.baseBackoffSeconds = baseBackoffSeconds
        self.maxBackoffSeconds = maxBackoffSeconds
    }

    public func evaluate(_ trigger: TriggerDefinition, at date: Date) -> TriggerScheduleResult {
        guard trigger.enabled else {
            return TriggerScheduleResult(trigger: trigger, enqueuedJob: nil)
        }

        switch trigger.kind {
        case .manual, .push, .event, .appLifecycle:
            return TriggerScheduleResult(trigger: trigger, enqueuedJob: nil)
        case .cron:
            guard isDue(trigger, at: date) else {
                return TriggerScheduleResult(trigger: trigger, enqueuedJob: nil)
            }
            let job = queue.enqueue(trigger: trigger, at: date)
            var updated = trigger
            updated.lastRunAt = date
            updated.nextRunAt = nextRunDate(for: updated, from: date)
            return TriggerScheduleResult(trigger: updated, enqueuedJob: job)
        }
    }

    public func enqueueManual(_ trigger: TriggerDefinition, at date: Date) -> TriggerScheduleResult {
        guard trigger.enabled else {
            return TriggerScheduleResult(trigger: trigger, enqueuedJob: nil)
        }
        let job = queue.enqueue(trigger: trigger, at: date)
        var updated = trigger
        updated.lastRunAt = date
        return TriggerScheduleResult(trigger: updated, enqueuedJob: job)
    }

    public func recordSuccess(for trigger: TriggerDefinition, at date: Date) -> TriggerDefinition {
        var updated = trigger
        updated.failureCount = 0
        updated.lastRunAt = date
        updated.nextRunAt = nextRunDate(for: updated, from: date)
        return updated
    }

    public func recordFailure(for trigger: TriggerDefinition, at date: Date) -> TriggerDefinition {
        var updated = trigger
        updated.failureCount += 1
        updated.lastRunAt = date
        updated.nextRunAt = date.addingTimeInterval(backoffDelay(forFailureCount: updated.failureCount))
        return updated
    }

    public func backoffDelay(forFailureCount failureCount: Int) -> TimeInterval {
        guard failureCount > 0 else { return 0 }
        let exponent = min(failureCount - 1, 10)
        let delay = baseBackoffSeconds * pow(2, Double(exponent))
        return min(delay, maxBackoffSeconds)
    }

    private func isDue(_ trigger: TriggerDefinition, at date: Date) -> Bool {
        guard trigger.kind == .cron else { return false }
        if let nextRunAt = trigger.nextRunAt {
            return nextRunAt <= date
        }
        guard let lastRunAt = trigger.lastRunAt else {
            return true
        }
        guard let intervalSeconds = trigger.intervalSeconds else {
            return false
        }
        return lastRunAt.addingTimeInterval(intervalSeconds) <= date
    }

    private func nextRunDate(for trigger: TriggerDefinition, from date: Date) -> Date? {
        guard trigger.kind == .cron, let intervalSeconds = trigger.intervalSeconds else {
            return nil
        }
        return date.addingTimeInterval(intervalSeconds)
    }
}
