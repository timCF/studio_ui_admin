rebuild:
	git submodule init
	git submodule update
	rm -rf ./node_modules
	rm -rf ./bower_components
	npm install
	bower install --allow-root
	npm rebuild node-sass
	brunch b
	brunch b --production
