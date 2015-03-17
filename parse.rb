require 'mechanize'
require 'uri'
require_relative 'auth.rb'
require_relative 'response.rb'
require_relative 'input_discovery.rb'

class Page
  COMMON_EXTENSIONS = %w(html jsp aspx php)
  @@pages = []
  @@authed = false
  @@agent = Mechanize.new
  @@threshold = nil
  attr_accessor :url, :params, :host_url, :status_code, :delayed_response
  # set default for @crawled, get the full url without params,
  # and take all the params on the url and store them
  def initialize(input_url, auth_site, threshold)
    @crawled = false
    @status_code = nil
    @delayed_response = false
    @@threshold = threshold if @@threshold.nil?
    
    unless @@authed
      @@agent = auth(@@agent, auth_site)
      @@authed = true
    end
    
    @url = full_path(input_url)
    @params = parse_params(input_url)
  end

  # gets the page and its links, then calls parse_urls
  def self.crawl!(vector_file, sensitive_file)
    # if vector file was provided, read in the vectors
    vectors = []
    vectors = File.readlines(vector_file).map(&:strip) if vector_file

    # if sensitive words file was provided, read in those words
    sensitive_words = []
    sensitive_words = File.readlines(sensitive_file).map(&:strip) if sensitive_file
    
    begin
      discoverCookies(@@agent)
    rescue
    end

    puts "Pages: "

    until @@pages.all?(&:crawled?)
      @@pages.each do |page|
        unless page.crawled?
          begin
            page_data = check_delayed_page_response(@@agent, page.url, @@threshold)
            page.delayed_response = page_data[1] unless page.delayed_response

            links = page_data.first.links.map do |link|
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

            page.status_code = get_status_code(page_data.first)
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
      puts "\t Status Code: #{page.status_code}" unless page.status_code == "200"
      puts "\t Delayed Response: True" if page.delayed_response
      
      if page.params.any?
        puts "\t Params: (and known values to work)"
        page.params.each do |param, values|
          puts "\t\t #{param}: #{values.join(", ")}"
        end
      end
      
      begin
        agent_page = check_delayed_page_response(@@agent, page.url, @@threshold)
        page.delayed_response = agent_page[1] unless page.delayed_response.nil?
        
        leaked_data = []
        sensitive_words.each do |word|
          leaked_data << word if agent_page.first.body.include? word 
        end

        puts "Leaked words: #{leaked_data.join(', ')}" unless leaked_data.empty?

        discover_form_parameters(agent_page.first, vectors, @@threshold)
      rescue
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

      page = Page.new(url, nil, nil)
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
            page = check_delayed_form_response(@@agent, test_url, @@threshold)
            Page.new(test_url, nil, nil) if page.code.to_i == 200
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
