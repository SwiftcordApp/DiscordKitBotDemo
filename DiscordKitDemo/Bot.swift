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
    static let logger = {
        var log = Logger(label: "main", level: nil)
        // Set the log level to trace to aid debugging
#if DEBUG
        log.logLevel = .trace
#endif
        return log
    }()

    // Create an instance of the bot in a static member
    // This doesn't establish any connection with the Discord API just yet,
    // we'll call Client.login(token:) in our main function to do so.
    static let bot = Client(intents: [.unprivileged, .messageContent])

    public static func main() {
        // MARK: Get token from environment variables
        // You can store the bot token in any way you see fit, this example
        // uses a .xcconfig file to store the token locally. Never add your
        // bot token to source control (i.e. git)!
        guard let token = ProcessInfo.processInfo.environment["TOKEN"]?.trimmingCharacters(in: .whitespaces) else {
            // We cannot continue without a token present
            logger.critical("TOKEN was not found in the environment!")
            exit(1)
        }

        // MARK: Register event listeners
        // Instances of a NotificationCenter wrapper are provided as properties
        // of the Client class. These allow less verbose registration of
        // strongly-typed event listeners, and async listeners.
        // Note: The event architecture is still in the process of being decided
        //       upon, so the API isn't stable or polished yet.
        bot.ready.listen {
            logger.info("Logged in!", metadata: [
                "user.id": "\(bot.user!.id)",
                "user.username": "\(bot.user!.username)",
                "user.discriminator": "\(bot.user!.discriminator)"
            ])
            if let channelID = ProcessInfo.processInfo.environment["TEST_CHANNEL_ID"] {
                do {
                    logger.trace("Attempting to send test message", metadata: ["channel.id": "\(channelID)"])
                    _ = try await bot.sendMessage("Hello world!", channel: "1044493748328992811")
                    logger.trace("Sent test message successfully!")
                } catch {
                    logger.error("Failed to send test message", metadata: ["error": "\(error.localizedDescription)"])
                }
            }
        }
        bot.messageCreate.listen { message in
            if message.content.hasPrefix("?test") {
                _ = try? await bot.sendMessage("Testing a reply!", channel: message.channelID, replyingTo: message.id)
            }
        }

        // MARK: Finally, log in to the Discord API with our token
        bot.login(token: token)
    }
}
