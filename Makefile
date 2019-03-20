include ./.env
export

.DEFAULT_GOAL := default

default:
	$(warning URL_ES = ${URL_ES})
	$(warning ES_INDEX = ${ES_INDEX})

###---------------------------------------
# API
###---------------------------------------
health:
	@ curl ${URL_ES}/_cluster/health

index:
	@ curl ${URL_ES}/_cat/indices?format=json&s=index

create-index:
	@ curl -XPUT ${URL_ES}/${ES_INDEX}

delete-index:
	@ curl -XDELETE ${URL_ES}/${ES_INDEX}

post-record:
	@ curl -K .curlrc \
		-XPOST \
		${URL_ES}/${ES_INDEX}/${ES_TYPE} \
		-d@-

post-record-bulk:
	@ curl -K .curlrc \
		-XPOST \
		${URL_ES}/_bulk \
		--data-binary @-

###---------------------------------------
# sample log
###---------------------------------------
gen-sample-tsv: NUM := 100
gen-sample-tsv:
	@ seq 1 ${NUM} | while read x; do \
		date -d "$$x seconds ago" +"$$x"$$'\t'"%Y-%m-%dT%H:%M:%S.%6N%z"; \
	done

tsv-to-json:
	@ jq -c -s -R -f jq/es/tsv2json.jq

to-bulk-format:
	@ jq -c -f jq/es/format.bulk.jq


###---------------------------------------
# import
###---------------------------------------
# 1件ずつ入れる
import-per:
	@ $(MAKE) gen-sample-tsv | $(MAKE) tsv-to-json \
		| while read x; do echo "$$x" | $(MAKE) post-record; done

# バルクインポート形式に整形
cmd-import-bulk:
	@ $(MAKE) gen-sample-tsv | $(MAKE) tsv-to-json \
		| $(MAKE) to-bulk-format \

# バルクインポート
import-bulk:
	@ $(MAKE) cmd-import-bulk \
		| $(MAKE) post-record-bulk

###---------------------------------------
# dump
###---------------------------------------
# まるごとダンプする
dump-whole:
	@ curl -K .curlrc -XGET "${URL_ES}/${ES_INDEX}/_count" \
		| jq -f jq/es/dump.whole.jq \
		| curl -K .curlrc \
			-XGET "${URL_ES}/${ES_INDEX}/_search" -d@- \
		| jq -c '.hits.hits[]'

# 指定件数ごとにダンプするcurlコマンド
cmd-dump-per: export PER := 100
cmd-dump-per:
	@ curl -K .curlrc \
			-XGET "${URL_ES}/${ES_INDEX}/_count" \
		| jq -c -f jq/es/dump.per.jq \
		| while read x; do \
			echo curl -K .curlrc \
				-XGET "${URL_ES}/${ES_INDEX}/_search" -d"'$$x'"; \
		done

# 指定件数ごとに全件ダンプ
dump-per:
	@ $(MAKE) cmd-dump-per | sh | jq -c '.hits.hits[]'

