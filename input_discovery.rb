require 'mechanize'
require 'rubygems'

# Input: a mechanize page, array of words
# Results: prints all inputs from the page and vulnerabilities found
def discover_form_parameters(page, vectors, threshold)
  puts "\t Forms:" if page.forms.any?
  page.forms.each do |form|
    puts "\t\t Form name: #{form.name}"
    puts "\t\t Action: #{form.action}"
    puts "\t\t Method: #{form.method}"

    form.fields.each do |field|
      puts "\t\t Field: #{field.name}"
    end

    form.buttons.each do |button|
      puts "\t\t Button: #{button.name}"
    end
    
    puts "\t\t Vectors:"

    # we dont know what the fields are or have a smart way to read them, the only ones bad to input
    # are any hidden csrf tokens, so we ignore these and submit with the visible ones
    public_fields = form.fields.select{ |f| f.type != "hidden" }
    
    # go through each vector and try to get it to spit out unsanitized data
    vectors.each do |vector|
      # set every visible input's value to the vector
      public_fields.each do |f| 
        f.value = vector
      end
      
      # submit the form with the values filled in, returns a mechanize page
      result_page = check_delayed_form_response(form, threshold)

      if result_page.body.include? vector
        # if the page body includes the exact vector, then it is very much unsanitized
        puts "\t\t\t(definitely) '#{vector}'"
      elsif !result_page.body.include?(CGI::escapeHTML(vector))
        # else, if the body doesnt have the escaped vector, it may be only partially sanitized
        # (or it may just not render the query to the page)
        puts "\t\t\t(maybe) '#{vector}'"
      end
    end

    puts ""



  end
end

def discoverCookies(agent)
  agent.cookies.each do |cookie|
    puts "Cookie: #{cookie.to_s}"
  end
end
