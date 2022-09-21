//
//  Task.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

public extension Task where Success == Never, Failure == Never {
    
    static func sleep(timeInterval: Double) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * Double(1_000_000_000)))
    }
}

// MARK: - Supporting Types

public actor TaskQueue {
    
    // MARK: - Properties
    
    public let name: String
    
    public let priority: TaskPriority
        
    private var tasks = [PendingTask]()
    
    private var isRunning = false
    
    private var count: UInt64 = 0
    
    // MARK: - Initialization
    
    public init(
        name: String = "Task Queue " + UUID().description,
        priority: TaskPriority = .userInitiated
    ) {
        self.name = name
        self.priority = priority
    }
    
    // MARK: - Methods
    
    public nonisolated func queue(after delay: Double? = nil, _ task: @escaping () async -> ()) {
        Task.detached(priority: priority) {
            // sleep before running task
            if let duration = delay {
                try? await Task.sleep(timeInterval: duration)
            }
            // execute and block global actor
            await self.execute(task)
        }
    }
    
    private func pop() -> PendingTask? {
        guard let pendingTask = tasks.first else {
            return nil
        }
        let _ = tasks.removeFirst()
        #if DEBUG
        print("\(name) Will execute task \(pendingTask.id)")
        print("\(name) \(tasks.map { $0.id })")
        #endif
        return pendingTask
    }
    
    private func push(_ task: @escaping (() async -> ())) {
        let pendingTask = PendingTask(
            id: count,
            work: task
        )
        count += 1
        tasks.append(pendingTask)
        #if DEBUG
        print("\(name) Queued task \(pendingTask.id)")
        print("\(name) \(tasks.map { $0.id })")
        #endif
    }
    
    private func lock(_ isRunning: Bool = true) {
        self.isRunning = isRunning
    }
    
    private func execute(_ task: @escaping () async -> ()) async {
        // push task to stack
        push(task)
        // check lock to see if currently running
        guard isRunning == false else {
            return // the other detached task will run them all
        }
        lock()
        // run in sequential order
        while let queuedTask = pop() {
            // execute task
            await queuedTask.work()
            #if DEBUG
            print("\(name) Executed task \(queuedTask.id) of \(count - 1)")
            print("\(name) \(tasks.map { $0.id })")
            #endif
        }
        lock(false) // unlock
    }
}

private extension TaskQueue {
    
    struct PendingTask: Identifiable {
        
        let id: UInt64
        
        let work: () async -> ()
    }
}

// MARK: - Defined Task Queue

public extension Task where Success == Never, Failure == Never {
    
    /// Serial task queue for Bluetooth.
    static func bluetooth(_ task: @escaping () async -> ()) {
        TaskQueue.bluetooth.queue(task)
    }
}

public extension TaskQueue {
    
    static let bluetooth = TaskQueue(
        name: "com.colemancda.Lock.TaskQueue.Bluetooth",
        priority: .userInitiated
    )
}
