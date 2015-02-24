require 'mechanize'
require 'uri'
require_relative 'auth.rb'
require_relative 'InputDiscovery.rb'

class Page
  COMMON_EXTENSIONS = %w(html jsp aspx php)
  @@pages = []
  attr_accessor :url, :params
  # set default for @crawled, get the full url without params,
  # and take all the params on the url and store them
  def initialize(url, auth)
    @crawled = false
    @url = full_path(url)
    @params = parse_params(url)
    @auth = auth
  end

  # gets the page and its links, then calls parse_urls
  def self.crawl!
    agent = Mechanize.new
    unless @auth.empty?
      agent = auth(agent, @auth)
    end

    begin
      discoverCookies(agent)
    rescue
    end

    puts "Pages: "

    until @@pages.all?(&:crawled?)
      @@pages.each do |page|
        unless page.crawled?
          begin
            page_data = agent.get(page.url)
            links = page_data.links.map(&:href).map { |link| "#{page.url}/#{link}" }
            self.parse_urls(links)
            page.crawled!
          rescue
            @@pages.delete page 
          end
        end
      end
    end

    @@pages.each do |page|
      puts page.url
      if page.params.any?
        puts "\t Params: (and known values to work)"
        page.params.each do |param, values|
          puts "\t\t #{param}: #{values.join(", ")}"
        end

        begin
          discoverFormParameters(page)
        rescue
        end
      end
    end
  end

  # used by self.crawl! to go through new urls and add them to the collection
  # of pages if they are not already there and combine with existing ones if
  # new parameters and values are discovered
  def self.parse_urls(urls)
    urls.each do |url|
      # clear out any bad input
      next if url.nil? || url.empty?
      # catches bad input from self.crawl! like site.com/index.jsp/index.jsp
      next if url =~ /\w\/\w+\.\w+\//

      page = Page.new(url, nil)
      if @@pages.include? page
        existing_page = @@pages.detect { |p| p.url == page.url }
        existing_page.add_params page.params
      else
        @@pages << page
      end
    end
  end

  # take a filename and guess pages based off of it
  def self.guess(file)
    agent = Mechanize.new
    File.readlines(file).each do |word|
      @@pages.each do |page|
        url = URI(page.url)
        base = "#{url.scheme}://#{url.host}"
        unless url.port.nil?
          port = ":#{url.port}"
        end
        paths = url.path.split("/")
        if paths.any?
          begin
            agent.get("#{base}#{paths.shuffle.join("/")}.#{COMMON_EXTENSIONS.sample}")
          rescue
            next
          end
        end
      end
    end
  end

  def self.add(page)
    @@pages << page
  end

  # merge in any new params discovered, add the successful value if
  # the params are already there to the array
  def add_params(new_params)
    new_params.each do |param, value|
      if @params[param].nil?
        @params[param] = value
      else
        (@params[param] += value).uniq!
      end
    end
  end

  def ==(another_page)
    @url == another_page.url
  end

  def crawled?
    @crawled
  end

  def crawled!
    @crawled = true
  end


  private

  # clean up the url for the Page object
  def full_path(url)
    uri = URI(url)
    returnUrl = "#{uri.scheme}://#{uri.host}"
    unless uri.port.nil?
      port = ":#{uri.port}"
    end
    returnUrl + port + uri.path
  end

  # Returns a hash of the query parameters for a given query string
  def parse_params(base_url)
    uri = URI(base_url)
    query = uri.query

    return {} if query.nil?

    queryPairs = Hash.new
    pairs = query.split('&')
    pairs.each do |pair|
      name, value = pair.split('=')
      queryPairs[name] = [value]
    end
    queryPairs
  end
end




# urlList = ['http://127.0.0.1/dvwa/index.php', 'http://127.0.0.1:8080/bodgeit/', 'http://www.ritathletics.com/sports/2007/10/31/saac2007.aspx', 'http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Operators', 'http://localhost:8081/index.jsp', 'http://localhost:8080/hello?2=2', 'http://localhost:8080/hello?1=1', 'http://localhost:8080?index=555']
# p parseUrls(urlList)
# returns => {"http://127.0.0.1:80/dvwa/index.php"=>{}, "http://127.0.0.1:8080/bodgeit/"=>{}, "http://www.ritathletics.com:80/sports/2007/10/31/saac2007.aspx"=>{}, "http://en.wikibooks.org:80/wiki/Ruby_Programming/Syntax/Operators"=>{}, "http://localhost:8081/index.jsp"=>{}, "http://localhost:8080/hello"=>{"2"=>"2", "1"=>"1"}, "http://localhost:8080"=>{"index"=>"555"}}