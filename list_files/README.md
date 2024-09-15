## 使用方法

./list_files.sh [-o output_file] [-m custom_message] /path/to/directory

### オプション

- `-o output_file` : 結果を指定ファイルに保存
- `-m custom_message` : カスタムメッセージを設定

### 引数

- `/path/to/directory` : 対象ディレクトリ。省略時は現在のディレクトリ

## 例

1. 現在のディレクトリを表示：

    ./list_files.sh .

2. 結果を `output.md` に保存：

    ./list_files.sh -o output.md .

3. カスタムメッセージを設定し、クリップボードにコピー：

    ./list_files.sh -m "ディレクトリ内容" .
