require 'mechanize'
require 'rubygems'

#Input: a page
#Results: prints all inputs from the page
def discoverFormParameters(page)

		page.forms.each do |form|
			puts "\t\tForm name: #{form.name}"
			puts "\t\tAction: #{form.action}"
			puts "\t\tMethod: #{form.method}"

			form.fields.each do |field|
				puts "\t\tField: #{field.name}"
			end

			form.buttons.each do |button|
				puts "\t\tButton: #{button.name}"
			end
			puts ""
		end
end

def discoverCookies(agent)
	puts "Cookie #{agent.cookies.to_s}"
end
