example_embed = {
	color: 0xEC1622,
	title: "Article title",
	url: "https://discord.js.org",
	author: {
		name: 'Publisher Title',
		icon_url: 'https://i.imgur.com/wSTFkRM.png',
		url: 'https://discord.js.org',
	},
	description: 'Some description here',
	thumbnail: {
		url: 'https://i.imgur.com/wSTFkRM.png',
	},
	image: {
		url: 'https://i.imgur.com/wSTFkRM.png',
	},
	timestamp: "",
	footer: {
		text: 'Some footer text here',
		icon_url: 'https://i.imgur.com/wSTFkRM.png',
	},
}

@rubyshin.message content: /!r\s+embed/ do |event|
	if !event.from_bot?
		example_embed[:footer][:text] = "#{event.user.name} ##{event.user.discriminator} can use the reaction buttons below to cycle pages!"
									 # message content, tts, embed
		m = event.respond("", false, example_embed)
		m.react CROSS_MARK
		m.react LEFTWARDS_ARROW
		m.react RIGHTWARDS_ARROW

		@rubyshin.add_await(:"delete_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: CROSS_MARK, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id
			m.delete
		end

		@rubyshin.add_await(:"cycle_next_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: RIGHTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id

			example_embed[:description] = "🥵 #{RIGHTWARDS_ARROW}"
			m.edit("", example_embed)
		end

		@rubyshin.add_await(:"cycle_prev_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: LEFTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id

			example_embed[:description] = "🥶 #{LEFTWARDS_ARROW}"
			m.edit("", example_embed)
		end

		@rubyshin.add_await(:"beans_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: ":beans:", timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id

			example_embed[:thumbnail][:url], example_embed[:image][:url] = "http://simply-bbq.com/wp-content/uploads/2017/01/Baked-Beans.jpg", "http://simply-bbq.com/wp-content/uploads/2017/01/Baked-Beans.jpg"
			m.edit("", example_embed)
		end

		puts 'Await destroyed.'
	end
end
