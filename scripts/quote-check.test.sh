#!/usr/bin/env bash
# Tests scripts/quote-check on stub pages. QUOTE_CHECK_PAGES keeps it off the network.
# No network, no Claude.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
qc=$root/scripts/quote-check
tmp=$(mktemp -d)
trap 'rm -rf "${tmp:?}"' EXIT
failed=0
fail() { echo "FAIL: $1"; failed=1; }
has() { grep -qF -- "$2" <<<"$1" || fail "${3:-missing}: $2"; }

export QUOTE_CHECK_PAGES=$tmp/pages
mkdir -p "$QUOTE_CHECK_PAGES"
tab=$'\t'
url_a=https://code.claude.com/docs/en/a
url_b=https://example.com/b
url_gone=https://code.claude.com/docs/en/gone

stub() { printf '%s' "$2" >"$QUOTE_CHECK_PAGES/$(printf '%s' "$1" | sha256sum | cut -d' ' -f1)"; }
stub "$url_a" $'# Title\n\nThe cache keeps the\nfirst  request warm. It has *emphasis* and a [link text](https://x.test/p_q) too.\nThe “curly” quote \xe2\x80\x94 and a `code` span.\n'
stub "$url_b" $'<html><body><p>Tags &amp; entities are <b>stripped</b>.</p></body></html>\n'

printf 'A guide that says: The cache keeps the first request warm. It has emphasis and a link text too.\nThe "curly" quote - and a code span.\nTags & entities are stripped.\n' >"$tmp/guide.md"

run() {  # manifest body; sets out and rc
  printf '%b' "$1" >"$tmp/manifest.tsv"
  rc=0
  out=$("$qc" --manifest "$tmp/manifest.tsv" --guide "$tmp/guide.md" 2>&1) || rc=$?
}
expect() { ((rc == $1)) || fail "$2: exit $rc, wanted $1"; }

[[ -x $qc ]] || { echo "FAIL: scripts/quote-check is missing or not executable"; exit 1; }

run "# a comment\n\n$url_a${tab}The cache keeps the first request warm\n"
expect 0 'a present quote'

run "$url_a${tab}first request warm. It has emphasis and a link text too\n"
expect 0 'emphasis and a link in the page only'

run "$url_a${tab}The \"curly\" quote - and a code span\n"
expect 0 'curly quotes, a dash and backticks'

run "$url_b${tab}Tags & entities are stripped\n"
expect 0 'a non-docs page with tags and entities'

run "# first\n$url_a${tab}The cache keeps the first request warm\n$url_a${tab}A sentence the page never says\n"
expect 1 'a missing quote'
has "$out" "$url_a" 'the URL is not printed'
has "$out" 'line 3' 'the manifest line number is not printed'

run "$url_a${tab}The cache keeps the first request warm. It has emphasis\n"
expect 0 'a quote spanning emphasis'

printf 'Nothing quoted here.\n' >"$tmp/guide.md"
run "$url_a${tab}The cache keeps the first request warm\n"
expect 1 'a quote the guide lacks'
has "$out" 'guide' 'the guide is not named'

printf 'The cache keeps the first request warm.\n' >"$tmp/guide.md"
run "$url_gone${tab}The cache keeps the first request warm\n"
expect 2 'an unfetchable page'

run "$url_gone${tab}The cache keeps the first request warm\n$url_a${tab}Not on the page at all\n"
expect 2 'a fetch failure beside a missing quote'

printf 'The guide alone says this sentence.\n' >"$tmp/guide.md"
run "$url_a${tab}The guide alone says this sentence\n"
expect 1 'a quote in the guide but not on the page'
has "$out" 'not on the page' 'a quote the page lacks is not named'

printf 'The cache keeps the first request warm.\n' >"$tmp/guide.md"
for empty in '***' '`_`' '   '; do
  run "$url_a${tab}$empty\n"
  expect 1 "a quote that normalizes to empty: '$empty'"
  has "$out" 'empty' 'an empty quote is not named'
  has "$out" 'line 1' 'an empty quote has no line number'
done

run "# only a comment\n\n"
expect 1 'a manifest with no quotes'
has "$out" 'no quotes' 'an empty manifest is not named'

for bad in http://code.claude.com/docs/en/a ftp://example.com/b file:///etc/hostname; do
  stub "$bad" 'The cache keeps the first request warm'
  run "$bad${tab}The cache keeps the first request warm\n"
  expect 1 "a URL that is not https: $bad"
  has "$out" 'https' 'a bad scheme is not named'
done

# A live fetch against a stub curl: https only, redirects included, the URL as a
# value and not an option, and the manifest kept off curl's stdin.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/curl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$CURL_LOG"
cat >>"$CURL_STDIN"
echo 'The cache keeps the first request warm'
SH
chmod +x "$tmp/bin/curl"
printf '%b' "$url_a${tab}The cache keeps the first request warm\n$url_b${tab}The cache keeps the first request warm\n" >"$tmp/manifest.tsv"
export CURL_LOG=$tmp/curl.log CURL_STDIN=$tmp/curl.stdin
: >"$CURL_LOG"
: >"$CURL_STDIN"
rc=0
out=$(env -u QUOTE_CHECK_PAGES PATH="$tmp/bin:$PATH" "$qc" --manifest "$tmp/manifest.tsv" --guide "$tmp/guide.md" 2>&1) || rc=$?
expect 0 'a live fetch through curl'
log=$(<"$CURL_LOG")
args=$(tr '\n' ' ' <<<"$log")
[[ $(grep -cx -- '--proto' "$CURL_LOG") == 2 ]] || fail 'a curl call may follow another scheme'
[[ $(grep -cx -- '--proto-redir' "$CURL_LOG") == 2 ]] || fail 'a curl redirect may leave https'
has "$args" "--url $url_a.md" 'a docs URL is not passed with --url'
has "$args" "--url $url_b" 'another URL is not passed with --url'
[[ ! -s $CURL_STDIN ]] || fail 'curl read the manifest from stdin'

((failed == 0)) && echo "quote-check: all passed"
exit "$failed"
