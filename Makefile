all:
	ruby make.rb

watch:
	while inotifywait posts/*.rhtml; do make; done

serve:
	ruby -run -e httpd blog/ -p 8000
