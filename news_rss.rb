require "date"
require "rss"
require "open-uri"

class NewsRSS
  # attr_accessor :attribute_name
  # def initialize(attribute)
  #   @attribute = attribute
  # end

  def get_rss(url)
    begin
      URI.open(url) do |rss|
        return feed = RSS::Parser.parse(rss)
      end # open
    rescue => exception
      puts "There was an oopsy woopsy:\n"
      puts exception
    end # begin/rescue
  end # rss

  def create_embed(rss_response, index, icon_url, pub_url)
		embed = {
			color: 0xEC1622,
			title: rss_response.items[index].title,
			url: rss_response.items[index].link,
			author: {
				name: "#{rss_response.channel.title} | page #{index + 1}/#{rss_response.items.length}",
				icon_url: icon_url,
				url: pub_url,
			},
			description: rss_response.items[index].description,
			thumbnail: {
				url: icon_url,
			},
			timestamp: DateTime.rfc822(rss_response.items[0].pubDate.to_s),
			footer: {
				text: "",
				icon_url: icon_url,
			},
		}
		return embed
	end

  # https://www.japantimes.co.jp/
  # https://www.japantimes.co.jp/about-us/link-policy/
  # excerpt must be <= 20% of the original article
  def japan_times_rss()
    japanTimes = get_rss("https://www.japantimes.co.jp/feed/topstories/")
      # items
        # .title
        # .link
        # .description
        # .category
        # .author
        # .pubDate
        # .guid

    return japanTimes
  end # japan_times_rss

  # https://news.tv-asahi.co.jp/
  # http://www.asahi.com/information/service/rss.html
  def asahi_news_rss()
    asahi = get_rss("http://www.asahi.com/rss/asahi/newsheadlines.rdf")
    return asahi
  end # asahi_news_rss

  # https://mainichi.jp/rss/
    # https://mainichi.jp/rss/etc/mainichi-sports.rss
    # https://mainichi.jp/rss/etc/mainichi-enta.rss
    # https://mainichi.jp/rss/etc/opinion.rss
  def mainichi_news_rss()
    mainichi = get_rss("https://mainichi.jp/rss/etc/mainichi-flash.rss")
      # item rdf:about
        # .title
        # .link
        # dc:subject
        # dc:date
      return mainichi
  end # mainichi_news_rss

  def nhk_news_rss(cat = "cat0")
    # cat0 主要ニュース
    # cat1 社会
    # cat2 文化・エンタメ
    # cat3 科学・医療
    # cat4 政治
    # cat5 経済
    # cat6 国際
    # cat7 スポーツ
    # cat-live LIVEニュース
    nhk = get_rss("https://www.nhk.or.jp/rss/news/#{cat}.xml")
    return nhk
  end # nhk_news_rss

end # module
