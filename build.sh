
## 用法
# git submodule update --init --recursive
# normal build: 
#    1) sh build.sh  
#    2) sh build.sh glog
# clean build:  
#    1) sh build.sh --clean 
#    2) sh build.sh --clean [glog|brpc|...] 

BASE=$(cd "$(dirname "$0")";pwd)

# ================================================================
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

# ================================================================
OUTPUT=output
LOG_PATH=/tmp/3rd.log

echo "" > $LOG_PATH
echo "copy: \cp -rf $OUTPUT/lib*/* $BASE/lib" >> $LOG_PATH
echo "copy: \cp -rf $OUTPUT/include/* $BASE/include" >> $LOG_PATH
echo "copy: \cp -rf $OUTPUT/lib*/* $BASE/lib" >> $LOG_PATH
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

## 指定目录 clean 时，不进行清理
if [ "$IS_CLEAN" == "1" -a "$1" == "" ]; then
   echo "clean output"
    rm -rf $BASE/include $BASE/lib $BASE/bin
fi

# ================================================================
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
   
   SOURCE_PATH=".."
   BUILD_PATH=builds
   BUILD_LIBRARY="-DBUILD_SHARED_LIBS=0"
   CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUTPUT -DCMAKE_CXX_FLAGS=-fPIC"

   POSITIONAL=()
   for key in "$@"; do
   case $key in
      --source=*) 
      SOURCE_PATH="${key#*=}"
      shift;;
      --build=*) 
      BUILD_PATH="${key#*=}"
      shift;;
      --copy_bin) 
      COPY_BIN=1
      shift;;
      --shared) 
      CMAKE_FLAGS="$CMAKE_FLAGS -DBUILD_SHARED_LIBS=1"
      BUILD_LIBRARY=
      shift;;
      --static) 
      CMAKE_FLAGS="$CMAKE_FLAGS -DBUILD_STATIC_LIBS=1"
      BUILD_LIBRARY=
      shift;;
      *)
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
   esac
   done
   set -- "${POSITIONAL[@]}" # restore positional parameters

   mkdir -p $BUILD_PATH
   pushd $BUILD_PATH

   CMAKE_FLAGS="$CMAKE_FLAGS $BUILD_LIBRARY"
   cmake $SOURCE_PATH $CMAKE_FLAGS 
   make -j && make install 

   \cp -rf $OUTPUT/include/* $BASE/include
   \cp -rf $OUTPUT/lib*/* $BASE/lib
   if [ "$COPY_BIN" == "1" ]; then
      \cp -rf $OUTPUT/bin/* $BASE/bin
   fi

   echo "" >> $LOG_PATH
   echo "build $1: $CMAKE_FLAGS" >> $LOG_PATH
   
   popd
   popd
}

# ================================================================
if [ -d "$1" ]; then
    build $*
else
    build gflags --shared --static
    build googletest
    build protobuf --source=. --build=cmake --copy_bin
    build leveldb
    build brpc
fi

