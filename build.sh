## 用法
# normal build: sh build.sh 
# clean build:  sh build.sh 1  

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

CLEAN=${1-0}
OUTPUT=output
mkdir -p $BASE/include $BASE/lib $BASE/bin

build () {
   echo "=========================================="
   echo "try to build $1"
   
   pushd $1
   [ "$CLEAN" == "1" ] && echo "clean build" && git clean -xdf

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
   \cp -rf $OUTPUT/lib/* $BASE/lib

   if [ "$3" == "bin" ]; then
      \cp -rf $OUTPUT/bin/* $BASE/bin
   fi

   popd
   popd
}

build gflags
build googletest
build protobuf cmake bin
build leveldb
build brpc
