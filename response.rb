require 'mechanize'
require 'benchmark'

#Input: a mechanize page
#Results: returns status code
def get_status_code(page)
  page.code
end

def check_delayed_form_response(form, threshold)
  response = nil
  time = Benchmark.realtime do 
    response = form.submit
  end
  [response, calulate_delay(threshold, time)]
end

def check_delayed_page_response(agent, page_url, threshold)
  response = nil
  time = Benchmark.realtime do 
    response = agent.get(page_url)
  end
  [response, calulate_delay(threshold, time)]
end

def calulate_delay(threshold, time)
  if threshold
    thresh_micro = threshold.to_i / 1000.0 
    time > thresh_micro
  else
    false
  end
end

