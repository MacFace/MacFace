#!/usr/bin/perl
@fileList = (
    "face-base.tiff",		# 0 ベース
    "brow-normal.tiff",		# 1 まゆ普通
    "brow-hi.tiff",			# 2 まゆ高
    "brow-up.tiff",			# 3 まゆ上がり
    "brow-down.tiff",		# 4 まゆ下がり
    "eye-spiral.tiff",		# 5 ぐるぐる目
    "eye-line.tiff",		# 6 線目
    "eye-close.tiff",		# 7 閉じ目
    "eye-circle.tiff",		# 8 丸目
    "eye-arrow.tiff",		# 9 矢印目
    "eye-smile.tiff",		# 10 笑い目
    "eye-normal.tiff",		# 11 普通目
    "mouth-smile.tiff",		# 12 ほほ笑み口
    "mouth-close.tiff",		# 13 閉じ口
    "mouth-circle.tiff",	# 14 おちょぼ口
    "mouth-open.tiff",		# 15 開き口
    "mouth-laugh.tiff"		# 16 笑い口
);

@faceDef = (
[[ 1, 7,15],[ 1, 6,13],[ 1, 6,14],[ 1,11,12],[ 2,11,16],[ 2,10,12],
			[ 2,10,16],[ 3, 8,12],[ 3, 8,16],[ 3, 9,16],[ 3, 9,16]],
[[ 1, 7,13],[ 7, 4,13],[ 1, 6,13],[ 1, 6,15],[ 2,11,16],[ 1,11,13],
			[ 3,11,15],[ 3, 8,12],[ 1, 8,13],[ 2, 5,14],[ 3, 5,15]],
[[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],
			[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],[ 4, 5,15],[ 3, 5,15]],
);

print <<EOM;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="0.9">
<dict>
	<key>titile</key>
	<string>Default face</string>
	<key>parts</key>
	<array>
EOM

foreach ( @fileList ){
	print <<EOM;
		<dict>
			<key>filename</key>
			<string>$_</string>
			<key>pos x</key>
			<integer>0</integer>
			<key>pos y</key>
			<integer>0</integer>
		</dict>
EOM
}

	print <<EOM;
	</array>
	<key>pattern</key>
	<array>
EOM

	foreach $line ( @faceDef ){
		print "\t\t<array>\n";
		foreach $pattern ( @$line ){
			print "\t\t\t<array>\n";
			print "\t\t\t\t<integer>0</integer>\n";
			foreach ( @$pattern ){
				print "\t\t\t\t<integer>$_</integer>\n";
			}
			print "\t\t\t</array>\n";
		}
		print "\t\t</array>\n";
	}

print <<EOM;
	</array>
</dict>
</plist>
EOM
