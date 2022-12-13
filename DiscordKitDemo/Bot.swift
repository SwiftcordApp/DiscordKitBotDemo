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

/// The main entrypoint of our Discord bot
///
/// This is where all the magic happens - where you'll interact with Discord's API to bring your
/// bot to life!
@main
public struct Bot {
    /// A simple logger for this bot
    ///
    /// Here we're using `SwiftLog`, but feel free to use any logging module that fits your needs.
    static let logger = {
        var log = Logger(label: "main", level: nil)
        // The log level defaults to info, so messages below that level
        // will be hidden.
        // If this binary was built for debugging, set the log level to
        // trace for more verbose logs, to aid debugging.
#if DEBUG
        log.logLevel = .trace
#endif
        return log
    }()

    /// Create an instance of the bot in a static member
    ///
    /// This doesn't establish any connection with the Discord API just yet, we'll call
    /// `Client.login(token:)` in our main function to do so.
    static let bot = Client(intents: [.unprivileged, .messageContent])

    /// Register the slash commands for this bot
    ///
    /// Here, we're only registering slash commands, but the ability to register other types of
    /// commands such as user or message commands might be added in the future.
    private static func registerSlashCommands() async throws {
        try await bot.registerApplicationCommands(guild: ProcessInfo.processInfo.environment["COMMAND_GUILD_ID"]) {
            // MARK: hello - Basic command which uses a variety of options
            NewAppCommand("hello", description: "Get a nice hello message") {
                StringOption("name", description: "Your beautiful name")
                IntegerOption("age", description: "How old (in years) are you?", min: 1)
            } handler: { interaction in
                if let name: String = interaction.optionValue(of: "name") {
                    if let age: Int = interaction.optionValue(of: "age") {
                        let bornAge = Calendar.current.date(byAdding: .init(year: -age), to: Date())
                        try? await interaction.reply("Hi \(name), you were born <t:\(Int(bornAge!.timeIntervalSince1970)):R>!")
                    }
                    try? await interaction.reply("Hey \(name), nice to meet you!")
                } else {
                    try? await interaction.reply("Hi there! Fill in the name option for a personalised greeting!")
                }
            }

            // MARK: time - Simple command without any options
            NewAppCommand("time", description: "What time is it???") { interaction in
                try? await interaction.reply("Today's <t:\(Int(Date().timeIntervalSince1970)):F>")
            }

            // MARK: choose - Demonstrates simple sub-commands
            NewAppCommand("choose", description: "Make a choice, and I'll tell you if I approve of it") {
                SubCommand("yes", description: "How about yes?")
                SubCommand("no", description: "Maybe not...")
            } handler: { interaction in
                let choice = interaction.subOption(name: "yes") != nil
                try? await interaction.reply("You said \(choice ? "yes" : "no"), and I \(Bool.random() ? "" : "dis")agree!")
            }

            // MARK: calculator - A complex command with nested options
            NewAppCommand("calculator", description: "Need help crunching numbers? Just use this command!") {
                // Sub-commands can be defined like so, and even support nested options!
                SubCommand("plus", description: "Add two numbers") {
                    NumberOption("lhs", description: "First number to add", required: true)
                    NumberOption("rhs", description: "Second number to add", required: true)
                }
                SubCommand("minus", description: "Subtract one number from the other") {
                    NumberOption("lhs", description: "Number to subtract from", required: true)
                    NumberOption("rhs", description: "Number to subtract", required: true)
                }
                SubCommand("times", description: "Multiply the first number with the other") {
                    NumberOption("lhs", description: "Base value to multiply", required: true)
                    NumberOption("rhs", description: "Multiplier/Factor to multiply base value by", required: true)
                }
                SubCommand("divide", description: "Divide the first number by the second") {
                    NumberOption("lhs", description: "Quotient (number to divide)", required: true)
                    NumberOption("rhs", description: "Divisor", required: true)
                }
            } handler: { interaction in
                if let opt = interaction.subOption(name: "plus"),
                   let lhs: Double = opt["lhs"]?.value(),
                   let rhs: Double = opt["rhs"]?.value() {
                    try? await interaction.reply("`\(lhs) + \(rhs) = \(lhs + rhs)`")
                } else if let opt = interaction.subOption(name: "minus"),
                          let lhs: Double = opt["lhs"]?.value(),
                          let rhs: Double = opt["rhs"]?.value() {
                    try? await interaction.reply("`\(lhs) - \(rhs) = \(lhs - rhs)`")
                } else if let opt = interaction.subOption(name: "times"),
                          let lhs: Double = opt["lhs"]?.value(),
                          let rhs: Double = opt["rhs"]?.value() {
                    try? await interaction.reply("`\(lhs) × \(rhs) = \(lhs * rhs)`")
                } else if let opt = interaction.subOption(name: "divide"),
                          let lhs: Double = opt["lhs"]?.value(),
                          let rhs: Double = opt["rhs"]?.value() {
                    try? await interaction.reply("`\(lhs) ÷ \(rhs) = \(lhs / rhs)`")
                }
            }
        }
    }

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

            // MARK: Register some slash commands for our bot
            // Commands can **only** be registered _after_ the ready event has
            // been fired, as it relies on the presence of the application's ID to
            // register application commands, which is provided in the READY event.
            do {
                logger.trace("Registering interactions...")
                try await registerSlashCommands()
                logger.info("Registered interactions!")
            } catch {
                logger.error("Failed to register interactions", metadata: ["error": "\(error.localizedDescription)"])
            }
        }
        bot.messageCreate.listen { message in
            if message.content.hasPrefix("?test") {
                _ = try? await bot.sendMessage("Testing a reply!", channel: message.channelID, replyingTo: message.id)
            }
        }

        // MARK: Finally, log in to the Discord API with our token
        bot.login(token: token)

        // Run the main RunLoop to prevent the program from exiting
        RunLoop.main.run()
    }
}
