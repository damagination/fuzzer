require 'mechanize'

#Input: a mechanize page
#Results: returns status code
def get_status_code(page)
  page.code
end