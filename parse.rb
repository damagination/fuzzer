require 'mechanize'
require 'uri'
load 'main.rb'

def getFullPath(url)
  uri = URI(url)
  uri.host + uri.path
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
  queryPairs = Hash.new
  pairs = query.split('&')
  pairs.each do |pair|
    name, value = pair.split('=')
    queryPairs[name] = value
  end
  queryPairs
end

