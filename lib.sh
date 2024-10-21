function config_set_view {
    local dirname="$1"
    local view_command="$2"
    local err="$(stat "$dirname/config.json" > /dev/null)"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
    local JQ_PREFIX=".viewCommand = \"$view_command\""
    err="$(jq "$JQ_PREFIX" "$dirname/config.json" > "$dirname/config.json.tmp")"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
    err="$(mv "$dirname/config.json.tmp" "$dirname/config.json")"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
}

function config_set_preview {
    local dirname="$1"
    local preview_command="$2"
    local err="$(stat "$dirname/config.json" > /dev/null)"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
    local JQ_PREFIX=".previewCommand = \"$preview_command\""
    err="$(jq "$JQ_PREFIX" "$dirname/config.json" > "$dirname/config.json.tmp")"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
    err="$(mv "$dirname/config.json.tmp" "$dirname/config.json")"
    if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
    fi
}

function config_get_view {
	local dirname="$1"
	local err="$(stat "$dirname/config.json" > /dev/null)"
	if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
	fi
	local view_command="$(jq -r '.viewCommand' "$dirname/config.json")"
	echo "$view_command"
}

function config_get_preview {
	local dirname="$1"
	local err="$(stat "$dirname/config.json" > /dev/null)"
	if [ $? -ne 0 ]; then
	echo "$err"
	exit 1
	fi
	local preview_command="$(jq -r '.previewCommand' "$dirname/config.json")"
	echo "$preview_command"
}

function get_starred_repos {
    local dirname="$1"
    local username="$2"
    local queryPath="$dirname/graphql/queries/get-starred-repos.graphql"
    local response="$(exec gh api graphql \
	-f login="$username" \
	-f query="$(cat $queryPath)" \
	--jq '[.data.user.starredRepositories.edges[] | .node]'
    )"

    # define table data
    local table_headers=$(echo -e "REPO\tDESCRIPTION\tURL")
    local table_data="$(echo "$response" | \
	jq --color-output \
	    -r '.[] | "\(.nameWithOwner)\t\"\(.description)\"\t\(.url)\"\t\(.id)"'
    )"
    local table="$(echo -e "${table_headers}\n${table_data}")"
    
    local readme_query=$(cat "$dirname/graphql/queries/get-readme.graphql")

    README_QUERY_PREFIX="gh api graphql \
        -f query='$readme_query' \
        --jq '.data.node | if (.masterReadme.text == null or .masterReadme.text == \"\") then .mainReadme.text else .masterReadme.text end' \
        -f nodeId="
    SEP=" | "
    WEB_BROWSER_CMD="gh repo view -w "
    PREVIEW_CMD="$(config_get_preview "$dirname")"
    BECOME_CMD="$(config_get_view "$dirname")"
    echo "$table" | \
    sed $'s/ /\u00a0/g' | \
    column -t -s $'\t' | \
    fzf --ansi \
	--nth=1 \
	--header-lines=1 \
	--delimiter='\s+'\
	--with-nth=1..4\
	--preview-label='README'\
	--bind "?:preview($README_QUERY_PREFIX{-1}$SEP$PREVIEW_CMD)"\
	--bind "_:close"\
	--bind "ctrl-v:become($README_QUERY_PREFIX{-1}$SEP$PREVIEW_CMD)"\
	--bind "ctrl-t:become($WEB_BROWSER_CMD{1})"\
	--bind "enter:become($README_QUERY_PREFIX{-1}$SEP$BECOME_CMD)"\
	--bind "enter:+become(echo {})"
}

function get_user_lists {
    local dirname="$1"
    local username="$2"
    local queryPath="$dirname/graphql/queries/get-lists-with-ids.graphql"
    local pageSize=100 # max page size from GitHub GraphQL API

    local response="$(exec gh api graphql \
	-f login="$username" \
	-f query="$(cat $queryPath)" \
	--jq '.data.viewer.lists.nodes' #TODO: Also destructure pagination cursors
    )"

    local table_headers=$(echo -e "LIST\tLAST-ADDED-TO")
    local table_data="$(\
	echo "$response" | \
	jq --color-output \
	-r '.[] | "\(.name)\t\(.lastAddedAt | split("T")[0])\t\(.id)"'
    )"
    local table="$(echo -e "${table_headers}\n${table_data}")"

    local id="$(echo "$table" | \
    sed $'s/ /\u00a0/g' | \
    column -t -s $'\t' | \
    fzf --ansi \
	--nth=1 \
	--header-lines=1 \
	--delimiter='\s+'\
	--with-nth=1..2\
	--preview-label='README'\
	--bind "enter:become(echo {-1})")"

    if [[ -z "$id" ]]; then
	echo "No list selected" # TODO: REMOVE WHEN OBSELETE
	exit 0
    fi

    get_repos_by_userlist_id "$dirname" "$username" "$id"
}

function get_repos_by_userlist_id {
    local dirname="$1"
    local username="$2"
    local id="$3"

    local repo_query_path="$dirname/graphql/queries/get-repos-by-userlist-id.graphql"

    local response=$(exec gh api graphql \
	-f login="$username" \
	-f nodeId="$id" \
	-f query="$(cat $repo_query_path)" \
	--jq '.data.node.items.nodes' # TODO: Also destructure pagination cursors
    ) 

    local table_headers=$(echo -e "REPO\tDESCRIPTION\tURL")
    local table_data="$(\
	echo "$response" | \
	jq --color-output \
	    -r '.[] | "\(.nameWithOwner)\t\(.description)\t\(.url)\t\(.id)"'\
    )"
    local table="$(echo -e "${table_headers}\n${table_data}")"

    local readme_query=$(cat "$dirname/graphql/queries/get-readme.graphql")

    README_QUERY_PREFIX="gh api graphql \
        -f query='$readme_query' \
        --jq '.data.node | if (.masterReadme.text == null or .masterReadme.text == \"\") then .mainReadme.text else .masterReadme.text end' \
        -f nodeId="
    SEP=" | "
    PREVIEW_CMD="$(config_get_preview "$dirname")"
    BECOME_CMD="$(config_get_view "$dirname")"
    WEB_BROWSER_CMD="gh repo view -w "
    echo "$table" | \
    sed $'s/ /\u00a0/g' | \
    column -t -s $'\t' | \
    fzf --ansi \
	--nth=1 \
	--header-lines=1 \
	--delimiter='\s+'\
	--with-nth=1..3\
	--preview-label='README'\
	--bind "?:preview($README_QUERY_PREFIX{-1}$SEP$PREVIEW_CMD)"\
	--bind "_:close"\
	--bind "ctrl-t:become($WEB_BROWSER_CMD{1})"\
	--bind "ctrl-v:become($README_QUERY_PREFIX{-1}$SEP$PREVIEW_CMD)"\
	--bind "enter:become($README_QUERY_PREFIX{-1}$SEP$BECOME_CMD)"
}
