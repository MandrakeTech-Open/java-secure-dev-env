#!/bin/bash

hit_url() {
    unset HTTP_RESP_CODE
    url="$1"

    if [ -z "${url}" ]; then
        >&2 echo "incorrect parameters to hit_url [${url}]"
        exit 100
    fi

    # Check the HTTP status code
    HTTP_RESP_CODE=$(curl -sk -o /dev/null --no-buffer -w '%{http_code}' ${url})
    if [[ "${HTTP_RESP_CODE}" == "000" ]]; then
        HTTP_RESP_CODE=0
    fi
    echo "Received http code:[$HTTP_RESP_CODE]"
    export HTTP_RESP_CODE
}

check_abort_url() {
    if [[ $# -ne 2 ]]; then
        >&2 echo "incorrect parameters to check_abort_url [${msg}] [${url}]"
        return 100
    fi

    msg="$1"
    url="$2"

    echo "$msg"
    # Check the HTTP status code
    hit_url "${url}"

    # Fail if the response code is not 400-499 (HTTP aborts)
    if [[ ${HTTP_RESP_CODE} -ne 0 && (${HTTP_RESP_CODE} -lt 400 || ${HTTP_RESP_CODE} -gt 499) ]]; then
        >&2 echo "Error: Unexpected response code from [$url]: $HTTP_RESP_CODE"
        exit 10
    fi
}

check_redirect_url() {
    if [[ $# -ne 2 ]]; then
        >&2 echo "incorrect parameters to check_redirect_url [${msg}] [${url}]"
        exit 100
    fi

    msg="$1"
    url="$2"

    echo "$msg"
    # Check the HTTP status code
    hit_url "${url}"

    # Fail if the response code is not 400-499 (HTTP aborts)
    if [[ $HTTP_RESP_CODE -ne 308 ]]; then
        >&2 echo "Error: Unexpected response code from [$url]: $HTTP_RESP_CODE"
        exit 11
    fi
}

check_success_or_gateway_error_url() {
    if [[ $# -ne 2 ]]; then
        >&2 echo "incorrect parameters to check_success_or_gateway_error_url [${msg}] [${url}]"
        exit 100
    fi

    msg="$1"
    url="$2"

    echo "$msg"
    # Check the HTTP status code
    hit_url "${url}"

    # Fail if the response code is not 400-499 (HTTP aborts)
    if [[ $HTTP_RESP_CODE -lt 500 || $HTTP_RESP_CODE -gt 599 ]]; then
        >&2 echo "Error: Unexpected response code from [$url]: $HTTP_RESP_CODE"
        exit 12
    fi
}

check_redirect_url "Request to loadbalancer (raw)" "http://ingress.localhost/"

check_abort_url "Request to loadbalancer (secure)" "https://ingress.localhost/"

check_success_or_gateway_error_url "Request to external domain with environment variable [www.localhost]" "https://www.localhost/"
