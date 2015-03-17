# fuzzer

Installation

1. gem install bundler

2. bundler install --path=[enter the fuzzer directory here]

3. When running ruby main.rb ... you need to add bundler exec before the ruby main.rb ... 


Example usage
	
bundler exec ruby main.rb discover http://127.0.0.1/dvwa/index.php --custom-auth=dvwa
