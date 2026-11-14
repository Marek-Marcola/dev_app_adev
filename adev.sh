#!/bin/bash

VERSION_BIN="261114"

SN="${0##*/}"
ID="[${SN%.sh}]"

: ${OSN:=""}
: ${OSA:=""}
: ${OSC:=""}
: ${OSE:=""}

: ${V:=""}
: ${S:=""}

PATH=/usr/local/bin:/usr/sbin:$PATH

ARCH=0
ARCH_DIR="/tmp"
INSTALL_RSYNC=0
INSTALL_RSYNC_HL="$(hostname -s)"
INSTALL_ANPB=0
INSTALL_ANPB_HP="adev"
VERSION=0
STAGE_LIST=0
BACKUP=0
BACKUP_LIST=0
DEBUG=0
DEBUG_OPTS=""
LINK=0
LINK_CHECK=0
RINFO=0
RINFO_RE=""
RSHOW=0
RSHOW_RE=""
RFUNC=0
ELIST=0
ELIST_RE=""
ESHOW=0
EEDIT=0
AINIT=0
APULL=0
AUNPACK=0
ACONFIG=0
ABUILD=0
AINSTALL=0
ASAVE=0
APUSH=0
EVAL=0
HELP=0
: ${QUIET:=0}

ARGC=$#
declare -a DOCS
declare -a OPTS

s=0

: ${A:=${SN%.sh}}
: ${APN:=$(echo $A|cut -d- -f2)}
: ${API:=$(echo $A|cut -d- -f3-)}
: ${EDIR:="/usr/local/etc/adev.d"}
: ${RDIR:="/usr/local/etc/adev.d/recipes"}
: ${LDIR:="/usr/local/bin/alias-adev"}
: ${DDIR:="/var/backup/adev"}
: ${COMM:=$(readlink -f ${BASH_SOURCE})}

if [ -z "$OSN" ]; then
  if [ -f /etc/debian_version ]; then
    OSV=$(cat /etc/debian_version)
    if expr match $OSV kali > /dev/null; then
      OSN=kali
    else
      OSN=debian$(echo $OSV|awk -F. '{print $1}')
    fi
  elif [ -f /etc/centos-release ]; then
    OSV=$(cat /etc/centos-release)
    OSN=centos$(echo $OSV|awk '{print $4}'|awk -F. '{print $1}')
  elif [ -f /etc/rocky-release ]; then
    OSV=$(cat /etc/rocky-release)
    OSN=rocky$(echo $OSV|awk '{print $4}'|awk -F. '{print $1}')
  elif [ -f /etc/redhat-release ]; then
    OSV=$(cat /etc/redhat-release)
    OSN=rhel$(echo $OSV|awk '{print $4}'|awk -F. '{print $1}')
  fi
fi

if [ -z "$OSA" ]; then
  OSA=$(uname -m)
fi

if [ -z "$OSE" ]; then
  if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
    OSE=k8s
  elif [ -f /.dockerenv ]; then
    OSE=docker
  elif [ -f /run/.containerenv ]; then
    OSE=podman
  fi
fi

while [ $# -gt 0 ]; do
  case $1 in
    --ver*|-ver*)
      VERSION=1
      shift
      ;;
    --arch*|-arch*)
      ARCH=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && ARCH_DIR="$2" && shift
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_RSYNC_HL="$2" && shift
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    --stage|-stage)
      STAGE_LIST=1
      shift
      ;;
    -B)
      BACKUP=1
      BACKUP_LIST=1
      shift
      ;;
    -Bl)
      BACKUP_LIST=1
      shift
      ;;
    -g)
      DEBUG=1
      DEBUG_OPTS="--log-level=debug"
      shift
      ;;
    -A)
      A="$2"
      APN=$(echo $A|cut -d- -f2)
      API=$(echo $A|cut -d- -f3-)
      ID="[$A]"
      shift; shift
      ;;
    -L)
      LINK=1
      QUIET=1
      shift
      ;;
    -Lc)
      LINK_CHECK=1
      QUIET=1
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -el)
      ELIST=1
      [[ ${2:0:1} != "-" ]] && ELIST_RE="$2" && shift
      QUIET=1
      shift
      ;;
    -es)
      ESHOW=1
      ESHOW_RE="$2"
      QUIET=1
      shift; shift
      ;;
    -ee)
      EEDIT=1
      shift
      ;;
    -r)
      RINFO=1
      [[ ${2:0:1} != "-" ]] && RINFO_RE="$2" && shift
      QUIET=1
      shift
      ;;
    -rs)
      RSHOW=1
      [[ ${2:0:1} != "-" ]] && RSHOW_RE="$2" && shift
      QUIET=1
      shift
      ;;
    -f)
      RFUNC=1
      QUIET=1
      shift
      ;;
    -init)
      AINIT=1
      shift
      ;;
    -P)
      APULL=1
      shift
      ;;
    -u)
      AUNPACK=1
      shift
      ;;
    -c)
      ACONFIG=1
      shift
      ;;
    -b)
      ABUILD=1
      shift
      ;;
    -i)
      AINSTALL=1
      shift
      ;;
    -s)
      ASAVE=1
      shift
      ;;
    -p)
      APUSH=1
      shift
      ;;
    -V)
      V="$2"
      shift; shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    --)
      shift
      for i in $*; do
        OPTS+=("$i")
      done
      break
      ;;
    *)
      OPTS+=("$1")
      shift
      ;;
  esac
done

if [[ $ARGC -eq 0 && "$A" = "adev" ]]; then
  ELIST=1
  QUIET=1
fi

if [[ $ARGC -eq 1 && "$A" = "adev" ]]; then
  if [ -n "${OPTS[0]}" ]; then
    ELIST=1
    ELIST_RE=${OPTS[0]}
    QUIET=1
  fi
fi

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "Application development tools."
  echo ""
  echo "$SN -ver                      # version"
  echo "$SN -arch [dir]               # archive"
  echo "$SN -inst [host_list]    [-x] # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo "$SN -stage                    # stage list"
  echo ""
  echo "$SN -B                        # backup"
  echo "$SN -Bl                       # backup list"
  echo ""
  echo "$SN -L  [-x]                  # link show,run"
  echo "$SN -Lc                       # link check"
  echo ""
  echo "$SN -r                        # recipe info"
  echo "$SN -rs [re]                  # recipe show"
  echo "$SN -f                        # recipe functions"
  echo ""
  echo "$SN -init                     # app init"
  echo "$SN -P                        # app pull"
  echo "$SN -u                        # app unpack"
  echo "$SN -c                        # app config"
  echo "$SN -b                        # app build"
  echo "$SN -i                        # app install"
  echo "$SN -s                        # app save"
  echo "$SN -p                        # app push"
  echo ""
  echo "$SN -el [re]                  # env list"
  echo "$SN -es [re]                  # env show"
  echo "$SN -ee                       # env edit"
  echo ""
  echo "$SN [re]                      # env list"
  echo ""
  echo "opts:"
  echo "  -V   app version"
  exit 0
fi

#
# stage: CONFIG
#
for f in /usr/local/etc/adev.env $EDIR/$A $HOME/.adev.env .adev.env $ADEVENV; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

for f in "${RECIPES[@]}"; do
  if [ -e $RDIR/$f ]; then
    [[ "$RFILE" != "" ]] && RFILE="$RFILE $RDIR/$f" || RFILE="$RDIR/$f"
    . $RDIR/$f
  fi
done

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  exit 0
fi

#
# stage: ARCH
#
if [ $ARCH -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ARCH (DIR=$ARCH_DIR)"

  if [ ! -d "$ARCH_DIR" ]; then
    echo "$ID: E: arch dir not found: $ARCH_DIR"
    exit 1
  fi

  if [ ! -f adev.sh ]; then
    echo "$ID: E: no files to archive"
    exit 1
  fi

  D=adev-$(date "+%y%m%d%H%M")
  F=$ARCH_DIR/$D.tar

  set -x
  tar cf $F --transform "s|^|$D/|" LICENSE README* *.sh
  gzip -f $F
  ls -ogh --time-style=long $F.gz
  { set +x; } 2>/dev/null

  exit 0
fi

#
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-RSYNC (EVAL=$EVAL HL=$INSTALL_RSYNC_HL)"

  [[ $EVAL -ne 1 ]] && EVAL_OPT="-n" || EVAL_OPT=""

  if [ -f adev.sh ]; then
    for d in /usr/local/bin /pub/pkb/pb/playbooks/999206-adev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT adev.sh $d/adev.sh
        { set +ex; } 2>/dev/null
      fi
    done
  elif [ -f /pub/pkb/pb/playbooks/999206-adev/files/adev.sh ]; then
    for h in $(echo $INSTALL_RSYNC_HL|sed 's/,/ /g'); do
      set -ex
      rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/999206-adev/files/adev.sh $h:/usr/local/bin/adev.sh
      { set +ex; } 2>/dev/null
    done
  fi

  if [ -f zlocal-adev.sh ]; then
    for d in /etc/profile.d/ /pub/pkb/pb/playbooks/999206-adev/files/; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT zlocal-adev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  elif [ -f /pub/pkb/pb/playbooks/999206-adev/files/zlocal-adev.sh ]; then
    for h in $(echo $INSTALL_RSYNC_HL|sed 's/,/ /g'); do
      set -ex
      rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/999206-adev/files/zlocal-adev.sh $h:/etc/profile.d/zlocal-adev.sh
      { set +ex; } 2>/dev/null
    done
  fi

  if [ -d recipes ]; then
    for d in /usr/local/etc/adev.d/recipes /pub/pkb/pb/playbooks/999206-adev/files/recipes; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT recipes/ $d
        { set +ex; } 2>/dev/null
      fi
    done
  elif [ -d /pub/pkb/pb/playbooks/999206-adev/files/recipes ]; then
    for h in $(echo $INSTALL_RSYNC_HL|sed 's/,/ /g'); do
      set -ex
      rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/999206-adev/files/recipes/ $h:/usr/local/etc/adev.d/recipes/
      { set +ex; } 2>/dev/null
    done
  fi

  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL HP=$INSTALL_ANPB_HP)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: E: command not found: anpb"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb adev_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

  exit 0
fi

#
# stage: STAGE-LIST
#
if [ $STAGE_LIST -eq 1 ]; then
  cat $COMM | grep '^#' | grep 'stage:'
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info      = $INFO"
  echo "cwd       = $(pwd -P)"
  echo "OSN       = ${OSN:-[none]}"
  echo "OSA       = ${OSA:-[none]}"
  echo "OSE       = ${OSE:-[none]}"
  echo "efile     = ${EFILE:-[none]}"
  echo "rfile     = ${RFILE:-[none]}"
  echo "App       = ${A:-[none]}"
  echo "APN       = ${APN:-[none]}"
  echo "API       = ${API:-[none]}"
  echo "Ver       = ${V:-[none]}"
  echo "Src       = ${S:-[none]}"
  echo "DST       = ${DST:-[none]}"
  echo "wdir      = ${WDIR:-[none]}"
  echo "edir      = ${EDIR:-[none]}"
  echo "ldir      = ${LDIR:-[none]}"
  echo "comm      = ${COMM:-[none]}"

  if [ -n "$(type -t do_init)" ]; then
    echo "f_init    = do_init"
  else
    echo "f_init    = [none]"
  fi

  if [ -n "$(type -t do_pull)" ]; then
    echo "f_pull    = do_pull"
  else
    echo "f_pull    = [none]"
  fi

  if [ -n "$(type -t do_unpack)" ]; then
    echo "f_unpack  = do_unpack"
  else
    echo "f_unpack  = [none]"
  fi

  if [ -n "$(type -t do_config)" ]; then
    echo "f_config  = do_config"
  else
    echo "f_config  = [none]"
  fi

  if [ -n "$(type -t do_build)" ]; then
    echo "f_build   = do_build"
  else
    echo "f_build   = [none]"
  fi

  if [ -n "$(type -t do_install)" ]; then
    echo "f_install = do_install"
  else
    echo "f_install = [none]"
  fi

  if [ -n "$(type -t do_save)" ]; then
    echo "f_save    = do_save"
  else
    echo "f_save    = [none]"
  fi

  if [ -n "$(type -t do_push)" ]; then
    echo "f_push    = do_push"
  else
    echo "f_push    = [none]"
  fi

  if [ -n "$OPTS" ]; then
    echo "opts      = ${OPTS[@]}"
  else
    echo "opts      = [none]"
  fi

  if [ -n "$DOCS" ]; then
    echo -n "docs      = "
    for s in "${DOCS[@]}"; do
      echo "$s"
    done | sed '2,$s/^/            /'
  fi
fi

#
# stage: LINK
#
if [ $LINK -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LINK (EVAL=$EVAL)"

  if [ ! -d $EDIR ]; then
    echo "$ID: E: directory not found: $EDIR"
    exit 1
  fi
  if [ ! -d $LDIR ]; then
    echo "$ID: E: directory not found: $LDIR"
    exit 1
  fi

  ls $EDIR/ | \
  while read E; do
    if [ -x $EDIR/$E ]; then
      continue
    fi
    if grep -q EXEC=1 $EDIR/$E; then
      LSRC=${COMM%.sh}-exec.sh
    else
      LSRC=${COMM}
    fi
    if [ ! -f $LDIR/$E ]; then
      if [ $EVAL -ne 0 ]; then
        set -ex
        ln -svr $LSRC $LDIR/$E
        { set +ex; } 2>/dev/null
      else
        echo "ln -svr $LSRC $LDIR/$E"
      fi
    else
      echo "# ln -svr $LSRC $LDIR/$E"
    fi
  done
fi

#
# stage: LINK-CHECK
#
if [ $LINK_CHECK -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LINK-CHECK"

  if [ ! -d $EDIR ]; then
    echo "$ID: E: directory not found: $EDIR"
    exit 1
  fi
  if [ ! -d $LDIR ]; then
    echo "$ID: E: directory not found: $LDIR"
    exit 1
  fi

  ls $LDIR/ | \
  while read L; do
    if [ ! -f $EDIR/$L ]; then
      echo " - $LDIR/$L"
    fi
  done
fi

#
# stage: RECIPE-INFO
#
if [ $RINFO -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RECIPE-INFO (re: *$RINFO_RE*)"

  (
  echo Recipe Info
  for f in $RDIR/*$RINFO_RE*; do
    (
    if [ -f $f ]; then
      unset INFO
      . $f

      [[ "$INFO" = "" ]] && INFO="-"
      XINFO=$(echo $INFO|sed 's/ /__SPACE__/g')
      echo "$(basename $f) $XINFO"
    fi
    )
  done
  ) 2>/dev/null | column -t | sed 's/__SPACE__/ /g'

  i=0

  for f in $RDIR/*$RINFO_RE*; do
    if [ -f $f ]; then
      ((i++))
    fi
  done

  if [ $i -ne 0 ]; then
    echo "[$i]"
  fi
fi

#
# stage: RECIPE-SHOW
#
if [ $RSHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RECIPE-SHOW (re: *$RSHOW_RE*)"

  if [ -d $RDIR ]; then
    cd  $RDIR
    for f in $(ls *$RSHOW_RE* 2>/dev/null); do
      echo "### recipe: $f"
      cat $f
    done
  fi
fi

#
# stage: RECIPE-FUNCIONS
#
if [ $RFUNC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: RECIPE-FUNCIONS"

  if [ -n "$(type -t do_init)" ]; then
    declare -f do_init
  fi

  if [ -n "$(type -t do_pull)" ]; then
    echo
    declare -f do_pull
  fi

  if [ -n "$(type -t do_unpack)" ]; then
    echo
    declare -f do_unpack
  fi

  if [ -n "$(type -t do_config)" ]; then
    echo
    declare -f do_config
  fi

  if [ -n "$(type -t do_build)" ]; then
    echo
    declare -f do_build
  fi

  if [ -n "$(type -t do_install)" ]; then
    echo
    declare -f do_install
  fi

  if [ -n "$(type -t do_save)" ]; then
    echo
    declare -f do_save
  fi

  if [ -n "$(type -t do_push)" ]; then
    echo
    declare -f do_push
  fi
fi

#
# stage: ENV-LIST
#
if [ $ELIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-LIST (re: *$ELIST_RE*)"

  (
  echo Env Recipes Ver
  for f in $EDIR/*$ELIST_RE*; do
    (
    if [ -f $f ]; then
      unset INFO
      . $f

      if [[ -n "$RECIPES" ]]; then
        P=$(echo "${RECIPES[@]}"|sed 's/ /,/g')
      else
        P="-"
      fi

      [[ "$V" = "" ]] && V="-"
      XV=$(echo $V|sed 's/ /__SPACE__/g')

      echo "$(basename $f) $P $XV"
    fi
    )
  done
  ) 2>/dev/null | column -t | sed 's/__SPACE__/ /g'

  i=0

  for f in $EDIR/*$ELIST_RE*; do
    if [ -f $f ]; then
      ((i++))
    fi
  done

  if [ $i -ne 0 ]; then
    echo "[$i]"
  fi
fi

#     
# stage: ENV-SHOW
#   
if [ $ESHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (re: *$ESHOW_RE*)"
    
  if [ "$A" != "adev" -a  "$ESHOW_RE" = "" ]; then
    if [ ! -f $EDIR/$A ]; then
      echo "$ID: E: file not found: $EDIR/$A"
    else
      set -ex
      cat $EDIR/$A
      { set +ex; } 2>/dev/null
    fi
  else
    for f in $( ls $EDIR/*$ESHOW_RE*); do
      if [ -f $f ]; then
        set -ex
        cat $f  2>&1
        { set +ex; } 2>/dev/null
        echo
      fi
    done
  fi
fi

#
# stage: ENV-EDIT
#
if [ $EEDIT -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-EDIT"

  if [ ! -d $EDIR ]; then
    echo "$ID: E: directory not found: $EDIR"
  else
    if [ "$EDITOR" != "" ]; then
      set -ex
      $EDITOR $EDIR/$A
      { set +ex; } 2>/dev/null
    else
      set -ex
      vi $EDIR/$A
      { set +ex; } 2>/dev/null
    fi
  fi
fi

#
# stage: APP-INIT
#
if [ $AINIT -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-INIT"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_init)" ]; then
    set -ex
    do_init
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_init"
  fi
fi

#
# stage: APP-PULL
#
if [ $APULL -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-PULL"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_pull)" ]; then
    set -ex
    do_pull
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_pull"
  fi
fi

#
# stage: APP-UNPACK
#
if [ $AUNPACK -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-UNPACK"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_unpack)" ]; then
    set -ex
    do_unpack
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_unpack"
  fi
fi

#
# stage: APP-CONFIG
#
if [ $ACONFIG -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-CONFIG"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_config)" ]; then
    set -ex
    do_config
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_config"
  fi
fi

#
# stage: APP-BUILD
#
if [ $ABUILD -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-BUILD"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_build)" ]; then
    set -ex
    do_build
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_build"
  fi
fi

#
# stage: APP-INSTALL
#
if [ $AINSTALL -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-INSTALL"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_install)" ]; then
    set -ex
    do_install
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_install"
  fi
fi

#
# stage: APP-SAVE
#
if [ $ASAVE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-SAVE"

  if [ -n "$WDIR" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_save)" ]; then
    set -ex
    do_save
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_save"
  fi
fi

#
# stage: APP-PUSH
#
if [ $APUSH -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: APP-PUSH"

  if [ "$WDIR" != "" ]; then
    set -ex
    cd $WDIR
    { set +ex; } 2>/dev/null
  fi

  if [ -n "$(type -t do_push)" ]; then
    set -ex
    do_push
    { set +ex; } 2>/dev/null
  else
    echo "W: function not defined: do_push"
  fi
fi

#
# stage: BACKUP
#
if [ $BACKUP -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP"

  if [ ! -d $DDIR ]; then
    set -x
    mkdir -pv $DDIR
    { set +x; } 2>/dev/null
  fi

  F=$DDIR/adev-$(hostname -s)-$(date "+%y%m%d%H%M").tar

  set -x
  cd /usr/local
  tar cf $F etc/adev* bin/adev*
  gzip -f $F
  ls -ogh --time-style=long $F.gz
  { set +x; } 2>/dev/null
fi

#
# stage: BACKUP-LIST
#
if [ $BACKUP_LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-LIST"

  set -x
  tree --noreport -F -h -C -L 1 $DDIR
  { set +x; } 2>/dev/null
fi
