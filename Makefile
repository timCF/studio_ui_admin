rebuild:
	git submodule init
	git submodule update
	rm -rf ./node_modules
	rm -rf ./bower_components
	npm install
	bower install