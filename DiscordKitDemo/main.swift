//
//  main.swift
//  DiscordKitDemo
//
//  Created by Vincent Kwok on 20/11/22.
//

import Foundation
import Logging
import DiscordKitBot

let logger = Logger(label: "main")

guard let token = ProcessInfo.processInfo.environment["TOKEN"] else {
    // We cannot continue without a token present
    logger.critical("TOKEN was not found in the environment!")
    exit(1)
}

let bot = Client(intents: [.unprivileged, .messageContent])

bot.login(token: token)
