require 'mechanize'
require 'uri'
require_relative 'auth.rb'
require_relative 'input_discovery.rb'

class Page
  COMMON_EXTENSIONS = %w(html jsp aspx php)
  @@pages = []
  @@authed = false
  @@agent = Mechanize.new
  attr_accessor :url, :params, :host_url
  # set default for @crawled, get the full url without params,
  # and take all the params on the url and store them
  def initialize(input_url, auth_site)
    @crawled = false
    unless @@authed 
      @@agent = auth(@@agent, auth_site)
      @@authed = true
    end
    @url = full_path(input_url)
    @params = parse_params(input_url)
  end

  # gets the page and its links, then calls parse_urls
  def self.crawl!

    begin
      discoverCookies(@@agent)
    rescue
    end

    puts "Pages: "

    until @@pages.all?(&:crawled?)
      @@pages.each do |page|
        unless page.crawled?
          begin
            page_data = @@agent.get(page.url)
            links = page_data.links.map do |link| 
              if link.href.include? page.host_url
                link.href 
              else
                if link.href[0] == "?"
                  "#{page.url}#{link.href}"
                else
                  "#{page.host_url}/#{link.href}" 
                end
              end
            end

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
          agent_page = @@agent.get(page.url)
          discoverFormParameters(agent_page)
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
      next if url =~ /.+\.$/ 
      next if url =~ /.*\/\/.+:\/\//
      # catches bad input from self.crawl! like site.com/index.jsp/index.jsp

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
    words = []
    File.readlines(file).each do |word|
      words << word
    end

    @@pages.each do |page|
      short_url = page.url.split("/")[0..-1].join("/")
      words.each do |word|
        COMMON_EXTENSIONS.each do |ext|
          begin
            test_url = "#{short_url}/#{word}.#{ext}"
            page = @@agent.get(test_url)
            Page.new(test_url, nil) if page.code.to_i == 200
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
    @host_url = "#{uri.scheme}://#{uri.host}"
    unless uri.port.nil?
      @host_url += ":#{uri.port}"
    end

    if uri.port == 80 && !url.include?("dvwa")
      @host_url += "/dvwa" 
    elsif uri.port == 8080 && !url.include?("bodgeit")
      @host_url += "/bodgeit" 
    end
    @host_url + uri.path
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
