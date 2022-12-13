#  DiscordKit Bot Demo

A macOS CLI Swift app to demonstrate the usage of DiscordKit
to create Discord bots in Swift.

> **Warning**
> DiscordKit's bot support is still in its preliminary stages
> and under heavy development, so a stable API isn't available.
> Check out the PR in DiscordKit: SwiftcordApp/DiscordKit#18
> for the latest progress updates and code.
>
> If you'd like to be a valuable beta tester, you can add a 
> dependancy on the `bot-support` branch of 
> [DiscordKit](https://github.com/SwiftcordApp/DiscordKit) or
> fork this repository!

## Getting Started

To build your very own Discord bot in Swift with DiscordKit,
simply...

1. Fork this repository
2. Clone the forked repository with Xcode
3. (If necessary) Create a new application at Discord's
   [Developer Portal](https://discord.com/developers/applications).
   Add a bot to the application, and generate a token. Remember
   to copy it to add it to your configuration file in the
   following step, as you won't be able to see it again!

   Also, enable the "Message Content Intent" to ensure the bot
   can see the content of your messages. You can always disable
   it later.
4. Create a new "Configuration Settings File" in the Xcode
   project and add the following line:
   ```
   TOKEN=<your bot token>
   ```
5. Add your bot to a server, minimally enabling the "Send
   Messages" permission. Copy the ID of the server and set the
   `COMMAND_GUILD_ID` environment variable in the "DiscordKitDemo"
   scheme to your server's ID. This allows creating slash
   commands scoped to your guild, which update instantly
   (compared to global commands which may take hours to update).
6. Build and run the project. Congratulations! 🎉 You've just
   brought your bot to life!

Feel free to open an issue or leave a message in Swiftcord's
Discord server if you get stuck on any step. Have fun!

## Status

What's up with DiscordKit's bot support? Find out below!

### What Works

* [x] Bot gateway identification with intents support
* [x] Correct user agent, properties and REST authentication
* [x] Sending basic messages
* [x] Event dispatching with `NotificationCenter` for message
      create and ready events
* [x] Application command registration with a `resultBuilder`
      (currently limited to slash commands)
* [x] Adding parameters to commands in the `resultBuilder`
      (currently only supports type `STRING`)
* [x] Handling interactions with a closure, allowing responses

### What's Planned

* [ ] Support more types of interaction responses
* [ ] Wider support of command parameter types
* [ ] Other types of application commands (i.e. `USER`/`MESSAGE`)
* [ ] Utility methods for received messages/channels/etc.

_...and much more (TBD)_

## Contributing

Feel free to join in the bot support discussion on Swiftcord's
Discord server! There, I post frequent updates as well as ask for
advice regarding the design of the bot API.

Forking the `bot-support` branch and contributing your code is
another great way to accelerate progress.

Finally, my work has greatly benefited you, consider sponsoring me!
Your donation allows me to spend more time improving such projects.
