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
    /// The prefix we're using for commands
    ///
    /// This reads from the `MESSAGE_COMMAND_PREFIX` environment variable and defaults
    /// to "?" as the prefix if the variable isn't found.
    static let MSG_CMD_PREFIX = ProcessInfo.processInfo.environment["MESSAGE_COMMAND_PREFIX"] ?? "?"

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
                IntegerOption("age", description: "How old (in years) are you?").min(1)
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
                    NumberOption("lhs", description: "First number to add").required()
                    NumberOption("rhs", description: "Second number to add").required()
                }
                SubCommand("minus", description: "Subtract one number from the other") {
                    NumberOption("lhs", description: "Number to subtract from").required()
                    NumberOption("rhs", description: "Number to subtract").required()
                }
                SubCommand("times", description: "Multiply the first number with the other") {
                    NumberOption("lhs", description: "Base value to multiply").required()
                    NumberOption("rhs", description: "Multiplier/Factor to multiply base value by").required()
                }
                SubCommand("divide", description: "Divide the first number by the second") {
                    NumberOption("lhs", description: "Quotient (number to divide)").required()
                    NumberOption("rhs", description: "Divisor").required()
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

            NewAppCommand("timer", description: "Can we have a timer? \"We already have a timer at home\" The timer at home:") {
                IntegerOption("duration", description: "The approximate duration of this timer")
                    .required()
                    .min(1)
                    .max(30)
            } handler: { interaction in
                try? await interaction.deferReply() // Call this as soon as possible to defer the response and display a loading state

                let duration: Int = interaction.optionValue(of: "duration")!
                try? await Task.sleep(for: .seconds(duration))
                try? await interaction.reply("Your timer for \(duration)s is up! It ended <t:\(Int(Date().timeIntervalSince1970)):R>.")
            }

            NewAppCommand("embed", description: "Help me make an embed!") {
                StringOption("title", description: "Title of the embed")
                StringOption("description", description: "Description of the embed")
                StringOption("url", description: "URL of the embed (must be a valid URL)")
                StringOption("fields", description: "Fields of the embed in the format `title1,value1,title2,value2,...`")
            } handler: { interaction in
                let title: String? = interaction.optionValue(of: "title")
                let description: String? = interaction.optionValue(of: "description")
                let url: String? = interaction.optionValue(of: "url")
                let rawFields: String? = interaction.optionValue(of: "fields")
                var fields: [BotEmbed.Field] = []

                func errorReply(_ error: String) async throws {
                    try await interaction.reply {
                        BotEmbed()
                            .title(error)
                            .color(0xff0000)
                    }
                }

                // Ensure at least one of the properties isn't nil
                guard title != nil || description != nil || rawFields != nil else {
                    try? await errorReply("At least one of title, description or fields must be set")
                    return
                }
                // Try to decode fields if present
                if let rawFields {
                    let pairs = rawFields.components(separatedBy: ",")
                    guard pairs.count.isMultiple(of: 2) else {
                        try? await errorReply("Pairs of field title and values are incomplete")
                        return
                    }
                    for i in 0..<pairs.count where i.isMultiple(of: 2) {
                        fields.append(.init(
                            pairs[i].trimmingCharacters(in: .whitespaces),
                            value: pairs[i+1].trimmingCharacters(in: .whitespaces)
                        ))
                    }
                }

                try? await interaction.reply {
                    BotEmbed(fields: fields.isEmpty ? nil : fields)
                        .title(title)
                        .description(description)
                        .url(url)
                }
            }
        }
    }

    public static func main() {
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
        // MARK: Listen for message create events for text messages
        // For this to work, you'll have to ensure you've enabled the message
        // content intent in both the client init call and Discord's developer
        // portal, or the message content you receive will always be empty.
        bot.messageCreate.listen { message in
            if message.content.hasPrefix(Self.MSG_CMD_PREFIX) { // Check if the message has our prefix
                // Remove the prefix and split the text into individual args
                let args = message.content
                    .trimmingPrefix(Self.MSG_CMD_PREFIX)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                // Ensure there's at least one arg, which will be used as the command
                guard let command = args.first else { return }
                logger.debug("Received message command", metadata: ["command": "\(command)"])
                switch command {
                case "ping":
                    _ = try? await message.reply("Pong!")
                default:
                    _ = try? await message.reply("I don't recognise that command :(")
                }
            }
        }

        // MARK: Finally, log in to the Discord API with our bot's token
        // You can store the bot token in any way you see fit, this example
        // uses a .xcconfig file to store the token locally. Never add your
        // bot token to source control (i.e. git)!
        // In this example, since we've set the DISCORD_TOKEN environment
        // variable to our bot's token, we can simply call login without any
        // arguments. It defaults to using the DISCORD_TOKEN env variable.
        bot.login()

        // Run the main RunLoop to prevent the program from exiting
        RunLoop.main.run()
    }
}
