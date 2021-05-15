//
//  CheckDeviceTokenJob.swift
//
//
//  Created by Mikhail Ivanov on 15.05.2021.
//

import Vapor
import Fluent
import Queues

struct CheckDeviceTokenJob: ScheduledJob {
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        context.application.logger.info("Start of job \"\(String(describing: CheckDeviceTokenJob.self))\"")
        
        let oldDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        
        return DeviceInfo.query(on: context.application.db).filter(\.$initDate >= oldDate)
            .all().flatMap { devices in
            if !devices.isEmpty {
                return devices.delete(on: context.application.db).map {
                    context.application.logger.info("Removed old devices")
                }
            }
            
            return context.eventLoop.makeSucceededVoidFuture()
        }.map {
            context.application.logger.info("Completed job \"\(String(describing: CheckDeviceTokenJob.self))\"")
        }
    }
}
