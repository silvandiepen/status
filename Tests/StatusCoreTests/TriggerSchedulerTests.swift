import Foundation
import Testing
@testable import StatusCore

@Test func cronTriggerEnqueuesJobWhenDueAndSchedulesNextRun() {
    let queue = InMemoryJobQueue()
    let scheduler = TriggerScheduler(queue: queue)
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_appstore_poll",
        pluginID: "com.status.appstoreconnect",
        accountID: "acc_asc",
        kind: .cron,
        label: "Poll App Store Connect",
        intervalSeconds: 900
    )

    let result = scheduler.evaluate(trigger, at: now)

    #expect(result.enqueuedJob?.triggerID == trigger.id)
    #expect(result.enqueuedJob?.status == .queued)
    #expect(result.trigger.lastRunAt == now)
    #expect(result.trigger.nextRunAt == now.addingTimeInterval(900))
    #expect(queue.allJobs().count == 1)
}

@Test func cronTriggerDoesNotEnqueueBeforeNextRun() {
    let queue = InMemoryJobQueue()
    let scheduler = TriggerScheduler(queue: queue)
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_appstore_poll",
        pluginID: "com.status.appstoreconnect",
        kind: .cron,
        label: "Poll App Store Connect",
        intervalSeconds: 900,
        nextRunAt: now.addingTimeInterval(60)
    )

    let result = scheduler.evaluate(trigger, at: now)

    #expect(result.enqueuedJob == nil)
    #expect(queue.allJobs().isEmpty)
}

@Test func manualTriggerOnlyEnqueuesWhenExplicitlyRequested() {
    let queue = InMemoryJobQueue()
    let scheduler = TriggerScheduler(queue: queue)
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_manual_refresh",
        pluginID: "com.status.github",
        kind: .manual,
        label: "Refresh GitHub"
    )

    #expect(scheduler.evaluate(trigger, at: now).enqueuedJob == nil)

    let manual = scheduler.enqueueManual(trigger, at: now)

    #expect(manual.enqueuedJob?.pluginID == "com.status.github")
    #expect(manual.trigger.lastRunAt == now)
    #expect(queue.allJobs().count == 1)
}

@Test func disabledTriggerDoesNotEnqueue() {
    let queue = InMemoryJobQueue()
    let scheduler = TriggerScheduler(queue: queue)
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_disabled",
        pluginID: "com.status.github",
        kind: .cron,
        label: "Disabled",
        enabled: false,
        intervalSeconds: 900
    )

    #expect(scheduler.evaluate(trigger, at: now).enqueuedJob == nil)
    #expect(scheduler.enqueueManual(trigger, at: now).enqueuedJob == nil)
    #expect(queue.allJobs().isEmpty)
}

@Test func failureBackoffDelaysNextRunAndSuccessResetsFailures() {
    let queue = InMemoryJobQueue()
    let scheduler = TriggerScheduler(queue: queue, baseBackoffSeconds: 60, maxBackoffSeconds: 600)
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_uptime",
        pluginID: "com.status.uptime",
        kind: .cron,
        label: "Check site",
        intervalSeconds: 300
    )

    let failedOnce = scheduler.recordFailure(for: trigger, at: now)
    let failedTwice = scheduler.recordFailure(for: failedOnce, at: now)
    let recovered = scheduler.recordSuccess(for: failedTwice, at: now)

    #expect(failedOnce.failureCount == 1)
    #expect(failedOnce.nextRunAt == now.addingTimeInterval(60))
    #expect(failedTwice.failureCount == 2)
    #expect(failedTwice.nextRunAt == now.addingTimeInterval(120))
    #expect(recovered.failureCount == 0)
    #expect(recovered.nextRunAt == now.addingTimeInterval(300))
}

@Test func jobQueueTracksLifecycle() {
    let queue = InMemoryJobQueue()
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let trigger = TriggerDefinition(
        id: "trg_github",
        pluginID: "com.status.github",
        kind: .manual,
        label: "Refresh"
    )

    let job = queue.enqueue(trigger: trigger, at: now)
    queue.start(jobID: job.id, at: now.addingTimeInterval(1))
    queue.finish(jobID: job.id, at: now.addingTimeInterval(2), emittedEventIDs: ["evt_1"])

    #expect(queue.job(id: job.id)?.status == .success)
    #expect(queue.job(id: job.id)?.startedAt == now.addingTimeInterval(1))
    #expect(queue.job(id: job.id)?.finishedAt == now.addingTimeInterval(2))
    #expect(queue.job(id: job.id)?.emittedEventIDs == ["evt_1"])
    #expect(queue.nextQueuedJob() == nil)
}
