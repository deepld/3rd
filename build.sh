
## 用法
# git submodule update --init --recursive
# normal build: 
#    1) sh build.sh  
#    2) sh build.sh glog
# clean build:  
#    1) sh build.sh --clean 
#    2) sh build.sh --clean [glog|brpc|...] 

BASE=$(cd "$(dirname "$0")";pwd)

## 添加路径
BASH_3rd=~/.bash_3rd
cat << EOF > $BASH_3rd
   BASE=$BASE
   export CMAKE_INCLUDE_PATH=\$BASE/include:\$CMAKE_INCLUDE_PATH
   export CMAKE_LIBRARY_PATH=\$BASE/lib:\$CMAKE_LIBRARY_PATH
   export PATH=\$PATH:\$BASE/bin
EOF

if ! grep -q "$BASH_3rd" ~/.bashrc; then
cat << EOF >> ~/.bashrc
   source $BASH_3rd
EOF
source $BASH_3rd  ## 当前立即生效
fi

OUTPUT=output
mkdir -p $BASE/include $BASE/lib $BASE/bin

 # set -x
POSITIONAL=()
for key in "$@"; do
case $key in
   --clean) 
   IS_CLEAN="1"
   shift;;
   *)
   POSITIONAL+=("$1") # save it in an array for later
   shift # past argument
   ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

build () {
   echo "=========================================="
   echo "try to build $1"
   
   pushd $1
   if [ "$IS_CLEAN" == "1" ]; then 
      echo "clean build - $1"
      git clean -xdf
      popd
      return
   fi
   
   BUILD_PATH=${2-builds}
   mkdir -p $BUILD_PATH
   pushd $BUILD_PATH

   if [ "$BUILD_PATH" == "builds" ]; then
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUTPUT ..
   else
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUTPUT .
   fi

   make -j && make install 

   \cp -rf $OUTPUT/include/* $BASE/include
   \cp -rf $OUTPUT/lib*/* $BASE/lib

   if [ "$3" == "bin" ]; then
      \cp -rf $OUTPUT/bin/* $BASE/bin
   fi

   popd
   popd
}

if [ -d "$1" ]; then
    build $1
else
    build gflags
    build googletest
    build protobuf cmake bin
    build leveldb
    build brpc
fi

