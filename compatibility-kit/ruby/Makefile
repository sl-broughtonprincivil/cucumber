include default.mk

CCK_PATH = ..

# https://stackoverflow.com/questions/2483182/recursive-wildcards-in-gnu-make
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

CCK_FEATURES=$(call rwildcard,$(CCK_PATH)/javascript/features,*.feature)
FEATURES=$(patsubst $(CCK_PATH)/javascript/%,%,$(CCK_FEATURES))
NDJSON=$(patsubst %.feature,%.ndjson,$(FEATURES))
SPEC=$(patsubst %.feature,%_spec.rb,$(FEATURES))
RUBY_FILES=$(call rwildcard,../lib ../../cucumber-ruby-core/lib/,*.rb)

SELF_TESTED = $(patsubst %.feature,%.json.tested,$(FEATURES))
JSONS=$(patsubst %.feature,%.json,$(FEATURES))
GOLDEN_JSONS=$(patsubst %.feature,%-golden.json,$(FEATURES))

CCK_JSON_TESTED=$(patsubst %.feature,%-cck.json.tested,$(FEATURES))
CCK_JSONS=$(patsubst %.feature,%-cck.json,$(FEATURES))

default: tested cck_json_compared

reports: json_reports html_reports
.PHONY: reports

clean:
	rm -rf Gemfile.lock **/*.feature **/*.ndjson feature/**.json features/**/*_spec.rb output
.PHONY: clean

###############################################################################
#            Run features file and compare messages against CCK               #
###############################################################################

tested: $(SPEC) $(NDJSON)
	bundle exec rspec features/**/*_spec.rb
.PHONY: tested

%_spec.rb: %.ndjson templates/specs.rb
	cp templates/specs.rb $@

###############################################################################
#     Run features file and compare messages against CCK JSONS                #
###############################################################################

cck_json_compared: $(CCK_JSON_TESTED)
.PHONY: cck_json_compared

%-cck.json.tested: %-cck.json %-neutralized.json
	diff --unified $^
.PHONY: %-cck.json.tested

%-cck.json: scripts/neutralize-json-cross-language # Need to make it depend on source file ...
	cat $(CCK_PATH)/javascript/$(patsubst %-cck.json,%.ndjson,$@) | \
		"$(CCK_PATH)/scripts/cucumber-json-formatter" | \
		jq --sort-keys "." | \
		scripts/neutralize-json-cross-language > $@

%-neutralized.json: %.json scripts/neutralize-json-cross-language
	cat $< | \
		jq --sort-keys "." | \
		scripts/neutralize-json-cross-language > $@

###############################################################################
#        Compare --format=json against --format=message | json-formatter      #
###############################################################################

self_tested: $(SELF_TESTED)

%.json.tested: %-golden.json %.json
	-diff --unified $^

%.json: %.ndjson scripts/neutralize-json
	cat $< | "$(CCK_PATH)/scripts/cucumber-json-formatter" | \
		jq --sort-keys "." | \
		scripts/neutralize-json > $@

%-golden.json: %.feature %_steps.rb Gemfile.lock $(RUBY_FILES) scripts/neutralize-json
	-bundle exec cucumber $< --require $(patsubst %-golden.json,%_steps.rb,$@) --format=json  | \
		jq --sort-keys "." | \
		scripts/neutralize-json > $@

###############################################################################
#                    Get features from CCK and run them                       #
###############################################################################

%.ndjson: %.feature %_steps.rb Gemfile.lock $(RUBY_FILES)
	-bundle exec cucumber $< --require $(patsubst %.ndjson,%_steps.rb,$@) --format=message > $@

%.feature:
	mkdir -p $(@D)
	cp $(patsubst %,$(CCK_PATH)/javascript/%,$@) $@

###############################################################################
#               Generate reports after execution against CCK                  #
###############################################################################

json_reports: $(NDJSON)
	mkdir -p output/json
	$(CCK_PATH)/scripts/run-formatter \
                -e .json \
                -o output/json \
                -c "$(CCK_PATH)/scripts/cucumber-json-formatter" \
                features/**/*.ndjson
.PHONY: json_reports

html_reports: $(NDJSON)
	mkdir -p output/html
	$(CCK_PATH)/scripts/run-formatter \
                -e .html \
                -o output/html \
                -c "$(CCK_PATH)/scripts/cucumber-html-formatter" \
                features/**/*.ndjson
.PHONY: html_reports
