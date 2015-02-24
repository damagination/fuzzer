require 'mechanize'
require 'rubygems'
require_relative 'parse.rb'

#Input: a url
#Results: prints all inputs from the page
def discoverFormParameters(url)

	if sameHost?(url)
		agent = Mechanize.new
		page = agent.get(url)
		
		pp page
		
		page.forms.each do |form|
			puts "Form name: #{form.name}"
			puts "Action: #{form.action}"
			puts "Method: #{form.method}"
		
			form.fields.each do |field|
				puts "Field: #{field.name}"
			end

			form.buttons.each do |button|
				puts "Button: #{button.name}"
			end
			puts ""
		end
	end
end

def discoverCookies(agent)
	puts "Cookie #{agent.cookies.to_s}" 
end
