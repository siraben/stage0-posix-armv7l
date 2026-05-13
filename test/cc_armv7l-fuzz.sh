#!/bin/sh
set -eu

tmp=${TMPDIR:-/tmp}/cc_armv7l-fuzz.$$
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

QEMU=${QEMU:-qemu-arm}

if ! command -v "$QEMU" >/dev/null 2>&1; then
	echo "skipping: $QEMU not found"
	exit 0
fi

if command -v arm-linux-gnueabihf-as >/dev/null 2>&1 && command -v arm-linux-gnueabihf-ld >/dev/null 2>&1; then
	arm-linux-gnueabihf-as GAS/cc_x86.S -o "$tmp/cc_armv7l.o"
	arm-linux-gnueabihf-ld "$tmp/cc_armv7l.o" -o "$tmp/cc_armv7l"
elif command -v arm-linux-gnueabi-as >/dev/null 2>&1 && command -v arm-linux-gnueabi-ld >/dev/null 2>&1; then
	arm-linux-gnueabi-as GAS/cc_x86.S -o "$tmp/cc_armv7l.o"
	arm-linux-gnueabi-ld "$tmp/cc_armv7l.o" -o "$tmp/cc_armv7l"
elif command -v clang >/dev/null 2>&1; then
	clang --target=armv7-linux-gnueabihf -nostdlib -static -fuse-ld=lld \
		GAS/cc_x86.S -o "$tmp/cc_armv7l"
else
	echo "no armv7l assembler or clang found"
	exit 1
fi

check_no_crash()
{
	name=$1
	input=$2
	printf '%s' "$input" > "$tmp/$name.c"
	set +e
	timeout 5 "$QEMU" "$tmp/cc_armv7l" "$tmp/$name.c" "$tmp/$name.M1" >/dev/null 2>&1
	status=$?
	set -e
	if [ "$status" -eq 124 ]; then
		echo "$name timed out"
		exit 1
	fi
	if [ "$status" -ge 128 ]; then
		echo "$name crashed with status $status"
		exit 1
	fi
}

check_no_crash unterminated-string '"'
check_no_crash line-comment-eof 'int#main() { return 0; }'
check_no_crash block-comment-eof '/*'
check_no_crash global-declarator-eof 'int 0'
check_no_crash global-open-paren-eof 'int('
check_no_crash global-close-brace-eof 'int}'
check_no_crash global-quote-eof 'int"'
check_no_crash global-single-quote-eof "int'"
check_no_crash function-arguments-eof 'int 0('
check_no_crash function-declaration-eof 'int 0()'
check_no_crash function-expression-eof 'int 0()0'
check_no_crash function-return-eof 'int 0()return'
check_no_crash function-body-eof 'int 0(){'
check_no_crash function-body-statement-eof 'int 0(){0;'
check_no_crash function-if-eof 'int 0()if(0)'
check_no_crash function-return-unary-eof 'int 0()return~'
check_no_crash function-local-name-eof 'int 0()int'
check_no_crash function-global-load-eof 'int x;int 0()x'
check_no_crash function-name-load-eof 'int n()n'
check_no_crash function-local-delimiter-eof 'int 0(){0;int}'
check_no_crash function-local-declaration-eof 'int 0()int 0'
check_no_crash function-if-no-else-eof 'int 0()if(0)0;'
check_no_crash function-array-target-eof 'int 0()0[0'
check_no_crash function-call-open-eof 'int m0in()return m0in('
check_no_crash function-local-load-eof 'int 0(){int i;i'
check_no_crash enum-open-eof 'enum {'
check_no_crash enum-value-eof 'enum { A ='
check_no_crash enum-comma-eof 'enum { A = 1,'
check_no_crash asm-open-eof 'int main() asm('
check_no_crash asm-string-eof 'int main() asm("x"'
check_no_crash for-open-eof 'int main() for('
check_no_crash sizeof-open-eof 'int main() return sizeof('
check_no_crash struct-open-eof 'struct s {'
check_no_crash struct-member-type-eof 'struct s { int'
check_no_crash struct-array-open-eof 'struct s { int x['
check_no_crash arrow-member-eof 'struct s { int x; }; int main(){ struct s *p; p->'
check_no_crash arrow-load-eof 'struct s { int x; }; int main(){ struct s *p; p->x'
check_no_crash goto-label-eof 'int main() goto'
check_no_crash scalar-array-index-eof 'int n(){int x;x[0]'
check_no_crash struct-array-load-eof 'struct S{char*s;int y[4];};int n(){struct S*p;p->s="";return p->y[0]'
check_no_crash scalar-arrow-member-eof 'int n(){int x;1->y'
check_no_crash struct-array-member-type-eof 'struct S{S e[a'
