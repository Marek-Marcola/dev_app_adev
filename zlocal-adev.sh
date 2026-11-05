export PATH=/usr/local/bin/alias-adev:$PATH

a() {
  local desc="@@application development (via adev.sh)@@"
  adev.sh $@
}
