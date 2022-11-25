//
//  Bot.swift
//  DiscordKitDemo
//
//  Renaming the file from main.swift to Bot.swift was neccessary
//  due to a bug in Swift: https://github.com/apple/swift/issues/55127
//
//  Created by Vincent Kwok on 20/11/22.
//

import Foundation
import Logging
import DiscordKitBot // Import the DiscordKit module for all the wonders contained within

@main
public struct Bot {
    static let logger = Logger(label: "main")

    // Create an instance of the bot in a static member
    // This doesn't establish any connection with the Discord API just yet,
    // we'll call Client.login(token:) in our main function to do so.
    static let bot = Client(intents: [.unprivileged, .messageContent])

    public static func main() {
        // Get token from environment variables
        // You can store the bot token in any way you see fit, this example
        // uses a .xcconfig file to store the token locally. Never add your
        // bot token to source control (i.e. git)!
        guard let token = ProcessInfo.processInfo.environment["TOKEN"]?.trimmingCharacters(in: .whitespaces) else {
            // We cannot continue without a token present
            logger.critical("TOKEN was not found in the environment!")
            exit(1)
        }

        // Finally, log in to the Discord API with our token
        bot.login(token: token)
    }
}
