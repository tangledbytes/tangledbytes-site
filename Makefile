build:
	hugo --minify --gc --cleanDestinationDir && npx pagefind --source public

dev:
	hugo server -D --minify --bind 0.0.0.0

clean:
	rm -rf public