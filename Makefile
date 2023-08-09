build:
	hugo --minify --gc --cleanDestinationDir && npx pagefind --source public

dev:
	hugo server -D --minify

clean:
	rm -rf public