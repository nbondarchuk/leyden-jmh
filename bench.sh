MYDIR="$(cd "$(dirname $0)"; pwd)"
echo script is installed at $MYDIR

echo "PREMAIN_HOME=$1"
echo "MAINLINE_HOME=$2"

make clean
make PREMAIN_HOME=$1 MAINLINE_HOME=$2 $3