//
//  jobs.swift
//
//
//  Created by Mikhail Ivanov on 15.05.2021.
//

import Vapor
import Queues

func jobs(_ app: Application) throws {
    app.queues.use(.init { job in
        job.queues.schedule(CheckDeviceTokenJob())
            .weekly().on(.sunday)
            .at(.noon)
    })
    
    try app.queues.startScheduledJobs()
}
