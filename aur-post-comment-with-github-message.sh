#!/bin/bash -x
#wip: probe for ID alongside $token

# config
aur_username="bartus"
github_username="bartoszek"
_message_eval_template='Please+report+%60issues%60+and+%60patches%60+to+%5B${pkgname}%40github.com%5D%28https%3A%2F%2Fgithub.com%2F${github_username}%2FAUR-${pkgname}%29'

#trap 'rm /tmp/aur_cookie.txt' EXIT


#  define evals for `curl`
_curl='curl -s -b /tmp/aur_cookie.txt "https://aur.archlinux.org/pkgbase/${pkgname}/"'
# post comment needs: token, comment, ID ( can be anything, AUR isn't chacking it )
_curl_post_comment=$_curl' -d "action=do_AddComment&ID=141089&token=${token}&comment=${message}"'
# pin comment needs: token, comment_id
_curl_pin_comment=$_curl' -d "action=do_PinComment&comment_id=${comment_id}&token=${token}"'

# message base on PKGBUILD
[ ! -f PKGBUILD ] && { echo "PKGBUILD missing, run $(basename "$0") inside package folder" >&2; exit 1;}
pkgname=$(. PKGBUILD; echo $pkgname)
message="$(eval echo $_message_eval_template)"

# check if cookie.txt exist
# get cookie with: curl -c cookie.txt -d "user=" -d "password=" https://aur.archlinux.org/login
[ -f /tmp/aur_cookie.txt ] || {
  read -p "password for ${aur_username}@aur:" pass
  curl -s -c /tmp/aur_cookie.txt 'https://aur.archlinux.org/login' -d "user=${aur_username}&passwd=$pass" >/dev/null
}

# get post token by probing comment FORM
token=$(eval ${_curl}|grep -Po 'name="token" value="\K[a-z0-9]*'|head -n1)
# post a comment
eval ${_curl_post_comment}
# get $comment_id
comment_id=$(eval ${_curl}|grep -Po 'name="comment_id" value="\K[0-9]*'|head -n1)
# ping comment base on $comment_id
eval ${_curl_pin_comment}
