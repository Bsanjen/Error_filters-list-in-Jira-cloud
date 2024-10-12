#!/bin/bash

JIRA_USER="ABC@gmail.com"
JIRA_API_TOKEN="_____"
JIRA_DOMAIN="https://ABC.atlassian.net"

# Jira API URL to search filters
JIRA_FILTER_SEARCH_API="$JIRA_DOMAIN/rest/api/3/filter/search"

# Fetch filters using the search API
response=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" -X GET -H "Content-Type: application/json" "$JIRA_FILTER_SEARCH_API")

# Check if API call was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to search filters from Jira"
    exit 1
fi

# Try to parse JSON response
echo "$response" | jq -c '.values[]' | while read filter; do
    filter_id=$(echo "$filter" | jq '.id')
    filter_name=$(echo "$filter" | jq '.name')

    # Validate JQL for each filter
    filter_jql=$(echo "$filter" | jq -r '.jql')
    search_url="$JIRA_DOMAIN/rest/api/3/search?jql=$filter_jql"
    search_result=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" -X GET "$search_url")

    # Check if the search query returned an error message
    error_message=$(echo "$search_result" | jq '.errorMessages[]?' 2>/dev/null)

    if [[ -n "$error_message" ]]; then
        # Print if there's a broken JQL
        echo "Filter \"$filter_name\" (ID: $filter_id) has a broken JQL: $error_message"
    else
        # Print if the filter is working fine
        echo "Filter \"$filter_name\" (ID: $filter_id) is working fine."
    fi
done
