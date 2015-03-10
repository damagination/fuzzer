require 'mechanize'
require 'rubygems'

#Input: a page
#Results: prints all inputs from the page
def discoverFormParameters(page)
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
    puts ""
  end
end

def discoverCookies(agent)
  puts "Cookie #{agent.cookies.to_s}"
end
