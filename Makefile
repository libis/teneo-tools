include .env
export

VERSION = $(shell awk --field-separator '"' '/VERSION/' $(VERSION_FILE))

patch: _patch _publish

minor: _minor _publish

major: _major _publish

_patch:
	gem bump -v patch --no-commit

_minor:
	gem bump -v minor --no-commit

_major:
	gem bump -v major --no-commit

_publish:
	bundle install
	git commit -am 'Version bump: $(VERSION)'
	gem release --tag --push --github --key github --token $(CHANGELOG_GITHUB_TOKEN)
	github_changelog_generator --token $(CHANGELOG_GITHUB_TOKEN)
