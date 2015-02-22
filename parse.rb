require 'mechanize'
require 'uri'
load 'main.rb'

def getFullPath(url)
  uri = URI(url)
  returnUrl = uri.scheme + '://' + uri.host
  if not uri.port.to_s.empty?
    port = ':' + uri.port.to_s
  end
  returnUrl + port  + uri.path
end

def getQueryParams(url)
  uri = URI(url)
  uri.query
end

# Checks if the url is the same host as the original url
def sameHost?(url)
  getFullPath(@input_url).eql?(getFullPath(url))
end

# Returns a hash of the query parameters for a given query string
def queryToHash(query)
  return {} if query.nil?

  queryPairs = Hash.new
  pairs = query.split('&')
  pairs.each do |pair|
    name, value = pair.split('=')
    queryPairs[name] = value
  end
  queryPairs
end

# Input: Array of urls (Strings)
# Output: Hash of urls (key) with all the found query parameters
def parseUrls(urls)
  urlPairs = Hash.new( Hash.new )

  urls.each do |url|
    # Create new key value if key doesn't exist
    # Else merge the query param hashs together
    urlPairs[getFullPath(url)] = urlPairs[getFullPath(url)]
                                    .merge(queryToHash(getQueryParams(url)))
  end
  urlPairs
end

# urlList = ['http://127.0.0.1/dvwa/index.php', 'http://127.0.0.1:8080/bodgeit/', 'http://www.ritathletics.com/sports/2007/10/31/saac2007.aspx', 'http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Operators', 'http://localhost:8081/index.jsp', 'http://localhost:8080/hello?2=2', 'http://localhost:8080/hello?1=1', 'http://localhost:8080?index=555']
# p parseUrls(urlList)
# returns => {"http://127.0.0.1:80/dvwa/index.php"=>{}, "http://127.0.0.1:8080/bodgeit/"=>{}, "http://www.ritathletics.com:80/sports/2007/10/31/saac2007.aspx"=>{}, "http://en.wikibooks.org:80/wiki/Ruby_Programming/Syntax/Operators"=>{}, "http://localhost:8081/index.jsp"=>{}, "http://localhost:8080/hello"=>{"2"=>"2", "1"=>"1"}, "http://localhost:8080"=>{"index"=>"555"}}