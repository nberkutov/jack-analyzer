build:
	mkdir -p build/bin
	dart2native bin/main.dart -o build/bin/JackAnalyzer
clean:
	cd build; rm -r .