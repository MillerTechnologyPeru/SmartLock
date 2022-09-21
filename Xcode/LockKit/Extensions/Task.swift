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
    
    private var currentTask: (id: UInt64, task: Task<Void, Never>)?
    
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
    
    public func queue(after delay: Double? = nil, _ task: @escaping () async -> ()) async -> PendingTask {
        return await Task(priority: priority) {
            // sleep before running task
            if let duration = delay {
                try? await Task.sleep(timeInterval: duration)
            }
            // execute and block global actor
            return await self.execute(task)
        }.value
    }
    
    public func cancelAll() {
        var count = tasks.count
        if currentTask != nil {
            count += 1
        }
        //currentTask?.task.cancel()
        currentTask = nil
        tasks.removeAll(keepingCapacity: true)
        isRunning = false
        tasks.forEach { task in
            Task { await task.setFinished() }
        }
        #if DEBUG
        if count > 0 {
            NSLog("\(name) Cancelled \(count) tasks")
        }
        #endif
    }
    
    private func pop() -> PendingTask? {
        guard let pendingTask = tasks.first else {
            return nil
        }
        let _ = tasks.removeFirst()
        #if DEBUG
        NSLog("\(name) Will execute task \(pendingTask.id)")
        #endif
        return pendingTask
    }
    
    private func push(_ task: @escaping (() async -> ())) -> PendingTask {
        let id = self.count
        let name = self.name
        let pendingTask = PendingTask(
            id: id,
            work: task,
            onTermination: {
                Task {
                    // cancel current executing task
                    if let task = self.currentTask, task.id == id {
                        self.currentTask = nil
                        //task.task.cancel()
                        #if DEBUG
                        NSLog("\(name) Cancelled task \(id)")
                        #endif
                    }
                }
            }
        )
        count += 1
        tasks.append(pendingTask)
        #if DEBUG
        NSLog("\(name) Queued task \(pendingTask.id)")
        #endif
        return pendingTask
    }
    
    private func lock(_ isRunning: Bool = true) {
        self.isRunning = isRunning
    }
    
    private func execute(_ task: @escaping () async -> ()) async -> PendingTask {
        // push task to stack
        let newTask = push(task)
        // check lock to see if currently running
        guard isRunning == false else {
            return newTask // the other detached task will run them all
        }
        lock()
        // run in sequential order
        while let queuedTask = pop() {
            // skip cancelled task
            guard await queuedTask.didFinish == false else {
                NSLog("\(name) Skipped task \(queuedTask.id)")
                continue
            }
            // execute task
            let task = Task(priority: priority) {
                await queuedTask.work()
            }
            currentTask = (queuedTask.id, task)
            await task.value // wait for task to finish
            currentTask = nil
            await queuedTask.setFinished()
            #if DEBUG
            NSLog("\(name) Executed task \(queuedTask.id) of \(count - 1)")
            #endif
        }
        lock(false) // unlock
        return newTask
    }
}

public extension TaskQueue {
    
    actor PendingTask: Identifiable {
        
        public let id: UInt64
        
        internal let work: () async -> ()
        
        internal let onTermination: () -> ()
        
        internal fileprivate(set) var didFinish = false
        
        fileprivate init(id: UInt64, work: @escaping () async -> (), onTermination: @escaping () -> Void) {
            self.id = id
            self.work = work
            self.onTermination = onTermination
        }
        
        public func cancel() {
            guard didFinish == false else {
                return
            }
            setFinished()
            onTermination()
        }
        
        fileprivate func setFinished() {
            didFinish = true
        }
    }
}

// MARK: - Defined Task Queue

public extension Task where Success == Never, Failure == Never {
    
    /// Serial task queue for Bluetooth.
    @discardableResult
    static func bluetooth(_ task: @escaping () async -> ()) async -> TaskQueue.PendingTask {
        return await TaskQueue.bluetooth.queue(task)
    }
}

public extension TaskQueue {
    
    static let bluetooth = TaskQueue(
        name: "com.colemancda.Lock.TaskQueue.Bluetooth",
        priority: .userInitiated
    )
}
