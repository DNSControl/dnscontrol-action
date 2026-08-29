#!/usr/bin/env bash
set -eo pipefail

# this script is called by the dnscontrol-action commenting steps. it is not
# expected to work outside of GHA

$FJECHO "$STEP_TITLE"
comment_id=""
page=1
while [[ -z "$comment_id" ]]; do
  if [[ -n "$API_PAGER" ]]; then
    query_string="?${API_PAGER}=$PAGE_LIMIT&page=$page"
  else
    query_string=""
  fi
  $DEBUG "fetching page $page of PR comments:"
  $DEBUG "${PR_API_URL}${query_string}"

  comments=$($CURLJSON -H "Authorization: Token ${API_TOKEN}" \
    "${PR_API_URL}${query_string}")
  comment_id=$(printf '%s' "$comments" \
    | jq --arg marker "$MARKER" -r '[.[] | select(.body | contains($marker)) | .id] | first // empty')

  comments_length=$(printf '%s' "$comments" | jq 'length')
  $DEBUG "API returned $comments_length comments"

  if [[ -z "$API_PAGER" ]] || \
     [[ $comments_length -lt $PAGE_LIMIT ]] || \
     [[ -n "$comment_id" ]]; then
    break
  fi
  ((page++))
done

comment_payload=$(jq -n --arg body "$COMMENT_BODY" '{body: $body}')

if [[ -n "$comment_id" ]]; then
  $DEBUG "updating comment $comment_id"
  comment=$($CURLJSON -X PATCH -H "Authorization: Token ${API_TOKEN}" --json "$comment_payload" \
    "${COMMENT_API_URL}/$comment_id")
else
  $DEBUG "posting new comment"
  comment=$($CURLJSON -X POST -H "Authorization: Token ${API_TOKEN}" --json "$comment_payload" \
    "${PR_API_URL}")
fi

comment_url=$(printf '%s' "$comment" | jq -r '.html_url')
$DEBUG "$comment_url"
