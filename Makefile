#!/usr/bin/make -f

.PHONY: server livereload post

DATE:=$(shell date "+%Y-%m-%d")
POST:=new

# -----------------------------------------------------------------------------

server:
	bundle exec jekyll serve --host 0.0.0.0

livereload:
	bundle exec jekyll serve --host 0.0.0.0 --livereload

post:
	@touch _posts/${DATE}-new.md
	@echo '---' >> _posts/${DATE}-new.md
	@echo 'title: TBD' >> _posts/${DATE}-new.md
	@echo '---' >> _posts/${DATE}-new.md
	@echo ">>> create post named _posts/${DATE}-new.md"
