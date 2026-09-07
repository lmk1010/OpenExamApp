构建时才有东西的目录。

`tool/bank.py link` 会把 `bank/openexam_seed.db.gz` 复制进来，那次构建就带内置
题库；`unlink` 拿掉，构建出来就是空库版（App Store 走这个）。

pubspec 里声明的是这个**目录**而不是具体文件 —— 声明成文件的话，文件不在就
构建失败，空库版根本打不出来。
