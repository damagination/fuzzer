require 'mechanize'

$dvwa_user = 'admin'
$dvwa_pass = 'password'

$bodgeIt_user = 'j@j.j'
$bodgeIt_pass = '     '

# Authenticates the agent and returns the logged in agent
def auth(agent, website)

  if website == 'dvwa'
    agent.get('http://127.0.0.1/dvwa/login.php') do |page|

      # Submit the login form
      my_page = page.form_with(:action => 'login.php') do |form|
        username_field = form.field_with(:name => 'username')
        username_field.value = $dvwa_user
        password_field = form.field_with(:name => 'password')
        password_field.value = $dvwa_pass
      end.click_button
    end
    # Return the agent after auth
    agent
  elsif website == 'bodgeit'
    agent.get('http://127.0.0.1:8080/bodgeit/login.jsp') do |page|

      # Submit the login form
      my_page = page.form_with(:method => 'POST') do |form|
        username_field = form.field_with(:name => 'username')
        username_field.value = $bodgeIt_user
        password_field = form.field_with(:name => 'password')
        password_field.value = $bodgeIt_pass
      end.click_button
    end
    # Return the agent after auth
    agent
  end
  agent
end

# Register for bodgeit store account
def register(agent)
  agent.get('http://127.0.0.1:8080/bodgeit/register.jsp') do |page|

    # Submit the login form
    my_page = page.form_with(:method => 'POST') do |form|
      username_field = form.field_with(:name => 'username')
      username_field.value = $bodgeIt_user
      password1_field = form.field_with(:name => 'password1')
      password1_field.value = $bodgeIt_pass
      password2_field = form.field_with(:name => 'password2')
      password2_field.value = $bodgeIt_pass
    end.click_button
  end
  # Return the agent after auth
  agent
end