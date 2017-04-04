//
//  KTPomodoroTaskConstants.swift
//  Cherry
//
//  Created by Kenny Tang on 2/22/15.
//
//

import Foundation

struct Constants {

    enum KTPomodoroActivityStatus: Int {
        case inProgress = 0, stopped, completed
    }

    enum KTPomodoroStartActivityError: Int {
        case otherActivityActive
    }

}

