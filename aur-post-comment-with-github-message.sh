#!/bin/bash -x
#wip: probe for ID alongside $token

# config
aur_username="${username:-bartus}"
github_username="${github_username:-bartoszek}"
_message_eval_template='
# This package is also hosted on GitHub.

* Please report \`issues\` and \`patches\` to [${pkgname}*github.com](https://github.com/${github_username}/AUR-${pkgname})

* Travis CI Status: [![Build Status](https://travis-ci.org/${github_username}/AUR-${pkgname}.svg?branch=master)](https://travis-ci.org/${github_username}/AUR-${pkgname})
'

#trap 'rm /tmp/aur_cookie.txt' EXIT


#  define evals for `curl`
_curl='curl -L -s -b /tmp/aur_cookie.txt "https://aur.archlinux.org/pkgbase/${pkgname}/"'
# post comment needs: token, comment, ID ( can be anything, AUR isn't chacking it )
#_curl_post_comment=$_curl' -d "action=do_AddComment&ID=${ID}&token=${token}" --data-urlencode "comment=${message}"'
_curl_post_comment='curl -b /tmp/aur_cookie.txt "https://aur.archlinux.org/pkgbase/${pkgname}/comments" --data-urlencode "comment=${message}"'
# pin comment needs: token, comment_id
#_curl_pin_comment=$_curl' -d "action=do_PinComment&comment_id=${comment_id}&token=${token}"'
_curl_pin_comment='curl -b /tmp/aur_cookie.txt "https://aur.archlinux.org/pkgbase/${pkgname}/comments/${comment_id}/pin" --data-raw "submit.x=4&submit.y=7"'

# message base on PKGBUILD
[ ! -f PKGBUILD ] && { echo "PKGBUILD missing, run $(basename "$0") inside package folder" >&2; exit 1;}
pkgname=$(. PKGBUILD; echo $pkgname)
[[ ! -v message ]] && message="$(eval echo "\"$_message_eval_template\"")"

# check if cookie.txt exist
# get cookie with: curl -c cookie.txt -d "user=" -d "password=" https://aur.archlinux.org/login
[ -f /tmp/aur_cookie.txt ] || {
  read -p "password for ${aur_username}@aur:" pass
  curl -c /tmp/aur_cookie.txt 'https://aur.archlinux.org/login' -H 'referer: https://aur.archlinux.org/login' -d "user=${aur_username}&passwd=$pass&next=/" >/dev/null
}

# get post token/ID by probing comment FORM
# post a comment
eval ${_curl_post_comment}
# get $comment_id (latest comment_id will be last in the numerical order)
comment_id=$(eval ${_curl}|grep -Po 'comments/\K[0-9]*(?=\/pin)'|sort -n|tail -n1)
# ping comment base on $comment_id
eval ${_curl_pin_comment}
