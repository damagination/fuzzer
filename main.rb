require "optparse"
require "mechanize"
require_relative 'parse.rb'

@input_url = nil

# Help message
@message = %q{
fuzz [discover | test] url OPTIONS

COMMANDS:
  discover  Output a comprehensive, human-readable list of all discovered inputs to the system. Techniques include both crawling and guessing.
  test      Discover all inputs, then attempt a list of exploit vectors on those inputs. Report potential vulnerabilities.

OPTIONS:
  --custom-auth=string     Signal that the fuzzer should use hard-coded authentication for a specific application (e.g. dvwa). Optional.

  Discover options:
    --common-words=file    Newline-delimited file of common words to be used in page guessing and input guessing. Required.

  Test options:
    --vectors=file         Newline-delimited file of common exploits to vulnerabilities. Required.
    --sensitive=file       Newline-delimited file data that should never be leaked. It's assumed that this data is in the application's database (e.g. test data), but is not reported in any response. Required.
    --random=[true|false]  When off, try each input to each page systematically.  When on, choose a random page, then a random input field and test all vectors. Default: false.
    --slow=500             Number of milliseconds considered when a response is considered "slow". Default is 500 milliseconds

Examples:
  # Discover inputs
  fuzz discover http://localhost:8080 --common-words=mywords.txt

  # Discover inputs to DVWA using our hard-coded authentication
  fuzz discover http://localhost:8080 --common-words=mywords.txt

  # Discover and Test DVWA without randomness
  fuzz test http://localhost:8080 --custom-auth=dvwa --common-words=words.txt --vectors=vectors.txt --sensitive=creditcards.txt --random=false
}

def getOptions
    # Get the options for the program
    options = {}
    OptionParser.new do |opt|
        opt.on('--custom-auth STRING') { |o| options['custom_auth'] = o }
        opt.on('--common-words FILE') { |o| options['common_words'] = o }

        opt.on('--vectors FILE') { |o| options['vectors'] = o }
        opt.on('--sensitive FILE') { |o| options['sensitive'] = o }
        opt.on('--random [ture|false]') { |o| options['random'] = o }
        opt.on('--slow 500') { |o| options['slow'] = o }
    end.parse!
    return options
end

def getArguments
    # Get arguments
    command = ARGV.shift
    url = ARGV.shift

    # Check that arguments exist
    if command.nil? or url.nil?
        puts @message
        exit(-1)
    end
    return [command, url]
end


def main
    args = getArguments()
    opts = getOptions()
    @auth_site = nil

    @input_url = args[1]
    if ['discover', 'test'].include?(args[0])
      if ['dvwa', 'bodgeit'].include?(opts['custom_auth'])
        @auth_site = opts['custom_auth'].downcase
      end
      page = Page.new(@input_url, @auth_site, opts['slow'])
      Page.add(page)
      Page.crawl!(opts['vectors'], opts['sensitive'])
      Page.guess(opts['common_words']) if opts['common_words']
    else
      puts @message
    end
end

main