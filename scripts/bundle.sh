LIBRARY_PATH=$(dirname $(realpath -s $0))/..
node "$LIBRARY_PATH/bundler" create "$LIBRARY_PATH" $@
