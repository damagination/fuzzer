require 'mechanize'
require 'rubygems'

def discoverFormParameters(url)

	#TOOD:Check if url is within DVWA first

	agent = Mechanize.new
	page = agent.get(url)
	page.forms.each do |f|
		puts "Form name: #{f.name}"
		puts "Action: #{f.action}"
		puts "Method: #{f.method}"
	
		f.fields.each do |field|
			puts "Field: #{field.name}"
		end

		f.buttons.each do |b|
			puts "Button: #{b.name}"
		end
	end
end

def discoverCookies(agent)
	puts agent.cookies.to_s 
end

