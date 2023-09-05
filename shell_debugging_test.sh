
SHELL=`ps -p $$`

if [[ $SHELL =~ ksh ]]; then
  ksh --version
elif [[ $SHELL =~ bash ]]; then
  bash --version
elif [[ $SHELL =~ zsh ]]; then
  zsh --version
elif [[ $SHELL =~ ' sh' ]]; then
  sh --version
else
  echo "unknown"
fi

set -x

# ksh doesn't have LINENO, and FUNCNAME is only available if "function" is used
# for definition
IS_THIS_DELAY_EVALUATED="eval echo \"\$LINENO \${FUNCNAME[0]:-\$0} \${FUNCNAME[1]}\""

# neither ksh88 not ksh93 will propagate the `set -x` here
function second_level_function {
  echo "in second_level_function"
  _="second_level_function trace test"
  $IS_THIS_DELAY_EVALUATED # should have 6 if LINENO and delayed
}

# ksh93 will propagate the `set -x` here, but not ksh88
first_level_function() {
  echo "in first_level_function"
  _="first_level_function trace test"
  $IS_THIS_DELAY_EVALUATED # should have 11 if LINENO and delayed
  second_level_function
}

first_level_function
