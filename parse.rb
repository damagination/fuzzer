require 'mechanize'
require 'uri'
load 'main.rb'

def getFullPath(url)
  uri = URI(url)
  returnUrl = uri.scheme + '://' + uri.host + uri.path
  if not uri.port.to_s.empty?
    port = ':' + uri.port.to_s
  end
  returnUrl + port
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

# urlList = ['http://localhost:8081', 'http://localhost:8080/hello?2=2', 'http://localhost:8080/hello?1=1', 'http://localhost:8080?index=555']
# p parseUrls(urlList)
# returns => {"http://localhost:8081"=>{}, "http://localhost/hello:8080"=>{"2"=>"2", "1"=>"1"}, "http://localhost:8080"=>{"index"=>"555"}}