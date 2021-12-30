require "dotenv/load"
require "discordrb"

require_relative "news_rss.rb"
module RubyShinbun
	newsRss = NewsRSS.new()

	# deepl_key = ENV["DEEPL_KEY"] maybe ???
	# https://www.deepl.com/docs-api/translating-text/request/
	discord_token = ENV["DISCORD_TOKEN"]
	discord_id = ENV["DISCORD_ID"]

	@rubyshin = Discordrb::Bot.new token: discord_token, client_id: discord_id, name: "RubyShinbun", ignore_bots: true
	@rubyshin.run true
	@rubyshin.update_status("online", "the ニュースです。 Type !r help for help.", nil, 0, false, 3)

	@rubyshin.message content: /!r\s+ping/ do |event|
		m = event.respond("Pong!")
		m.edit "Pong! Time taken: #{Time.now - event.timestamp} seconds."
	end

	@rubyshin.mention do |event|
		event.respond("Hi #{event.user.name}, type \"!r help\" to see my commands")
	end

	@rubyshin.message content: /!r\s+help/ do |event|
		commands_embed = {
			color: 0xEC1622,
			title: "Ruby Shinbun",
			url: "https://github.com/juiceboxh3ro/RubyShinbun",
			description: 'Here are my commands:',
			fields: [ # 25 fields per embed
				{
					name: "!r invite",
					value: "Get a link to invite me to your server.",
				},
				{
					name: "!r japan times",
					value: "The Japan Times articles (English)",
				},
				{
					name: "!r nhk news",
					value: "NHK News articles (Japanese)",
					inline: true,
				},
				{
					name: "Available categories (NHK only)",
					value: "JP: 主要ニュース, 社会, 文化, エンタメ, 科学, 医療, 政治, 経済, 国際, スポーツ, ライブ",
					inline: true,
				},
				{
					name: "Links",
					value: "[Github](https://github.com/juiceboxh3ro/RubyShinbun)",
				},
			],
			footer: {
				text: "Raise an issue on my Github repo if you'd like to see more RSS feeds or features.",
				icon_url: "https://cdn.discordapp.com/avatars/829657532799647744/b89303f620df2a8efbfb920def2f1d49.webp?size=256",
			},
		}
		event.respond("", false, commands_embed)
	end

	@rubyshin.message content: /!r\s+invite/ do |event|
		event.respond("I'll DM you 📨")
		event.user.pm("#{@rubyshin.invite_url(server: nil, permission_bits: 27712)}")
	end

	LEFTWARDS_ARROW = "\u2B05" # ⬅️
	RIGHTWARDS_ARROW = "\u27A1" # ➡️
	DOUBLE_RIGHTWARDS_ARROW = "\u23E9" # ⏩
	CROSS_MARK = "\u274c" # ❌

	# *************************
	# 			JAPAN TIMES
	# *************************
	@rubyshin.message content: /!r\s+japan\s+times/ do |event|
		rss_response = newsRss.japan_times_rss()
		index = 0
		jt_thumb = "https://duckduckgo.com/i/4c31eccd.png"
		jt_link = "https://www.japantimes.co.jp/"

		embed = newsRss.create_embed(rss_response, index, jt_thumb, jt_link)

		embed[:footer][:text] = "#{event.user.name} ##{event.user.discriminator} can use the reaction buttons below to cycle pages!"
		embed[:footer][:icon_url] = event.user.avatar_url
		
		m = event.respond("", false, embed)
		m.react LEFTWARDS_ARROW
		m.react RIGHTWARDS_ARROW

		# NEXT ARROW
		@rubyshin.add_await(:"cycle_next_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: RIGHTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id && event.user.id == reaction_event.user.id

			index >= rss_response.items.length - 1 ? index = 0 : index += 1
			
			embed[:author][:name] = "#{rss_response.channel.title} | page #{index + 1}/#{rss_response.items.length}"
			embed[:title] = rss_response.items[index].title
			embed[:url] = rss_response.items[index].link
			embed[:description] = rss_response.items[index].description
			embed[:timestamp] = DateTime.rfc822(rss_response.items[index].pubDate.to_s)

			m.edit("", embed)
			m.delete_all_reactions
			m.react LEFTWARDS_ARROW
			m.react RIGHTWARDS_ARROW
			return false # this allows the await to be repeated
		end
		
		# PREV ARROW
		@rubyshin.add_await(:"cycle_prev_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: LEFTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id && event.user.id == reaction_event.user.id

			index == 0 ? index = rss_response.items.length - 1 : index -= 1

			embed[:author][:name] = "#{rss_response.channel.title} | page #{index + 1}/#{rss_response.items.length}"
			embed[:title] = rss_response.items[index].title
			embed[:url] = rss_response.items[index].link
			embed[:description] = rss_response.items[index].description
			embed[:timestamp] = DateTime.rfc822(rss_response.items[index].pubDate.to_s)

			m.edit("", embed)
			m.delete_all_reactions
			m.react LEFTWARDS_ARROW
			m.react RIGHTWARDS_ARROW
			return false
		end
	end


	# *************************
	# 				NHK NEWS
	# *************************
	@rubyshin.message content: /!r\s+nhk\s+news+\s([a-zA-Z]|[　-龯]).*/ do |event|
		puts event.content
		category = event.content.split(" ")[3]
		category.downcase!
		cat = "cat"
		case category
		when "主要ニュース", "main"
			cat += "0"
		when "社会", "society", "soc"
			cat += "1"
		when "文化", "エンタメ", "culture", "entertainment", "ent"
			cat += "2"
		when "科学", "医療", "science", "medicine", "sci", "med"
			cat += "3"
		when "政治", "politics", "pol"
			cat += "4"
		when "経済", "economics", "economy", "eco"
			cat += "5"
		when "国際", "international", "intl"
			cat += "6"
		when "スポーツ", "sports", "sp"
			cat += "7"
		when "ライブ", "live"
			cat += "-live"
		else
			cat += "0"
		end

		rss_response = newsRss.nhk_news_rss(cat)
		index = 0
		nhk_thumb = "https://pbs.twimg.com/profile_images/1232909058786484224/X8-z940J_400x400.png"
		nhk_link = "https://www.nhk.or.jp/"

		embed = newsRss.create_embed(rss_response, index, nhk_thumb, nhk_link)

		embed[:footer][:text] = "#{event.user.name} ##{event.user.discriminator} can use the reaction buttons below to cycle pages!"
		embed[:footer][:icon_url] = event.user.avatar_url
		
		m = event.respond("", false, embed)
		m.react LEFTWARDS_ARROW
		m.react RIGHTWARDS_ARROW

		# NEXT ARROW
		@rubyshin.add_await(:"cycle_next_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: RIGHTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id && event.user.id == reaction_event.user.id

			index >= rss_response.items.length - 1 ? index = 0 : index += 1
			
			embed[:author][:name] = "#{rss_response.channel.title} | page #{index + 1}/#{rss_response.items.length}"
			embed[:title] = rss_response.items[index].title
			embed[:url] = rss_response.items[index].link
			embed[:description] = rss_response.items[index].description
			embed[:timestamp] = DateTime.rfc822(rss_response.items[index].pubDate.to_s)

			m.edit("", embed)
			m.delete_all_reactions
			m.react LEFTWARDS_ARROW
			m.react RIGHTWARDS_ARROW
			return false # this allows the await to be repeated
		end
		
		# PREV ARROW
		@rubyshin.add_await(:"cycle_prev_#{m.id}", Discordrb::Events::ReactionAddEvent, emoji: LEFTWARDS_ARROW, timeout: 45) do |reaction_event|
			next true unless reaction_event.message.id == m.id && event.user.id == reaction_event.user.id

			index == 0 ? index = rss_response.items.length - 1 : index -= 1

			embed[:author][:name] = "#{rss_response.channel.title} | page #{index + 1}/#{rss_response.items.length}"
			embed[:title] = rss_response.items[index].title
			embed[:url] = rss_response.items[index].link
			embed[:description] = rss_response.items[index].description
			embed[:timestamp] = DateTime.rfc822(rss_response.items[index].pubDate.to_s)

			m.edit("", embed)
			m.delete_all_reactions
			m.react LEFTWARDS_ARROW
			m.react RIGHTWARDS_ARROW
			return false
		end
	end

	@rubyshin.join
end
