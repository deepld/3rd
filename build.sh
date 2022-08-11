
## 用法
# git submodule update --init --recursive
# normal build: 
#    1) sh build.sh  
#    2) sh build.sh glog
# clean build:  
#    1) sh build.sh --clean 
#    2) sh build.sh --clean [glog|brpc|...] 
#    3) sh build.sh --api_version=10.14

BASE=$(cd "$(dirname "$0")";pwd)

# ================================================================
## 添加路径
THIRD_PATH=$BASE
export CMAKE_INCLUDE_PATH=$THIRD_PATH/include:$CMAKE_INCLUDE_PATH
export CMAKE_LIBRARY_PATH=$THIRD_PATH/lib:$CMAKE_LIBRARY_PATH
export PATH=$PATH:$THIRD_PATH/bin

# ================================================================
OUTPUT=output
LOG_PATH=/tmp/3rd.log

echo "" > $LOG_PATH
echo "copy:† \cp -rf $OUTPUT/lib*/* $BASE/lib" >> $LOG_PATH
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
   --api_version=*)
   MAC_API_VERSION=CXXFLAGS=$CXXFLAGS-mmacosx-version-min=${key#*=}
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
   
   SOURCE_PATH=".."
   BUILD_PATH=builds
   BUILD_LIBRARY="-DBUILD_SHARED_LIBS=0"
   CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUTPUT -DCMAKE_CXX_FLAGS=-fPIC"

   pushd $1
   if [ "$IS_CLEAN" == "1" ]; then 
      echo "clean build - $1"
      git clean -xdf
      rm -rf $BUILD_PATH
      # for protobuf, remove /home/deep.ld/repo/3rd/protobuf/cmake/CMakeCache.txt
      popd
      return
   fi

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

   ## fix error
   if [ "$1" == "leveldb" ]; then 
      echo "\n******"
      echo "remove [sigma_gn], vim leveldb/third_party/benchmark/src/complexity.cc"
      echo "******\n"
   elif [ "$1" == "glog" ]; then 
      echo "\n******"
      echo "change WITH_GTEST OFF, vim glog/CMakeLists.txt"
      echo "******\n"
   fi
   
   ## compile
   CMAKE_FLAGS="$CMAKE_FLAGS $BUILD_LIBRARY"
   cmake $SOURCE_PATH $CMAKE_FLAGS 
   make -j $MAC_API_VERSION && make install

   ## copy output
   if [ "$1" == "protobuf" ]; then 
      \cp -rf ../src/google/protobuf/*.inc $OUTPUT/include/google/protobuf 
   fi   
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
    build glog
fi

