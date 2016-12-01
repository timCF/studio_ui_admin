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
desktop:
	rm -rf ./public/desktop_tmp
	rm -rf ./public/desktop
	mkdir ./public/desktop_tmp
	mkdir ./public/desktop
	cd ./public/desktop_tmp && electron-packager ../../ studio_ui_admin --platform=all --arch=all --ignore="node_modules|bower_components|\.git" && for i in *; do zip -r $$i $$i; done && cd ../../
	cp ./public/desktop_tmp/*.zip ./public/desktop
	zip -r ./public/studio_ui_admin.zip ./public/desktop
	./deploy_yandex.sh ./public/studio_ui_admin.zip
	rm -rf ./public/desktop_tmp
